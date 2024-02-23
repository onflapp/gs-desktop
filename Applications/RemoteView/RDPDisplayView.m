/*
*/

#import "RDPDisplayView.h"

@implementation RDPDisplayView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];
  xwindowid = 0;
  xdisplay = NULL;

  return self;
}

@end
