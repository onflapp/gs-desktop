/* 
   Project: ImageViewer

   Author: Parallels

   Created: 2022-09-13 12:09:30 +0000 by parallels
   
   Application Controller
*/

#import "STScriptingSupport.h"
#import "AppController.h"
#import "InspectorPanel.h"
#import "Document.h"

@implementation AppController

+ (void) initialize {
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init {
  if ((self = [super init])) {
  }
  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (void) awakeFromNib {
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
  [NSApp registerServicesMenuSendTypes:[NSArray array] 
                           returnTypes:[NSArray arrayWithObject:NSTIFFPboardType]];

  if([NSApp isScriptingSupported])
  {
      [NSApp initializeApplicationScripting];
  }
}

- (BOOL) applicationShouldTerminate: (id)sender {
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif {
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName {

  Document* doc = [self documentForFile:fileName];
  [doc displayFile:fileName];
  [doc showWindow];
  return NO;
}

- (id) validRequestorForSendType:(NSString*) sendType
                      returnType:(NSString*) returnType {
  if ([returnType isEqualToString:NSTIFFPboardType]) {
    return self;
  }
  else {
    return nil;
  }
}

- (BOOL) readSelectionFromPasteboard:(NSPasteboard*) pboard {
  Document* doc = [[Document alloc]init];
  [doc showWindow];
  return [doc readFromPasteboard:pboard];
}

- (Document*) documentForFile:(NSString*) fileName {
  for (NSWindow* win in [NSApp windows]) {
    id del = [win delegate];
    if ([del isKindOfClass:[Document class]]) {
      if ([[del fileName]isEqualToString:fileName]) {
        return (Document*)del;
      }
    }
  }

  Document* doc = [[Document alloc] init];
  return doc;
}

- (void) newDocument:(id)sender {
  Document* doc = [[Document alloc] init];
  NSPasteboard* pboard = [NSPasteboard generalPasteboard];
  [doc readFromPasteboard:pboard];
  [doc showWindow];
}

- (void) cloneDocument:(id)sender {
  NSImage* img = [[[NSApp mainWindow] delegate] image];
  if (img) {
    Document* doc = [[Document alloc] init];
    [doc setImage:img];
    [doc showWindow];
  }
}

- (void) openDocument:(id)sender {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  if ([panel runModal]) {
    NSString* fileName = [panel filename];
    Document* doc = [self documentForFile:fileName];
    [doc displayFile:fileName];
    [doc showWindow];
  }
}

- (void) showPrefPanel: (id)sender {
}

- (void) showInspectorPanel: (id)sender {
  [[InspectorPanel sharedInstance] orderFrontInspectorPanel:sender];
}

@end
