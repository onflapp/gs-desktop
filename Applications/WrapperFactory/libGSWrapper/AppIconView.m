#import "AppIconView.h"

#include <X11/Xlib.h>
#include <X11/X.h>

@implementation AppIconView

- (id) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  tileImage = [NSImage imageNamed:@"common_Tile"];
  return self;
}

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

- (void) setImage:(NSImage*) img {

}

- (void) mouseDown:(NSEvent*) theEvent {
}

- (void) drawRect:(NSRect)r
{
  [tileImage compositeToPoint:NSMakePoint(0,0)
                     fromRect:NSMakeRect(0, 0, 64, 64)
                    operation:NSCompositeSourceAtop];

  [super drawRect:r];
}
@end
