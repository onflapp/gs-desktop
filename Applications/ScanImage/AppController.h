/* 
   Project: ScanImage

   Author: Ondrej Florian,,,

   Created: 2024-04-03 22:31:47 +0200 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import "ListDevices.h"
#import "ScanImage.h"

@interface AppController : NSObject {
  ListDevices* listDevices;
  ScanImage* scanImage;

  NSImageView* imagePreview;
  NSBrowser* deviceList;
  NSButton* scanButton;
  NSWindow* panel;
  NSProgressIndicator* progress;
  NSPopUpButton* outputType;
  NSPopUpButton* outputRes;
  NSTextField* outputPath;
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

- (IBAction) showPrefPanel:(id)sender;
- (IBAction) showScanPanel:(id)sender;
- (IBAction) refreshDevices:(id)sender;
- (IBAction) selectDevice:(id)sender;
- (IBAction) scanImage:(id)sender;
- (IBAction) openImage:(id)sender;

@end

#endif
