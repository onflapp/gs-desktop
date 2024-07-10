/* 
 * AppController.h
 */

#import <AppKit/AppKit.h>
#import "NetworkManager/NetworkManager.h"
#import "NetworkManager/NMAccessPoint.h"
#import "NetworkManager/NMConnectionSettings.h"
#import "NMSetup.h"
#import "NetworkInfo.h"
#import "MiniView.h"

#define WIFI_ITEM_TAG 123

@interface AppController : NSObject
{
  DKPort       *sendPort;
  NSConnection *connection;
  NSTimer      *timer;

  // Data
  NSMutableArray *connections;

  BOOL wifiActive;

  // GUI
  NSView        *controlView;
  NSWindow      *window;
  NSBox         *contentBox;
  NSBrowser     *connectionList;
  NSPopUpButton *connectionAction;
  NSButton      *connectionToggle;
  NSProgressIndicator *signalInfo;
  NSButton      *wifiToggle;
  NSTextField   *labelInfo;

  NSBox         *statusBox;
  NSTextField   *statusInfo;
  NSTextField   *statusDescription;
  NSView        *connectionView;

  NMSetup       *nmSetupPanel;
  NetworkInfo   *networkInfo;

  DKProxy<NetworkManager>       *networkManager;
}

- (void)deactivateConnection;
- (void)activateConnection;

- (void)connectionListClick:(id)sender;
- (void)updateConnectionInfo:(NSTimer *)ti;

@property (retain) DKProxy<NetworkManager> *networkManager;

@end
