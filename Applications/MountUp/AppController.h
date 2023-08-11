/* 
   Project: MountUp

   Author: Ondrej Florian,,,

   Created: 2023-08-09 19:25:27 +0000 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import <DBusKit/DBusKit.h>

@interface AppController : NSObject
{
  IBOutlet NSView* controlView;
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
