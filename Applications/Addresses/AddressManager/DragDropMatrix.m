// NSMatrix+DragDrop.m (this is -*- ObjC -*-)
// 
// Aauthor: Björn Giesler <giesler@ira.uka.de>
// 
// 
// 


#import <AppKit/AppKit.h>
#import <AddressView/AddressView.h>

#import "Controller.h"
#import "DragDropMatrix.h"

static NSMutableArray *contactRows;

@implementation NSBrowserCell (DragAndDrop)
- (NSImage *) getImageOfContents: (NSSize) a_frame
{
  NSImage *image = nil;
  NSRect textFrame;
  
  textFrame.size = a_frame;
  textFrame.origin = NSZeroPoint;
  
  image = [[NSImage alloc] initWithSize: textFrame.size];
  [image setBackgroundColor:[NSColor clearColor]];
  
  [image lockFocus];
  [self drawInteriorWithFrame: textFrame inView: [NSView focusView]];
  [image unlockFocus];

  return [image autorelease];
}
@end

@implementation DragDropMatrix
- initWithFrame: (NSRect) frameRect
	   mode: (NSMatrixMode) aMode
      prototype: (NSCell*) aCell
   numberOfRows: (NSInteger) numRows
numberOfColumns: (NSInteger) numColumns

{
  [super initWithFrame: frameRect
	 mode: aMode
	 prototype: aCell
	 numberOfRows: numRows
	 numberOfColumns: numColumns];

  [self registerForDraggedTypes: [NSArray arrayWithObjects:
					    ADPeoplePboardType,
					  @"NSVCardPboardType", nil]];
  _shouldSel = @selector(dragDropMatrix:shouldAcceptDropFromSender:onCell:);
  _didSel = @selector(dragDropMatrix:didAcceptDropFromSender:onCell:);
  return self;
}

- (BOOL) acceptsFirstMouse: (NSEvent *) theEvent
{
  return YES;
}

- (void) copyToPasteboard: (NSPasteboard *) pb
{
  NSMutableArray *arr;
  NSEnumerator *e; NSCell *c;

  arr = [NSMutableArray arrayWithCapacity: [[self selectedCells] count]];
  e = [[self selectedCells] objectEnumerator];
  while((c = [e nextObject]))
    {
      NSMutableDictionary *d;
      ADPerson *p;
      
      if(![c representedObject] ||
	 ![[c representedObject] isKindOfClass: [ADPerson class]])
	continue;

      p = [c representedObject];

      d = [NSMutableDictionary dictionaryWithCapacity: 3];
      [d setObject: [NSString stringWithFormat: @"%d",
			      [[NSProcessInfo processInfo]
				processIdentifier]]
	 forKey: @"PID"];
      if([p uniqueId])
	[d setObject: [p uniqueId]
	   forKey: @"UID"];
      if([p addressBook])
	[d setObject: [[p addressBook] addressBookDescription]
	   forKey: @"AB"];

      [arr addObject: d];
    }

  if(![arr count])
    return;

  [pb declareTypes: [NSArray arrayWithObject: ADPeoplePboardType]
      owner: self];
  [pb setPropertyList: [NSArray arrayWithArray: arr]
      forType: ADPeoplePboardType];
}

- (void) mouseDown: (NSEvent *) event
{
  NSInteger row = -1, column = -1;

  if([self getRow: &row
	   column: &column
	   forPoint: [self convertPoint:[event locationInWindow]
			   fromView: nil]] &&
     [[self cellAtRow:row column: column] isEnabled] &&
     [event modifierFlags] == 0)
    {
      NSArray *sel = [self selectedCells];
  
      if([sel count] == 1 ||
	 ![sel containsObject: [self cellAtRow: row column: column]])
	[self deselectAllCells];
      if([sel containsObject: [self cellAtRow: row column: column]])
	_didDrag = NO;
      [self selectCellAtRow: row column: column];
      [self sendAction];
    }
  else
    {
      if(![[self cellAtRow: row column: column] isLeaf])
	[self deselectAllCells];
      [super mouseDown: event];
    }
}

- (void) mouseUp: (NSEvent*) event
{
  NSInteger row, column;
  if(!_didDrag && [event modifierFlags] == 0 &&
     [[self selectedCell] isLeaf])
    {
      [self getRow: &row
	    column: &column
	    forPoint: [self convertPoint:[event locationInWindow]
			    fromView: nil]];
      [self deselectAllCells];
      [self selectCellAtRow: row column: column];
      [self sendAction];
    }

  [super mouseUp: event];
}

- (void) mouseDragged: (NSEvent*) event
{
  NSPasteboard *pboard;
  NSImage *image = nil;
  NSPoint dragPoint = NSZeroPoint;
  NSPoint cellOrigin;
  CGFloat width=0, height=0;
  NSArray *cells;
  NSUInteger i;

  cells = [self selectedCells];
  for(i=0; i<[cells count]; i++)
    if(![[cells objectAtIndex: i] isLeaf]) // can only drag leaf cells
      return;

  _didDrag = YES;
  
  pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
  [self copyToPasteboard: pboard];
  
  dragPoint = [self convertPoint: [event locationInWindow]
		    fromView: nil];

  [contactRows release];
  contactRows = [[NSMutableArray alloc] initWithCapacity: [cells count]];
  for(i=0; i<[cells count]; i++)
    {
      NSInteger row, column;
      [self getRow: &row column: &column ofCell: [cells objectAtIndex: i]];
      [contactRows addObject: [NSNumber numberWithInteger: row]];
    }

  cellOrigin = [self cellFrameAtRow: [self selectedRow]
		     column: [self selectedColumn]].origin;

  image = [self draggingImage];
  width = [image size].width;
  height = [image size].height;

  [self dragImage: image
	at: dragPoint
	offset: NSMakeSize(0,0)
	event: event
	pasteboard: pboard
	source: self
	slideBack: YES];
}

- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL) local
{
  return NSDragOperationLink;
}

- (NSDragOperation) draggingEntered: (id<NSDraggingInfo>) sender
{
  return NSDragOperationLink;
}

- (void) draggingExited:  (id<NSDraggingInfo>) sender
{
  if(oldCell)
    {
      [self lockFocus];
      [oldCell drawWithFrame: oldFrame inView: self];
      [oldCell release];
      oldCell = nil;
      [_window flushWindow];
      [self unlockFocus];
    }
}

- (NSDragOperation) draggingUpdated: (id<NSDraggingInfo>) sender
{
  NSInteger row, column;
  NSRect frame;
  NSPoint p;
  NSPasteboard *pb;
  id delegate;
  NSDragOperation op;

  curCell = nil;

  delegate = [(NSBrowser*)[[[self superview] superview] superview] delegate];

  pb = [sender draggingPasteboard];

  if(![[pb types] containsObject: ADPeoplePboardType])
    return NSDragOperationNone;
  if(!delegate || ![delegate respondsToSelector: _shouldSel])
    return NSDragOperationNone;

  p = [self convertPoint: [sender draggingLocation]
	    fromView: nil];

  if(![self getRow: &row column: &column forPoint: p] ||
     self == [sender draggingSource])
    {
      if(oldCell)
	{
	  [self lockFocus];
	  [oldCell drawWithFrame: oldFrame inView: self];
	  [oldCell release];
	  oldCell = nil;
	  [_window flushWindow];
	  [self unlockFocus];
	}

      groupRow = -1;
      return NSDragOperationNone;
    }

  groupRow = row;
  curCell = [self cellAtRow: row column: column];
  
  frame = [self cellFrameAtRow: row column: column];

  [self lockFocus];
  if(curCell != oldCell)
    {
      if(oldCell)
	{
	  [self display];
	  [oldCell release];
	}
      oldCell = [curCell retain];
      oldFrame = frame;
    }
  
  op = [delegate dragDropMatrix: self
		 shouldAcceptDropFromSender: sender
		 onCell: curCell];
  if(op == NSDragOperationNone)
    return NSDragOperationNone;

  [[NSColor blackColor] set];
  NSFrameRect(frame);
  [_window flushWindow];
  [self unlockFocus];

  return op;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>) sender
{
  id delegate;

  delegate = [(NSBrowser*)[[[self superview] superview] superview] delegate];

  if(!delegate || !curCell ||
     ![delegate respondsToSelector: _shouldSel] ||
     ([delegate dragDropMatrix: self
		shouldAcceptDropFromSender: sender
		onCell: oldCell] == NSDragOperationNone))
    return NO;
  
  return YES;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>) sender
{
  id delegate;

  delegate = [(NSBrowser*)[[[self superview] superview] superview] delegate];

  if(oldCell)
    {
      [self lockFocus];
      [oldCell drawWithFrame: oldFrame inView: self];
      [oldCell release];
      oldCell = nil;
      [_window flushWindow];
      [self unlockFocus];
    }

  if(!delegate || !curCell ||
     ![delegate respondsToSelector: _didSel])
    return NO;

  return [delegate dragDropMatrix: self
		   didAcceptDropFromSender: sender
		   onCell: curCell];
}

- (NSImage*) draggingImage
{
  if([[self selectedCells] count] > 1)
    return [NSImage imageNamed: @"VCFImageMulti"];
  else
    return [NSImage imageNamed: @"VCFImage"];
}

@end
