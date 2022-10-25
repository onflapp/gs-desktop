/* 
   Project: Librarian

   Author: Ondrej Florian,,,

   Created: 2022-09-16 09:53:08 +0200 by oflorian
   
   Application Controller
*/

#import "AppController.h"
#import "Document.h"

@implementation AppController

+ (void) initialize {
  NSMutableDictionary* defaults = [NSMutableDictionary dictionary];

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
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

- (void) applicationDidFinishLaunching:(NSNotification *) aNotif {
}

- (BOOL) applicationShouldTerminate:(id) sender {
  return YES;
}

- (void) applicationWillTerminate:(NSNotification*) aNotif {
}

- (BOOL) application:(NSApplication* )application
	    openFile:(NSString*) fileName {

  Document* doc = [[Document alloc] init];
   [doc openFile: fileName];
  return YES;
}

- (void) newDocument:(id) sender {
  Document* doc = [[Document alloc] init];
}

- (void) openDocument: (id)sender {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  [panel setAllowsMultipleSelection: NO];
  [panel setCanChooseDirectories: NO];

  if ([panel runModalForTypes:[NSArray arrayWithObject:@"books"]] == NSOKButton) {
    NSString* fileName = [[panel filenames] firstObject];
    Document* doc = [[Document alloc] init];
    [doc openFile: fileName];
  }
}

- (void) showPrefPanel:(id) sender {
}

@end
