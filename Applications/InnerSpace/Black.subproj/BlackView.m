#include "BlackView.h"

@implementation BlackView
//
// Initialization
//
- (BOOL)useBufferedWindow
{
  return NO;
}

- (BOOL)isBoringScreenSaver
{
  return NO;
}

//
// The Graphics Code
//
- (void)drawRect:(NSRect)rects
{
  [[NSColor blackColor] set];
  NSRectFill(rects);
}

- (void)oneStep
{
  // do nothing...
  // NSLog(@"One step called");
}
@end

//
// Static view...
//
@implementation StaticBlackView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect:rects];
}
@end
