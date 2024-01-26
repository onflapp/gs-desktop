/* 
   Project: SystemManager

   Author: Ondrej Florian

   Created: 2024-01-19 23:40:24 +0100 by oflorian
   
   Application Controller
*/

#import "AppController.h"

@implementation AppController

+ (void) initialize {
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init {
  if ((self = [super init])) {
    systemWindow = [[SystemWindow alloc] init];
    consoleController = [[ConsoleController alloc] init];
  }
  return self;
}

- (void) dealloc {
  RELEASE(systemWindow);
  [super dealloc];
}

- (void) awakeFromNib {
}

- (void) applicationDidFinishLaunching:(NSNotification*)aNotif {
  if([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }
}

- (BOOL) applicationShouldTerminate:(id)sender {
  return YES;
}

- (void) applicationWillTerminate:(NSNotification*)aNotif {
}

- (BOOL) application:(NSApplication*)application
	    openFile:(NSString*)fileName {
  return NO;
}

- (void) editStartup: (id)sender {
  NSFileManager* fm = [NSFileManager defaultManager];
  NSWorkspace* ws = [NSWorkspace sharedWorkspace];

  if ([sender tag] == 1) {
    NSString* gsde_file = [@"~/.gsderc" stringByExpandingTildeInPath];

    if (![fm fileExistsAtPath:gsde_file]) {
      [@"# exec before UI\n" writeToFile:gsde_file atomically:NO];
    }
    [ws openFile:gsde_file withApplication:@"TextEdit"];
  }
  else if ([sender tag] == 2) {
    BOOL isdir = NO;
    NSString* start_dir = [@"~/Library/Startup" stringByExpandingTildeInPath];

    if (![fm fileExistsAtPath:start_dir isDirectory:&isdir]) {
      [fm createDirectoryAtPath:start_dir attributes:nil]; 
    }
    [ws selectFile:@"." inFileViewerRootedAtPath:start_dir];
  }
}

- (void) openDirectory:(id)sender {
  NSWorkspace* ws = [NSWorkspace sharedWorkspace];
 
  if ([sender tag] == 1) {
    NSString* dir = [[[NSBundle mainBundle] resourcePath] 
	    stringByAppendingPathComponent:@"Tasks"];

    [ws selectFile:@"." inFileViewerRootedAtPath:dir];
  }
  else if ([sender tag] == 2) {
    NSURL* url = [NSURL URLWithString:@"admin:///etc"];
    [ws openURL:url];
  }
}

- (void) control:(id)sender {
  NSWindow* panel = [consoleController  panel];
  NSString* exec = [[[[NSBundle mainBundle] resourcePath] 
    stringByAppendingPathComponent:@"commands"]
    stringByAppendingPathComponent:@"system_control"];

  NSString* type = nil;
  if ([sender tag] == 1) {
    type = @"shutdown";
  }
  if ([sender tag] == 2) {
    type = @"sleep";
  }
  if ([sender tag] == 3) {
    type = @"emergency";
  }
  if ([sender tag] == 4) {
    type = @"reboot";
  }

  if (type) {
    [self executeConsoleCommand:exec withArguments:[NSArray arrayWithObject:type]];
    [panel makeKeyAndOrderFront:self];
    [panel center];
  }
}

- (void) showSystemProcesses:(id)sender {
  [systemWindow showWindow];
  [systemWindow refresh:sender];
}

- (void) showSystemControl:(id)sender {
  [controlPanel center];
  [controlPanel makeKeyAndOrderFront:sender];
}

- (NSWindow*) executeConsoleCommand:(NSString*) exec withArguments:args{
  NSWindow* panel = [consoleController  panel];

  [consoleController execCommand:exec withArguments:args];
  [panel makeKeyAndOrderFront:self];
  [panel center];

  return panel;
}

- (void) showPrefPanel:(id)sender {
}

@end
