/* 
   Project: ScreenShot

   Author: Parallels

   Created: 2022-09-13 13:11:46 +0000 by parallels
   
   Application Controller
*/

#import "AppController.h"
#import "STScriptingSupport.h"

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
  if([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }

  /*
  [NSApp setServicesProvider:self];
  [NSApp registerServicesMenuSendTypes:[NSArray array] 
                           returnTypes:[NSArray arrayWithObject:NSTIFFPboardType]];
  */
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

- (void) grabScreenShot: (NSPasteboard *) pboard
               userData: (NSString *) userData
                  error: (NSString **) error
{
  *error = @"doesn't work yet";
}

- (void) execScrot:(NSInteger) type {
  if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/scrot"]) {
    NSRunAlertPanel(@"Scrot command not found", @"ScreenShot app needs command '/usr/bin/scrot' to work properly\nPlease install it and try again.", @"Ok", nil, nil);
    return;
  }

  [screenshotFile release];

  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  NSInteger tm = (NSInteger)[limit timeIntervalSinceReferenceDate];

  NSMutableArray* args = [NSMutableArray array];
  screenshotFile = [NSString stringWithFormat:@"/tmp/%ld-screenshot.tiff", tm];
  [screenshotFile retain];

  if ([NSApp isActive]) {
    [NSApp hide:self];
  }
  
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
  
  if (type == 1) { //screen
    [args addObject:@"--delay"];
    [args addObject:@"1"];
  }
  else if (type == 2) { //window
    [args addObject:@"--delay"];
    [args addObject:@"1"];
    [args addObject:@"-b"];
    [args addObject:@"--focused"];
  }
  else {
    [args addObject:@"-b"]; //selection
    [args addObject:@"--select"];
  }
  [args addObject:screenshotFile];
  
  NSTask* task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:@"/usr/bin/scrot"];
  [task setArguments:args];
  //[task setCurrentDirectoryPath:wp];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkTaskStatus:) name:NSTaskDidTerminateNotification object:task];
  
  [task launch];
}

- (void) checkTaskStatus:(id) not {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if ([[NSFileManager defaultManager] fileExistsAtPath:screenshotFile]) {
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    [ws openFile:screenshotFile];
  }
}

- (IBAction) takeScreenShot:(id) sender {
  [self execScrot:[sender tag]];
}

- (IBAction) showPrefPanel: (id)sender {
}

@end
