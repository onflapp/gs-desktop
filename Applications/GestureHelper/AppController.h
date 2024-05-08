/* 
   Project: GestureHelper

   Created: 2023-07-08 22:24:53 +0200 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import "TouchController.h"

@interface AppController : NSObject
{
  TouchController* touchController;
  NSPanel* panel;

  NSButton* hold3enabled;
  NSTextField* hold3command;
}

+ (void) initialize;

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;

@end

#endif
