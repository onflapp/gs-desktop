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
  if([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }

  [NSApp setServicesProvider:self];
}

- (BOOL) applicationShouldTerminate:(id) sender {
  return YES;
}

- (void) applicationWillTerminate:(NSNotification*) aNotif {
}

- (BOOL) application:(NSApplication* )application
	    openFile:(NSString*) fileName {

  Document* doc = [self documentForFile:fileName];
  [doc showWindow];
  [doc list:self];
  return YES;
}

- (void) searchSelectionService:(NSPasteboard *)pboard
                       userData:(NSString *)userData
                          error:(NSString **)error {
  NSString *text = [[pboard stringForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];
  NSString* defbook = [[NSUserDefaults standardUserDefaults] valueForKey:@"DEFAULT_BOOK"];

  if ([text length] > 0 && defbook) {
    [NSApp activateIgnoringOtherApps:YES];
    [self performSelector:@selector(searchText:) withObject:text afterDelay:0.3];
  }
}

- (void) searchText:(NSString*) text {
  NSString* defbook = [[NSUserDefaults standardUserDefaults] valueForKey:@"DEFAULT_BOOK"];
  [self searchText:text inLibrary:defbook];
}

- (void) searchText:(NSString*) text inLibrary:(NSString*) file {
  Document* doc = [self documentForFile:file];
  [doc showWindow];
  [doc searchText:text];
}

- (Document*) currentDocument {
  return [Document lastActiveDocument];
}

- (Document*) documentForFile:(NSString*) fileName {
  Document* doc = nil;

  for (NSWindow* win in [NSApp windows]) {
    if ([[win delegate] isKindOfClass:[Document class]]) {
      doc = (Document*) [win delegate];
      if ([[doc fileName] isEqualToString: fileName]) {
        return doc;
      }
    }
  }

  doc = [[Document alloc] init];
  [doc openFile: fileName];
  return doc;
}

- (void) newDocument:(id) sender {
  Document* doc = [[Document alloc] init];
  [doc showWindow];
}

- (void) openDocument: (id)sender {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  [panel setAllowsMultipleSelection: NO];
  [panel setCanChooseDirectories: NO];

  if ([panel runModalForTypes:[NSArray arrayWithObject:@"books"]] == NSOKButton) {
    NSString* fileName = [[panel filenames] firstObject];
    Document* doc = [self documentForFile:fileName];
    [doc showWindow];
    [doc list:self];
  }
}

- (void) showPrefPanel:(id) sender {
  NSInteger t = [[[NSUserDefaults standardUserDefaults] valueForKey:@"hide_on_deactivate"] integerValue];
  [prefsHideOnDeactivate setState:t];

  NSString* s = [[NSUserDefaults standardUserDefaults] valueForKey:@"DEFAULT_BOOK"];
  [prefsDefaultBook setStringValue:s];

  [prefsWindow makeKeyAndOrderFront:sender];
}

- (void) changePrefs: (id)sender {
  if (sender == prefsHideOnDeactivate) {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:[sender state]] forKey:@"hide_on_deactivate"];
  }
  if (sender == prefsDefaultBook) {
    [[NSUserDefaults standardUserDefaults] setValue:[sender stringValue] forKey:@"hide_on_deactivate"];
  }
}
@end
