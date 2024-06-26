/* -*- mode: objc -*- */
// Created with dk_make_protocol tool (part of DBusKit): dk_make_protocol -i <dbus-send out>.
// Input file for dk_make_protocol is a XML file generated by command:

/* 
  dbus-send \
   --type=method_call --print-reply \
   --system \                                      <--- Send to system message bus
   --dest=org.freedesktop.NetworkManager \         <--- Connection name
   /org/freedesktop/NetworkManager \               <--- Object Path (change this)
   org.freedesktop.DBus.Introspectable.Introspect  <--- Method (Interface.Memeber)
*/

#import <Foundation/Foundation.h>
#import "NetworkManager/DBusIntrospectable.h"
#import "NetworkManager/DBusPeer.h"
#import "NetworkManager/DBusProperties.h"
#import "NetworkManager/NMActiveConnection.h"
#import "NetworkManager/NMDevice.h"

// org.freedesktop.NetworkManager
@protocol NetworkManager <DBusIntrospectable, DBusPeer, DBusProperties>

// Properties
@property (readonly) NSArray                                 *ActiveConnections;
@property (readonly) DKProxy                                 *ActivatingConnection;
@property (readonly) DKProxy                                 *PrimaryConnection;
@property (readonly) NSArray                                 *AllDevices;
@property (readonly) NSArray                                 *Devices;

@property (assign,readwrite) NSDictionary *GlobalDnsConfiguration;
@property (assign,readwrite) NSNumber     *ConnectivityCheckEnabled;
@property (assign,readwrite) NSNumber     *WimaxEnabled;
@property (assign,readwrite) NSNumber     *WwanEnabled;
@property (assign,readwrite) NSNumber     *WirelessEnabled;

@property (readonly) NSNumber *NetworkingEnabled;
@property (readonly) NSArray  *Checkpoints;
@property (readonly) NSNumber *State;
@property (readonly) NSNumber *Connectivity;
@property (readonly) NSString *PrimaryConnectionType;
@property (readonly) NSString *Version;
@property (readonly) NSNumber *Startup;
@property (readonly) NSNumber *Capabilities;
@property (readonly) NSNumber *ConnectivityCheckAvailable;
@property (readonly) NSNumber *Metered;
@property (readonly) NSNumber *WwanHardwareEnabled;
@property (readonly) NSNumber *WimaxHardwareEnabled;
@property (readonly) NSNumber *WirelessHardwareEnabled;

// Enumerating
- (NSArray*)GetAllDevices;
- (NSArray*)GetDevices;
- (DKProxy*)GetDeviceByIpIface:(NSString*)iface;
- (NSDictionary*)GetPermissions;
// State
- (NSNumber*)state;
- (void)Reload:(NSNumber*)flags;
- (void)Sleep:(NSNumber*)sleep;
- (void)Enable:(NSNumber*)enable;

- (NSNumber*)CheckConnectivity;
// Connections
- (NSArray*)AddAndActivateConnection:(NSDictionary*)connection
                                    :(DKProxy*)device
                                    :(DKProxy*)specific_object;
- (DKProxy*)ActivateConnection:(DKProxy*)connection
                              :(DKProxy*)device
                              :(DKProxy*)specific_object;
- (void)DeactivateConnection:(DKProxy*)active_connection;
// Loggging
- (NSArray*)GetLogging;
- (void)SetLogging:(NSString*)level
                  :(NSString*)domains;

// Checkpoints
- (DKProxy*)CheckpointCreate:(NSArray*)devices
                            :(NSNumber*)rollback_timeout
                            :(NSNumber*)flags;
- (void)CheckpointDestroy:(DKProxy*)checkpoint;
- (void)CheckpointAdjustRollbackTimeout:(DKProxy*)checkpoint
                                       :(NSNumber*)add_timeout;
- (NSDictionary*)CheckpointRollback:(DKProxy*)checkpoint;

@end
