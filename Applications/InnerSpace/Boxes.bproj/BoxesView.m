#include "BoxesView.h"
#include <stdlib.h>

#define RAND  ((float)rand()/(float)RAND_MAX)

@implementation BoxesView
//
// Initialization
//
- (BOOL)useBufferedWindow
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
  float x = 0, y = 0, w = 0, h = 0;
  float r = 0, g = 0, b = 0, a = 0;
  NSRect rect; 
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSRect frame = [[NSScreen mainScreen] frame];
  
  // size and position...
  x = RAND * frame.size.width;
  y = RAND * frame.size.height;
  w = RAND * (frame.size.width - x);
  h = RAND * (frame.size.height - y);

  // color and opacity...
  r = RAND; // 0..1
  g = RAND; // 0..1
  b = RAND; // 0..1
  a = RAND; // 0..1
  // NSLog(@"%f %f %f %f     %f %f %f %f",x,y,w,h,r,g,b,a);
  rect = NSMakeRect(x,y,w,h);
  [[NSColor colorWithCalibratedRed: r green: g blue: b alpha: a] set];
  NSRectFill(rect);
}
@end

//
// Static view...
//
@implementation StaticBoxesView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect:rects];
}
@end
