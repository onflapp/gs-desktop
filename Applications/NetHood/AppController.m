/* 
   Project: NetHood

   Author: Ondrej Florian,,,

   Created: 2023-09-06 23:21:19 +0200 by oflorian
   
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
    networkServices = [[NetworkServices alloc]init];
  }
  return self;
}

- (void) dealloc
{
  [networkServices release];
  [super dealloc];
}

- (void) awakeFromNib
{
  [panel setFrameAutosaveName:@"main_browser"];
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
/*
  if([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }
*/
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(didReceiveServiceNotification:)
             name:@"serviceStatusHasChanged"
           object:nil];

}

- (void) applicationDidBecomeActive:(NSNotification *)notification
{
  if (running && ![panel isVisible]) {
    [self showPanel:self];
  }
  running = YES;
}

- (BOOL) applicationShouldTerminate:(id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName
{
  return NO;
}

- (void) didReceiveServiceNotification:(NSNotification*) val {
  if ([networkServices status]) {
    [location setStringValue:@""];
    [service setStringValue:@"refreshing..."];
    [browser setEnabled:NO];
  }
  else {
    [location setStringValue:@""];
    [service setStringValue:@""];
    [browser setEnabled:YES];

    [browser reloadColumn:0];
  }
}

- (void) browser:(NSBrowser*) brow willDisplayCell:(NSBrowserCell*) cell atRow:(NSInteger)row column:(NSInteger)col {
  if (col == 0) {
    NSString* title = [[networkServices foundServiceGroups]objectAtIndex:row];
    [cell setLeaf:NO];
    [cell setStringValue:title];
  }
  else if (col == 1) {
    NSString* group = [[brow selectedCellInColumn:0] stringValue];
    NSArray* ls = [networkServices foundServicesForGroup:group];
    NSDictionary* it = [ls objectAtIndex:row];
    NSString* title = [it valueForKey:@"service"];

    [cell setRepresentedObject:it];
    [cell setLeaf:YES];
    [cell setStringValue:title];
  }
}

- (NSInteger) browser:(NSBrowser*) brow numberOfRowsInColumn:(NSInteger) col {
  if (col == 0) {
    return [[networkServices foundServiceGroups]count];
  }
  else {
    NSString* group = [[brow selectedCellInColumn:0] stringValue];
    NSArray* ls = [networkServices foundServicesForGroup:group];
    return [ls count];
  }
}

- (void) selectService: (id)sender
{
  if ([networkServices status]) return;

  id it = [[sender selectedCell] representedObject];
  if (it) {
    [location setStringValue:[it valueForKey:@"location"]];
    [service setStringValue:[it valueForKey:@"service"]];
  }
  else {
    [location setStringValue:@""];
    [service setStringValue:@""];
  }
}
- (void) openService: (id)sender
{
  NSString* loc = [location stringValue];
  if (!loc) return;

  if ([loc containsString:@"://"]) {
    NSURL* url = [NSURL URLWithString:loc];
    if (url) [[NSWorkspace sharedWorkspace] openURL:url];
  }
  else {
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", loc]];
    if (url) [[NSWorkspace sharedWorkspace] openURL:url];
  }
}

- (void) refreshServices: (id)sender
{
  [networkServices refresh];
}

- (void) showPanel: (id)sender
{
  [panel makeKeyAndOrderFront:sender];
  [self refreshServices:sender];
}

- (void) showPrefPanel: (id)sender
{
}

@end
