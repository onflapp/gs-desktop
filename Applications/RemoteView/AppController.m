/* 
   Project: RemoteView

   Author: Parallels

   Created: 2023-05-09 07:49:50 +0000 by parallels
   
   Application Controller
*/

#import "AppController.h"
#import "VNCDisplay.h"

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

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif {
  NSUserDefaults* cfg = [NSUserDefaults standardUserDefaults];
  [connectionHostname setStringValue:[cfg valueForKey:@"last_hostname"]];
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName
{
  NSURL* url = [NSURL URLWithString:fileName];
  if (url) {
    VNCDisplay* display = [[VNCDisplay alloc] init];
    [display showWindow];
    [display connect:url];
  }
  return YES;
}

- (void) newDisplay: (id)sender {
  [connectionPanel makeKeyAndOrderFront:sender];
}
- (void) connectDisplay: (id)sender {
  NSString* host = [connectionHostname stringValue];
  if (![host length]) return;
  
  NSURL* url = [NSURL URLWithString:host];
  if (![url host]) {
    url = [NSURL URLWithString:[NSString stringWithFormat:@"vnc://%@", host]];
  }

  NSUserDefaults* cfg = [NSUserDefaults standardUserDefaults];
  [cfg setValue:host forKey:@"last_hostname"];

  VNCDisplay* display = [[VNCDisplay alloc] init];
  [display showWindow];
  [display connect:url];

  [connectionPanel orderOut:sender];
}

- (void) showPrefPanel: (id)sender
{
}

@end
