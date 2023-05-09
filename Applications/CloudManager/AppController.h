/* 
   Project: CloudManager

   Author: Ondrej Florian,,,

   Created: 2022-09-15 23:45:03 +0200 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import "ServiceManager.h"
#import "ServiceTask.h"
#import "RCloneSetup.h"

@interface AppController : NSObject {
  IBOutlet NSMatrix* serviceListView;
  IBOutlet NSTextField* serviceName;
  IBOutlet NSTextField* serviceStatus;
  IBOutlet NSTextField* serviceDescription;
  IBOutlet NSTextField* serviceRemoteName;
  IBOutlet NSTextField* serviceMountPoint;

  IBOutlet NSWindow* window;
  
  BOOL launched;
  ServiceManager* serviceManager;

  RCloneSetup* rcloneSetup;
}

+ (void) initialize;

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName;

- (IBAction) showPrefPanel:(id)sender;
- (IBAction) configRCloneService:(id)sender;
- (IBAction) controlService:(id)sender;

@end

#endif
