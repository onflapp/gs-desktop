/* All Rights reserved */

#import "NetworkController.h"

static NetworkController *_controller = nil;

@implementation NetworkController

+ (instancetype)controller
{
  if (_controller == nil) {
    _controller = [NetworkController new];
  }

  return _controller;
}

+ (NSView *)view
{
  if (_controller == nil) {
    _controller = [NetworkController controller];
  }

  return [_controller view];
}

- (void)dealloc
{
  NSLog(@"NetworkController: dealloc");
  [super dealloc];
}

- (id)init
{
  if ((self = [super init])) {
    if (![NSBundle loadNibNamed:@"NetworkView" owner:self]) {
      NSLog (@"EthernetView: Could not load NIB, aborting.");
      return nil;
    }
  }  
  
  return self;
}

- (void)awakeFromNib
{
  [networkView retain];
  [networkView removeFromSuperview];
}

- (NSView *)view
{
  return networkView;
}

- (void)updateForDevice:(DKProxy<NMDevice> *)device
{
}

- (void)updateForConnection:(DKProxy<NMConnectionSettings> *)conn
{
  NSDictionary *settings;
}

@end
