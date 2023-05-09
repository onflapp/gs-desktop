/* 
   Project: CloudManager

   Author: Ondrej Florian,,,

   Created: 2022-09-15 23:45:03 +0200 by oflorian
   
   Application Controller
*/

#import "AppController.h"

@implementation AppController

+ (void) initialize {
  NSMutableDictionary* defaults = [NSMutableDictionary dictionary];

  [defaults setObject:@"~/Cloud" forKey:@"default_base"];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init {
  if ((self = [super init])) {
     serviceManager = [[ServiceManager alloc] init];

     [[NSNotificationCenter defaultCenter] addObserver:self 
                                              selector:@selector(serviceStatusHasChanged:) 
                                                  name:@"serviceStatusHasChanged" object:nil];

     [[NSNotificationCenter defaultCenter] addObserver:self 
                                              selector:@selector(serviceRegistrationHasChanged:) 
                                                  name:@"serviceRegistrationHasChanged" object:nil];
  }
  return self;
}

- (void) dealloc {
   [serviceManager release];
   [super dealloc];
}

- (void) awakeFromNib {
   NSButtonCell* cell = AUTORELEASE([NSButtonCell new]);
   [cell setButtonType:NSMomentaryPushInButton];
   [cell setImagePosition:NSImageOverlaps];

   NSRect r = [serviceListView frame];
   [serviceListView setCellSize:NSMakeSize(r.size.width-23,48)];
   [serviceListView setPrototype:cell];
   [serviceListView setMode:NSRadioModeMatrix];
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif {
  [serviceManager configureAllServices];

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

  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.5];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName {
  return NO;
}

- (void) refreshServiceListView {
   while ([serviceListView numberOfRows]) {
     [serviceListView removeRow:0];
   }

   NSInteger row = 0;
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
   [serviceListView sizeToCells];
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
  [serviceDescription setStringValue:[task message]];
  [serviceRemoteName setStringValue:[task remoteName]];
  [serviceMountPoint setStringValue:[task mountPoint]];
}

- (IBAction) configRCloneService:(id)sender {
  if (!rcloneSetup) rcloneSetup = [[RCloneSetup alloc] init];

  [rcloneSetup showPanelAndRunSetup:sender];
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

- (void) serviceRegistrationHasChanged:(NSNotification*) not {
  [serviceManager configureAllServices];

  [self refreshServiceListView];
}

- (void) serviceStatusHasChanged:(NSNotification*) not {
  NSLog(@"service has changed: %@", not);
  [self showServiceInfo:self];
}

@end
