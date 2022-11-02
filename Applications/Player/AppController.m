/* 
   Project: Player

   Author: Ondrej Florian,,,

   Created: 2022-10-29 23:12:00 +0200 by oflorian
   
   Application Controller
*/

#import "AppController.h"
#import "MediaDocument.h"

@implementation AppController

+ (void) initialize
{
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

- (id) init
{
  if ((self = [super init])) {
  }
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (void) openDocument: (id)sender {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  [panel setAllowsMultipleSelection: NO];
  [panel setCanChooseDirectories: NO];

  if ([panel runModalForTypes:nil] == NSOKButton) {
    NSString* fileName = [[panel filenames] firstObject];
    [self application:NSApp openFile:fileName];
  }
}

- (BOOL) application: (NSApplication *)application
            openFile: (NSString *)fileName {

  MediaDocument* doc = [[MediaDocument alloc] init];
  [doc loadFile:fileName];
  
  return NO;
}


- (void) showPrefPanel: (id)sender
{
}

@end
