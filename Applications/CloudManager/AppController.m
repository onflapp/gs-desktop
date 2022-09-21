/* 
   Project: CloudManager

   Author: Ondrej Florian,,,

   Created: 2022-09-15 23:45:03 +0200 by oflorian
   
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
     serviceManager = [[ServiceManager alloc] init];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceStatusHasChanged:) name:@"serviceStatusHasChanged" object:nil];
  }
  return self;
}

- (void) dealloc {
   [serviceManager release];
   [super dealloc];
}

- (void) awakeFromNib {
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif {
   [self refreshServiceListView];
}

- (void) applicationDidBecomeActive:(NSNotification*) not {
  if (launched) [self showPrefPanel:nil];
  launched = YES;
}

- (BOOL) applicationShouldTerminate: (id)sender {
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif {
  NSLog(@"terminating all services");
  for (ServiceTask* task in [serviceManager listServices]) {
    [task stopTask];
  }
  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName {
  return NO;
}

- (void) refreshServiceListView {
   NSButtonCell* cell = AUTORELEASE([NSButtonCell new]);
   [cell setButtonType:NSPushOnPushOffButton];
   [cell setImagePosition:NSImageOverlaps];

   NSInteger row = 0;
   //[serviceListView setCellSize:NSMakeSize(64,64)];
   [serviceListView setPrototype:cell];
   [serviceListView setMode:NSRadioModeMatrix];

   for (ServiceTask* task in [serviceManager listServices]) {
      [serviceListView addRow];
      NSCell* cell = [serviceListView cellAtRow:row column:0];
      [cell setRefusesFirstResponder:YES];
      [cell setTitle:[task name]];
      row++;
   }
   
   [serviceListView setAllowsEmptySelection:YES];
   [serviceListView setTarget:self];
   [serviceListView setAction: @selector(showServiceInfo:)];
}

- (IBAction) showServiceInfo:(id) sender {
  NSInteger p = [serviceListView selectedRow];
  ServiceTask* task = [[serviceManager listServices] objectAtIndex:p];
  
  NSString* stat = @"unknown";
  if ([task status] == -1) stat = @"no started";
  if ([task status] ==  1) stat = @"running";
  if ([task status] ==  0) stat = @"terminated";  
  
  [serviceName setStringValue:[task name]];
  [serviceStatus setStringValue:stat];
  [serviceRemoteName setStringValue:[task remoteName]];
  [serviceMountPoint setStringValue:[task mountPoint]];
}

- (IBAction) addService:(id)sender {
}

- (IBAction) openMountPoint:(id)sender {
  NSInteger p = [serviceListView selectedRow];
  ServiceTask* task = [[serviceManager listServices] objectAtIndex:p];
  NSString* mp = [task mountPoint];
  if (mp) {
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    [ws selectFile:@"." inFileViewerRootedAtPath:mp];
  }
}

- (IBAction) controlService:(id)sender {
  NSInteger p = [serviceListView selectedRow];
  ServiceTask* task = [[serviceManager listServices] objectAtIndex:p];

  if ([sender tag] == 1) {
    [task startTask];
  }
  else {
    [task stopTask];
  }
}

- (void) showPrefPanel: (id)sender {
  if (!launched) return;
  [window makeKeyAndOrderFront:self];
}

- (void) serviceStatusHasChanged:(NSNotification*) not {
  NSLog(@"service has changed: %@", not);
  [self showServiceInfo:self];
}

@end
