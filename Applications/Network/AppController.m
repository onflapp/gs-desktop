/*
 *  AppController.m 
 */

#import <Foundation/NSNotification.h>
#import <DBusKit/DBusKit.h>
#import <DesktopKit/NXTAlert.h>

#import "NetworkController.h"
#import "AppController.h"

#define CONNECTION_NAME @"org.freedesktop.NetworkManager"
#define OBJECT_PATH     @"/org/freedesktop/NetworkManager"
#define DKNC [DKNotificationCenter systemBusCenter]

void removeMenuItems(NSMenu* menu)
{
  NSMutableArray* toremove = [NSMutableArray array];
  for (NSMenuItem* it in [menu itemArray]) {
    if ([it tag] == WIFI_ITEM_TAG) {
      [toremove addObject:it];
    }
  }
  for (NSMenuItem* it in toremove) {
    [menu removeItem:it];
  }
}

@implementation AppController (NetworkManager)

- (NSString *)_nameOfDeviceType:(NSNumber *)type
{
  NSString *typeName = nil;
  switch([type intValue]) {
  case 1:
    typeName = @"Ethernet";
    break;
  case 2:
    typeName = @"Wi-Fi";
    break;
  case 5:
    typeName = @"Bluetooth";
    break;
  case 14:
    typeName = @"Generic";
    break;
  }
  return typeName;
}

- (NSString *)_descriptionOfDeviceState:(NSNumber *)state
{
  NSString *desc = nil;
  switch([state intValue]) {
  case 0:
    desc = @"The device's state is unknown";
    break;
  case 10:
    desc = @"The device is recognized, but not managed by NetworkManager";
    break;
  case 20:
    desc = @"The device is managed by NetworkManager, but is not available for "
      @"use. Reasons may include the wireless switched off, missing firmware, no"
      @" ethernet carrier, missing supplicant or modem manager, etc.";
    break;
  case 30:
    desc = @"The device can be activated, but is currently idle and not connected "
      @"to a network.";
    break;
  case 40:
    desc = @"The device is preparing the connection to the network. This may "
      @"include operations like changing the MAC address, setting physical link "
      @"properties, and anything else required to connect to the requested network.";
    break;
  case 50:
    desc = @"The device is connecting to the requested network. This may include "
      @"operations like associating with the Wi-Fi AP, dialing the modem, connecting "
      @"to the remote Bluetooth device, etc.";
    break;
  case 60:
    desc = @"The device requires more information to continue connecting to the "
      @"requested network. This includes secrets like WiFi passphrases, login "
      @"passwords, PIN codes, etc.";
    break;
  case 70:
    desc = @"The device is requesting IPv4 and/or IPv6 addresses and routing "
      @"information from the network.";
    break;
  case 80:
    desc = @"The device is checking whether further action is required for the "
      @"requested network connection. This may include checking whether only "
      @"local network access is available, whether a captive portal is blocking "
      @"access to the Internet, etc.";
    break;
  case 90:
    desc = @"The device is waiting for a secondary connection (like a VPN) which "
      @"must activated before the device can be activated";
    break;
  case 100:
    desc = @"The device has a network connection, either local or global.";
    break;
  case 110:
    desc = @"A disconnection from the current network connection was requested, "
      @"and the device is cleaning up resources used for that connection. The "
      @"network connection may still be valid.";
    break;
  case 120:
    desc = @"The device failed to connect to the requested network and is "
      @"cleaning up the connection request";
    break;
  }
  return desc;
}

- (DKProxy<NMConnectionSettings> *)_connectionWithName:(NSString *)name
                                             forDevice:(DKProxy<NMDevice> *)device
{
  NSDictionary *settings;
  DKProxy<NMConnectionSettings> *conn = nil;
  
  // NSArray<DKProxy<NMConnectionSettings> *> *allConns;
  // allConns = device.AvailableConnections;
  for (DKProxy<NMConnectionSettings> *connSets in device.AvailableConnections) {
    settings = [connSets GetSettings];
    if ([[[settings objectForKey:@"connection"] objectForKey:@"id"]
          isEqualToString:name] != NO) {
      conn = connSets;
      break;
    }
  }

  return conn;
}

- (BOOL)_isActiveConnection:(NSString *)name
                  forDevice:(DKProxy<NMDevice> *)device
{
  DKProxy<NMConnectionSettings> *conn;
  DKProxy<NMActiveConnection>   *active;
  DKProxy<NMConnectionSettings> *activeConn;

  conn = [self _connectionWithName:name forDevice:device];
  active = device.ActiveConnection;
  if ([active respondsToSelector:@selector(Connection)]) {
    activeConn = (DKProxy<NMConnectionSettings> *)active.Connection;
  }
  else {
    return NO;
  }
  
  return [conn.Filename isEqualToString:activeConn.Filename];
}

@end

@implementation AppController

@synthesize networkManager;

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init {
  if ((self = [super init])) {
     MiniView *mv = [[MiniView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    [[NSApp iconWindow] setContentView:mv];

    nmSetupPanel = [[NMSetup alloc] init];
    networkInfo = [[NetworkInfo alloc] init];
  }
  return self;
}

//
// --- Application
//

- (void)applicationWillFinishLaunching:(NSNotification *)notif
{
  connections = [NSMutableArray new];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
  [[[NSApp iconWindow] contentView] addSubview:controlView];
  [controlView setFrame:NSMakeRect(8, 8, 48, 48)];
  [controlView setNeedsDisplay:YES];

  [labelInfo setFont:[NSFont labelFontOfSize:7]];
  [labelInfo setStringValue:@"..."];
  [signalInfo setDoubleValue:0];

  [NSApp setServicesProvider:self];
  
  if([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }

  [self performSelector:@selector(initConnection) 
             withObject:nil 
             afterDelay:0.1];
}

- (void)initConnection {
  DKPort *receivePort;
    
  sendPort = [[DKPort alloc] initWithRemote:CONNECTION_NAME
                                      onBus:DKDBusSystemBus];
  receivePort = [DKPort portForBusType:DKDBusSessionBus];
  connection = [NSConnection connectionWithReceivePort:receivePort
                                              sendPort:sendPort];

  if (connection) {
    [DKPort enableWorkerThread];
    self.networkManager = (DKProxy<NetworkManager> *)[connection proxyAtPath:OBJECT_PATH];
    NSLog(@"awakeFromNib: NetworkManager: %@", self.networkManager.Version);

    [connection retain];
    [window setTitle:@"Network Connections"];
    [connectionList loadColumnZero];
    [connectionList selectRow:0 inColumn:0];
    [self connectionListClick:connectionList];
    [DKNC addObserver:self
             selector:@selector(deviceStateDidChange:)
                 name:@"DKSignal_org.freedesktop.NetworkManager.Device_StateChanged"
               object:nil];
    [connectionAction setEnabled:YES];

    [self updateSignalInfo];
  }
  else {
    [window setTitle:@"Connection to NetworkManager failed!"];
  }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
  if (timer) {
    [timer invalidate];
    RELEASE(timer);
  }
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
  NSLog(@"AppController: applicationWillTerminate");
  [[NetworkController controller] release];
  [connection invalidate];
  [sendPort release];
  self.networkManager = nil;
}

//
// --- Main window
//

- (void)_clearFields
{
  [statusInfo setStringValue:@"Unknown"];
  [statusDescription setStringValue:@""];
}

- (void)_lockControls
{
  [wifiToggle setEnabled:NO];
  [connectionToggle setEnabled:NO];
}

- (void)_unlockControls
{
  [wifiToggle setEnabled:YES];
  [connectionToggle setEnabled:YES];
}

- (void)awakeFromNib
{
  [statusBox retain];
  [statusBox removeFromSuperview];
  [window center];
  [window setTitle:@"Connecting to NetworkManager..."];
  [window setFrameAutosaveName:@"connection_window"];
  [connectionAction setRefusesFirstResponder:YES];
  [self _clearFields];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
  if ([menuItem action] == @selector(wifiToggleClick:)) {
    if (wifiActive) {
      [menuItem setTitle:@"Turn Off"];
    }
    else {
      [menuItem setTitle:@"Turn On"];
    }
  }
  return YES;
}

- (void)     browser:(NSBrowser *)sender
 createRowsForColumn:(NSInteger)column
            inMatrix:(NSMatrix *)matrix
{
  NSBrowserCell *cell;
  NSInteger     row = 0;
  NSString      *title;
  NSArray       *allDevices = [self.networkManager GetAllDevices];
    
  for (DKProxy<NMDevice> *device in allDevices) {
    if ([device.DeviceType intValue] == 14)
      continue; //loopback

    if ([device.Managed intValue]) {
      for (DKProxy<NMConnectionSettings> *conn in device.AvailableConnections) {
        if ([conn respondsToSelector:@selector(GetSettings)] == NO)
          continue;
        title = [[[conn GetSettings] objectForKey:@"connection"]
                      objectForKey:@"id"];
        if (title && [title isEqualToString:@""] == NO) {
          [matrix addRow];
          row = [matrix numberOfRows] - 1;
          cell = [matrix cellAtRow:row column:column];
          [cell setLeaf:YES];
          [cell setRefusesFirstResponder:YES];
          [cell setTitle:title];
          [cell setRepresentedObject:device];
        }
      }  
    }
    else {
      title = [NSString stringWithFormat:@"%@ (unmanaged)", device.Interface];
      [matrix addRow];
      row = [matrix numberOfRows] - 1;
      cell = [matrix cellAtRow:row column:column];
      [cell setLeaf:YES];
      [cell setRefusesFirstResponder:YES];
      [cell setTitle:title];
      [cell setRepresentedObject:device];
    }
  }
}

- (void) requestScan:(id)sender
{
  NSArray       *allDevices = [self.networkManager GetAllDevices];
  NSMenu        *menu = [sender menu];

  removeMenuItems(menu);

  for (DKProxy<NMDevice> *device in allDevices) {
    if ([device respondsToSelector:@selector(GetAllAccessPoints)]) {
      [device RequestScan:nil];
      NSArray *list = [device GetAccessPoints];
      if (list) {
        for (DKProxy<NMAccessPoint> *ap in list) {
          if ([ap respondsToSelector:@selector(Ssid)]) {
            NSMutableString* sid = [NSMutableString string];
            for (id c in ap.Ssid) {
              [sid appendFormat:@"%c", [c charValue]];
            }
            NSLog(@"(%@)", sid);
            NSLog(@" - Strength: %d%% Bitrate: %d Mb/s Frequency: %.2f Hz\n",
                [ap.Strength intValue], [ap.MaxBitrate intValue]/1000,
                [ap.Frequency floatValue]/1000.0);

            NSString* title = [NSString stringWithFormat:@"%@ - %d%%", 
                                sid, [ap.Strength intValue]];

            NSMenuItem *item = [menu addItemWithTitle:title
                                               action:@selector(runMenuItem:) 
                                        keyEquivalent:@""];
            [item setTarget:self];
            //[item setRepresentedObject:it];
            [item setTag:WIFI_ITEM_TAG];
          }
        }
      }
    }
  }
}

- (void) updateSignalInfo
{
  NSArray       *allDevices = [self.networkManager GetAllDevices];

  wifiActive = NO;
  [labelInfo setStringValue:@"..."];
  for (DKProxy<NMDevice> *device in allDevices) {
    // Wi-Fi
    if ([device respondsToSelector:@selector(ActiveAccessPoint)]) {
      DKPort<NMAccessPoint> *ap = device.ActiveAccessPoint;
      if (ap && [ap respondsToSelector:@selector(Ssid)]) {
        NSMutableString* sid = [NSMutableString string];
        for (id c in ap.Ssid) {
          [sid appendFormat:@"%c", [c charValue]];
        }
        NSLog(@"(%s)", [ap.HwAddress cString]);
        NSLog(@" - Strength: %d%% Bitrate: %d Mb/s Frequency: %.2f Hz\n",
                [ap.Strength intValue], [ap.MaxBitrate intValue]/1000,
                [ap.Frequency floatValue]/1000.0);
        
        [labelInfo setStringValue:sid];
        [signalInfo setDoubleValue:(double)[ap.Strength intValue]];
        wifiActive = YES;

        break;
      }
    }
  }

  if (wifiActive) {
    [wifiToggle setState:1];
  }
  else {
    [wifiToggle setState:0];
    [labelInfo setStringValue:@"N/A"];
    [signalInfo setDoubleValue:0.0];
  }
}

- (void) wifiToggleClick:(id) sender
{
  if (wifiActive) {
    [wifiToggle setState:0];
    [self performSelector:@selector(deactivateWifi) withObject:nil afterDelay:0.1];
  }
  else {
    [wifiToggle setState:1];
    [self performSelector:@selector(activateWifi) withObject:nil afterDelay:0.1];
  }
}

- (void)_setConnectionView:(NSView *)view
{
  NSRect viewFrame;

  if (connectionView) {
    [connectionView removeFromSuperview];
  }
  if (view) {
    [contentBox addSubview:view];
  }
  connectionView = view;
  NSRect r = [contentBox frame];
  r.origin.x = 0;
  r.origin.y = 0;
  [connectionView setFrame:r];
  [connectionView setHidden:NO];
}

- (void)_updateStatusInfoForDevice:(DKProxy<NMDevice> *)device
{
  NSString *status, *statusDesc;
  BOOL managed = (BOOL)[device.Managed intValue];
  
  status = ([device.State intValue] < 100) ? @"Not Connected": @"Connected";
  statusDesc = [self _descriptionOfDeviceState:device.State];
  
  [self _clearFields];
  [statusInfo setStringValue:status];
  [statusDescription setStringValue:statusDesc];
}

- (void)connectionListClick:(id)sender
{
  NSBrowserCell                 *cell = [connectionList selectedCell];
  DKProxy<NMDevice>             *device;
  DKProxy<NMConnectionSettings> *conn;
  id<NSMenuItem>                popupItem;

  if (cell == nil)
    return;

  if ((device = [cell representedObject]) == nil)
    return;

  if ([statusBox superview] == nil) {
    [[window contentView] addSubview:statusBox];
  }
 
  if ([device.Managed intValue]) {
    switch([device.DeviceType intValue]) {
    case 1: // Ethernet
      [connectionToggle setEnabled:YES];
      if ((BOOL)[self _isActiveConnection:[cell title] forDevice:device] != NO) {
        NSLog(@"%@ is active connection.", [cell title]);
        DKProxy<NMActiveConnection> *ac = device.ActiveConnection;
        [[NetworkController controller]
          updateForConnection:ac.Connection];


        [self _setConnectionView:[NetworkController view]];
        [self _updateStatusInfoForDevice:device];
      }
      else {
        conn = [self _connectionWithName:[cell title] forDevice:device];
        [[NetworkController controller] updateForConnection:conn];
        [self _clearFields];
        [connectionView setHidden:YES];
        [statusInfo setStringValue:@"Not Connected"];
      }
      break;
    case 2: // Wi-Fi
      [connectionToggle setEnabled:YES];
      if ((BOOL)[self _isActiveConnection:[cell title] forDevice:device] != NO) {
        NSLog(@"%@ is active connection.", [cell title]);
        DKProxy<NMActiveConnection> *ac = device.ActiveConnection;
        [[NetworkController controller]
          updateForConnection:ac.Connection];

        [self _setConnectionView:[NetworkController view]];
        [self _updateStatusInfoForDevice:device];
      }
      else {
        conn = [self _connectionWithName:[cell title] forDevice:device];
        [[NetworkController controller] updateForConnection:conn];
        [self _clearFields];
        [connectionView setHidden:YES];
        [statusInfo setStringValue:@"Not Connected"];
      }
      break;
    case 5: // Bluetooth
      break;
    case 14: // Generic
    default:
      [statusInfo setStringValue:@"Unknown"];
      [connectionToggle setEnabled:NO];
      [connectionView setHidden:YES];
      break;
    }

    popupItem = [connectionAction
                  itemAtIndex:[connectionAction indexOfItemWithTag:3]];
    if ([self _isActiveConnection:[cell title] forDevice:device]) {
      [popupItem setTitle:@"Deactivate..."];
      [connectionToggle setTitle:@"Disconnect"];
    }
    else {
      [popupItem setTitle:@"Activate..."];
      [connectionToggle setTitle:@"Connect"];
    }
  }
  else {
    [connectionToggle setEnabled:NO];
    [self _setConnectionView:[NetworkController view]];
    [[NetworkController controller] updateForDevice:device];
    [self _clearFields];
    [statusInfo setStringValue:@"Not Managed"];
  }
}

- (void)connectionToggleClick:(id)sender
{
  if ([[sender title] isEqualToString:@"Disconnect"]) {
    [self deactivateConnection];
  }
  else {
    [self activateConnection];
  }
}

// --- "Connection" pull down button
- (void)connectionActionClick:(id)sender
{
  switch ([[sender selectedItem] tag])
    {
    case 0: // Add
      // Delay message send to leave room for popup menu closing
      [NSTimer scheduledTimerWithTimeInterval:0.1
                                       target:self
                                     selector:@selector(addConnection)
                                     userInfo:nil
                                      repeats:NO];
      break;
    case 1: // Remove
      [NSTimer scheduledTimerWithTimeInterval:0.1
                                       target:self
                                     selector:@selector(removeConnection)
                                     userInfo:nil
                                      repeats:NO];
      break;
    case 2: // Rename
      NSLog(@"Rename Connection");
      break;
    case 3: // Deactivate
      if ([[[sender selectedItem] title] isEqualToString:@"Deactivate..."]) {
        [self deactivateConnection];
      }
      else {
        [self activateConnection];
      }
      break;
    default:
      break;
    }
}

- (void)showNetworkSetup:(id) sender
{
  [nmSetupPanel showPanelAndRunSetup:sender];
}

- (void)showNetworkInfo:(id) sender
{
  [networkInfo showPanelAndRunInfo:sender];
}

- (void)showConfig:(id) sender
{
  [window makeKeyAndOrderFront:sender];
}

- (void)deactivateConnection
{
  [statusInfo setStringValue:@"Disconnecting..."];
  [self _lockControls];

  DKProxy<NMDevice> *device = [[connectionList selectedCell] representedObject];
  [self.networkManager DeactivateConnection:device.ActiveConnection];
}

- (void)deactivateWifi
{  
  [self _lockControls];

  NSArray       *allDevices = [self.networkManager GetAllDevices];
  DKProxy<NMDevice> *device = nil;

  for (DKProxy<NMDevice> *dev in allDevices) {
    if ([dev respondsToSelector:@selector(ActiveAccessPoint)]) {
      DKPort<NMAccessPoint> *ap = dev.ActiveAccessPoint;
      if (ap && [ap respondsToSelector:@selector(Ssid)]) {
        device = dev;
        break;
      }
    }
  }

  if (device) {
    [self.networkManager DeactivateConnection:device.ActiveConnection];
  }
  else {
    [self _unlockControls];
  }

}

- (void)activateConnection
{
  [statusInfo setStringValue:@"Connecting..."];
  [self _lockControls];

  DKProxy<NMDevice>             *device;
  DKProxy<NMConnectionSettings> *conn;

  device = [[connectionList selectedCell] representedObject];
  conn = [self _connectionWithName:[[connectionList selectedCell] title]
                         forDevice:device];
  
  // NSLog(@"Activate connection: %@ - %@", conn,
  //       [[[conn GetSettings] objectForKey:@"connection"] objectForKey:@"id"]);
  [self.networkManager ActivateConnection:conn
                                         :device
                                         :device];
}

- (void)activateWifi
{
  [self _lockControls];

  NSArray       *allDevices = [self.networkManager GetAllDevices];
  DKProxy<NMDevice>             *device = nil;
  DKProxy<NMConnectionSettings> *conn = nil;

  for (DKProxy<NMDevice> *dev in allDevices) {
    if ([dev respondsToSelector:@selector(AccessPoints)]) {
      for (DKProxy<NMConnectionSettings> *c in dev.AvailableConnections) {
        if ([c respondsToSelector:@selector(GetSettings)]) {
          conn = c;
          device = dev;
          break;
        }
      }
    }
  }

  if (device && conn) {
    NSLog(@"activate");
    [self.networkManager ActivateConnection:conn
                                       :device
                                       :device];
  }
  else {
    [self _unlockControls];
  }

}


/* Signals/Notifications */
- (void)deviceStateDidChange:(NSNotification *)aNotif
{
  NSLog(@"Device state was changed: \n%@\nuserInfo: %@",
        [aNotif object], [aNotif userInfo]);
  // if ([[connectionList selectedCell] representedObject] == [aNotif object]) {
  //   NSLog(@"Update selected connection info");
    // [self connectionListClick:connectionList];
  // }
  if (timer &&
      [timer isKindOfClass:[NSTimer class]] &&
      [timer isValid]) {

    [timer invalidate];
    RELEASE(timer);
  }
  timer = [NSTimer scheduledTimerWithTimeInterval:.5
                                  target:self
                                selector:@selector(updateConnectionInfo:)
                                userInfo:nil
                                 repeats:NO];
  RETAIN(timer);
}

- (void)updateConnectionInfo:(NSTimer *)ti
{
  [self _unlockControls];
  [self updateSignalInfo];
  [self connectionListClick:connectionList];

  [timer invalidate];
  RELEASE(timer);
  timer = nil;
}

@end
