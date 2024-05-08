/* 
Project: GestureHelper

Created: 2023-07-08 22:24:53 +0200 by oflorian

Application Controller
*/

#import "AppController.h"

@implementation AppController
+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init
{
  if ((self = [super init])) {
    touchController = [[TouchController alloc] init];
  }
  return self;
}

- (void) dealloc
{
  [touchController release];
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
  [touchController execTask];
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  [touchController stopTask];
  return YES;
}

- (BOOL) application:(NSApplication *)application
            openFile:(NSString *)fileName
{
  if ([fileName isEqualToString:@"-configure"]) {
    NSLog(@"configure");
    [self showPreferences: self];
  }
  else if ([fileName isEqualToString:@"-reconfigure"]) {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];

    NSLog(@"reconfigure");
    [touchController reconfigure];
  }
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (void) windowWillClose: (NSNotification *)aNotif
{
  [NSApp deactivate];
}

- (void) changeConfig:(id)sender
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  [defaults setBool:[hold3enabled state] forKey:@"Hold3Enabled"];
  [defaults setValue:[hold3command stringValue] forKey:@"Hold3Command"];

  [touchController reconfigure];
}

- (void) showPreferences:(id)sender 
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  [hold3enabled setState:[defaults boolForKey:@"Hold3Enabled"]];
  [hold3command setStringValue:[defaults valueForKey:@"Hold3Command"]];

  [panel makeKeyAndOrderFront:self];
}

@end
