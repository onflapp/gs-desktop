/* 
   Project: SystemManager

   Author: Ondrej Florian

   Created: 2024-01-19 23:40:24 +0100 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import "SystemWindow.h"
#import "ConsoleController.h"

@interface AppController : NSObject
{
  SystemWindow* systemWindow;
  ConsoleController* consoleController;
  NSWindow* controlPanel;
  NSWindow* startupPanel;
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

- (void) openDirectory: (id)sender;
- (void) control: (id)sender;
- (void) editStartup: (id)sender;

- (void) showPrefPanel: (id)sender;
- (void) showSystemProcesses: (id)sender;

- (NSWindow*) executeConsoleCommand:(NSString*)exec withArguments:args;

@end

#endif
