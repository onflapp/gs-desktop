/* 
   Project: VolMon

   Author: Ondrej Florian,,,

   Created: 2022-10-21 09:49:06 +0200 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import <SoundKit/SoundKit.h>

@interface AppController : NSObject
{
  IBOutlet NSView* controlView;
  IBOutlet NSSlider* volumeSlider;
  IBOutlet NSButton* muteButton;
  IBOutlet NSButton* micMuteButton;

  NSTimeInterval lastChange;

  SNDServer	*soundServer;
  SNDOut	*soundOut;
  SNDIn		*soundIn;
}

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;

- (void) changeVolume: (id)sender;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName;

- (void) showPrefPanel: (id)sender;

@end

#endif
