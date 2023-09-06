/* 
   Project: MountUp

   Author: Ondrej Florian,,,

   Created: 2023-08-09 19:25:27 +0000 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import <SystemKit/OSEUDisksAdaptor.h>
#import <SystemKit/OSEUDisksVolume.h>
#import "ServiceManager.h"
#import "NetworkDrive.h"

@interface AppController : NSObject
{
  IBOutlet NSView* controlView;
  IBOutlet NSBrowser* volumesBrowser;
  IBOutlet NSPanel* volumesPanel;
  IBOutlet NSButton* actionButton;
  IBOutlet NSButton* openButton;
  IBOutlet NSButton* toggleButton;
  IBOutlet NSTextField* device;
  IBOutlet NSTextField* path;
  IBOutlet NSTextField* status;

  OSEUDisksAdaptor* disks;
  NSMutableArray* volumes;
  ServiceManager* services;

  NetworkDrive* networkDrive;
}

+ (void)  initialize;

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName;

- (void) ejectLastMounted:(id)sender;

- (void) showPrefPanel: (id)sender;
- (void) showMountPanel:(id)sender;
- (void) showVolumesPanel: (id)sender;
- (void) toggleShowAll: (id)sender;

@end

#endif
