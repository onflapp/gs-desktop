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

  NSButton* left3enabled;
  NSTextField* left3command;

  NSButton* right3enabled;
  NSTextField* right3command;

  NSButton* top3enabled;
  NSTextField* top3command;

  NSButton* bottom3enabled;
  NSTextField* bottom3command;
}

+ (void) initialize;

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;

- (void) syncPreferences:(id)sender;
- (void) showPreferences:(id)sender;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;

@end

#endif
