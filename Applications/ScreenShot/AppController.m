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
  [recordButton setHidden:YES];

  [[[NSApp iconWindow] contentView] addSubview:iconView];
  [iconView setFrame:NSMakeRect(8, 8, 48, 48)];
  [iconView setNeedsDisplay:YES];
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
  [task terminate];
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

- (void) execRecord:(NSInteger) type {
  if (task) {
    NSLog(@"task is running already");
    return;
  }

  if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/ffmpeg"]) {
    NSRunAlertPanel(@"ffmpeg command not found", @"ScreenShot app needs command '/usr/bin/ffmpeg' to work properly\nPlease install it and try again.", @"Ok", nil, nil);
    return;
  }

  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  NSInteger tm = (NSInteger)[limit timeIntervalSinceReferenceDate];

  NSMutableArray* args = [NSMutableArray array];
  screenshotFile = [NSString stringWithFormat:@"/tmp/%ld-screencapture.mp4", tm];
  [screenshotFile retain];

  if ([NSApp isActive]) {
    [NSApp hide:self];
  }
  
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
  NSString* t = @"selection";

  if (type == 1) {
    t = @"screen";
  }
  
  [args addObject:t];
  [args addObject:screenshotFile];

  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"capture"];

  NSLog(@"exec %@ [%@]", exec, args);

  task = [[NSTask alloc] init];
  [task setLaunchPath:exec];
  [task setArguments:args];
  //[task setCurrentDirectoryPath:wp];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkTaskStatus:) name:NSTaskDidTerminateNotification object:task];
  
  [recordButton setHidden:NO];
  [task launch];
}

- (void) execScrot:(NSInteger) type {
  if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/scrot"]) {
    NSRunAlertPanel(@"Scrot command not found", @"ScreenShot app needs command '/usr/bin/scrot' to work properly\nPlease install it and try again.", @"Ok", nil, nil);
    return;
  }

  if (task) {
    NSLog(@"task is running already");
    return;
  }

  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  NSInteger tm = (NSInteger)[limit timeIntervalSinceReferenceDate];

  NSMutableArray* args = [NSMutableArray array];
  screenshotFile = [NSString stringWithFormat:@"/tmp/%ld-screenshot.tiff", tm];
  [screenshotFile retain];

  if ([NSApp isActive]) {
    [NSApp hide:self];
  }
  
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
  NSString* t = @"selection";

  if (type == 1) {
    t = @"screen";
  }
  else if (type == 2) {
    t = @"window";
  }
  
  [args addObject:t];
  [args addObject:screenshotFile];

  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"takeshot"];
  task = [[NSTask alloc] init];
  [task setLaunchPath:exec];
  [task setArguments:args];
  //[task setCurrentDirectoryPath:wp];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkTaskStatus:) name:NSTaskDidTerminateNotification object:task];
  
  [task launch];
}

- (void) checkTaskStatus:(id) not {
  [recordButton setHidden:YES];
  [iconView setNeedsDisplay:YES];
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if ([[NSFileManager defaultManager] fileExistsAtPath:screenshotFile]) {
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    [ws openFile:screenshotFile];
  }

  [screenshotFile release];
  screenshotFile = nil;

  [task release];
  task = nil;
}

- (IBAction) takeScreenShot:(id) sender {
  [self execScrot:[sender tag]];
}

- (IBAction) recordScreen:(id) sender {
  [self execRecord:[sender tag]];
}

- (IBAction) stopRecording:(id) sender {
  [task interrupt];
}

- (IBAction) showPrefPanel: (id)sender {
}

@end
