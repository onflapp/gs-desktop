/*
*/

#import "VNCDisplayView.h"

@implementation VNCDisplayView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];
  xwindowid = 0;
  xdisplay = NULL;

  return self;
}

@end
