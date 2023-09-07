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

- (BOOL) applicationShouldTerminate: (id)sender
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
  [browser reloadColumn:0];
}

- (BOOL)browser:(NSBrowser *)sender selectRow:(NSInteger)row inColumn:(NSInteger)col {
  return YES;
}

- (void) browser:(NSBrowser*) browser willDisplayCell:(NSBrowserCell*) cell atRow:(NSInteger)row column:(NSInteger)col {
  NSDictionary* it = [[networkServices foundServices]objectAtIndex:row];
  NSString* title = [it valueForKey:@"title"];
  [cell setLeaf:YES];
  [cell setStringValue:title];
}

- (NSInteger) browser:(NSBrowser*) browser numberOfRowsInColumn:(NSInteger) col {
  return [[networkServices foundServices]count];
}

- (void) showPanel: (id)sender
{
  [panel makeKeyAndOrderFront:sender];
  [networkServices refresh];
}

- (void) showPrefPanel: (id)sender
{
}

@end
