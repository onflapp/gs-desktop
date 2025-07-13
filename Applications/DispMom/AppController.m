/* 
  Project: DispMon

  Author: Ondrej Florian,,,

  Created: 2022-10-21 09:49:06 +0200 by oflorian
   
  Application Controller
*/

#import "AppController.h"
#import "MiniView.h"
#import "STScriptingSupport.h"

@implementation AppController

- (id) init
{
  if ((self = [super init])) {
    MiniView *mv = [[MiniView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    [[NSApp iconWindow] setContentView:mv];
    lastValue = 0;
  }
  return self;
}

- (void) dealloc
{
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

  if ([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }
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

- (void) _updateControls
{
  if (soundOut) {
    [muteButton setEnabled:YES];
    [volumeSlider setEnabled:YES];
    [muteButton setState:[soundOut isMute]];
    [volumeSlider setIntegerValue:[soundOut volume]];
  }
  else {
    [muteButton setEnabled:NO];
    [volumeSlider setEnabled:NO];
  }
  if (soundIn) {
    [micMuteButton setState:[soundIn isMute]];
    [micMuteButton setEnabled:YES];
  }
  else {
    [micMuteButton setEnabled:NO];
  }
}

- (void) _updateMenu
{
  NSMenu* menu = [audioMenu submenu];
  [menu removeAllItems];

  NSString *active = [[soundServer defaultOutput] activePort];

  for (SNDDevice *device in [soundServer outputList]) {
    if ([[device availablePorts] count] > 0) {
      for (NSDictionary *port in [device availablePorts]) {
        NSString* title = [NSString stringWithFormat:@"%@",
                        [port objectForKey:@"Description"]];
        NSMenuItem* it = [menu addItemWithTitle:title action:@selector(changeDevice:) keyEquivalent:@""];
        [it setRepresentedObject:device];
        if ([title isEqualToString:active]) {
          [it setState:YES];
        }
      }
    }
  }
}

- (void) increaseVolume: (id)sender
{
  NSInteger delta = ([volumeSlider maxValue] / 20);
  NSInteger val = (NSInteger)[volumeSlider doubleValue];
  [volumeSlider setIntValue:val+delta];
  [self changeVolume:volumeSlider];
}

- (void) decreaseVolume: (id)sender
{
  NSInteger delta = ([volumeSlider maxValue] / 20);
  NSInteger val = (NSInteger)[volumeSlider doubleValue];
  [volumeSlider setIntValue:val-delta];
  [self changeVolume:volumeSlider];
}

- (void) showPrefPanel: (id)sender
{
}

- (void) showAudioPreferences: (id)sender
{
  id preferences = [NSConnection rootProxyForConnectionWithRegisteredName:@"Preferences" host:@""];
  if (preferences) {
    [preferences performSelector:@selector(showPreferencesForModule:) withObject:@"Sound"];
  }
}

@end
