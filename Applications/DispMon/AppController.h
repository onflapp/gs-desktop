/* 
   Project: VolMon

   Author: Ondrej Florian,,,

   Created: 2022-10-21 09:49:06 +0200 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>

#import <SystemKit/OSEScreen.h>
#import <SystemKit/OSEDisplay.h>

@interface AppController : NSObject
{
  IBOutlet NSView* controlView;
  IBOutlet NSSlider* brightnessSlider;

  NSTimeInterval lastChange;

  OSEScreen  *systemScreen;
}

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;

- (void) changeBrightness: (id)sender;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName;

- (void) showPrefPanel: (id)sender;

@end

#endif
