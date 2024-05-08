/* 
Project: NotMon

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
    messages = [[NSMutableArray alloc] init];
    consoleController = [[ConsoleController alloc] init];
  }
  return self;
}

- (void) dealloc
{
  [consoleController release];
  [messages release];
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
    else if ([[url host] isEqualToString:@"show-modal-panel"]) {
      NSDictionary* dict = [self parseURL:url];
      NSString* title = [dict valueForKey:@"title"];
      NSString* info = [dict valueForKey:@"info"];
      NSLog(@"show:%@", dict);

      [self showModalPanelWithTitle:title info:info];
    }
    else if ([[url host] isEqualToString:@"hide-panel"]) {
      NSLog(@"hide");
      [self hidePanelAfter:0];
    }
    else if ([[url host] isEqualToString:@"show-message"]) {
      NSDictionary* dict = [self parseURL:url];
      NSString* title = [dict valueForKey:@"title"];
      NSString* info = [dict valueForKey:@"info"];
      NSLog(@"show:%@", dict);

      [self showMessageWithTitle:title info:info];
    }
    else if ([[url host] isEqualToString:@"show-console"]) {
      NSDictionary* dict = [self parseURL:url];
      NSString* cmd = [dict valueForKey:@"cmd"];
      NSString* arg = [dict valueForKey:@"arg"];
      NSLog(@"console:%@", dict);

      [self showConsoleWithCommand:cmd argument:arg];
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

- (void) showConsoleWithCommand:(NSString*) exec
                       argument:(NSString*) arg
{
  NSWindow* cpanel = [consoleController panel];
  [cpanel setLevel:NSDockWindowLevel];
  [cpanel makeKeyAndOrderFront:self];

  [consoleController execCommand:exec argument:arg];
}

- (void) showMessageWithTitle:(NSString*) title
                         info:(NSString*) info
{
  MessageController* ctrl = [[MessageController alloc] init];
  NSPanel* mpanel = [ctrl panel];

  [mpanel setLevel:NSDockWindowLevel];

  [[ctrl panelTitle] setStringValue:title?title:@""];
  [[ctrl panelInfo] setStringValue:info?info:@""];

  [messages addObject:ctrl];
  [self reoderMessages];
}

- (void) showPanelWithTitle:(NSString*) title 
                       info:(NSString*) info
{
  [panelTitle setStringValue:title?title:@""];
  [panelInfo setStringValue:info?info:@""];
  [panelProgress animate:self];

  [panel setBecomesKeyOnlyIfNeeded:YES];
  [panel setLevel:NSDockWindowLevel];
  [panel center];
  [panel orderFront:self];

  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(__hidePanel) withObject:nil afterDelay:5.0];
}

- (void) showModalPanelWithTitle:(NSString*) title 
                            info:(NSString*) info
{
  [panelTitle setStringValue:title?title:@""];
  [panelInfo setStringValue:info?info:@""];
  [panelProgress animate:self];

  [panel setBecomesKeyOnlyIfNeeded:NO];
  [panel setLevel:NSDockWindowLevel];
  [panel center];
  [panel orderFront:self];

  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(__hidePanel) withObject:nil afterDelay:5.0];

  [self _grabEvents];
}

- (void) reoderMessages {
  NSScreen* screen = [NSScreen mainScreen];
  NSRect sr = [screen visibleFrame];
  CGFloat margin = 8;
  CGFloat height = 0;
  NSInteger c = 1;

  for (MessageController* ctrl in messages) {
    NSPanel* mpanel = [ctrl panel];
    NSRect pr = [mpanel frame];

    height = pr.size.height;
    pr.origin.x = sr.size.width - 64 - margin - pr.size.width;
    pr.origin.y = sr.size.height - ((height + 2) * c);
    
    [mpanel setFrame:pr display:NO];
    [mpanel orderFront:self];
    c++;
  }
}

- (void) removeMessageController:(id) mctrl {
  [messages removeObject:mctrl];
  [self reoderMessages];
}

- (void) _grabEvents {
  Window win = (Window)[panel windowRef];
  Display* dpy = XOpenDisplay(NULL);
  XGrabPointer(dpy, win, False,
		     PointerMotionMask | ButtonReleaseMask | ButtonPressMask,
		     GrabModeAsync, GrabModeAsync, win, None, CurrentTime);
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
