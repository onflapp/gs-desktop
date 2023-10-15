/* 
 * AppController.h
 */

#import <AppKit/AppKit.h>
#import "NetworkManager/NetworkManager.h"
#import "NetworkManager/NMAccessPoint.h"
#import "NetworkManager/NMConnectionSettings.h"
#import "ConnectionManager.h"
#import "MiniView.h"

@interface AppController : NSObject
{
  DKPort       *sendPort;
  NSConnection *connection;
  NSTimer      *timer;

  ConnectionManager *connMan;

  // Data
  NSMutableArray *connections;

  // GUI
  NSView        *controlView;
  NSWindow      *window;
  NSBox         *contentBox;
  NSBrowser     *connectionList;
  NSPopUpButton *connectionAction;
  NSProgressIndicator *signalInfo;
  NSTextField   *labelInfo;

  NSBox         *statusBox;
  NSTextField   *statusInfo;
  NSTextField   *statusDescription;
  NSView        *connectionView;
}

@property (readonly) DKProxy<NetworkManager> *networkManager;

@end
