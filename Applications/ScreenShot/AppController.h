/* 
   Project: ScreenShot

   Author: Parallels

   Created: 2022-09-13 13:11:46 +0000 by parallels
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>

@interface AppController : NSObject {
  NSString* screenshotFile;
  NSTask* task;
  NSInteger status;

  IBOutlet NSButton* recordButton;
  IBOutlet NSView* iconView;
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

- (IBAction) showPrefPanel:(id) sender;
- (IBAction) takeScreenShot:(id) sender;
- (IBAction) recordScreen:(id) sender;
- (IBAction) stopRecording:(id) sender;

- (void) execScrot:(NSInteger) type;
- (void) execRecord:(NSInteger) type;

@end

#endif
