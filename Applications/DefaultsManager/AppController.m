/* 
   Project: DefaultsManager

   Author: ,,,

   Created: 2022-09-26 17:05:45 +0200 by pi
   
   Application Controller
*/

#import "AppController.h"

@implementation AppController

+ (void) initialize
{
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

- (id) init
{
  if ((self = [super init]))
    {
      domains = [[Domains alloc] init];
      defaults = [[Defaults alloc] init];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(domains);
  RELEASE(defaults);
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
  [self showDomainsPanel:self];
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

- (void) showDomainsPanel: (id)sender
{
  [domains showPanel:sender];
}

- (void) showDefaultsPanel: (id)sender
{
  [defaults showPanel:sender];
}


@end
