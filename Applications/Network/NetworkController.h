/* All Rights reserved */

#import <AppKit/AppKit.h>
#import <DBusKit/DBusKit.h>
#import "NetworkManager/NetworkManager.h"

@interface NetworkController : NSObject
{
  id networkView;
  NSTextView* textView;
}

+ (instancetype)controller;
+ (NSView *)view;
- (void)updateForDevice:(DKProxy<NMDevice> *)device;
- (void)updateForConnection:(DKProxy<NMConnectionSettings> *)conn;

@end
