/* 
Project: GestureHelper

Created: 2023-07-08 22:24:53 +0200 by oflorian

Application Controller
*/

#import "AppController.h"

@implementation NSApplication(Remote)
- (void) syncPreferences {
  [[NSApp delegate] syncPreferences:nil];
}

- (void) showPreferences {
  [[NSApp delegate] showPreferences:nil];
}
@end

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
  [touchController configsynclient];
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  [touchController stopTask];
  return YES;
}

- (BOOL) application:(NSApplication *)application
            openFile:(NSString *)fileName
{
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

  [defaults setBool:[left3enabled state] forKey:@"Left3Enabled"];
  [defaults setValue:[left3command stringValue] forKey:@"Left3Command"];

  [defaults setBool:[right3enabled state] forKey:@"Right3Enabled"];
  [defaults setValue:[right3command stringValue] forKey:@"Right3Command"];

  [defaults setBool:[top3enabled state] forKey:@"Top3Enabled"];
  [defaults setValue:[top3command stringValue] forKey:@"Top3Command"];

  [defaults setBool:[bottom3enabled state] forKey:@"Bottom3Enabled"];
  [defaults setValue:[bottom3command stringValue] forKey:@"Bottom3Command"];

  [touchController reconfigure];
}

- (void) syncPreferences:(id)sender
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];

  NSLog(@"reconfigure");
  [touchController reconfigure];
  [touchController configsynclient];
}

- (void) showPreferences:(id)sender 
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  [hold3enabled setState:[defaults boolForKey:@"Hold3Enabled"]];
  [hold3command setStringValue:[defaults valueForKey:@"Hold3Command"]];

  [left3enabled setState:[defaults boolForKey:@"Left3Enabled"]];
  [left3command setStringValue:[defaults valueForKey:@"Left3Command"]];

  [right3enabled setState:[defaults boolForKey:@"Right3Enabled"]];
  [right3command setStringValue:[defaults valueForKey:@"Right3Command"]];

  [top3enabled setState:[defaults boolForKey:@"Top3Enabled"]];
  [top3command setStringValue:[defaults valueForKey:@"Top3Command"]];

  [bottom3enabled setState:[defaults boolForKey:@"Bottom3Enabled"]];
  [bottom3command setStringValue:[defaults valueForKey:@"Bottom3Command"]];

  [panel makeKeyAndOrderFront:self];
}

@end
