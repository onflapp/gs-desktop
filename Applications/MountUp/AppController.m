/* 
   Project: MountUp

   Created: 2023-08-09 19:25:27 +0000 by oflorian
   
   Application Controller
*/

#import "AppController.h"
#import "MiniView.h"

@implementation AppController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init {
  if ((self = [super init])) {
     MiniView *mv = [[MiniView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    [[NSApp iconWindow] setContentView:mv];
  }
  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (void) awakeFromNib {
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif {
  [[[NSApp iconWindow] contentView] addSubview:controlView];
  [controlView setFrame:NSMakeRect(8, 8, 48, 48)];
  [controlView setNeedsDisplay:YES];
  
  DKNotificationCenter *center = [DKNotificationCenter systemBusCenter];
  
  [center addObserver: self
             selector: @selector(didReceiveBusNotification:)
                 name: @"DKSignal_org.freedesktop.DBus.ObjectManager_InterfacesAdded"
               object: nil];
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

- (void) didReceiveBusNotification:(NSNotification*) val {
  NSLog(@"notification:%@", val);
}

- (void) showPrefPanel: (id)sender {
}

@end
