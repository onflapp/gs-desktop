/* 
   Project: DefaultsManager

   Author: ,,,

   Created: 2022-09-26 17:05:45 +0200 by pi
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import "Domains.h"
#import "Defaults.h"

@interface AppController : NSObject
{
  Domains* domains;
  Defaults* defaults;
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

- (void) showDomainsPanel: (id)sender;
- (void) showDefaultsPanel: (id)sender;

@end

#endif
