/* 
Project: NotMon

Created: 2023-07-08 22:24:53 +0200 by oflorian

Application Controller
*/

#import "AppController.h"
#include <GNUstepGUI/GSDisplayServer.h>

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

- (void) applicationDidBecomeActive: (NSNotification *)aNotif
{
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
      NSTimeInterval delay = (NSTimeInterval)[[dict valueForKey:@"delay"] integerValue];
      if (delay <= 0) delay = 5;
      NSLog(@"show:%@", dict);

      [self showPanelWithTitle:title info:info];
    }
    else if ([[url host] isEqualToString:@"show-modal-panel"]) {
      NSDictionary* dict = [self parseURL:url];
      NSString* title = [dict valueForKey:@"title"];
      NSString* info = [dict valueForKey:@"info"];
      NSTimeInterval delay = (NSTimeInterval)[[dict valueForKey:@"delay"] integerValue];
      if (delay <= 0) delay = 5;
      NSLog(@"show:%@", dict);

      [self showModalPanelWithTitle:title info:info delay:delay];
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

  //ugly hack to force terminal to resize (confused by missing titlebar?)
  NSRect r = [cpanel frame];
  r.size.height = r.size.height - 1;
  [cpanel setFrame:r display:YES];

  r.size.height = r.size.height + 1;
  [cpanel setFrame:r display:YES];

  [consoleController execCommand:exec argument:arg];
}

- (void) showMessageWithTitle:(NSString*) title
                         info:(NSString*) info
{
  [self showMessageWithTitle:title info:info action:nil];
}

- (void) showMessageWithTitle:(NSString*) title
                         info:(NSString*) info
                       action:(NSString*) action
{
  MessageController* ctrl = [[MessageController alloc] init];
  NSPanel* mpanel = [ctrl panel];

  [mpanel setLevel:NSDockWindowLevel];
  [mpanel setBecomesKeyOnlyIfNeeded:YES];

  [[ctrl panelTitle] setStringValue:title?title:@""];
  [[ctrl panelInfo] setStringValue:info?info:@""];

  if (action) {
    [ctrl setActionCommand:action];
  }

  [messages addObject:ctrl];
  [self reoderMessages:nil];
}

- (void) showPanelWithTitle:(NSString*) title 
                       info:(NSString*) info
{
  [self showPanelWithTitle:title info:info delay:5];
}

- (void) showPanelWithTitle:(NSString*) title 
                       info:(NSString*) info
                      delay:(NSTimeInterval) delay
{
  [panelTitle setStringValue:title?title:@""];
  [panelInfo setStringValue:info?info:@""];
  [panelProgress animate:self];

  [panel setBecomesKeyOnlyIfNeeded:YES];
  [panel setLevel:NSDockWindowLevel];
  [panel center];
  [panel orderFront:self];

  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(__hidePanel) withObject:nil afterDelay:delay];
}

- (void) showModalPanelWithTitle:(NSString*) title 
                            info:(NSString*) info
{
  [self showModalPanelWithTitle:title info:info delay:5];
}

- (void) showModalPanelWithTitle:(NSString*) title 
                            info:(NSString*) info
                           delay:(NSTimeInterval) delay
{
  [panelTitle setStringValue:title?title:@""];
  [panelInfo setStringValue:info?info:@""];
  [panelProgress animate:self];

  [panel setBecomesKeyOnlyIfNeeded:NO];
  [panel setLevel:NSDockWindowLevel];
  [panel center];
  [panel makeKeyAndOrderFront:self];

  if (delay <= 0) delay = 5;

  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(__hidePanel) withObject:nil afterDelay:delay];
  [self performSelector:@selector(_grabEvents) withObject:nil afterDelay:0.5];
}

- (void) reoderMessages:(id)val {
  NSScreen* screen = [NSScreen mainScreen];
  NSRect sr = [screen visibleFrame];
  CGFloat margin = 8;
  CGFloat height = 0;
  NSInteger c = 1;

  for (MessageController* ctrl in messages) {
    NSPanel* mpanel = [ctrl panel];
    NSRect pr = [mpanel frame];

    [mpanel orderFront:self];

    height = pr.size.height;
    pr.origin.x = sr.size.width - 64 - margin - pr.size.width;
    pr.origin.y = sr.size.height - (height * c);

    if ([val integerValue] == 1) {
      pr.size.width = pr.size.width + 1;
    }

    [mpanel setFrame:pr display:YES];

    c++;
  }

  if (val == nil) {
    [self performSelector:@selector(reoderMessages:) 
               withObject:[NSNumber numberWithInteger:1]
               afterDelay:0.0];
  }
}

- (void) removeMessageController:(id) mctrl {
  [messages removeObject:mctrl];
  [self reoderMessages:nil];
}

- (void) _grabEvents {
  Window win = (Window)[panel windowRef];
  GSDisplayServer *server = GSCurrentServer();
  Display *dpy = (Display *)[server serverDevice];

  int status = XGrabPointer(dpy, win, True,
		     PointerMotionMask | ButtonReleaseMask | ButtonPressMask,
		     GrabModeAsync, GrabModeAsync, win, None, CurrentTime);

  XFlush(dpy);
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
