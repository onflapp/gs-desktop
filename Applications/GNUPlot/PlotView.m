/*
*/

#import "PlotView.h"

@implementation PlotView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];
  xwindowid = 0;
  xdisplay = NULL;
  
  return self;
}

- (NSString*) createPlotWindow {
  [self createXWindowID];
  
  return [NSString stringWithFormat:@"%lx", xwindowid];
}

@end
