/*
*/

#import <AppKit/AppKit.h>
#import <LinkIcon.h>

@implementation LinkIcon

- (void)awakeFromNib
{
  [self setRefusesFirstResponder:YES];
  [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];

  [self setRefusesFirstResponder:YES];

  return self;
}

- (void)dealloc
{
  RELEASE(linkToDrag);
  [super dealloc];
}

// --- Drag and drop

- (void)mouseDown:(NSEvent *)theEvent
{
  
  if (delegate &&  [delegate respondsToSelector:@selector(provideLinkForDragging)]) {
    NSString* link = [delegate provideLinkForDragging];
    if (link) ASSIGN(linkToDrag, link);
    else {
      RELEASE(linkToDrag);
      linkToDrag = nil;
      return;
    }
  }

  NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
  NSPoint dragPosition;

  [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
  [pboard setString:linkToDrag forType:NSStringPboardType];

  // Start the drag operation
  dragPosition = [self convertPoint:[theEvent locationInWindow]
			   fromView:nil];
  dragPosition.x += 8;
  dragPosition.y -= 32;

  [self dragImage:[self image]
	       at:dragPosition
	   offset:NSZeroSize
	    event:theEvent
       pasteboard:pboard
	   source:self
	slideBack:YES];
}

// --- NSDraggingDestination protocol methods
// -- Before the image is released
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
  if (linkToDrag) return NSDragOperationCopy;
  else return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
}

// -- After the image is released
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
  return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}

// --- NSDraggingSource protocol methods

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
  return NSDragOperationCopy;
}

@end

