// ADPersonPropertyView+Events.m (this is -*- ObjC -*-)
// 
// Authors: Björn Giesler <giesler@ira.uka.de>
//          Riccardo Mottola <rm@gnu.org>
// 
// Address View Framework for GNUstep
// 


/* system includes */
/* (none) */

/* my includes */
#import "ADPersonPropertyView.h"
#import "ADPersonView.h"

@implementation ADPersonPropertyView (Events)
- (void) mouseDown: (NSEvent*) event
{
  int i; id c = nil; id details; ADMutableMultiValue *mv;
  NSPoint p;

  _mouseDownOnSelf = YES;
  _mouseDownCell = nil;
  
  p = [self convertPoint: [event locationInWindow]
		    fromView: nil];

  for(i=0; i<[_cells count]; i++)
    {
      c = [_cells objectAtIndex: i];
      if(NSPointInRect(p, [c rect]))
	{
	  _mouseDownCell = c;
	  break;
	}
    }
  if(i == [_cells count]) return;

  details = [c details]; 

  if([c isEditable] && ![self isEditable])
    _propertyForDrag = [[self propertyForDragWithDetails: [c details]]
			 retain];
  else
    {
      [_propertyForDrag release];
      _propertyForDrag = nil;
    }
  
  if([c isKindOfClass: [ADPersonActionCell class]])
    {
      ADActionType type; NSString *ident, *label;
      NSUInteger index;

      type = [c actionType];
      
      switch(type)
	{
	case ADAddAction:
	  mv = [[[ADMutableMultiValue alloc]
		  initWithMultiValue: [_person valueForProperty: _property]]
		 autorelease];
	  ident = [mv addValue: [self emptyValue]
		      withLabel: [self defaultLabel]];
	  [_person setValue: mv forProperty: _property];
	  [[self superview] setNeedsDisplay: YES];
	  [self layout];
	  break;

	case ADRemoveAction:
	  ident = [details objectForKey: @"Identifier"];
	  label = [details objectForKey: @"Label"];

          [self endEditing];

	  if(!ident || !label)
	    {
	      NSLog(@"Ident %@ or label %@ are nil!\n", ident, label);
	      return;
	    }
	  index = [[_person valueForProperty: _property]
		    indexForIdentifier: ident];
	  if(index == NSNotFound)
	    {
	      NSLog(@"Property %@ (%@) doesn't know identifier %@\n",
		    _property, [_person valueForProperty: _property],
		    ident);
	      return;
	    }

	  mv = [[[ADMutableMultiValue alloc]
		  initWithMultiValue: [_person valueForProperty: _property]]
		 autorelease];
	  [mv removeValueAndLabelAtIndex: index];
	  [_person setValue: mv forProperty: _property];
	  [[self superview] setNeedsDisplay: YES];
	  [self layout];
	  break;

	case ADChangeAction:
	  ident = [details objectForKey: @"Identifier"];
	  label = [details objectForKey: @"Label"];
	  if(!ident || !label)
	    {
	      NSLog(@"Ident %@ or label %@ are nil!\n", ident, label);
	      return;
	    }
	  index = [[_person valueForProperty: _property]
		    indexForIdentifier: ident];
	  if(index == NSNotFound)
	    {
	      NSLog(@"Property %@ (%@) doesn't know identifier %@\n",
		    _property, [_person valueForProperty: _property],
		    ident);
	      return;
	    }
	  label = [self nextLabelAfter: label];

	  mv = [[[ADMutableMultiValue alloc]
		  initWithMultiValue: [_person valueForProperty: _property]]
		 autorelease];
	  [mv replaceLabelAtIndex: index withLabel: label];
	  [_person setValue: mv forProperty: _property];
	  [self layout];
	  break;

	default:
	  NSLog(@"Unknown action type %d\n", type);
	}

      return;
    }
  
  if(_editable)
    {
      if(_delegate)
	[_delegate viewWillBeginEditing: self];
      [self beginEditingInCellWithDetails: details
	    becauseOfEvent: event];

      [self setNeedsDisplay: YES];
    }
}

- (void) _DISABLED_mouseDragged: (NSEvent*) event
{
  NSPasteboard *pb;
  
  if(!_mouseDownOnSelf || !_delegate || _editable)
    return;

  pb = [NSPasteboard pasteboardWithName: NSDragPboard];

  if(_propertyForDrag &&
     [_delegate respondsToSelector: @selector(personPropertyView:willDragValue:forProperty:)] &&
     [_delegate personPropertyView: self
		willDragValue: _propertyForDrag
		forProperty: _property])
    {
      [pb declareTypes: [NSArray arrayWithObject: NSStringPboardType]
	  owner: self];
      [pb setData: [_person vCardRepresentation]
	  forType: @"NSVCardPboardType"];
      [pb setString: _propertyForDrag forType: NSStringPboardType];

      [self dragImage: [self imageForDraggedProperty: _propertyForDrag]
	    at: NSZeroPoint
	    offset: NSZeroSize
	    event: event
	    pasteboard: pb
	    source: self
	    slideBack: YES];
    }
  else if(!_propertyForDrag &&
	  [_delegate respondsToSelector: @selector(personPropertyView:willDragPerson:)] &&
	  [_delegate personPropertyView: self
		     willDragPerson: _person])
    {
      NSString *str;
      NSMutableDictionary *dict;
      
      [pb declareTypes: [NSArray arrayWithObjects: @"NSVCardPboardType",
				 @"NSFilesPromisePboardType",
				 NSStringPboardType,
				 ADPeoplePboardType,
				 nil]
	  owner: self];
      [pb setData: [_person vCardRepresentation]
	  forType: @"NSVCardPboardType"];

      dict = [NSMutableDictionary dictionary];
      [dict setObject: [NSString stringWithFormat: @"%d",
				 [[NSProcessInfo processInfo]
				   processIdentifier]]
	    forKey: @"PID"];
      if([_person uniqueId])
	[dict setObject: [_person uniqueId]
	      forKey: @"UID"];
      if([_person addressBook])
	[dict setObject: [[_person addressBook] addressBookDescription]
	      forKey: @"AB"];
      [pb setPropertyList: [NSArray arrayWithObject: dict]
	  forType: ADPeoplePboardType];

      if([[_person valueForProperty: ADEmailProperty] count])
	str = [NSString stringWithFormat: @"%@ <%@>",
			[_person screenNameWithFormat: ADScreenNameFirstNameFirst],
			[[_person valueForProperty: ADEmailProperty]
			  valueAtIndex: 0]];
      else
	str = [_person screenName];
      [pb setString: str forType: NSStringPboardType];

      [self dragImage: [_delegate draggingImage]
	    at: NSZeroPoint
	    offset: NSZeroSize
	    event: event
	    pasteboard: pb
	    source: self
	    slideBack: YES];
    }

  _mouseDownCell = nil;
}

- (void) mouseUp: (NSEvent*) event
{
  if(_editable)
    return;
  
  if(_mouseDownCell && _delegate && [_mouseDownCell isEditable] &&
     [_delegate respondsToSelector: _clickSel])
    [_delegate clickedOnProperty: _property
	       withValue: [_mouseDownCell stringValue]
	       inView: self];

  [_propertyForDrag release];
  _propertyForDrag = nil;

  _mouseDownOnSelf = NO;
  _mouseDownCell = nil;
}

- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL) isLocal
{
  return NSDragOperationCopy|NSDragOperationLink;
}

- (void) beginEditingInCellWithDetails: (id) details
		       becauseOfEvent: (NSEvent*) e
{
  ADPersonPropertyCell *c;
  NSRect r;
  NSText *t;
  int i;
  [[details retain] autorelease];
  [self endEditing];

  i = [self indexOfEditableCellWithDetails: details];
  
  c =  [_cells objectAtIndex: i];
  
  if(![c isEditable]) return;
  _editingCellIndex = i;
  r = [c rect];
      
  t = [_window fieldEditor: YES forObject: c];
  _textObject = [c setUpFieldEditorAttributes: t];
  [_textObject setString: [c stringValue]];
  [c setTextColor: [NSColor textColor]];
  
  if([[c stringValue] hasPrefix: @"["])
    {
      [c setStringValue: @""];
      r.size.width = [[c font] widthOfString: @""];
    }
      
  r.size.width += 4; // make the cursor fit too

  if(e)
    [c editWithFrame: r
       inView: self
       editor: _textObject
       delegate: self
       event: e];
  else
    {
      // HACK: We must create our own event here, since we can't
      // pass nil as event argument to
      // editWithFrame:inView:...
      // REASON: In that method, the event is asked for its event
      // type, which (for a nil event) is 0==NSLeftMouseDown. The
      // effect is that the NSCell sits there waiting for the
      // mouse up :-)
      // REMEDY: Maybe fix this by checking for nil event in
      // NSCell editWithFrame:inView:...?
      e = [NSEvent keyEventWithType: NSKeyDown
		   location: NSMakePoint(0, 0)
		   modifierFlags: 0
		   timestamp: 0
		   windowNumber: 0
		   context: nil
		   characters: @"\t"
		   charactersIgnoringModifiers: @"\t"
		   isARepeat: NO
		   keyCode: '\t'];
      [c editWithFrame: r
	 inView: self
	 editor: _textObject
	 delegate: self
	 event: e];
      [_textObject setSelectedRange: NSMakeRange(0, [[c stringValue]
						      length])];
    }

  [c setStringValue: @""];

  [self setNeedsDisplay: YES];
}

- (void) beginEditingInCellAtIndex: (NSUInteger) i
		    becauseOfEvent: (NSEvent*) e
{
  id cell = [_cells objectAtIndex: i];
  return [self beginEditingInCellWithDetails: [cell details]
	       becauseOfEvent: e];
}

@end
