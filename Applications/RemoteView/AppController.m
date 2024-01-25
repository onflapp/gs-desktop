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
  [connectionParA setStringValue:[cfg valueForKey:@"last_hostname"]];

  [self changeConnectionType:nil];
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (void)openURL:(NSPasteboard *)pboard
       userData:(NSString *)userData
          error:(NSString **)error  {
  NSString *path = [[pboard stringForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];

  if (path) {
    [self application:NSApp openFile:path];
  }
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName
{
  NSURL* url = [NSURL URLWithString:fileName];
  [self application:application openURL:url];
  return YES;
}


- (BOOL) application: (NSApplication *)application
	    openURL: (NSURL *)url
{
  if ([[url scheme] isEqualToString:@"vnc"]) {
    VNCDisplay* display = [[VNCDisplay alloc] init];
    [display showWindow];
    [display connect:url];
  }
  else if (url) {
    [self openTermWithURL:url];
  }
  return YES;
}

- (void) openTermWithURL:(NSURL*) url {
  NSString* wp = [[NSBundle mainBundle] resourcePath];
  NSString* exec = [wp stringByAppendingPathComponent:@"connect"];
  NSMutableArray* args = [NSMutableArray array];
  [args addObject:[url description]];

  NSLog(@"exec %@ args %@", exec, args);

  NSTask* task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:exec];
  [task setArguments:args];
  [task setCurrentDirectoryPath:wp];
  
  [task launch];
}

- (void) newDisplay: (id)sender {
  [connectionPanel makeKeyAndOrderFront:sender];
}

- (void) changeConnectionType: (id)sender {
  NSInteger t = [[connectionType selectedItem]tag];
  if (t == 1 || t == 2) {
    [labelParA setStringValue:@"Hostname:"];
    [labelParB setStringValue:@"User:"];
  }
  else if (t == 3) {
    [labelParA setStringValue:@"/dev/"];
    [labelParB setStringValue:@"Speed:"];
  }
  else {
    [labelParA setStringValue:@"Hostname:"];
    [labelParB setStringValue:@"Password:"];
  }
}

- (void) connectDisplay: (id)sender {
  NSString* host = [connectionParA stringValue];
  NSInteger type = [[connectionType selectedItem]tag];

  if (![host length]) return;

  if (type == 0) {
    NSURL* url = [NSURL URLWithString:host];
    if (![url host]) {
      url = [NSURL URLWithString:[NSString stringWithFormat:@"vnc://%@", host]];
    }

    NSUserDefaults* cfg = [NSUserDefaults standardUserDefaults];
    [cfg setValue:host forKey:@"last_hostname"];

    VNCDisplay* display = [[VNCDisplay alloc] init];
    [display showWindow];
    [display connect:url];
  }
  else {
    NSString* p = @"unknown";
    NSString* u = [connectionParB stringValue];
    if (u == nil) u = @"";

    if (type == 1) p = @"ssh";
    if (type == 2) p = @"telnet";
    if (type == 3) p = @"uart";

    NSLog(@"connect to %@", p);

    NSURL* url = [NSURL URLWithString:host];
    if (![url host]) {
      url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", p, u, host]];
    }
    if (url) {
      [self openTermWithURL:url];
    }
  }

  [connectionPanel orderOut:sender];
}

- (void) showPrefPanel: (id)sender
{
}

@end
