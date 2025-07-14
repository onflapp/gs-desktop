/* 
  Project: DispMon

  Author: Ondrej Florian,,,

  Created: 2022-10-21 09:49:06 +0200 by oflorian
   
  Application Controller
*/

#import "AppController.h"
#import "MiniView.h"
#import "STScriptingSupport.h"

#import <SystemKit/OSEScreen.h>
#import <SystemKit/OSEDisplay.h>

@implementation AppController

- (id) init
{
  if ((self = [super init])) {
    MiniView *mv = [[MiniView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    [[NSApp iconWindow] setContentView:mv];
  
    systemScreen = [OSEScreen new];
  }
  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [systemScreen release];
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
  //[NSApp deactivate];
  [[[NSApp iconWindow] contentView] addSubview:controlView];
  [controlView setFrame:NSMakeRect(8, 8, 48, 48)];
  [controlView setNeedsDisplay:YES];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(updateControls:)
           name:OSEDisplayDidUpdateNotification
         object:nil];


  if ([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }

  [self updateControls:nil];
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

- (IBAction)changeBrightness:(id)sender
{
  CGFloat value = [sender floatValue];

  if (value > 100) 
    value = 100;

  lastChange = [[NSDate date] timeIntervalSinceReferenceDate];

  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(__updateDisplayBrigthness:)
    withObject:[NSNumber numberWithFloat:value]
    afterDelay:0.2];
}

- (IBAction)increaseBrightness:(id)sender
{
  CGFloat value = [brightnessSlider floatValue] + 10;

  if (value > 100) 
    value = 100;

  [brightnessSlider setFloatValue:value];

  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(__updateDisplayBrigthness:)
    withObject:[NSNumber numberWithFloat:value]
    afterDelay:0.1];
}

- (IBAction)decreaseBrightness:(id)sender
{
  CGFloat value = [brightnessSlider floatValue] - 10;

  if (value < 10) 
    value = 10;

  [brightnessSlider setFloatValue:value];

  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(__updateDisplayBrigthness:)
    withObject:[NSNumber numberWithFloat:value]
    afterDelay:0.2];
}

- (void)updateControls:(NSNotification *) aNotif
{
  OSEDisplay *selectedDisplay = nil;
  NSTimeInterval d = [[NSDate date] timeIntervalSinceReferenceDate] - lastChange;

  if (d < 0.5) return;

  for (OSEDisplay *dpy in [systemScreen connectedDisplays]) {
    if ([dpy isDisplayBrightnessSupported]) {
      selectedDisplay = dpy;
      break;
    }
  }

  if (selectedDisplay) {
    CGFloat value = [selectedDisplay displayBrightness];

    [brightnessSlider setEnabled:YES];
    [brightnessSlider setFloatValue:floor(value)];

  }
  else {
    [brightnessSlider setEnabled:NO];
  }
}

- (void)__updateDisplayBrigthness:(NSNumber *)value
{
  lastChange = [[NSDate date] timeIntervalSinceReferenceDate];
  OSEDisplay *selectedDisplay = nil;

  for (OSEDisplay *d in [systemScreen connectedDisplays]) {
    if ([d isDisplayBrightnessSupported]) {
      selectedDisplay = d;
      break;
    }
  }

  if (selectedDisplay) {
    [selectedDisplay setDisplayBrightness:[value floatValue]];
  }
}


- (void) showPrefPanel: (id)sender
{
}

- (void) showDisplayPreferences: (id)sender
{
  id preferences = [NSConnection rootProxyForConnectionWithRegisteredName:@"Preferences" host:@""];
  if (preferences) {
    [preferences performSelector:@selector(showPreferencesForModule:) withObject:@"Display"];
  }
}

@end
