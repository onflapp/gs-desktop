/* 
   Project: Player

   Author: Ondrej Florian,,,

   Created: 2022-10-29 23:12:00 +0200 by oflorian
   
   Application Controller
*/

#import "STScriptingSupport.h"
#import "AppController.h"
#import "MediaDocument.h"
#import "VideoDocument.h"

@implementation AppController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"reuse_window"];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init
{
  self = [super init];
  videoExtensions = [[NSArray arrayWithObjects:@"mp4", @"m4v", @"ogv", @"mkv", nil] retain];
  audioExtensions = [[NSArray arrayWithObjects:@"mp3", @"au", @"snd", @"pls", @"wav", nil] retain];

  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (NSArray*) documents
{
  NSMutableArray* ls = [NSMutableArray array];
  for (NSWindow* win in [NSApp windows]) {
    if ([[win delegate] isKindOfClass: [MediaDocument class]]) {
      [ls addObject:[win delegate]];
    }
  }
  return ls;
}

- (MediaDocument*) currentDocument 
{
  return [[self documents] firstObject];
}

- (void) awakeFromNib
{
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
  if([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }

  [[[NSApp iconWindow] contentView] addSubview:controlView];
  [controlView setFrame:NSMakeRect(8, 8, 48, 48)];
  [controlView setNeedsDisplay:YES];

  [self performSelector:@selector(checkStatus) withObject:nil afterDelay:0.5];
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (void) play:(id) sender {
  MediaDocument* doc = [self currentDocument];
  if (!doc) {
    [self openDocument:sender];
  }
  else if ([doc isPlaying]) {
    [controlPlayButton setIntValue:0];
    [doc stop];
  }
  else {
    [controlPlayButton setIntValue:1];
    [doc play];
  }
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
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"reuse_window"]) {
    [[[self currentDocument] window] close];
  }

  if ([videoExtensions containsObject:ext]) {
    VideoDocument* doc = [[VideoDocument alloc] init];
    [doc loadFile:fileName];
    [controlPlayButton setIntValue:1];
  }
  else if ([audioExtensions containsObject:ext]) {
    MediaDocument* doc = [[MediaDocument alloc] init];
    [doc loadFile:fileName];
    [controlPlayButton setIntValue:1];
  }
  else {
    [controlPlayButton setIntValue:0];
    NSLog(@"unable to open %@", fileName);
  }
  
  return NO;
}

- (void) checkStatus {
  if ([[self currentDocument] isPlaying] != (BOOL)[controlPlayButton intValue]) {
    [controlPlayButton setIntValue:(int)[[self currentDocument] isPlaying]];
  }
  [self performSelector:@selector(checkStatus) withObject:nil afterDelay:0.5];
}

- (void) showPrefPanel: (id)sender
{
}

@end
