/* 
 * AppController.m created by phr on 2000-08-27 11:38:58 +0000
 *
 * Project TestApp
 *
 * Created with ProjectCenter - http://www.projectcenter.ch
 *
 * $Id: AppController.m,v 1.2 2000/12/31 14:26:29 robert Exp $
 */

#import "AppController.h"
#import "DefaultsManager.h"

@implementation AppController

static NSDictionary *infoDict = nil;

+ (void)initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)init
{
  if ((self = [super init])) {
  }
  return self;
}

- (void)dealloc
{
  [super dealloc];
}

- (void)awakeFromNib
{
}

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
}

- (BOOL)applicationShouldTerminate:(id)sender
{
  if (NSRunAlertPanel(@"Eeeek!",
		      @"Do you really want to quit me?",
		      @"No",
		      @"Yes",
		      nil)) {
    return NO;
  }
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
}

- (void)showPrefPanel:(id)sender
{
}

- (void)showInfoPanel:(id)sender
{
  [[NSApplication sharedApplication] orderFrontStandardInfoPanel:sender];
}

- (void)showDefaultsWindow:(id)sender
{
  [[DefaultsManager sharedManager] openMainWindow];
}

@end
