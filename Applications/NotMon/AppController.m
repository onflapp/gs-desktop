/* 
Project: NotMon

Author: Ondrej Florian,,,

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
  }
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) awakeFromNib
{
  [panelProgress setUsesThreadedAnimation:YES];
  [panel setBecomesKeyOnlyIfNeeded:YES];
}

- (NSDictionary*) parseURL:(NSURL*) url 
{
  NSMutableDictionary* dict = [NSMutableDictionary dictionary];
  NSArray* ls = [[url query]componentsSeparatedByString:@"&"];

  for (NSString* it in ls) {
    NSRange r = [it rangeOfString:@"="];
    if (r.location != NSNotFound) {
      NSString* name = [it substringToIndex:r.location];
      NSString* value = [it substringFromIndex:r.location+1];
      [dict setValue:value forKey:name];
    }
  }

  return dict;
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
  launched = YES;
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  if (!launched) {
    id url = [[[NSProcessInfo processInfo] arguments] lastObject];
    id app = [NSConnection rootProxyForConnectionWithRegisteredName:@"NotMon" host:@""];

    if (url && app) {
      [app application:nil openFile:url];
    }
  }
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (BOOL) application:(NSApplication *)application
            openFile:(NSString *)fileName
{
  if ([fileName hasPrefix:@"notmon:"]) {
    NSURL* url = [NSURL URLWithString:fileName];
    if (!url) {
      NSLog(@"unable to parse URL [%@]", fileName);
      return YES;
    }

    if ([[url host] isEqualToString:@"show-panel"]) {
      NSDictionary* dict = [self parseURL:url];
      NSString* title = [dict valueForKey:@"title"];
      NSString* info = [dict valueForKey:@"info"];
      NSLog(@"show:%@", dict);
      [self showPanelWithTitle:title info:info];
    }
    else if ([[url host] isEqualToString:@"hide-panel"]) {
      NSLog(@"hide");
      [self hidePanelAfter:0];
    }
  }

  return NO;
}

- (void)openURL:(NSPasteboard *)pboard
       userData:(NSString *)userData
          error:(NSString **)error  {
  NSString *path = [[pboard stringForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];

  if (path) {
    [self application:NSApp openFile:path];
  }
}


- (void) showPanelWithTitle:(NSString*) title 
                       info:(NSString*) info
{
  [panelTitle setStringValue:title?title:@""];
  [panelInfo setStringValue:info?info:@""];
  [panelProgress animate:self];

  [panel setLevel:NSDockWindowLevel];
  [panel center];
  [panel orderFront:self];

  [self performSelector:@selector(__hidePanel) withObject:nil afterDelay:5.0];
}

- (void) __hidePanel {
  [panel orderOut:self];
}

- (void) hidePanelAfter:(NSTimeInterval) time
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  if (time == 0.0) {
    NSLog(@"hide panel now");
    [self __hidePanel];
  }
  else {
    NSLog(@"hide panel after %f", time);
    [self performSelector:@selector(__hidePanel) withObject:nil afterDelay:time];
  }
}

- (void) showPrefPanel:(id)sender
{
}

@end
