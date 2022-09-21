/* 
   Project: ScreenShot

   Author: Parallels

   Created: 2022-09-13 13:11:46 +0000 by parallels
   
   Application Controller
*/

#import "AppController.h"

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

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif {
}

- (BOOL) applicationShouldTerminate: (id)sender {
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif {
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName {
  return NO;
}

- (void) execScrot:(NSInteger) type {
  NSMutableArray* args = [NSMutableArray array];
  NSString* file = @"/tmp/screenshot.png";
  [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
  [NSApp hide:self];
  
  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
  
  if (type == 1) {
    [args addObject:@"--delay"];
    [args addObject:@"1"];
  }
  else if (type == 2) {
    [args addObject:@"--delay"];
    [args addObject:@"1"];
    [args addObject:@"--focused"];
  }
  else {
    [args addObject:@"-b"];
    [args addObject:@"--select"];
  }
  [args addObject:file];
  
  NSTask* task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:@"/usr/bin/scrot"];
  [task setArguments:args];
  //[task setCurrentDirectoryPath:wp];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkTaskStatus:) name:NSTaskDidTerminateNotification object:task];
  
  [task launch];
}

- (void) checkTaskStatus:(id) not {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  NSString* file = @"/tmp/screenshot.png";
  if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    [ws openFile:file];
  }
}

- (IBAction) takeScreenShot:(id) sender {
  if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/scrot"]) {
    NSRunAlertPanel(@"Scrot command not found", @"ScreenShot app needs command '/usr/bin/scrot' to work properly\nPlease install it and try again.", @"Ok", nil, nil);
    return;
  }

  [self execScrot:[sender tag]];
}

- (IBAction) showPrefPanel: (id)sender {
}

@end
