// ADSinglePropertyView.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address View Framework for GNUstep

#import "ADSinglePropertyView.h"

// redefine _(@"...") so that it looks into our bundle, not the main bundle
#undef _
#define _(x) [[NSBundle bundleForClass: [ADSinglePropertyView class]] \
		   localizedStringForKey: x \
		   value: x \
		   table: nil]

@interface ADSinglePropertyView (Private)
- (void) _buildArrays;
- (void) _handleDatabaseChanged: (NSNotification*) note;
- (void) _selectGroupInBrowser: (id) sender;
- (void) _doubleOnBrowser: (id) sender;
@end

@implementation ADSinglePropertyView (Private)
- (void) _buildArrays
{
  ADPropertyType type;
  NSArray *people;
  ADPerson *p;
  NSEnumerator *e;

  [_names release]; [_values release]; [_namesUnthinned release];
  [_people release];
  _names = [[NSMutableArray alloc] init];
  _namesUnthinned = [[NSMutableArray alloc] init];
  _values = [[NSMutableArray alloc] init];
  _people = [[NSMutableArray alloc] init];

  type = [[ADPerson class] typeOfProperty: _property];

  if(_selectedGroup)
    {
      ADRecord *record;
      NSString *uid = [_selectedGroup uniqueId];
      record = [[_book recordForUniqueId: uid] retain];
      if ([record isKindOfClass:[ADGroup class]])
        {
         [_selectedGroup autorelease];
          _selectedGroup = (ADGroup *)record;
        }
      else
        {
          NSLog(@"Internal Error: recordForUniqueId should return an ADGroup");
        }
    }
  
  if(!_selectedGroup)
    people = [_book people];
  else
    people = [_selectedGroup members];
  people = [people sortedArrayUsingSelector: @selector(compareByScreenName:)];

  e = [people objectEnumerator];
  while((p = [e nextObject]))
    {
      if(type & ADMultiValueMask)
	{
	  int i, index; BOOL hasPreferred;
	  id val;

	  val = [p valueForProperty: _property];
	  if(![val count]) continue;

	  hasPreferred = NO; // does it have values matching the
			     // preferred label? 
	  if(_prefLabel)
	    for(i=0; i<[val count]; i++)
	      if([_prefLabel isEqualToString: [val labelAtIndex: i]])
		{
		  hasPreferred = YES;
		  break;
		}

	  for(i=0,index=0; i<[val count]; i++)
	    {
	      if(hasPreferred &&
		 ![_prefLabel isEqualToString: [val labelAtIndex: i]])
		continue;
	      
	      if(index==0)
		{
		  NSString *name = [p screenName];
		  if(p == [_book me])
		    name = [name stringByAppendingString: _(@" (Me)")];
		  [_names addObject: name];
		}
	      else [_names addObject: @""];
	      [_namesUnthinned addObject: [p screenName]];
	      [_values addObject: [[val valueAtIndex: i] description]];
	      [_people addObject: p];

	      index++;
	    }
	}
      else
	{
	  if(![p valueForProperty: _property]) continue;
	  [_names addObject: [p screenName]];
	  [_namesUnthinned addObject: [p screenName]];
	  [_values addObject: [[p valueForProperty: _property] description]];
	}
    }

  [_peopleTable reloadData];
}

- (void) _handleDatabaseChanged: (NSNotification*) note
{
  int row;
  
  [self _buildArrays];

  row = [_groupsBrowser selectedRowInColumn: 0];
  [_groupsBrowser reloadColumn: 0];
  [_groupsBrowser selectRow: row inColumn: 0];
}

- (void) _handleDoubleclickOnTable: (id) sender
{
  NSString *name;
  NSString *value;
  int row;

  row = [sender selectedRow];
  if(row == -1 || !_delegate) return;
  name = [_namesUnthinned objectAtIndex: row];
  value = [_values objectAtIndex: row];
  
  if([_delegate
       respondsToSelector: @selector(doubleClickOnName:value:inView:)])
    [_delegate doubleClickOnName: name value: value inView: self];
}

- (void) _selectGroupInBrowser: (id) sender
{
  int row;
  ADGroup *newGroup = nil;

  if(!_book) _book = [ADAddressBook sharedAddressBook];
  row = [sender selectedRowInColumn: 0];
  if(row) newGroup = [[_book groups] objectAtIndex: row-1];

  if(newGroup == _selectedGroup) return;

  [_selectedGroup release];
  _selectedGroup = [newGroup retain];

  [_peopleTable deselectAll: self];
  [self _buildArrays];
  [_peopleTable reloadData];
}

- (void) _doubleOnBrowser: (id) sender
{
  [self autoselectAccordingToMode: _autosel];
}
@end

@implementation ADSinglePropertyView
- initWithFrame: (NSRect) frame
{
  NSRect r;

  if(![super initWithFrame: frame]) return nil;

  [self setDisplayedProperty: ADEmailProperty];
  _selectedGroup = nil;
  
  [self setAutoresizesSubviews: YES];

  r = frame; r.origin = NSMakePoint(0, 0);
  _splitView = [[[NSSplitView alloc] initWithFrame: r] autorelease];
  [_splitView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [_splitView setVertical: YES];
  [_splitView setDelegate: self];
  [self addSubview: _splitView];

  r = frame; r.origin = NSMakePoint(0, 0);
  r.size.width = frame.size.width/4;
  _groupsBrowser = [[[NSBrowser alloc] initWithFrame: r] autorelease];
  [_groupsBrowser setMaxVisibleColumns: 1];
  [_groupsBrowser setAllowsEmptySelection: NO];
  [_groupsBrowser setAllowsMultipleSelection: NO];
  [_groupsBrowser setDelegate: self];
  [_groupsBrowser setTarget: self];
  [_groupsBrowser setAction: @selector(_selectGroupInBrowser:)];
  [_groupsBrowser setDoubleAction: @selector(_doubleOnBrowser:)];
  [_groupsBrowser loadColumnZero];
  [_groupsBrowser selectRow: 0 inColumn: 0];
  [_splitView addSubview: _groupsBrowser];
  
  r = frame; r.origin = NSMakePoint(0, 0);
  r.size.width = (frame.size.width*3)/4;
  _ptScrollView = [[[NSScrollView alloc] initWithFrame: r] autorelease];
  [_ptScrollView setRulersVisible: NO];
  [_ptScrollView setHasVerticalScroller: YES];
  [_ptScrollView setHasHorizontalScroller: YES];
  [_ptScrollView setBorderType: NSBezelBorder];
  [_ptScrollView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [_splitView addSubview: _ptScrollView];

  _peopleTable = [[[NSTableView alloc] initWithFrame: frame] autorelease];
  [_peopleTable setDataSource: self];
  [_peopleTable setTarget: self];
  [_peopleTable setDelegate: self];
  [_peopleTable setDoubleAction: @selector(_handleDoubleclickOnTable:)];

  _nameColumn = [[[NSTableColumn alloc] initWithIdentifier: @"Name"]
		  autorelease];
  [[_nameColumn headerCell] setStringValue: _(@"Person Name")];
  
  _propertyColumn = [[[NSTableColumn alloc] initWithIdentifier: @"Property"]
		      autorelease];
  [[_propertyColumn headerCell]
    setStringValue: ADLocalizedPropertyOrLabel(_property)];
  
  [_peopleTable addTableColumn: _nameColumn];
  [_peopleTable addTableColumn: _propertyColumn];
  [_peopleTable setAutoresizesAllColumnsToFit: YES];
  [_peopleTable setAllowsMultipleSelection: YES];
  [_peopleTable sizeToFit];

  [_ptScrollView setDocumentView: _peopleTable];

  _delegate = nil;
  _prefLabel = nil;
  _autosel = ADAutoselectFirstValue;

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_handleDatabaseChanged:)
    name: ADDatabaseChangedExternallyNotification
    object: nil];
  
  return self;
}

- (void) setDelegate: (id) delegate
{
  _delegate = delegate;
}

- (id) delegate
{
  return _delegate;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [super dealloc];
}

- (void) setDisplayedProperty: (NSString*) property
{
  ADPropertyType type;

  if([_property isEqualToString: property]) return;
  if(!_book)
    _book = [ADAddressBook sharedAddressBook];
  
  type = [[ADPerson class] typeOfProperty: property];
  if(type == ADErrorInProperty)
    {
      NSLog(@"Trying to set unknown property %@\n", property);
      return;
    }

  [_property release];
  _property = [property copy];

  [self _buildArrays];
  [[_propertyColumn headerCell]
    setStringValue: ADLocalizedPropertyOrLabel(_property)];
  [[_peopleTable headerView] setNeedsDisplay: YES];
  [_peopleTable deselectAll: self];
  [_peopleTable reloadData];
}

- (NSString*) displayedProperty
{
  return _property;
}

- (void) setPreferredLabel: (NSString*) preferredLabel
{
  if([preferredLabel isEqualToString: _prefLabel])
    return;
  
  [_prefLabel release];
  _prefLabel = [preferredLabel copy];
  [self _buildArrays];
  if(_selectedGroup)
    [self autoselectAccordingToMode: _autosel];
}

- (NSString*) preferredLabel
{
  return _prefLabel;
}

- (void) setAutoselectMode: (ADAutoselectMode) mode
{
  _autosel = mode;
}

- (ADAutoselectMode) autoselectMode
{
  return _autosel;
}

- (void) autoselectAccordingToMode: (ADAutoselectMode) mode
{
  int i;
  ADPerson *p;

  [_peopleTable reloadData];
  switch(mode)
    {
    case ADAutoselectAll:
      [_peopleTable selectAll: self];
      return;
    case ADAutoselectFirstValue:
      /* extend selection without duplicates */
      [_peopleTable deselectAll: self];

      p = nil;
      for(i=0; i<[_people count]; i++)
	{
	  if(p != [_people objectAtIndex: i])
	    {
	      p = [_people objectAtIndex: i];
	      [_peopleTable selectRow: i byExtendingSelection: YES];
	    }
	}
      return;
    default:
      return;
    }
}

- (NSArray*) selectedNamesAndValues
{
  NSMutableArray *retval;
  NSEnumerator *e;
  NSNumber *r;

  retval = [NSMutableArray array];
  e = [_peopleTable selectedRowEnumerator];
  while((r = [e nextObject]))
    {
      int i = [r intValue];
      [retval addObject: [NSArray arrayWithObjects:
				    [_namesUnthinned objectAtIndex: i],
				  [_values objectAtIndex: i], nil]];
    }
  return [NSArray arrayWithArray: retval];  
}

- (NSArray*) selectedPeopleAndValues
{
  NSMutableArray *retval;
  NSEnumerator *e;
  NSNumber *r;

  retval = [NSMutableArray array];
  e = [_peopleTable selectedRowEnumerator];
  while((r = [e nextObject]))
    {
      int i = [r intValue];
      [retval addObject: [NSArray arrayWithObjects:
				    [_people objectAtIndex: i],
				  [_values objectAtIndex: i],
				  [NSNumber numberWithInt: i],
				  nil]];
    }
  return [NSArray arrayWithArray: retval];  
}

- (NSArray*) selectedValues
{
  NSMutableArray *retval;
  NSEnumerator *e;
  NSNumber *r;

  retval = [NSMutableArray array];
  e = [_peopleTable selectedRowEnumerator];
  while((r = [e nextObject]))
    [retval addObject: [_values objectAtIndex: [r intValue]]];
  return [NSArray arrayWithArray: retval];
}

- (ADGroup*) selectedGroup
{
  return _selectedGroup;
}

- (NSArray*) selectedPeople
{
  NSMutableArray *retval;
  NSEnumerator *e;
  NSNumber *r;

  retval = [NSMutableArray array];
  e = [_peopleTable selectedRowEnumerator];
  while((r = [e nextObject]))
    if(![retval containsObject: [_people objectAtIndex: [r intValue]]])
      [retval addObject: [_people objectAtIndex: [r intValue]]];
  return [NSArray arrayWithArray: retval];
}

/*
 * NSTableDataSource methods
 */

- (NSInteger) numberOfRowsInTableView: (NSTableView*) view
{
  return [_values count];
}

- (id) tableView: (NSTableView*) v
objectValueForTableColumn: (NSTableColumn*) col
	     row: (NSInteger) row
{
  NSString *val;
  
  if(col == _nameColumn)
    val = [_names objectAtIndex: row];
  else
    val = [_values objectAtIndex: row];
  return val;
}

- (BOOL) tableView: (NSTableView*) v
shouldEditTableColumn: (NSTableColumn*) col
	       row: (NSInteger) row
{
  return NO;
}

/*
 * NSSplitView delegate methods
 */

- (CGFloat) splitView: (NSSplitView*) sender
constrainMinCoordinate: (CGFloat) proposedMin
	ofSubviewAt: (NSInteger) offset
{
  if(offset == 0 && proposedMin < [_groupsBrowser minColumnWidth])
    return [_groupsBrowser minColumnWidth];
  return proposedMin;
}

- (CGFloat) splitView: (NSSplitView*) sender
constrainMaxCoordinate: (CGFloat) proposedMax
	ofSubviewAt: (NSInteger) offset
{
  NSRect r;

  r = [self frame];
  if(offset == 0 &&
     proposedMax > r.size.width - [_groupsBrowser minColumnWidth])
    return r.size.width - [_groupsBrowser minColumnWidth];
  return proposedMax;
}

/*
 * NSBrowser delegate methods
 */

- (NSInteger) browser: (NSBrowser*) b
numberOfRowsInColumn: (NSInteger) col
{
  if(!_book) _book = [ADAddressBook sharedAddressBook];
  return [[_book groups] count]+1;
}

- (NSString*) browser: (NSBrowser*) b
	titleOfColumn: (NSInteger) col
{
  return _(@"Groups");
}

- (void) browser: (NSBrowser*) b
 willDisplayCell: (NSBrowserCell*) cell
	   atRow: (NSInteger) row
	  column: (NSInteger) col
{
  if(!_book) _book = [ADAddressBook sharedAddressBook];
  if(row)
    [cell setStringValue: [[[_book groups] objectAtIndex: row-1]
			    valueForProperty: ADGroupNameProperty]];
  else
    [cell setStringValue: _(@"All")];
  [cell setLeaf: YES];
}
@end
