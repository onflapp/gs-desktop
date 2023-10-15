/* All Rights reserved */

#import <AppKit/AppKit.h>
#import <DBusKit/DBusKit.h>
#import "NetworkManager/NetworkManager.h"
#import "EthernetController.h"

@interface WifiController : EthernetController
{
}

+ (instancetype)controller;
+ (NSView *)view;

@end
