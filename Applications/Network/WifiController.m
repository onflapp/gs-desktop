/* All Rights reserved */

#import "WifiController.h"

static WifiController *_controller = nil;

@implementation WifiController

+ (instancetype)controller
{
  if (_controller == nil) {
    _controller = [WifiController new];
  }

  return _controller;
}

+ (NSView *)view
{
  if (_controller == nil) {
    _controller = [WifiController controller];
  }

  return [_controller view];
}

- (void)dealloc
{
  NSLog(@"WifiController: dealloc");
  [super dealloc];
}

- (id)init
{
  if ((self = [super init])) {
    if (![NSBundle loadNibNamed:@"WifiView" owner:self]) {
      NSLog (@"WifiView: Could not load NIB, aborting.");
      return nil;
    }
  }  
  
  return self;
}

- (void)awakeFromNib
{
  [ethernetView retain];
  [ethernetView removeFromSuperview];
  [configureMethod setRefusesFirstResponder:YES];
}

- (NSView *)view
{
  return ethernetView;
}

@end
