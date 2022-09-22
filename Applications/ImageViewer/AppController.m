/* 
   Project: ImageViewer

   Author: Parallels

   Created: 2022-09-13 12:09:30 +0000 by parallels
   
   Application Controller
*/

#import "STScriptingSupport.h"
#import "AppController.h"
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

- (NSString*) test {
  return @"hello";
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
  if([NSApp isScriptingSupported])
  {
      [NSApp initializeApplicationScripting];
      [scriptMenu setSubmenu: [NSApp scriptingMenu]];
  }
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName {
  Document* doc = [[Document alloc] init];
  [doc displayFile:fileName];
  return NO;
}

- (void) newDocument:(id)sender {
  Document* doc = [[Document alloc] init];
  [doc readFromPasteboard];
}

- (void) openDocument:(id)sender {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  if ([panel runModal]) {
    Document* doc = [[Document alloc] init];
    [doc displayFile:[panel filename]];
  }
}

- (void) showPrefPanel: (id)sender {
}

@end
