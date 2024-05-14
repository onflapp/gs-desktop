#import <AppKit/AppKit.h>

#import "AddressView/ADPersonView.h"
#import "Controller.h"
#import "DragDropMatrix.h"
#import "STScriptingSupport.h"

@interface ADAddressBook (AddressManagerAdditions)
- (ADPerson*) personWithFirstName: (NSString*) first
			 lastName: (NSString*) last;
@end

@implementation ADAddressBook (AddressManagerAdditions)
- (ADPerson*) personWithFirstName: (NSString*) first
			 lastName: (NSString*) last
{
  NSEnumerator *e; ADPerson *p;
  e = [[self people] objectEnumerator];
  while((p = [e nextObject]))
    if([[p valueForProperty: ADFirstNameProperty]
	 isEqualToString: first] &&
       [[p valueForProperty: ADLastNameProperty]
	 isEqualToString: last])
      return p;
  return nil;
}
@end

@interface Controller (Private)
- (void) browserAction: (id) sender;
@end

@implementation Controller
- (void) applicationDidFinishLaunching: (NSNotification*) note
{
  if([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }

  NSUserDefaults *def;
  NSString *uid;
  
  [NSApp registerServicesMenuSendTypes: [NSArray arrayWithObjects:
						   NSStringPboardType,
						 nil]
	 returnTypes: nil];
  
  def = [NSUserDefaults standardUserDefaults];
  uid = [def stringForKey: @"SelectedGroup"];
  if(uid && ![uid isEqualToString: @"None"])
    [self selectGroup: (ADGroup*) [_book recordForUniqueId: uid]];
  else
    [self selectGroup: nil];

  uid = [def stringForKey: @"SelectedPerson"];
  if(uid && ![uid isEqualToString: @"None"])
    {
      [groupsBrowser selectRow: 0 inColumn: 0];
      [self selectPerson: (ADPerson*)[_book recordForUniqueId: uid]];
    }
  else
    {
      [groupsBrowser selectRow: 0 inColumn: 1];
    }

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(handleDatabaseChanged:)
    name: ADDatabaseChangedNotification
    object: nil];
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(handleDatabaseChangedExternally:)
    name: ADDatabaseChangedExternallyNotification
    object: nil];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector: @selector(handleNameChanged:)
    name: ADPersonNameChangedNotification
    object: nil];
}

- (void) awakeFromNib
{
  NSString *filename;
  
  _fm = [NSFileManager defaultManager];
  _book = [ADAddressBook sharedAddressBook];
  _selfChanging = NO;
  _selectedByDrop = NO;

  if(!_book)
    {
      NSRunAlertPanel(_(@"No Address Book"),
		      _(@"[ADAddressBook sharedAddressBook] returned nil.\n"
			@"Configuration broken?"),
		      _(@"OK"), nil, nil, nil);
      exit(-1);
    }

  [[groupsBrowser window] setFrameAutosaveName: @"Addresses"];
  [[groupsBrowser window] setFrameUsingName: @"Addresses"];
  [prefsPanel setFrameAutosaveName: @"Preferences"];
  [prefsPanel setFrameUsingName: @"Preferences"];
  
  [groupsBrowser setAllowsEmptySelection: NO];
  [groupsBrowser setAllowsMultipleSelection: YES];
  [groupsBrowser setMaxVisibleColumns: 2];
  [groupsBrowser setDelegate: self];
  [groupsBrowser setMatrixClass: [DragDropMatrix class]];
  [groupsBrowser setTarget: self];
  [groupsBrowser setAction: @selector(browserAction:)];

  clipView = [[NSClipView alloc] initWithFrame: [scrollView frame]];
  [clipView setAutoresizesSubviews: YES];
  personView = [[ADPersonView alloc] initWithFrame: NSZeroRect];
  [clipView setDocumentView: personView];
  [personView setFillsSuperview: YES];
  [personView setForceImage: YES];
	      
  [scrollView setContentView: clipView];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];

  [personView setDelegate: self];

  filename = [[NSBundle mainBundle] pathForResource: @"ISOCountryCodes"
				    ofType: @"dict"];
  _countryCodeDict = [[[NSString stringWithContentsOfFile: filename]
			propertyList] retain];
  NSAssert(_countryCodeDict, @"ISOCountryCodes.dict could not be loaded.");

  [self createCache];
  if([_peopleCache count])
    [self selectPerson: [_peopleCache objectAtIndex: 0]];
  
  [self initPrefsPanel];
}

- (void) initPrefsPanel
{
  NSUserDefaults *ud;
  NSEnumerator *e; NSString *key;
  
  ud = [NSUserDefaults standardUserDefaults];
  if(![ud objectForKey: @"Autosave"] ||
     ![[ud objectForKey: @"Autosave"] boolValue])
    [prefsAutosaveButton setState: NSOffState];
  else
    [prefsAutosaveButton setState: NSOnState];

  [prefsAddressLayoutPopup removeAllItems];
  e = [[[_countryCodeDict allKeys]
	 sortedArrayUsingSelector: @selector(compare:)]
	objectEnumerator];
  while((key = [e nextObject]))
    {
      [prefsAddressLayoutPopup
	addItemWithTitle: [_countryCodeDict objectForKey: key]];
      [[prefsAddressLayoutPopup
	 itemWithTitle: [_countryCodeDict objectForKey: key]]
	setRepresentedObject: key];
    }
  [prefsAddressLayoutPopup addItemWithTitle: _(@"Everything")];
  [[prefsAddressLayoutPopup itemWithTitle: _(@"Everything")]
    setRepresentedObject: @"Default"];
  [prefsAddressLayoutPopup sizeToFit];

  if([ud objectForKey: @"DefaultISOCountryCode"])
    {
      NSString *def;
      NSInteger index;

      def = [ud objectForKey: @"DefaultISOCountryCode"];
      index = [prefsAddressLayoutPopup indexOfItemWithRepresentedObject: def];
      if(index != NSNotFound)
	[prefsAddressLayoutPopup selectItemAtIndex: index];
      [[personView class] setDefaultISOCountryCode: def];
    }

  if([[ADPerson class] screenNameFormat] == ADScreenNameFirstNameFirst)
    [prefsScreenNameLayoutMatrix selectCellWithTag: 1];
  else
    [prefsScreenNameLayoutMatrix selectCellWithTag: 0];
}

- (void) createCache
{
  SEL sortingSelector;
    
  sortingSelector =
    GSSelectorFromNameAndTypes("compareByScreenName:", "i12@0:4@8");

  [_peopleCache release];
  if(_currentGroup)
    _peopleCache = [_currentGroup members];
  else
    _peopleCache = [_book people];
  _peopleCache =
    [[_peopleCache sortedArrayUsingSelector: sortingSelector]
      retain];
}

- (NSArray*) groupNames
{
  NSArray *groups;
  NSMutableArray *retval;
  int i;

  groups = [_book groups];
  retval = [NSMutableArray arrayWithCapacity: [groups count]];

  for(i=0; i<[groups count]; i++)
    {
      NSString *name;

      name = [[groups objectAtIndex: i]
	       valueForProperty: ADGroupNameProperty];
      if(!name) NSLog(@"Group at %d has no name!\n", i);
      else [retval addObject: name];
    }
  return retval;
}

- (void) selectGroup: (ADGroup*) group
{
  int num, i;

  if([personView isEditable])
    [self finishEditingPerson];
  
  if(!group)
    {
      [[groupsBrowser matrixInColumn: 0] deselectAllCells];
      [groupsBrowser selectRow: 0 inColumn: 0];
      [_currentGroup autorelease];
      _currentGroup = nil;
      [self createCache];

      [groupsBrowser reloadColumn: 1];
      
      if([_peopleCache count])
	[self selectPerson: [_peopleCache objectAtIndex: 0]];
      else
	[self selectPerson: nil];

      return;
    }

  num = [[groupsBrowser matrixInColumn: 0] numberOfRows];
  for(i=0; i<num; i++)
    {
      ADRecord *r;
      
      r = [[groupsBrowser loadedCellAtRow: i column: 0] representedObject];
      if([[r uniqueId] isEqualToString: [group uniqueId]])
	{
	  [[groupsBrowser matrixInColumn: 0] deselectAllCells];
	  [groupsBrowser selectRow: i inColumn: 0];

	  [_currentGroup autorelease];
	  _currentGroup = [group retain];
	  [self createCache];

	  [groupsBrowser reloadColumn: 1];
	  
	  if([_peopleCache count])
	    [self selectPerson: [_peopleCache objectAtIndex: 0]];
	  else
	    [self selectPerson: nil];
	  return;
	}
    }

  NSLog(@"Group %@ not found in column 0!\n", [group uniqueId]);
}

  
- (void) selectPerson: (ADPerson*) person
{
  int i;

  if([personView isEditable])
    [self finishEditingPerson];

  if(!person)
    {
      [personView setPerson: nil];
      return;
    }

  for(i=0; i<[_peopleCache count]; i++)
    if([[[_peopleCache objectAtIndex: i] uniqueId]
	 isEqualToString: [person uniqueId]])
      break;
  
  if(i==[_peopleCache count]) // Not found? Select "all" and try again
    {
      NSArray *all;
      SEL sortingSelector;
    
      sortingSelector =
	GSSelectorFromNameAndTypes("compareByScreenName:", "i12@0:4@8");


      all = [[_book people] sortedArrayUsingSelector: sortingSelector];
      for(i=0; i<[all count]; i++)
	{
	  if([[[all objectAtIndex: i] uniqueId]
	       isEqualToString: [person uniqueId]])
	    {
	      [self selectGroup: nil];
	      break;
	    }
	}
    }

  if(i==[_peopleCache count]) // Still not found? WEIRD.
    {
      NSLog(@"Person %@ not found!\n", [person uniqueId]);
      return;
    }

  [groupsBrowser selectRow: i inColumn: 1];

  [personView setPerson: [_peopleCache objectAtIndex: i]];
  [clipView scrollToPoint: NSZeroPoint];

  if([person readOnly])
    {
      [editButton setEnabled: NO];
      [editItem setEnabled: NO];
    }
  else
    {
      [editButton setEnabled: YES];
      [editItem setEnabled: YES];
    }
}

- (void) deletePersonAndSelectNext: (ADPerson*) person
{
  int row = [groupsBrowser selectedRowInColumn: 1];

  if(_currentGroup)
    [_currentGroup removeMember: person];
  else
    [_book removeRecord: person];

  [self createCache];
  [groupsBrowser reloadColumn: 1];

  if(![_peopleCache count])
    [personView setPerson: nil];
  else if(row >= [_peopleCache count])
    [self selectPerson: [_peopleCache objectAtIndex: [_peopleCache count]-1]];
  else
    [self selectPerson: [_peopleCache objectAtIndex: row]];
}

- (void) beginEditingPerson: (ADPerson*) person
{
  if([person readOnly])
    {
      NSRunAlertPanel(_(@"Read-Only Person"),
		      [NSString stringWithFormat:
			_(@"'%@' cannot be edited because\n"
			  @"the record is marked as read-only."), [person screenName]],
		      _(@"OK"), nil, nil, nil);
      [editButton setState: NSOffState];
      [editItem setTitle: _(@"Edit person")];
      return;
    }
  [self selectPerson: person];
  [personView setEditable: YES];
  [editItem setTitle: _(@"End editing")];
  [editButton setState: NSOnState];
  [clipView scrollToPoint: NSZeroPoint];
};

- (void) finishEditingPerson
{
  ADPerson *p;

  p = [personView person];
  if(!p || ![personView isEditable]) return;

  NSString *fn = [p valueForProperty: ADFirstNameProperty];
  NSString *ln = [p valueForProperty: ADLastNameProperty];

  if([fn length] == 0 && [ln length] == 0)
    {
      if(NSRunAlertPanel(_(@"Discard Person?"),
			 _(@"The person you have edited has no first or last\n"
			   @"names. Would you like to discard this person?"),
			 _(@"Yes"), _(@"No"), nil, nil))
	{
	    [personView setEditable: NO];
	    [self deletePersonAndSelectNext: p];
	    p = nil;
	}
    }
  [personView setEditable: NO];
  
  [editItem setTitle: _(@"Edit Person")];
  [editButton setState: NSOffState];

  if(p)
    {
        [groupsBrowser reloadColumn: 1];
	[self selectPerson: p];
    }
}

- (NSArray*) selectedPersons
{
  NSMutableArray *arr;
  NSEnumerator *e;
  NSCell *c;

  e = [[groupsBrowser selectedCells] objectEnumerator];
  arr = [NSMutableArray arrayWithCapacity: [[groupsBrowser selectedCells]
					     count]];
  while((c = [e nextObject]))
    if([c representedObject])
      [arr addObject: [c representedObject]];

  return [NSArray arrayWithArray: arr];
}
  
/*
  Actions
*/

- (void) doEditPerson: (id) sender
{
  ADPerson *p;

  p = [personView person];
  if(!p) return; // nothing to do
  if([personView isEditable])
    {
      [self finishEditingPerson];
    }
  else
    {
      [self beginEditingPerson: p];
    }
  [clipView scrollToPoint: NSZeroPoint];
}

- (void) doTogglePersonEditable: (id) sender
{
  ADPerson *p;

  p = [personView person];
  if(!p && [sender state] == NSOnState)
    {
      [self doCreatePerson: sender];
    }
  else if([sender state] == NSOnState)
    {
      [self beginEditingPerson: p];
    }
  else
    {
      [[personView window] makeFirstResponder: groupsBrowser];
      [self finishEditingPerson];
    }

  [clipView scrollToPoint: NSZeroPoint];
}

- (void) doCreatePerson: (id) sender
{
  BOOL ok;
  ADPerson *p;

  p = [[ADPerson alloc] init];

  ok = [_book addRecord: p];
  if(!ok)
    {
      NSRunAlertPanel(_(@"Couldn't create person"),
		      _(@"A new person could not be created."),
		      _(@"OK"), nil, nil, nil);
      return;
    }

  if(_currentGroup)
    {
      ok = [_currentGroup addMember: p];
      if(!ok)
	{
	  NSRunAlertPanel(_(@"Couldn't add person"),
			  _(@"The newly created person could not be\n"
			    @"added to this group."),
			  _(@"OK"), nil, nil, nil);
	  return;
	}
    }

  p = (ADPerson*)[_book recordForUniqueId: [p uniqueId]];
    
  [self createCache];
  [groupsBrowser reloadColumn: 1];
  [self beginEditingPerson: p];
  [personView beginEditingInFirstCell];
}

- (IBAction) doDeletePerson: (id) sender
{
  NSArray *a;
  NSEnumerator *e;
  ADPerson *p;

  a = [self selectedPersons];
  if(![a count]) return; // nothing to do.

  // deleting from "All"? Ask.
  if(!_currentGroup)
    {
      NSString *msg, *cpt;
      if([a count] == 1)
	{
	  msg = [NSString stringWithFormat: _(@"Do you really want to delete %@ "
					      @"from \"All\" and all groups?"),
			  [[a objectAtIndex: 0] screenName]];
	  cpt = _(@"Delete Person?");
	}
      else
	{
	  msg = [NSString stringWithFormat: _(@"Do you really want to delete "
					      @"the %d selected persons "
					      @"from \"All\" and all groups?"),
			  [a count]];
	  cpt = _(@"Delete Persons?");
	}
      if(!NSRunAlertPanel(cpt, msg,
			  _(@"Yes"), _(@"No"), nil, nil))
	{
	  NSLog(@"Not deleting.\n");
	  return;
	}
    }

  e = [a objectEnumerator];
  while((p = [e nextObject]))
    [self deletePersonAndSelectNext: p];
}

- (void) doImportPerson: (id) sender
{
  int retval;
  id obj;
  int loaded = 0;
  NSString *fname;
  id<ADInputConverting> conv;
  ADConverterManager *man;
  NSOpenPanel *p;
  
  man = [ADConverterManager sharedManager];
  
  p = [NSOpenPanel openPanel];

  [p setDirectory: [[NSUserDefaults standardUserDefaults]
		     objectForKey: @"ImportDirectory"]];

  [p setCanChooseDirectories: NO];
  [p setAllowsMultipleSelection: NO];
  [p setTitle: _(@"Import...")];
  retval = [p runModalForTypes: [man inputConvertableFileTypes]];
  if(!retval)
    return;

  [[NSUserDefaults standardUserDefaults]
    setObject: [p directory] forKey: @"ImportDirectory"];

  fname = [[p filenames] objectAtIndex: 0];
  conv = [man inputConverterWithFile: fname];
  NSAssert(conv, @"No converter for this file!");

  while((obj = [conv nextRecord]))
    {
      NSEnumerator *e = [_peopleCache objectEnumerator];
      id other;
      int retval;

      loaded++;
      
      retval = 0; // insert anyway
      while((other = [e nextObject]))
	{
	  if([[other screenName] isEqualToString: [obj screenName]])
	    {
	      NSString *fmt; 
	      fmt =
		[NSString stringWithFormat:
			    _(@"Trying to import person named '%@',\n"
			      @"which already exists in the database."),
			  [obj screenName]];
	      retval = NSRunAlertPanel(_(@"Existing person?"),
				       fmt, _(@"Replace"), _(@"Insert anyway"),
				       _(@"Don't insert"), nil);
	      break;
	    }
	}
      if(retval == 1) // replace
	{
	  [_book removeRecord: other];
	  [_book addRecord: obj];
	}
      else if(retval == 0) // insert anyway
	[_book addRecord: obj];
      else if(retval == -1) // don't insert; continue reading
	continue;
    }
  [groupsBrowser reloadColumn: 1];
}

- (void) doExportPerson: (id) sender
{
  ADConverterManager *man;
  NSSavePanel *panel;
  NSString *fname;
  int retval;
  NSArray *a;
  NSEnumerator *e; ADPerson *person;
  id<ADOutputConverting> conv;

  if([personView isEditable])
    [self finishEditingPerson];
  
  a = [self selectedPersons];
  if(![a count]) return;
  
  man = [ADConverterManager sharedManager];
  panel = [NSSavePanel savePanel];

  [panel setDirectory: [[NSUserDefaults standardUserDefaults]
			 objectForKey: @"ExportDirectory"]];
  [panel setRequiredFileType: @"vcf"];
  if([a count] > 1)
    [panel
      setTitle: [NSString stringWithFormat: _(@"Export %d records to..."),
			  [a count]]];
  else
    [panel
      setTitle: [NSString stringWithFormat: _(@"Export '%@' to..."),
			  [[a objectAtIndex: 0] screenName]]];
      
  
  retval = [panel runModal];
  if(!retval)
    return;

  [[NSUserDefaults standardUserDefaults]
    setObject: [panel directory]
    forKey: @"ExportDirectory"];
  
  fname = [panel filename];
  conv = [man outputConverterForType: [[fname pathExtension] lowercaseString]];
  if(!conv)
    {
      NSString *msg =
	[NSString stringWithFormat: _(@"Cannot export files of type %@"),
		  [fname pathExtension]];
      NSRunAlertPanel(_(@"Invalid File Type"), msg, _(@"OK"), nil, nil, nil);
      return;
    }
  else if([a count]>1 && ![conv canStoreMultipleRecords])
    {
      NSString *msg =
	[NSString stringWithFormat: _(@"Can only store a single person\n"
				      @"in files of type %@"),
		  [fname pathExtension]];
      NSRunAlertPanel(_(@"Invalid File Type"), msg, _(@"OK"), nil, nil, nil);
      return;
    }      

  e = [a objectEnumerator];
  while((person = [e nextObject]))
    [conv storeRecord: person];

  retval = [[conv string] writeToFile: fname atomically: NO];
  if(!retval)
    {
      NSString *msg =
	[NSString stringWithFormat: _(@"Could not write file %@.\n"
				      @"Permissions error?"),
		  fname];
      NSRunAlertPanel(_(@"Write Failed"), msg, _(@"OK"), nil, nil, nil);
    }      
}

- (void) doSetMe: (id) sender
{
  if(![personView person]) return;
  [_book setMe: [personView person]];
  [personView setNeedsDisplay: YES];
  [groupsBrowser reloadColumn: 1];
  [self selectPerson: [personView person]];
}

- (void) doShowMe: (id) sender
{
  if(![_book me]) return;

  [groupsBrowser selectRow: 0 inColumn: 0];
  [self selectPerson: [_book me]];
}

- (void) doSelectAllPersons: (id) sender
{
  [groupsBrowser selectAll: self];
  if([[groupsBrowser selectedCells] count] == 1)
    [personView setPerson: [[groupsBrowser selectedCellInColumn: 1]
			     representedObject]];
  else [personView setPerson: nil];
}

- (void) doToggleShared: (id) sender
{
  NSEnumerator *e;
  BOOL share;
  ADPerson *person;

  share = YES; // default yes, but if one selected person is shared,
	       // set to no
  e = [[self selectedPersons] objectEnumerator];
  while((person = [e nextObject]))
    if([person shared])
      {
	share = NO;
	break;
      }

  e = [[self selectedPersons] objectEnumerator];
  while((person = [e nextObject]))
    [person setShared: share];

  if(share)
    {
      if([[self selectedPersons] count] > 1)
	[shareItem setTitle: _(@"Do not share these people")];
      else
	[shareItem setTitle: _(@"Do not share this person")];
    }
  else
    {    
      if([[self selectedPersons] count] > 1)
	[shareItem setTitle: _(@"Share these people")];
      else
	[shareItem setTitle: _(@"Share this person")];
    }

  [personView setNeedsDisplay: YES];
}

- (void) doDuplicatePerson: (id) sender
{
  ADPerson *newPerson, *oldPerson;
  BOOL ok;

  oldPerson = [personView person];
  if(!oldPerson) return;

  newPerson = [oldPerson copy];
  [newPerson removeValueForProperty: ADFirstNameProperty];
  [newPerson removeValueForProperty: ADLastNameProperty];

  ok = [_book addRecord: newPerson];
  if(!ok)
    {
      NSRunAlertPanel(_(@"Couldn't create person"),
		      _(@"A new person could not be created."),
		      _(@"OK"), nil, nil, nil);
      return;
    }
  if(_currentGroup)
    {
      ok = [_currentGroup addMember: newPerson];
      if(!ok)
	{
	  NSRunAlertPanel(_(@"Couldn't add person"),
			  _(@"The newly created person could not be\n"
			    @"added to this group."),
			  _(@"OK"), nil, nil, nil);
	  return;
	}
    }

  [self createCache];
  [groupsBrowser reloadColumn: 1];
  [self beginEditingPerson: newPerson];
  [personView beginEditingInFirstCell];
}

- (void) doMergePersons: (id) sender
{
  // FIXME: Unimplemented!
}

- (void) doCreateGroup: (id)sender
{
  ADGroup *group;
  
  group = [[[ADGroup alloc] init] autorelease];
  [group setValue: _(@"New Group") forProperty: ADGroupNameProperty];
  if(![_book addRecord: group])
    NSRunAlertPanel(_(@"Error"), _(@"Could not create group!"),
		    _(@"OK"), nil, nil, nil);
  [groupsBrowser reloadColumn: 0];

  [self selectGroup: group];
}

- (void) doDeleteGroup: (id) sender
{
  ADGroup *group;
  NSString *name;
  NSString *msg;
  int retval;
  int row = [groupsBrowser selectedRowInColumn: 0];

  if(row == 0) return; // Can't delete this

  group = [[_book groups] objectAtIndex: row-1];
  name = [group valueForProperty: ADGroupNameProperty];

  msg =
    [NSString stringWithFormat: _(@"Do you really want to delete "
				  @"the group '%@'?"),
	      name];
  retval = NSRunAlertPanel(_(@"Delete Group?"), msg,
			       _(@"Yes"), _(@"No"), nil, nil);
  if(!retval) return;

  if(![_book removeRecord: group])
    {
      msg = 
	[NSString stringWithFormat: _(@"The group '%@` could not be deleted."),
		  name];
      NSRunAlertPanel(_(@"Error"), msg, _(@"OK"), nil, nil, nil);
    }

  lastCell = nil;
  [groupsBrowser reloadColumn: 0];
  [groupsBrowser selectRow: row-1 inColumn: 0]; // OK -- we caught 0 above
  [self browserAction: groupsBrowser];
  [self createCache];
  if([_peopleCache count])
    [self selectPerson: [_peopleCache objectAtIndex: 0]];
}

- (void) doSaveDatabase: (id) sender
{
  if([personView isEditable])
    {
      [[personView window] makeFirstResponder: groupsBrowser];
      [self finishEditingPerson];
    }
  if([_book hasUnsavedChanges])
    {
      _selfChanging = YES;

      if(![_book save])
	NSRunAlertPanel(_(@"Couldn't save"),
			_(@"The database could not be saved!"),
			_(@"OK"), nil, nil, nil);
      else
	[[personView window] setTitle: _(@"Addresses")];

      _selfChanging = NO;
    }
}

- (void) doShowPrefsPanel: (id) sender
{
  [prefsPanel makeKeyAndOrderFront: self];
}

- (void) prefsToggleAutosave: (id) sender
{
  if([sender state] == NSOnState)
    [[NSUserDefaults standardUserDefaults]
      setObject: @"YES" forKey: @"Autosave"];
  else
    [[NSUserDefaults standardUserDefaults]
      setObject: @"NO" forKey: @"Autosave"];
}

- (void) prefsChangeAddressLayout: (id) sender
{
  NSString *code, *title; NSEnumerator *e;

  title = [[sender selectedItem] title];
  e = [_countryCodeDict keyEnumerator];
  while((code = [e nextObject]))
    if([[_countryCodeDict objectForKey: code] isEqualToString: title])
      break;
  if(!code && [title isEqualToString: _(@"Everything")])
    code = @"Default";
  if(!code) return;
  
  [[NSUserDefaults standardUserDefaults]
    setObject: code forKey: @"DefaultISOCountryCode"];
  [[personView class] setDefaultISOCountryCode: code];
  [personView layout];
}

- (void) prefsChangeScreenNameLayout: (id) sender
{
  int tag;
  ADPerson *p;

  tag = [sender selectedTag];
  [[ADPerson class] setScreenNameFormat: tag];
  // FIXME: Doesn't change in remote address books

  p = [personView person];
  [self createCache];
  [groupsBrowser reloadColumn: 1];
  if(p) [self selectPerson: p];
}

/*
 *  Browser delegate methods
 */

- (NSInteger) browser: (NSBrowser*) sender
numberOfRowsInColumn: (NSInteger) column
{
  NSArray *groupnames = [self groupNames];

  if(column == 0)
    return [groupnames count]+1;
  else
    {
      NSCell *cell;
      NSString *oldName = @"";
      NSString *newName = @"";
      ADGroup *group = nil;

      cell = [sender selectedCellInColumn: 0];

      if([sender selectedRowInColumn: 0] != 0)
	{
	  group =
	    [[_book groups] objectAtIndex: [sender selectedRowInColumn: 0]-1];
	  oldName = [group valueForProperty: ADGroupNameProperty];
	  newName = [cell stringValue];
	}
      
      // stop editing; rename if necessary
      [lastCell setEditable: NO];
      if(cell == lastCell && ![oldName isEqualToString: newName])
	{
	  if([newName isEqualToString: _(@"All")])
	    {
	      [cell setStringValue: oldName];
	      NSRunAlertPanel(_(@"Disallowed"),
			      _(@"You cannot rename a group to \"All\",\n"
				@"since that name is reserved by the system."),
			      _(@"OK"), nil, nil, nil);
	    }
	  else if([groupnames containsObject: newName])
	    {
	      [cell setStringValue: oldName];
	      NSRunAlertPanel(_(@"Disallowed"),
			      [NSString stringWithFormat:
					  _(@"You cannot rename this group "
					    @"to \"%@\",\n"
					    @"since a group of that name "
					    @"already exists."), newName],
			      _(@"OK"), nil, nil, nil);
	    }
	  else
	    [group setValue: newName forProperty: ADGroupNameProperty];
	  [lastCell setEditable: NO];
	}

      if(![newName isEqualToString: _(@"All")] &&
	 ![oldName isEqualToString: _(@"All")] &&
	 ![[cell stringValue] isEqualToString: _(@"All")])
	{
	  if([cell isEditable] || _selectedByDrop)
	    [cell setEditable: NO];
	  else
	    [cell setEditable: YES];

	  _selectedByDrop = NO;
	  
	  [lastCell release];
	  lastCell = [cell retain];
	}
      
      return [_peopleCache count];
    }

  return 0;
}

- (NSString*) browser: (NSBrowser*) sender 
   titleOfColumn: column
{
  if (column == 1)
    {
      return _(@"Name");
    }
  else
    {
      return _(@"Group");
    }
}

- (void) browser: (NSBrowser*) sender
 willDisplayCell: (id) cell
	   atRow: (NSInteger) row
	  column: (NSInteger) column
{
  [cell setFont: [NSFont systemFontOfSize: [NSFont systemFontSize]]];
  if(column == 0)
    {
      if(row == 0)
	[cell setStringValue: _(@"All")];
      else
	{
	  [cell setStringValue: [[self groupNames] objectAtIndex: row-1]];
	  [cell setRepresentedObject: [[_book groups] objectAtIndex: row-1]];
	  [cell setEditable: NO];
	}
    }
  else
    {
      ADPerson *p = [_peopleCache objectAtIndex: row];
      if(p == [_book me])
	[cell setStringValue: [[p screenName]
				stringByAppendingString: _(@" (Me)")]];
      else
	[cell setStringValue: [p screenName]];
      [cell setRepresentedObject: p];
      [cell setLeaf: YES];
    }      
}

- (void) browserAction: (id) sender
{
  if([personView isEditable])
    {
      [personView setPerson: nil];
      [personView setEditable: NO];
      [editButton setState: NSOffState];
    }
  
  if([sender selectedColumn] == 0)
    {
      int row;
      ADGroup *group = nil;
      [_currentGroup release];
      _currentGroup = nil;

      row = [sender selectedRowInColumn: 0];
      if(row != 0)
	group = [[_book groups] objectAtIndex: row-1];
      if(![[group uniqueId] isEqualToString: [_currentGroup uniqueId]])
	{
	  _currentGroup = [group retain];
	  [self createCache];
	  [sender reloadColumn: 1];
	  if([_peopleCache count])
	    [self selectPerson: [_peopleCache objectAtIndex: 0]];
	  else
	    [self selectPerson: nil];
	}
    }
  else
    {
      NSEnumerator *e; ADPerson *p; BOOL shared;
      
      if([[sender selectedCells] count] == 1)
	[personView setPerson: [[sender selectedCellInColumn: 1]
				 representedObject]];
      else [personView setPerson: nil];

      shared = NO;
      e = [[self selectedPersons] objectEnumerator];
      while((p = [e nextObject]))
	if([p shared])
	  {
	    shared = YES;
	    break;
	  }

      if(shared)
	{
	  if([[self selectedPersons] count] > 1)
	    [shareItem setTitle: _(@"Do not share these people")];
	  else
	    [shareItem setTitle: _(@"Do not share this person")];
	}
      else
	{    
	  if([[self selectedPersons] count] > 1)
	    [shareItem setTitle: _(@"Share these people")];
	  else
	    [shareItem setTitle: _(@"Share this person")];
	}
    }
}

- (void) handleDatabaseChanged: (NSNotification*) note
{
  if([_book hasUnsavedChanges])
    {
      if([prefsAutosaveButton state] == NSOnState)
	{
	  _selfChanging = YES;
	  [_book save];
	  _selfChanging = NO;
	  [[personView window] setDocumentEdited: NO];
	  [[personView window] setTitle: _(@"Addresses")];
	}
      else
	{
	  [[personView window] setDocumentEdited: YES];
	  [[personView window] setTitle: _(@"Addresses*")];
	}
    }
  else
    {
      [[personView window] setDocumentEdited: NO];
      [[personView window] setTitle: _(@"Addresses")];
    }
  [self createCache];
}

- (void) handleDatabaseChangedExternally: (NSNotification*) note
{
  NSString *guid = nil, *uid = nil;

  if(_selfChanging) return;

  if(_currentGroup)
    guid = [[_currentGroup uniqueId] retain];
  if([personView person])
    uid = [[[personView person] uniqueId] retain];

  [self createCache];
  [groupsBrowser reloadColumn: 0];
  [groupsBrowser reloadColumn: 1];

  [self selectGroup: (ADGroup*)[_book recordForUniqueId: guid]];
  if(uid)
    {
      ADPerson *p = (ADPerson*)[_book recordForUniqueId: uid];
      if(p) [self selectPerson: p];
    }
}

- (void) handleNameChanged: (NSNotification*) note
{
  NSDictionary *userInfo; ADPerson *p;
  NSString *first, *last, *prop, *val, *scrName;
  ADScreenNameFormat fmt;
  
  if([note object] != [personView person])
    return;

  userInfo = [note userInfo];
  p = [note object];

  prop = [userInfo objectForKey: @"Property"];
  val = [userInfo objectForKey: @"Value"];
  if([prop isEqualToString: ADFirstNameProperty])
    {
      first = val;
      last = [p valueForProperty: ADLastNameProperty];
    }
  else
    {
      first = [p valueForProperty: ADFirstNameProperty];
      last = val;
    }

  if([first isEmptyString]) first = nil;
  if([last isEmptyString]) last = nil;

  fmt = [[p class] screenNameFormat];
  
  if(!last && !first) scrName = _(@"New Person");
  else if(!first) scrName = last;
  else if(!last) scrName = first;
  else if(fmt == ADScreenNameFirstNameFirst)
    scrName = [NSString stringWithFormat: @"%@ %@", first, last];
  else
    scrName = [NSString stringWithFormat: @"%@, %@", last, first];

  [[groupsBrowser selectedCellInColumn: 1] setStringValue: scrName];
  [groupsBrowser setNeedsDisplay: YES];
}

- (BOOL) application: (NSApplication*) app
	    openFile: (NSString*) filename
{
  id conv;
  ADRecord *r, *r1;

  conv = [[ADConverterManager sharedManager] inputConverterWithFile: filename];
  if(!conv) return NO;

  r1 = nil;
  while((r = [conv nextRecord]))
    {
      if(!r1) r1 = r;
      [_book addRecord: r];
    }
  if(!r1) return NO;

  [self createCache];
  [groupsBrowser reloadColumn: 0];
  [groupsBrowser reloadColumn: 1];
  if([r1 isKindOfClass: [ADPerson class]])
    {
      [self selectGroup: _currentGroup];
      [self selectPerson: (ADPerson*)r1];
    }
  else
    {
      [self selectGroup: (ADGroup*)r1];
      if(![_peopleCache count]) [self selectPerson: nil];
      else [self selectPerson: [_peopleCache objectAtIndex: 0]];
    }
    
  return YES;
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication*) app
{
  NSUserDefaults *def;
  
  if([personView isEditable])
    [self finishEditingPerson];

  // store current group and person in defaults
  def = [NSUserDefaults standardUserDefaults];
  if(_currentGroup)
    [def setObject: [_currentGroup uniqueId]
	 forKey: @"SelectedGroup"];
  else
    [def setObject: @"None" forKey: @"SelectedGroup"];
  
  if([personView person])
    [def setObject: [[personView person] uniqueId]
	 forKey: @"SelectedPerson"];
  else
    [def setObject: @"None" forKey: @"SelectedPerson"];
    
      
  if([_book hasUnsavedChanges])
    {
      int retval =
	NSRunAlertPanel(_(@"Save Changes?"),
			_(@"You have made changes to the database.\n"
			  @"Should these changes be saved?"),
			_(@"Save and Quit"), _(@"Quit without saving"),
			_(@"Don't quit"), nil);
      switch(retval)
	{
	case 1:
	  if(![_book save])
	    {
	      NSRunAlertPanel(_(@"Couldn't save"),
			      _(@"The database could not be saved!"),
			      _(@"OK"), nil, nil, nil);
	      return NSTerminateCancel;
	    }
	  return NSTerminateNow;
	case 0:
	  return NSTerminateNow;
	default:
	  return NSTerminateCancel;
	}
    }
  else
    return NSTerminateNow;
}

- (BOOL) validateMenuItem: (NSMenuItem*) anItem
{
  int count;

  count = [[self selectedPersons] count];
  
  if(anItem == editItem || anItem == duplicatePersonItem ||
     anItem == thisIsMeItem)
    {
      if(count != 1) return NO;
      return YES;
    }

  if(anItem == shareItem)
    {
      if(count < 1) return NO;
      return YES;
    }

  if(anItem == mergePersonsItem)
    {
      if(count <= 1) return NO;
      return YES;
    }

  return YES;
}

- (BOOL) personView: (ADPersonView*) aView
   shouldAcceptDrop: (id<NSDraggingInfo>) info
{
  return YES;
}

- (BOOL) personView: (ADPersonView*) aView
receivedDroppedPersons: (NSArray*) persons
{
  int i;

  if(![persons count]) return NO;

  for(i=0; i<[persons count]; i++)
    {
      ADPerson *p, *o;

      p = [persons objectAtIndex: i];
      o = [_book personWithFirstName: [p valueForProperty: ADFirstNameProperty]
		 lastName: [p valueForProperty: ADLastNameProperty]];
      if(o)
	{
	  NSString *fmt;
	  int retval;
	  
	  fmt =
	    [NSString stringWithFormat:
			_(@"Trying to import person named '%@',\n"
			  @"which already exists in the database."),
		      [p screenName]];
	  retval = NSRunAlertPanel(_(@"Existing person?"),
				   fmt, _(@"Replace"), _(@"Insert anyway"),
				   _(@"Don't insert"), nil);
	  if(retval == 1) // replace
	    {
	      [_book removeRecord: o];
	      [_book addRecord: p];
	    }
	  else if(retval == 0) // insert anyway
	    [_book addRecord: p];
	  else if(retval == -1) // don't insert; continue reading
	    return NO;
	}
      else
	if(![_book addRecord: p]) return NO;

      if(_currentGroup)
	[_currentGroup addMember: p];
    }

  [groupsBrowser reloadColumn: 1];
  [self selectPerson: [persons objectAtIndex: 0]];
  
  return YES;
}

- (BOOL) personView: (ADPersonView*) aView
     willDragPerson: (ADPerson*) person
{
  return YES;
}

- (BOOL) personView: (ADPersonView*) aView
   willDragProperty: (NSString*) property
{
  return YES;
}

- (NSDragOperation) dragDropMatrix: (DragDropMatrix*) matrix
	shouldAcceptDropFromSender: (id<NSDraggingInfo>) sender
			    onCell: (NSCell*) cell
{
  ADGroup *g;

  g = [cell representedObject];
  if(g && ![g isKindOfClass: [ADGroup class]])
    return NSDragOperationNone;
  
  if([[[sender draggingPasteboard] types]
       containsObject: ADPeoplePboardType])
    {
      NSDictionary *d; NSEnumerator *e; 
      BOOL _pureLocal, _didSomeWork;

      if(![cell representedObject] ||
	 ![[cell representedObject] isKindOfClass: [ADGroup class]] ||
	 [[[cell representedObject] uniqueId]
	   isEqualToString: [_currentGroup uniqueId]])
	goto useVCard;

      _pureLocal = YES;
      _didSomeWork = NO;
      e = [[[sender draggingPasteboard]
	     propertyListForType: ADPeoplePboardType] objectEnumerator];
      while((d = [e nextObject]))
	{
	  int pid; NSString *uid; NSArray *adDescr;
	  ADPerson *p;

	  if(![d objectForKey: @"UID"] ||
	     ![d objectForKey: @"AB"] ||
	     ![d objectForKey: @"PID"])
	    continue;

	  pid = [[d objectForKey: @"PID"] intValue];
	  uid = [d objectForKey: @"UID"];
	  adDescr = [d objectForKey: @"AD"];

	  p = (ADPerson*)[_book recordForUniqueId: uid];

	  if(pid != [[NSProcessInfo processInfo] processIdentifier])
	    _pureLocal = NO;
	  else if(!p || ![p isKindOfClass: [ADPerson class]])
	    continue;

	  if(g)
	    {
	      ADPerson *p2; NSEnumerator *e;
	      BOOL isIn;

	      isIn = NO;
	      e = [[g members] objectEnumerator];
	      while((p2 = [e nextObject]))
		if([[p2 uniqueId] isEqualToString: [p uniqueId]])
		  {
		    isIn = YES;
		    break;
		  }

	      if(isIn) continue;
	    }
	  
	  _didSomeWork = YES;
	}

      if(_didSomeWork)
	{
	  if(_pureLocal)
	    return NSDragOperationLink;
	  return NSDragOperationCopy;
	}
    }

 useVCard:
  if([[[sender draggingPasteboard] types]
       containsObject: @"NSVCardPboardType"])
    return NSDragOperationCopy;

  return NSDragOperationNone;
}
  
- (BOOL) dragDropMatrix: (DragDropMatrix*) matrix
didAcceptDropFromSender: (id<NSDraggingInfo>) sender
		 onCell: (NSCell*) cell
{
  NSPasteboard *pb;
  ADGroup *g;

  g = [cell representedObject];
  if(g && ![g isKindOfClass: [ADGroup class]])
    return NO;

  pb = [sender draggingPasteboard];

  if([[pb types] containsObject: ADPeoplePboardType])
    {
      NSDictionary *d; NSEnumerator *e;
      BOOL _didSomeWork;

      if(!g) goto useVCard;

      _didSomeWork = NO;
      e = [[pb propertyListForType: ADPeoplePboardType] objectEnumerator];
      while((d = [e nextObject]))
	{
	  int pid; NSString *uid; NSArray *adDescr;
	  ADPerson *p;

	  if(![d objectForKey: @"UID"] ||
	     ![d objectForKey: @"AB"] ||
	     ![d objectForKey: @"PID"])
	    continue;

	  pid = [[d objectForKey: @"PID"] intValue];
	  uid = [d objectForKey: @"UID"];
	  adDescr = [d objectForKey: @"AD"];

	  if(pid != [[NSProcessInfo processInfo] processIdentifier])
	    continue;

	  p = (ADPerson*)[_book recordForUniqueId: uid];
	  if(!p || ![p isKindOfClass: [ADPerson class]])
	    continue;

	  if([g addMember: p])
	    _didSomeWork = YES;
	}
      if(_didSomeWork)
	return YES;
    }

 useVCard:
  if([[pb types] containsObject: @"NSVCardPboardType"])
    {
      ADPerson *p, *o;
      NSData *vcard;

      vcard = [pb dataForType: @"NSVCardPboardType"];
      p = [[[ADPerson alloc] initWithVCardRepresentation: vcard] autorelease];
      if(!p)
	return NO;

      o = [_book personWithFirstName: [p valueForProperty: ADFirstNameProperty]
		 lastName: [p valueForProperty: ADLastNameProperty]];
      if(o)
	{
	  NSString *fmt;
	  int retval;
	  
	  fmt =
	    [NSString stringWithFormat:
			_(@"Trying to import person named '%@',\n"
			  @"which already exists in the database."),
		      [p screenName]];
	  retval = NSRunAlertPanel(_(@"Existing person?"),
				   fmt, _(@"Replace"), _(@"Insert anyway"),
				   _(@"Don't insert"), nil);
	  if(retval == 1) // replace
	    {
	      [_book removeRecord: o];
	      [_book addRecord: p];
	    }
	  else if(retval == 0) // insert anyway
	    [_book addRecord: p];
	  else if(retval == -1) // don't insert; continue reading
	    return NO;
	}
      else
	if(![_book addRecord: p]) return NO;

      p = (ADPerson*)[_book recordForUniqueId: [p uniqueId]];
      if(!p || ![p isKindOfClass: [ADPerson class]]) return NO;

      if(g)
	[g addMember: p];

      [groupsBrowser reloadColumn: 1];
      if(g)
	{
	  [self selectGroup: g];
	  _selectedByDrop = YES;
	}
      [self selectPerson: p];
      
      return YES;
    }

  return NO;
}
@end

