/* 
   Project: RemoteView

   Author: Parallels

   Created: 2023-05-09 07:49:50 +0000 by parallels
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>

@interface AppController : NSObject
{
   NSTextField* connectionParA;
   NSTextField* connectionParB;
   NSSecureTextField* connectionParC;
   NSTextField* labelParA;
   NSTextField* labelParB;
   NSTextField* labelParC;
   NSPopUpButton* connectionType;
   NSPanel* connectionPanel;
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

@end

#endif
