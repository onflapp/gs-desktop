/* 
   Project: NotMon

   Created: 2023-07-08 22:24:53 +0200 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#include <X11/Xlib.h>
#import <AppKit/AppKit.h>
#import "MessageController.h"
#import "ConsoleController.h"

@interface AppController : NSObject
{
  NSTextField* panelTitle;
  NSTextField* panelInfo;
  NSProgressIndicator* panelProgress;
  NSPanel* panel;

  NSMutableArray* messages;

  BOOL launched;

  ConsoleController* consoleController;
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

- (void) showPanelWithTitle:(NSString*) title
                       info:(NSString*) info;
- (void) showModalPanelWithTitle:(NSString*) title
                            info:(NSString*) info;
- (void) showMessageWithTitle:(NSString*) title
                         info:(NSString*) info;
- (void) showMessageWithTitle:(NSString*) title
                         info:(NSString*) info
                       action:(NSString*) action;
- (void) hidePanelAfter:(NSTimeInterval) time;

- (void) showPrefPanel:(id)sender;
- (void) removeMessageController:(id) mctrl;

@end

#endif
