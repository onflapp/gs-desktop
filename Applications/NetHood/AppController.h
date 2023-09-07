/* 
   Project: NetHood

   Author: Ondrej Florian,,,

   Created: 2023-09-06 23:21:19 +0200 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import "NetworkServices.h"

@interface AppController : NSObject
{
  IBOutlet NSPanel* panel;
  IBOutlet NSBrowser* browser;
  
  NetworkServices* networkServices;
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

- (void) showPrefPanel: (id)sender;
- (void) showPanel: (id)sender;

@end

#endif
