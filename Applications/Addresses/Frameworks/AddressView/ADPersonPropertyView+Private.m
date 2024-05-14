// ADPersonPropertyView+Private.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Application for GNUstep
// 

/* my includes */
#import "ADPersonPropertyView.h"

@implementation ADPersonPropertyView (Private)
- (ADPersonPropertyCell*) addCellWithValue: (NSString*) val
				    inRect: (NSRect*) rect
				  editable: (BOOL) yesno
				      font: (NSFont*) font
				 alignment: (NSTextAlignment) alignment
				   details: (id) details
{
  ADPersonPropertyCell *cell;
  NSSize s;

  cell = [[[ADPersonPropertyCell alloc] init] autorelease];
  [cell setEditable: yesno];
  [cell setStringValue: val];
  [cell setFont: font];
  [cell setAlignment: alignment];
  [cell setBackgroundColor: [NSColor textBackgroundColor]];
  [cell setDrawsBackground: YES];

  if(details) [cell setDetails: details];

  s = [cell cellSize];
  rect->size.width = MAX(rect->size.width, s.width);
  rect->size.height = MAX(rect->size.height, s.height);

  [cell setRect: *rect];
  [_cells addObject: cell];

  return cell;
}
  
- (ADPersonPropertyCell*) addValueCellForValue: (NSString*) val
					inRect: (NSRect*) rect
				       details: (id) details
{
  ADPersonPropertyCell *cell;

  cell = [self addCellWithValue: val
	       inRect: rect
	       editable: YES
	       font: [self font]
	       alignment: NSLeftTextAlignment
	       details: details];
  
  if(_delegate &&
     [_delegate respondsToSelector: _clickSel] &&
     [_delegate canPerformClickForProperty: _property] &&
     !_editable)
    [cell setTextColor: [NSColor blueColor]];
  else if(_editable)
    [cell setTextColor: [NSColor textColor]];
  else
    [cell setTextColor: [NSColor textColor]];
  return cell;
}

- (ADPersonPropertyCell*) addValueCellForValue: (NSString*) val
					inRect: (NSRect*) rect
{
  return [self addValueCellForValue: val
	       inRect: rect
	       details: nil];
}

- (ADPersonPropertyCell*) addLabelCellForLabel: (NSString*) label
					inRect: (NSRect*) rect
{
  NSString *str;
  NSFont *font;
  int w;

  str = ADLocalizedPropertyOrLabel(label);
  font = [self boldFont];
  w = [font widthOfString: str];
  
  _neededLabelWidth = MAX(_neededLabelWidth, w);
  str = [str stringByAbbreviatingToFitWidth: _maxLabelWidth
	     inFont: font];
  
  rect->size.width = [self maxLabelWidth];
  
  return [self addCellWithValue: str
	       inRect: rect
	       editable: NO
	       font: font
	       alignment: NSRightTextAlignment
	       details: nil];
}

- (ADPersonPropertyCell*) addConstantCellForString: (NSString*) str
					    inRect: (NSRect*) rect
{
  NSFont *font = [self font];
  rect->size.width = [font widthOfString: str];
  
  return [self addCellWithValue: str
	       inRect: rect
	       editable: NO
	       font: font
	       alignment: NSRightTextAlignment
	       details: nil];
}

- (ADPersonActionCell*) addActionCellWithType: (ADActionType) t
				       inRect: (NSRect*) rect
				      details: (id) details
{
  id cell;
  NSSize cellSize; NSPoint cellOrigin;

  cell = [[[ADPersonActionCell alloc] init] autorelease];
  switch(t)
    {
    case ADAddAction:
      [cell setImage: _addImg];
      break;
    case ADRemoveAction:
      [cell setImage: _rmvImg];
      break;
    case ADChangeAction:
      [cell setImage: _chgImg];
      break;
    default:
      NSLog(@"Unknown action type %d\n", t);
    }

  cellSize = [cell rect].size;
  cellOrigin = rect->origin;
  if(rect->size.height > cellSize.height)
    cellOrigin.y += (rect->size.height - cellSize.height)/2 + 2;
  [cell setOrigin: cellOrigin];

  rect->size = [cell rect].size;
  [cell setDetails: details];
  [cell setActionType: t];

  [_cells addObject: cell];
  return cell;
}

- (NSArray*) layoutDictionary: (NSDictionary*) dict
		    withLabel: (NSString*) label
	     forDisplayInRect: (NSRect*) rect
{
  NSArray *layout, *row;
  NSString *field;
  NSEnumerator *rowEnumerator, *fieldEnumerator;
  ADPersonPropertyCell *labelCell;
  NSSize rowSize; NSRect rowRect; float labelX;
  BOOL firstRow;
  NSMutableArray *cells;
  
  layout = [self layoutRuleForValue: dict];
  cells = [NSMutableArray array];

  labelCell = [self addLabelCellForLabel: label inRect: rect];
  rect->origin.x += rect->size.width + 5; labelX = rect->origin.x;
  rect->size.width += 5;
  
  rowRect = *rect;
  rowSize = rect->size;
  firstRow = YES;
  
  rowEnumerator = [layout objectEnumerator];
  while((row = [rowEnumerator nextObject]))
    {
      // do we have to layout anything in this row at all?
      fieldEnumerator = [row objectEnumerator];
      while((field = [fieldEnumerator nextObject]))
	{
	  if([field hasPrefix: @"$"] ||
	     ![dict objectForKey: field]) continue;
	  break;
	}
      
      if(!field) continue;
      
      fieldEnumerator = [row objectEnumerator];
      while((field = [fieldEnumerator nextObject]))
	{
	  NSString *str;
	  id cell;
	  
	  if([field hasPrefix: @"$"])
	    str = [field substringFromIndex: 1];
	  else
	    str = [dict objectForKey: field];
	  if(!str || [str length] == 0)
	    continue;
	  
	  rowRect.size = NSMakeSize(0, 0);

	  cell = [self addConstantCellForString: str inRect: &rowRect];
	  [cells addObject: cell];
	  
	  rowRect.origin.x += rowRect.size.width + 5;
	  rowSize.width += rowRect.size.width + 5;
	  rowSize.height = MAX(rowSize.height,
			       rowRect.size.height);
	}

      // add +1 to compensate tiny GNUstep bug
      rect->size.width = MAX(rect->size.width, rowSize.width+1);
      if(!firstRow)
	rect->size.height += rowSize.height+1;
      firstRow = NO;
      
      rowRect.origin.x = rect->origin.x;
      rowRect.origin.y += rowRect.size.height;
      rowSize = NSMakeSize(labelX, 0);
    }

  return [NSArray arrayWithArray: cells];
}

- (NSArray*) layoutDictionary: (NSDictionary*) dict
		    withLabel: (NSString*) label
		      details: (NSDictionary*) details
		      buttons: (BOOL) buttons
		forEditInRect: (NSRect*) rect
{
  NSArray *layout, *row;
  NSString *field;
  NSEnumerator *rowEnumerator, *fieldEnumerator;
  ADPersonPropertyCell *labelCell;
  NSSize rowSize; NSRect rowRect; float labelX;
  BOOL firstRow, showsDefault;
  NSMutableArray *cells;
  
  layout = [self layoutRuleForValue: dict];
  cells = [NSMutableArray array];

  labelCell = [self addLabelCellForLabel: label inRect: rect];
  rect->origin.x += rect->size.width + 5;
  rect->size.width += 5;
  
  rowSize = rect->size;

  if(buttons)
    {
      rect->size.height = rowSize.height;
      [self addActionCellWithType: ADChangeAction
	    inRect: rect
	    details: details];
      rect->origin.x += rect->size.width + 5;
      rowSize.width += rect->size.width + 5;
      rowSize.height = MAX(rowSize.height, rect->size.height);
      
      rect->size.height = rowSize.height;
      [self addActionCellWithType: ADRemoveAction
	    inRect: rect
	    details: details];
      rect->origin.x += rect->size.width + 5;
      rowSize.width += rect->size.width + 5;
      rowSize.height = MAX(rowSize.height, rect->size.height);
    }
  
  labelX = rect->origin.x;

  rowRect = *rect;
  firstRow = YES;

  rowEnumerator = [layout objectEnumerator];
  while((row = [rowEnumerator nextObject]))
    {
      fieldEnumerator = [row objectEnumerator];
      while((field = [fieldEnumerator nextObject]))
	{
	  NSString *str; BOOL label;

	  label = NO; showsDefault = NO;
	  if([field hasPrefix: @"$"])
	    {
	      str = [field substringFromIndex: 1];
	      label = YES;
	    }
	  else
	    str = [dict objectForKey: field];
	  if(!str)
	    {
	      str = [NSString stringWithFormat: @"[%@]",
			      ADLocalizedPropertyOrLabel(field)];
	      showsDefault = YES;
	    }
	  
	  rowRect.size = NSMakeSize(0, 0);
	  if(label)
	    {
	      ADPersonPropertyCell *cell =
		[self addConstantCellForString: str inRect: &rowRect];
	      [cells addObject: cell];
	    }
	  else
	    {
	      ADPersonPropertyCell *cell;

	      NSMutableDictionary *myDetails =
		[NSMutableDictionary dictionaryWithDictionary: details];
	      [myDetails setObject: field forKey: @"Key"];
	      cell = [self addValueCellForValue: str
			   inRect: &rowRect
			   details: myDetails];
	      if(showsDefault) 
                [cell setTextColor: [NSColor lightGrayColor]];
	      [cells addObject: cell];
	    }
	  rowRect.origin.x += rowRect.size.width + 5;
	  rowSize.width += rowRect.size.width + 5;
	  rowSize.height = MAX(rowSize.height,
			       rowRect.size.height);
	}
      rect->size.width = MAX(rect->size.width, rowSize.width+1);
      if(!firstRow)
	rect->size.height += rowSize.height+1;
      firstRow = NO;
      
      rowRect.origin.x = rect->origin.x;
      rowRect.origin.y += rowRect.size.height;
      rowSize = NSMakeSize(labelX, 0);
    }

  return [NSArray arrayWithArray: cells];
}

- (void) layoutForEdit
{
  id val;
  id cell;
  ADPropertyType type;
  NSRect r; NSSize allSize; 
  int i; BOOL showsDefault;

  if(!_property || !_person) return;

  val = [_person valueForProperty: _property];

  type = [_person typeOfProperty: _property];

  r = NSMakeRect(0, 0, 0, 0); allSize = NSMakeSize(0, 0);

  // convert types
  if(val)
    switch(type)
      {
      case ADStringProperty: break;
      case ADIntegerProperty:
	val = [NSString stringWithFormat: @"%d", [val intValue]];
	break;
      case ADRealProperty:
	val = [NSString stringWithFormat: @"%f", [val floatValue]];
	break;
      case ADDateProperty:
	val = [val descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString]];
	break;
      case ADArrayProperty:
      case ADDictionaryProperty:
      case ADDataProperty:
      case ADErrorInProperty:
	NSLog(@"Can't layout object of type %d\n", type);
	return;
      default:
	break;
      }

  // layout single-cell values
  if(!(type & ADMultiValueMask))
    {
      if(_displaysLabel)
	{
	  [self addLabelCellForLabel: _property inRect: &r];
	  r.origin.x += r.size.width + 5;
	  allSize.width = r.size.width + 5;
	  allSize.width += r.size.width + 5;
	  r.size = NSMakeSize(0, 0);
	}

      showsDefault = NO;
      if(!val)
	{
	  val = [self emptyValue];
	  showsDefault = YES;
	}
      cell = [self addValueCellForValue: val
		   inRect: &r];

      if([val isEqualToString:[self emptyValue]])
	[cell setTextColor: [NSColor lightGrayColor]];
      if(showsDefault)
	[cell setTextColor: [NSColor lightGrayColor]];
      allSize.width += r.size.width;
      allSize.height = MAX(allSize.height, r.size.height);
    }

  else if(type == ADMultiStringProperty)
    {
      if(![val count])
	{
	  ADPersonPropertyCell *labelCell, *valueCell;
	  NSString *label, *value;
	  NSDictionary *details;

	  label = [self defaultLabel];

	  details = [NSDictionary dictionaryWithObjectsAndKeys:
				    label, @"Label",
				  nil];
	  
	  labelCell = [self addLabelCellForLabel: label inRect: &r];
	  [labelCell setDetails: details];
	  r.origin.x += r.size.width + 5;
	  allSize.width = r.size.width + 5;
	  allSize.height = r.size.height;

	  r.size = NSMakeSize(0, 0);
	  value = [self emptyValue];
	  valueCell = [self addValueCellForValue: value inRect: &r];
	  [valueCell setTextColor: [NSColor lightGrayColor]];
	  [valueCell setDetails: details];

	  allSize.width += r.size.width;
	  allSize.height = MAX(allSize.height, r.size.height);
	}
      else
	{
	  for(i=0; i<[val count]; i++)
	    {
	      ADPersonPropertyCell *labelCell, *valueCell;
	      NSString *label, *identifier, *value;
	      NSDictionary *details;
	      NSSize rowSize;
	      
	      label = [val labelAtIndex: i];
	      identifier = [val identifierAtIndex: i];
	      value = [val valueAtIndex: i];
	      
	      details = [NSDictionary dictionaryWithObjectsAndKeys:
					identifier, @"Identifier",
				      label, @"Label",
				      nil];
	      
	      labelCell = [self addLabelCellForLabel: label inRect: &r];
	      [labelCell setDetails: details];
	      r.origin.x += r.size.width + 5; 
	      rowSize.width = r.size.width + 5;
	      rowSize.height = r.size.height;

	      r.size.height = rowSize.height;
	      [self addActionCellWithType: ADChangeAction
		    inRect: &r
		    details: details];
	      r.origin.x += r.size.width + 5;
	      rowSize.width += r.size.width + 5;
	      rowSize.height = MAX(rowSize.height, r.size.height);

	      r.size.height = rowSize.height;
	      [self addActionCellWithType: ADRemoveAction
		    inRect: &r
		    details: details];
	      r.origin.x += r.size.width + 5;
	      rowSize.width += r.size.width + 5;
	      rowSize.height = MAX(rowSize.height, r.size.height);

	      r.size = NSMakeSize(0, 0);
	      valueCell = [self addValueCellForValue: value inRect: &r];
	      [valueCell setDetails: details];
	      if([value isEqualToString: [self emptyValue]])
		[valueCell setTextColor: [NSColor lightGrayColor]];
	      else
		[valueCell setTextColor: [NSColor textColor]];

	      rowSize.width += r.size.width;
	      rowSize.height = MAX(rowSize.height, r.size.height);
	      r.size = NSMakeSize(0, 0);
	      r.origin.x = 0;
	      r.origin.y += rowSize.height;
	      
	      allSize.width = MAX(allSize.width, rowSize.width);
	      allSize.height += rowSize.height;
	    }

	  r.origin.x = _maxLabelWidth + 5 + [_chgImg size].width + 5;
	  r.origin.y += 5;
	  [self addActionCellWithType: ADAddAction
		inRect: &r
		details: nil];
	  allSize.height += r.size.height + 5;
	}
    }

  else if(type == ADMultiDictionaryProperty)
    {
      NSRect rect = NSZeroRect;
      
      if(![val count])
	{
	  NSDictionary *details;
	  NSString *label; NSMutableDictionary *value;

	  label = [self defaultLabel];
	  value = [self emptyValue];
	  details = [NSDictionary dictionaryWithObjectsAndKeys:
				    label, @"Label",
				  nil];

	  [self layoutDictionary: value
		withLabel: label
		details: details
		buttons: NO
		forEditInRect: &rect];
	  allSize = rect.size;
	}
      else
	{
	  for(i=0; i<[val count]; i++)
	    {
	      NSString *label, *value, *identifier;
	      NSDictionary *details;
		
	      label = [val labelAtIndex: i];
	      value = [val valueAtIndex: i];
	      identifier = [val identifierAtIndex: i];

	      details =
		[NSDictionary dictionaryWithObjectsAndKeys:
				identifier, @"Identifier",
			      label, @"Label",
			      nil];
	      
	      [self layoutDictionary: [val valueAtIndex: i]
		    withLabel: [val labelAtIndex: i]
		    details: details
		    buttons: YES
		    forEditInRect: &rect];
	      allSize.width = MAX(allSize.width, rect.size.width);
	      allSize.height += rect.size.height;
	      rect.origin.x = 0; rect.origin.y += rect.size.height;
	      rect.size = NSZeroSize;
	    }
	  
	  rect.origin.x = _maxLabelWidth + 5 + [_chgImg size].width + 5;
	  rect.origin.y += 5;
	  [self addActionCellWithType: ADAddAction
		inRect: &rect
		details: nil];
	  allSize.height += rect.size.height + 5;
	}
    }

  else NSLog(@"Can't layout values of type %d yet\n", type);

  _requiredSize = allSize;
  [self setFrameSize: _requiredSize];
}


- (void) layoutForDisplay
{
  NSRect r; NSSize allSize; 
  int i;
  id cell;
  id val;
  ADPropertyType type;

  if(!_property || !_person) return;

  val = [_person valueForProperty: _property];

  type = [_person typeOfProperty: _property];

  r = NSMakeRect(0, 0, 0, 0); allSize = NSMakeSize(0, 0);

  if(!val) return;

  // convert types
  switch(type)
    {
    case ADStringProperty: break;
    case ADIntegerProperty:
      val = [NSString stringWithFormat: @"%d", [val intValue]];
      break;
    case ADRealProperty:
      val = [NSString stringWithFormat: @"%f", [val floatValue]];
      break;
    case ADDateProperty:
      val = [val descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString]];
      break;
    case ADArrayProperty:
    case ADDictionaryProperty:
    case ADDataProperty:
    case ADErrorInProperty:
      NSLog(@"Can't layout object of type %d\n", type);
      return;
    default:
      break;
    }

  // layout single-cell values
  if(!(type & ADMultiValueMask))
    {
      if(_displaysLabel)
	{
	  [self addLabelCellForLabel: _property inRect: &r];
	  allSize.width += r.size.width + 5;
	  allSize.height = r.size.height;
	  r.origin.x += r.size.width + 5; r.size = NSMakeSize(0, 0);
	}

      cell = [self addValueCellForValue: val inRect: &r];
      allSize.width += r.size.width;
      allSize.height = MAX(allSize.height, r.size.height);
    }

  // layout multi-cell values; multi-string only this far
  else if(type == ADMultiStringProperty)
    {
      for(i=0; i<[val count]; i++)
	{
	  ADPersonPropertyCell *labelCell, *valueCell;
	  NSString *label, *value, *identifier;
	  NSSize rowSize;
	  NSDictionary *details;

	  label = [val labelAtIndex: i];
	  value = [val valueAtIndex: i];
	  identifier = [val identifierAtIndex: i];

	  details =
	    [NSDictionary dictionaryWithObjectsAndKeys:
			    identifier, @"Identifier",
			  label, @"Label",
			  nil];

	  labelCell = [self addLabelCellForLabel: label
			    inRect: &r];
	  r.origin.x += r.size.width + 5; 
	  rowSize.width = r.size.width + 5;
	  rowSize.height = r.size.height;
	  r.size = NSMakeSize(0, 0);
	      
	  valueCell = [self addValueCellForValue: value
			    inRect: &r
			    details: details];
	      
	  rowSize.width += r.size.width;
	  rowSize.height = MAX(rowSize.height, r.size.height);
	  r.size = NSMakeSize(0, 0);
	  r.origin.x = 0;
	  r.origin.y += rowSize.height;
	  
	  allSize.width = MAX(allSize.width, rowSize.width);
	  allSize.height += rowSize.height;
	}
    }

  // layout dictionaries
  else if(type == ADMultiDictionaryProperty)
    {
      NSRect rect = NSZeroRect;
      for(i=0; i<[val count]; i++)
	{
	  NSArray *cells; NSDictionary *details;
	  NSString *identifier, *label; int j;

	  label = [val labelAtIndex: i];
	  identifier = [val identifierAtIndex: i];

	  details =
	    [NSDictionary dictionaryWithObjectsAndKeys:
			    identifier, @"Identifier",
			  label, @"Label",
			  nil];

	  cells = [self layoutDictionary: [val valueAtIndex: i]
			withLabel: [val labelAtIndex: i]
			forDisplayInRect: &rect];
	  for(j=0; j<[cells count]; j++)
	    [[cells objectAtIndex: j] setDetails: details];
	  
	  allSize.width = MAX(allSize.width, rect.size.width);
	  allSize.height += rect.size.height;
	  rect.origin.x = 0; rect.origin.y += rect.size.height;
	  rect.size = NSZeroSize;
	}
    }

  else
    NSLog(@"Can't layout values of type %d yet\n", type);

  _requiredSize = allSize;
  [self setFrameSize: _requiredSize];
}

- (void) layout
{
  float heightBefore, heightAfter;

  _neededLabelWidth = 0;

  // clear everything
  [_cells release]; _cells = [[NSMutableArray alloc] init];

  heightBefore = [self frame].size.height;
  if([self isEditable])
    [self layoutForEdit];
  else
    [self layoutForDisplay];
  heightAfter = [self frame].size.height;

  if((heightBefore != heightAfter) &&
     (_delegate != nil) &&
     [_delegate respondsToSelector: @selector(view:changedHeightFrom:to:)])
    [_delegate view: self changedHeightFrom: heightBefore to: heightAfter];

  [self setNeedsDisplay: YES];
}
@end

