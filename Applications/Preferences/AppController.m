/* -*- mode: objc -*- */
//
// Project: Preferences
//
// Copyright (C) 2014-2019 Sergii Stoian
//
// This application is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This application is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this library; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
//

#import <DesktopKit/NXTDefaults.h>
#import <SystemKit/OSEKeyboard.h>
#import <SystemKit/OSEMouse.h>
#import <SystemKit/OSEDisplay.h>
#import <SystemKit/OSEScreen.h>
#import <DesktopKit/NXTClockView.h>

#import "AppController.h"
#import "KeyboardStatusMonitor.h"

@implementation AppController

- (id)init
{
  if (!(self = [super init])) {
    return nil;
  }

  prefsController = nil;
  return self;
}

- (void)awakeFromNib
{
  NSDictionary *cvDisplayRects;

  if (clockView)
    return;

  cvDisplayRects = [NSDictionary dictionaryWithObjectsAndKeys:
                     NSStringFromRect(NSMakeRect(14, 33, 33, 6)), @"DayOfWeek",
                     NSStringFromRect(NSMakeRect(14, 15, 33, 17)), @"Day",
                     NSStringFromRect(NSMakeRect(14,  9, 31, 6)), @"Month",
                     NSStringFromRect(NSMakeRect( 5, 46, 53, 11)), @"Time", nil];

  clockView = [[NXTClockView alloc]
                initWithFrame:NSMakeRect(0, 0, 64, 64)
                         tile:[NSImage imageNamed:@"ClockViewTile"]
                 displayRects:cvDisplayRects];
  [clockView setYearVisible:NO];
  [clockView setCalendarDate:[NSCalendarDate calendarDate]];
  [clockView setAlive:YES];
  [clockView setTarget:self];
  [clockView setDoubleAction:@selector(showPreferencesWindow)];
  [[NSApp iconWindow] setContentView:clockView];
  [clockView release];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notify {}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif
{
  OSEScreen* systemScreen = [OSEScreen new];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(screenDidUpdate:)
           name:OSEScreenDidUpdateNotification
         object:systemScreen];

  // Here will be applied various preferences to desktop/system:
  // keyboard, mouse, sound, power management.
  // Display preferences are applied in Workspace Manager because displays must
  // be configured before start of window management task.

  // Apply preferences only if we're autolaunched.
  // NSApplication removed arguments (-NXAutoLaunch YES) to omit flickering.
  // We've just finished launching and not active == we've autolaunched
  if ([NSApp isActive] == NO) {

    [self configureMouseAndKeyboard];

    NXTDefaults *defs = [NXTDefaults globalUserDefaults];
    BOOL managedExternally = [[defs objectForKey:@"DoNotManageDesktopBackground"] boolValue];

    /*
      NSLog(@"Configuring Desktop background...");
      OSEScreen *screen = [OSEScreen sharedScreen];
      CGFloat red, green, blue;
      if ([screen savedBackgroundColorRed:&red green:&green blue:&blue] == YES) {
        [screen setBackgroundColorRed:red green:green blue:blue];
      }
    */
  }

  // we used this to watch for display bein turned on and off
  // in which case we will reconfigure the mouse and keyboard
  // this should prevent reseting settings after a display goes to sleep
  KeyboardStatusMonitor* kstat = [[KeyboardStatusMonitor alloc] init];
  [kstat performSelectorInBackground:@selector(processXWindowsEvents:) withObject:self];
}

- (void) wakeUpAfterSleep
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(configureMouseAndKeyboard) object:nil];
  [self performSelector:@selector(configureMouseAndKeyboard) withObject:nil afterDelay:2.0];
}

// Notifications
- (void)screenDidUpdate:(NSNotification *)aNotif
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshScreen) object:nil];
  [self performSelector:@selector(refreshScreen) withObject:nil afterDelay:0.5];
}

- (void)configureMouseAndKeyboard
{
  NXTDefaults *defs = [NXTDefaults globalUserDefaults];

  NSLog(@"Configuring Keyboard...");
  [OSEKeyboard configureWithDefaults:defs];

  NSLog(@"Configuring Mouse...");
  OSEMouse *mouse = [OSEMouse new];
  [mouse setAcceleration:[defs integerForKey:OSEMouseAcceleration]
               threshold:[defs integerForKey:OSEMouseThreshold]];
  [mouse setPrimaryButton:[defs integerForKey:OSEMousePrimaryButtonHand]];
  [mouse setWheelScrollReverse:[defs integerForKey:OSEMouseWheelScrollReverse]];

  [mouse release];

  NSLog(@"Configuring Brightness...");
  int val = [[defs objectForKey:OSEDisplayBrightnessKey]intValue];
  if (val) {
    for (OSEDisplay *disp in [[OSEScreen sharedScreen] connectedDisplays]) {
      [disp setDisplayBrightness:val];
    }
  }

  NSString* initrc = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"apply_config"];
  NSLog(@"Exec apply_config %@ wakeup", initrc);
  [NSTask launchedTaskWithLaunchPath:initrc arguments:[NSArray arrayWithObject:@"keyboard"]];
}

- (void)refreshScreen
{
  NSString* initrc = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"apply_config"];
  NSLog(@"Exec apply_config %@ screenchange", initrc);
  [NSTask launchedTaskWithLaunchPath:initrc arguments:[NSArray arrayWithObject:@"screen"]];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotif
{
  [[NXTDefaults globalUserDefaults] synchronize];
  [prefsController release];
  [clockView removeFromSuperviewWithoutNeedingDisplay];
}

- (void)applicationDidBecomeActive:(NSNotification*)aNotification
{
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
  return YES;
}

- (void)showPreferencesWindow
{
  if (prefsController == nil) {
    if ([NSBundle loadNibNamed:@"PrefsWindow" owner:self] == NO) {
      NSLog(@"Error loading NIB PrefsWindow");
      return;
    }
  }

  [NSApp activateIgnoringOtherApps:YES];
  [[prefsController window] makeKeyAndOrderFront:self];
}

- (void)showInfoPanel:(id)sender
{
  if (!infoPanel) {
    if (![NSBundle loadNibNamed:@"InfoPanel" owner:self]) {
      NSLog (@"Failed to load InfoPanel.nib");
      return;
    }
   [infoPanel center];
  }
 [infoPanel makeKeyAndOrderFront:nil];
}

@end
