// ADPersonPropertyView.m (this is -*- ObjC -*-)
// 
// Authors: Björn Giesler <giesler@ira.uka.de>
//          Riccardo Mottola
// 
// Address View Framework for GNUstep
// 

/* system includes */
#import <Foundation/Foundation.h>

/* my includes */
#import "ADPersonView.h"
#import "ADPersonPropertyView.h"

@interface NSBezierPath (ADPersonPropertyExtensions)
+ (NSBezierPath *) bezierPathWithRoundedRectInRect:(NSRect)rect
					    radius:(float) radius;
@end

@implementation NSBezierPath (ADPersonPropertyExtensions)
+ (NSBezierPath *) bezierPathWithRoundedRectInRect:(NSRect)rect
					    radius:(float) radius;
{
  NSRect innerRect; NSPoint p1, p2, p3, p4, p11, p12, p13, p14;
  NSBezierPath *path;

  innerRect = NSInsetRect(rect, radius, radius);
  p1 = NSMakePoint(NSMinX(innerRect), NSMinY(innerRect));
  p2 = NSMakePoint(NSMaxX(innerRect), NSMinY(innerRect));
  p3 = NSMakePoint(NSMaxX(innerRect), NSMaxY(innerRect));
  p4 = NSMakePoint(NSMinX(innerRect), NSMaxY(innerRect));

  p11 = NSMakePoint(NSMinX(rect), NSMinY(rect));
  p12 = NSMakePoint(NSMaxX(rect), NSMinY(rect));
  p13 = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
  p14 = NSMakePoint(NSMinX(rect), NSMaxY(rect));
  path = [self bezierPath];
 
  [path moveToPoint: p11];
  
  [path appendBezierPathWithArcWithCenter: p1
	radius: radius startAngle: 180.0 endAngle:270.0];
  [path relativeLineToPoint: p12];
  [path appendBezierPathWithArcWithCenter: p2
	radius: radius startAngle: 270.0 endAngle: 360.0];
  [path relativeLineToPoint: p13];
  [path appendBezierPathWithArcWithCenter: p3
	radius: radius startAngle: 0.0  endAngle: 90.0];
  [path relativeLineToPoint: p14];
  [path appendBezierPathWithArcWithCenter: p4
	radius: radius startAngle: 90.0  endAngle: 180.0];
  [path closePath];
  
  return path;
}
@end

@interface NSDictionary (ADPersonPropertyExtensions)
- (BOOL) isEqualComparingValues: (NSDictionary*) dict;
@end

@implementation NSDictionary (ADPersonPropertyExtensions)
- (BOOL) isEqualComparingValues: (NSDictionary*) dict
{
  NSEnumerator *e; NSString *key;

  e = [self keyEnumerator];
  while((key = [e nextObject]))
    {
      if(![dict objectForKey: key]) continue;
      if(![[dict objectForKey: key] isEqual: [self objectForKey: key]])
	return NO;
    }
  return YES;
}
@end

@implementation NSString (ADPersonPropertySupport)
- (NSString*) stringByAbbreviatingToFitWidth: (int) width
				      inFont: (NSFont*) font
{
  int index;
  width--;
  if([font widthOfString: self] <= width) return self;
  NSAssert([self length]>3, @"String too short");

  index = [self length]-3;
  while(index>=0)
    {
      NSString *str = [[self substringToIndex: index]
			stringByAppendingString: @"..."];
      if([font widthOfString: str] <= width) return str;
      index--;
    }
  return nil;
}

- (NSString*) stringByTrimmingWhitespace
{
  NSCharacterSet *wsp = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  return [self stringByTrimmingCharactersInSet: wsp];
}
  
- (BOOL) isEmptyString
{
  NSString *str = [self stringByTrimmingWhitespace];
  if([str isEqualToString: @""]) return YES;
  return NO;
}
@end

@implementation ADPersonPropertyCell
- (void) dealloc
{
  [_details release];
  [super dealloc];
}
- (void) setRect: (NSRect) r
{
  _r = r;
}
- (NSRect) rect
{
  return _r;
}
- (void) setDetails: (id) details
{
  [_details release];
  _details = [details retain];
}
- (id) details
{
  return _details;
}
- (id) copyWithZone: (NSZone*) zone
{
  ADPersonPropertyCell *cell = [super copyWithZone: zone];
  cell->_details = [_details retain];
  return cell;
}
@end

@implementation ADPersonActionCell
- (void) dealloc
{
  [_details release];
  [super dealloc];
}
- (void) setActionType: (ADActionType) type
{
  _type = type;
}
- (ADActionType) actionType
{
  return _type;
}

- (void) setOrigin: (NSPoint) origin
{
  _origin = origin;
}
- (NSRect) rect
{
  NSRect r = NSMakeRect(_origin.x, _origin.y, 0, 0);
  if([self image]) r.size = [[self image] size];
  return r;
}
- (void) setDetails: (id) details
{
  [_details release];
  _details = [details retain];
}
- (id) details
{
  return _details;
}
- (id) copyWithZone: (NSZone*) zone
{
  ADPersonActionCell *cell = [super copyWithZone: zone];
  cell->_details = [_details retain];
  return cell;
}
@end

@implementation ADPersonPropertyView (LabelMangling)
- (NSString*) nextLabelAfter: (NSString*) previous
{
  return [[ADPersonView class]
	   nextLabelAfter: previous
	   forProperty: _property];
}

- (NSString*) defaultLabel
{
  return [[ADPersonView class] defaultLabelForProperty: _property];
}

- (id) emptyValue
{
  return [[ADPersonView class] emptyValueForProperty: _property];
}

- (NSArray*) layoutRuleForValue: (NSDictionary*) dict
{
  return [[ADPersonView class] layoutRuleForProperty: _property
			       value: dict];
}
@end

static float _globalFontSize;

@implementation ADPersonPropertyView
+ (NSFont*) font
{
  return [NSFont systemFontOfSize: [self fontSize]];
}

+ (NSFont*) boldFont
{
  return [NSFont boldSystemFontOfSize: [self fontSize]];
}

+ (float) fontSize
{
  return _globalFontSize;
}

+ (void) setFontSize: (float) size
{
  _globalFontSize = size;
}

- initWithFrame: (NSRect) frame
{
  NSBundle *b; NSString *filename;
  
  _maxLabelWidth = 130;
  _fontSize = 12;
  _font = [[NSFont systemFontOfSize: _fontSize] retain];
  _fontSetExternally = NO;
  _editable = NO;
  _editingCellIndex = -1;

  // load images
  b = [NSBundle bundleForClass: [self class]];
  filename = [b pathForImageResource: @"Add.tiff"];
  _addImg = [[NSImage alloc] initWithContentsOfFile: filename];
  NSAssert(_addImg, @"Image \"Add.tiff\" could not be loaded!\n");
  filename = [b pathForImageResource: @"Remove.tiff"];
  _rmvImg = [[NSImage alloc] initWithContentsOfFile: filename];
  NSAssert(_rmvImg, @"Image \"Remove.tiff\" could not be loaded!\n");
  filename = [b pathForImageResource: @"Change.tiff"];
  _chgImg = [[NSImage alloc] initWithContentsOfFile: filename];
  NSAssert(_chgImg, @"Image \"Change.tiff\" could not be loaded!\n");

  _clickSel = @selector(clickedOnProperty:withValue:inView:);
  _changeSel = @selector(valueForProperty:changedToValue:inView:);
  _canPerformSel = @selector(canPerformClickForProperty:);
  _widthSel = @selector(view:changedWidthFrom:to:);
  _editInNextSel = @selector(beginEditingInNextViewWithTextMovement:);

  return [super initWithFrame: frame];
}

- (void) dealloc
{
  if(_editingCellIndex || _textObject)
    [self endEditing];
  [_cells release];
  [_person release];
  [_font release];
  [_delegate release];
  [_addImg release];
  [_chgImg release];
  [super dealloc];
}

- (void) setDelegate: (id) delegate
{
  [_delegate release];
  _delegate = [delegate retain];
}

- (id) delegate
{
  return _delegate;
}

- (void) setPerson: (ADPerson*) person
{
  [_person release];
  _person = [person retain];
  if(_property) [self layout];
}

- (ADPerson*) person
{
  return _person;
}

- (void) setProperty: (NSString*) property
{
  _property = [property copy];
  if(_person) [self layout];
}

- (NSString*) property
{
  return _property;
}

- (BOOL) updatePersonWithMultiValueFromCell: (ADPersonPropertyCell*) cell
{
  NSString *key, *label, *identifier; id value; NSInteger i;
  ADPropertyType type; ADMutableMultiValue *mv;
  NSMutableDictionary *dict;

  identifier = [[cell details] objectForKey: @"Identifier"];
  label = [[cell details] objectForKey: @"Label"];
  key = [[cell details] objectForKey: @"Key"];
  value = [cell stringValue];

  type = [ADPerson typeOfProperty: _property];

  mv = [[[ADMutableMultiValue alloc]
	  initWithMultiValue: [_person valueForProperty: _property]]
	 autorelease];
    
  if(identifier)
    {
      i = [mv indexForIdentifier: identifier];
      if(i == NSNotFound)
	{
	  NSLog(@"Multivalue for %@ has no index for ID %@\n",
		_property, identifier);
	  return NO;
	}
      
      switch(type)
	{
	case ADMultiStringProperty:
	  if([[mv valueAtIndex: i] isEqualToString: value])
	    return NO; // nothing to do
	  if([value isEmptyString])
	    [mv removeValueAndLabelAtIndex: i];
	  else
	    [mv replaceValueAtIndex: i withValue: value];
	  return [_person setValue: mv forProperty: _property];

	case ADMultiDictionaryProperty:
	  if(!key)
	    {
	      NSLog(@"No key for Multivalue for %@\n", _property);
	      return NO;
	    }
	  dict = [NSMutableDictionary
		   dictionaryWithDictionary: [mv valueAtIndex: i]];
	  if([[dict objectForKey: key] isEqualToString: value])
	    return NO; // nothing to do
	  if([value isEmptyString])
	    {
	      if(![dict objectForKey: key]) return NO;
	      [dict removeObjectForKey: key];
	    }
	  else
	    [dict setObject: value forKey: key];
	  [mv replaceValueAtIndex: i withValue: dict];
	  return [_person setValue: mv forProperty: _property];

	default:
	  NSLog(@"Can't update values of type 0x%x yet.\n", type);
	  return NO;
	}
    }
  else // no identifier given; make up our own
    {
      if([value isEmptyString]) return NO; // nothing to do
      
      if(!label) label = [self defaultLabel];

      switch(type)
	{
	case ADMultiStringProperty:
	  identifier = [mv addValue: value withLabel: label];
	  return [_person setValue: mv forProperty: _property];
	case ADMultiDictionaryProperty:
	  dict = [NSDictionary dictionaryWithObjectsAndKeys: value,
			       key, nil];
	  identifier = [mv addValue: dict withLabel: label];
	  return [_person setValue: mv forProperty: _property];
	default:
	  NSLog(@"No identifier given for new value of type 0x%x\n", type);
	  return NO;
	}
    }
}

- (BOOL) updatePersonWithValueFromCell: (ADPersonPropertyCell*) cell
{
  id value;
  ADPropertyType type = [ADPerson typeOfProperty: _property];
  if(type & ADMultiValueMask)
    return [self updatePersonWithMultiValueFromCell: cell];

  value = [cell stringValue];
 
  switch(type)
    {
    case ADDateProperty:
      if([value isEmptyString])
	 {
	   if([_person valueForProperty: _property])
	     return [_person removeValueForProperty: _property];
	   else
	     return NO;
	 }
      value = [NSCalendarDate dateWithNaturalLanguageString: value];
      if(!value) return NO;
      return [_person setValue: value forProperty: _property];

    case ADStringProperty:
      if([value isEmptyString])
	 {
	   if([_person valueForProperty: _property])
	     return [_person removeValueForProperty: _property];
	   else
	     return NO; // nothing to do
	 }
      else if(![[_person valueForProperty: _property] isEqualToString: value])
	return [_person setValue: value forProperty: _property];
      break;
      
    default:
      NSLog(@"Can't handle type %d yet\n", type);
      return NO;
    }
  return NO;
}

- (void) setDisplaysLabel: (BOOL) yesno
{
  if(_displaysLabel == yesno) return;
  _displaysLabel = yesno;
  if([_cells count]) [self layout];
}
  
- (BOOL) displaysLabel
{
  return _displaysLabel;
}

- (void) setMaxLabelWidth: (int) width
{
  _maxLabelWidth = width;
  if([_cells count]) [self layout];
}

- (int) maxLabelWidth
{
  return _maxLabelWidth;
}

- (int) neededLabelWidth
{
  return _neededLabelWidth;
}

- (void) drawRect: (NSRect) rect
{
  ADPersonPropertyCell *c;
  NSEnumerator *e;

  [super drawRect: rect];

  [self lockFocus];

  //#define GEOM_DEBUG
#ifdef GEOM_DEBUG
  [[NSColor colorWithDeviceRed: .5 green: 1 blue: 1 alpha: 1] set];
  NSRectFill(rect);
#endif

  e = [_cells objectEnumerator];
  while((c = [e nextObject]))
    [c drawWithFrame: [c rect] inView: self];

  [self unlockFocus];
}

- (BOOL) isFlipped
{
  return YES; 
}

- (NSFont*) font
{
  return _font;
}

- (NSFont*) boldFont
{
  return [NSFont boldSystemFontOfSize: [self fontSize]];
}

- (float) fontSize
{
  if(!_fontSetExternally)
    return [[self class] fontSize];
  return _fontSize;
}

- (void) setFontSize: (float) size
{
  _fontSize = size;
  if(!_fontSetExternally)
    {
      [_font release];
      _font = [[NSFont systemFontOfSize: _fontSize] retain];
    }
  _fontSetExternally = YES;
  if([_cells count]) [self layout];
}

- (void) setFont: (NSFont*) font
{
  [_font release];
  _font = [font retain];
  _fontSetExternally = YES;
  if([_cells count]) [self layout];
}

- (void) setEditable: (BOOL) editable
{
  if(_editable == editable)
    return;
  _editable = editable;
  _editingCellIndex = -1;
  [self layout];
}
- (BOOL) isEditable
{
  return _editable;
}

/*
 * editing
 */

- (void) endEditing
{
  if(_editingCellIndex != -1)
    {
      id cell;

      cell = [_cells objectAtIndex: _editingCellIndex];
      [cell setStringValue: [[[_textObject string] copy] autorelease]];
      [cell endEditing: _textObject];
      
      if([[cell stringValue] isEmptyString])
	{
	  id emptyValue; NSDictionary *details; NSString *key;
	  emptyValue = [self emptyValue];
	  details = [cell details];

	  if([emptyValue isKindOfClass: [NSDictionary class]])
	    {
	      key = [details objectForKey: @"Key"];

	      if(!key)
		[NSException raise: NSGenericException
			     format: @"Cell for %@ has no value for \"key\" "
			     @"in its details!", _property];

	      emptyValue = [NSString stringWithFormat: @"[%@]",
				     ADLocalizedPropertyOrLabel(key)];
	    }

	  [cell setStringValue: emptyValue];
	  [cell setTextColor: [NSColor lightGrayColor]];
	}
      
      [self updatePersonWithValueFromCell: cell];
	 
      [_textObject removeFromSuperview];
      _textObject = nil;
      _editingCellIndex = -1;
      [self layout];
    }

  if(_textObject)
    {
      [_textObject resignFirstResponder];
      [_window makeFirstResponder: _window];
    }
}

- (BOOL) hasEditableCells
{
  NSUInteger i;
  for(i=0; i<[_cells count]; i++)
    if([[_cells objectAtIndex: i] isEditable])
      return YES;
  return NO;
}

- (BOOL) hasCells
{
  return [_cells count] != 0;
}

- (void) beginEditingInCellAtIndex: (NSUInteger) i
		 countingBackwards: (BOOL) backwards
{
  while(![[_cells objectAtIndex: i] isEditable])
    if(backwards)
      i--;
    else
      i++;
  [self beginEditingInCellAtIndex: i becauseOfEvent: nil];
}

- (void) beginEditingInFirstCell
{
  [self beginEditingInCellAtIndex: 0 countingBackwards: NO];
}

- (void) beginEditingInLastCell
{
  [self beginEditingInCellAtIndex: [_cells count]-1 countingBackwards: YES];
}

- (NSUInteger) indexOfEditableCellWithDetails: (id) details
{
  NSUInteger i;

  for(i=0; i<[_cells count]; i++)
    {
      if(details)
	{
	  if([[[_cells objectAtIndex: i] details]
	       isEqualComparingValues: details] &&
	     [[_cells objectAtIndex: i] isEditable])
	    return i;
	}
      else if([[_cells objectAtIndex: i] isEditable])
	return i;
    }
  return NSNotFound;
}

- (NSString*) propertyForDragWithDetails: (id) details
{
  NSString *identifier;
  NSUInteger index;
  ADMultiValue *mv;
  id value;

  if(!details &&
     !([[ADPerson class] typeOfProperty: _property] & ADMultiValueMask))
    {
      if([_property isEqualToString: ADFirstNameProperty] ||
	 [_property isEqualToString: ADLastNameProperty])
	return [_person screenNameWithFormat: ADScreenNameFirstNameFirst];
      else
	return [_person valueForProperty: _property];
    }

  identifier = [details objectForKey: @"Identifier"];
  if(!identifier)
    {
      NSLog(@"Error: No identifier in details %@ for property %@\n",
	    details, _property);
      return nil;
    }

  mv = [_person valueForProperty: _property];
  if(![mv isKindOfClass: [ADMultiValue class]])
    {
      NSLog(@"Error: Identifier %@ given, but val for %@ is no multivalue\n",
	    identifier, _property);
      return nil;
    }

  index = [mv indexForIdentifier: identifier];
  if(index == NSNotFound)
    {
      NSLog(@"Error: Identifier %@ not found in val for %@\n",
	    identifier, _property);
      return nil;
    }

  value = [mv valueAtIndex: index];

  if([[ADPerson class] typeOfProperty: _property] == ADMultiStringProperty)
    {
      if([_property isEqualToString: ADEmailProperty])
	return [NSString stringWithFormat: @"%@ <%@>",
			 [_person screenNameWithFormat:
				    ADScreenNameFirstNameFirst],
			 value];
      else
	return value;
    }

  else if([[ADPerson class] typeOfProperty: _property] ==
	  ADMultiDictionaryProperty)
    {
      NSArray *layout;
      NSEnumerator *rowEnum, *fieldEnum;
      NSArray *row; NSString *field;
      NSMutableString *retval;

      layout = [self layoutRuleForValue: value];
      if(!layout) return nil;

      retval = [NSMutableString stringWithString: @""];

      rowEnum = [layout objectEnumerator];
      while((row = [rowEnum nextObject]))
	{
	  NSMutableString *rowContents;

	  rowContents = [NSMutableString stringWithString: @""];

	  // do we have to layout anything in this row at all?
	  fieldEnum = [row objectEnumerator];
	  while((field = [fieldEnum nextObject]))
	    if(![field hasPrefix: @"$"] && [value objectForKey: field])
	      break;

	  if(!field) continue;
	  
	  fieldEnum = [row objectEnumerator];
	  while((field = [fieldEnum nextObject]))
	    {
	      if(![rowContents isEqualToString: @""])
		[rowContents appendString: @" "];
	      if([field hasPrefix: @"$"])
		[rowContents appendString: [field substringFromIndex: 1]];
	      else
		[rowContents appendString: [value objectForKey: field]];
	    }
	      
	  if(![rowContents isEqualToString: @""])
	    {
	      if([retval isEqualToString: @""])
		[retval appendString: rowContents];
	      else
		[retval appendString: [NSString stringWithFormat: @"\n%@",
						rowContents]];
	    }
	}

      if([_property isEqualToString: ADAddressProperty])
	return [NSString stringWithFormat: @"%@\n%@",
			 [_person screenNameWithFormat: ADScreenNameFirstNameFirst],
			 retval];
      else
	return retval;
    }
  
  return nil;
}

- (NSImage*) imageForDraggedProperty: (NSString*) prop
{
  NSAttributedString *str;
  NSImage *image; 
  NSSize size;
  NSRect rect;
  NSImageRep *rep;
#define GNUSTEP_BACK_HAS_TRANSPARENT_DRAG_IMAGES 0
#if GNUSTEP_BACK_HAS_TRANSPARENT_DRAG_IMAGES
  NSBezierPath *path;
#endif

  str = [[[NSAttributedString alloc] initWithString: prop]
	  autorelease];
  size = [str size];
  size.width += 10; size.height += 10;
  rect = NSMakeRect(0, 0, size.width, size.height);
  image = [[[NSImage alloc] initWithSize: size] autorelease];

#if GNUSTEP_BACK_HAS_TRANSPARENT_DRAG_IMAGES
  rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
				   pixelsWide: size.width
				   pixelsHigh: size.height
				   bitsPerSample: 8
				   samplesPerPixel: 4
				   hasAlpha: YES
				   isPlanar: YES
				   colorSpaceName: NSCalibratedRGBColorSpace
				   bytesPerRow: 0
				   bitsPerPixel: 0] autorelease];
  [image addRepresentation: rep];
  [image lockFocus];

  [[NSColor clearColor] set];
  NSRectFillUsingOperation(rect, NSCompositeCopy);
  
  [[NSColor blackColor] set];
  path = [NSBezierPath bezierPathWithRoundedRectInRect: rect radius: 5.0];
  [path fill];
#else
  rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
				   pixelsWide: size.width
				   pixelsHigh: size.height
				   bitsPerSample: 8
				   samplesPerPixel: 3
				   hasAlpha: NO // GSFIXME: back-art
				   isPlanar: YES
				   colorSpaceName: NSCalibratedRGBColorSpace
				   bytesPerRow: 0
				   bitsPerPixel: 0] autorelease];
  [image addRepresentation: rep];
  
  [image lockFocusOnRepresentation: rep];
  [[NSColor colorWithCalibratedRed: .7 green: .7 blue: 1.0 alpha: 1.0] set];
  NSRectFill(rect);
#endif
  
  [str drawAtPoint: NSMakePoint(5, 5)];
  [image unlockFocus];

  return image;
}

/*
 * action methods
 */

- (void) textDidEndEditing: (NSNotification*) aNotification
{
  int textMovement = -1;
  NSInteger cellIndex;
  id c;
  NSDictionary *dict = [aNotification userInfo];
  id details;

  c = [_cells objectAtIndex: _editingCellIndex];
  [c setStringValue: [[[_textObject string] copy] autorelease]];
  [c endEditing: _textObject];

  [self updatePersonWithValueFromCell: c];
  
  if(dict)
    {
      id num = [dict objectForKey: @"NSTextMovement"];
      if(num) textMovement = [num intValue];
    }

  cellIndex = _editingCellIndex;
  details = [[c details] retain];
  
  _editingCellIndex = -1;
  [_textObject removeFromSuperview];
  _textObject = nil;

  if(_delegate)
    if([_delegate respondsToSelector: _changeSel])
      [_delegate valueForProperty: _property
		 changedToValue: [c stringValue]
		 inView: self];

  [((ADPersonView*)[self superview]) cleanupEmptyProperties];

  [self layout];
  [[self superview] setNeedsDisplay: YES];

  // Ended editing by any special text movement?
  switch(textMovement)
    {
    case NSReturnTextMovement:
      if(_delegate)
	if([_delegate respondsToSelector: _editInNextSel])
	  [_delegate beginEditingInNextViewWithTextMovement: textMovement];

    case NSBacktabTextMovement:
      cellIndex = [self indexOfEditableCellWithDetails: details];
      [details release];
      if(cellIndex != NSNotFound)
	{
	  cellIndex--; 
	  while(cellIndex >= 0)
	    {
	      if([[_cells objectAtIndex: cellIndex] isEditable])
		break;
	      cellIndex--;
	    }

	  if(cellIndex >= 0)
	    {
	      [self beginEditingInCellAtIndex: cellIndex becauseOfEvent: nil];
	      [self setNeedsDisplay: YES];
	      return;
	    }
	}
      if(_delegate)
	if([_delegate respondsToSelector: _editInNextSel])
	  [_delegate beginEditingInNextViewWithTextMovement: textMovement];
      break;
      
    case NSTabTextMovement:
      cellIndex = [self indexOfEditableCellWithDetails: details];
      [details release];
      if(cellIndex != NSNotFound)
	{
	  cellIndex++; 
	  
	  while(cellIndex < [_cells count])
	    {
	      if([[_cells objectAtIndex: cellIndex] isEditable])
		break;
	      cellIndex++;
	    }
	  
	  if(cellIndex < [_cells count])
	    {
	      [self beginEditingInCellAtIndex: cellIndex becauseOfEvent: nil];
	      [self setNeedsDisplay: YES];
	      return;
	    }
	}
      if(_delegate)
	if([_delegate respondsToSelector: _editInNextSel])
	  [_delegate beginEditingInNextViewWithTextMovement: textMovement];
      break;
    default:
      break;
    }
}

- (void) textDidChange: (NSNotification*) aNotification
{
  id c = [_cells objectAtIndex: _editingCellIndex];

  NSSize oldSize;
  NSPoint o;
  NSSize s, ts;

  s = [c rect].size;
  o = [c rect].origin;
  ts = s;

  // size of entire view: take origin (i.e. width of label) into account
  s.width = o.x + [[c font] widthOfString: [_textObject string]] + 4;
  ts.width = [[c font] widthOfString: [_textObject string]] + 4;

  oldSize = [self frame].size;

  s.width = MAX(s.width, _requiredSize.width);
  s.height = MAX(s.height, _requiredSize.height);
  //ts.width = s.width;
  
  [self setFrameSize: s];

  [[_textObject superview] setFrameSize: ts];
  [_textObject setFrameSize: ts];
  [_textObject setNeedsDisplay: YES];
  [self setNeedsDisplay: YES];
  [super setNeedsDisplay: YES];
  
  if(_delegate && [_delegate respondsToSelector: _widthSel])
    [_delegate view: self changedWidthFrom: oldSize.width to: s.width];

  if([_property isEqualToString: ADFirstNameProperty] ||
     [_property isEqualToString: ADLastNameProperty])
    [[NSNotificationCenter defaultCenter]
      postNotificationName: ADPersonNameChangedNotification
      object: _person
      userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
				_property, @"Property",
			      [_textObject string], @"Value",
			      nil]];
}

@end

