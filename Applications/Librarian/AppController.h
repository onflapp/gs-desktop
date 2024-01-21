/* 
   Project: Librarian

   Author: Ondrej Florian,,,

   Created: 2022-09-16 09:53:08 +0200 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import "Document.h"

@interface AppController : NSObject
{
  NSWindow* prefsWindow;
  NSButton* prefsHideOnDeactivate;
  NSTextField* prefsDefaultBook;
}

+ (void)  initialize;

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;

- (Document*) documentForFile:(NSString*) fileName;

- (void) searchText:(NSString*) text;
- (void) searchText:(NSString*) text inLibrary:(NSString*) file;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName;

- (void) showPrefPanel: (id)sender;
- (void) changePrefs: (id)sender;

@end

#endif
