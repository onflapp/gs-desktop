/* 
   Project: Player

   Author: Ondrej Florian,,,

   Created: 2022-10-29 23:12:00 +0200 by oflorian
   
   Application Controller
*/

#import "AppController.h"
#import "MediaDocument.h"
#import "VideoDocument.h"

@implementation AppController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init
{
  self = [super init];
  videoExtensions = [[NSArray arrayWithObjects:@"mp4", @"m4v", @"ogv", nil] retain];
  audioExtensions = [[NSArray arrayWithObjects:@"mp3", @"au", @"snd", nil] retain];

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

  NSString* ext = [fileName pathExtension];
  if ([videoExtensions containsObject:ext]) {
    VideoDocument* doc = [[VideoDocument alloc] init];
    [doc loadFile:fileName];
  }
  else {
    MediaDocument* doc = [[MediaDocument alloc] init];
    [doc loadFile:fileName];
  }
  
  return NO;
}


- (void) showPrefPanel: (id)sender
{
}

@end
