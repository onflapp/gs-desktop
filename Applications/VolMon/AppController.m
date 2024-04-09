/* 
  Project: VolMon

  Author: Ondrej Florian,,,

  Created: 2022-10-21 09:49:06 +0200 by oflorian
   
  Application Controller
*/

#import "AppController.h"
#import "MiniView.h"

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
  // 1. Connect to PulseAudio on locahost
  soundServer = [SNDServer sharedServer];
  // 2. Wait for server to be ready
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(serverStateChanged:)
           name:SNDServerStateDidChangeNotification
         object:soundServer];
  // 3. Create connection to PulseAudio server
  if (soundServer.status == SNDServerNoConnnectionState) {
    [soundServer connect];
  }

  //[NSApp deactivate];
  [[[NSApp iconWindow] contentView] addSubview:controlView];
  [controlView setFrame:NSMakeRect(8, 8, 48, 48)];
  [controlView setNeedsDisplay:YES];
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
    [micMuteButton setEnabled:YES];
    [volumeSlider setEnabled:YES];
    [muteButton setState:[soundOut isMute]];
    [volumeSlider setIntegerValue:[soundOut volume]];
  }
  else {
    [micMuteButton setEnabled:NO];
    [muteButton setEnabled:NO];
    [volumeSlider setEnabled:NO];
  }
}

// --- Sound subsystem actions
- (void) serverStateChanged:(NSNotification *)notif
{
  if ([notif object] != soundServer) {
    NSLog(@"Received other SNDServer state change notification.");
    return;
  }
  if (soundServer.status == SNDServerReadyState) {
    soundOut = [[soundServer defaultOutput] retain];
    soundIn = [[soundServer defaultInput] retain];
    
    if (soundOut) {
      [volumeSlider setMaxValue:[soundOut volumeSteps]];
    }
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(deviceDidUpdate:)
               name:SNDDeviceDidChangeNotification
             object:nil];

    NSTimeInterval d = [[NSDate date] timeIntervalSinceReferenceDate] - lastChange;
    if (d > 0.5) {
      [self _updateControls];
    }  
  }
  else if (soundServer.status == SNDServerFailedState ||
           soundServer.status == SNDServerTerminatedState) {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    soundServer = nil;
  }
}

// --- Device notifications
- (void) deviceDidUpdate:(NSNotification *)aNotif
{
  id device = [aNotif object]; // SNDOut or SNDIn

  if ([device isKindOfClass:[SNDOut class]]) {
    NSTimeInterval d = [[NSDate date] timeIntervalSinceReferenceDate] - lastChange;

    SNDOut *output = (SNDOut *)device;
    if (output.sink == soundOut.sink && d > 0.5) {
      NSLog(@"dev update");
      [muteButton setState:[soundOut isMute]];
      [volumeSlider setIntegerValue:[soundOut volume]];
    }
  }
}

- (void) changeVolume: (id)sender
{
  if (sender == muteButton) {
    SNDDevice *device = (sender == muteButton) ? soundOut : soundIn;
    [device setMute:[sender state]];
    lastChange = [[NSDate date] timeIntervalSinceReferenceDate];
  }
  else if (sender == volumeSlider) {
    if ([sender intValue] != lastValue) {
      NSInteger val = [sender intValue];

      /* there seems to be a bug which causes slider to receive
       * max value once a while, we catch this and set the last val
       */
      if ((NSInteger)[volumeSlider maxValue] == val) {
        [volumeSlider setIntegerValue:lastValue];
        return;
      }

      SNDDevice *device = (sender == volumeSlider) ? soundOut : soundIn;
      [device setVolume:val];
      lastChange = [[NSDate date] timeIntervalSinceReferenceDate];
      lastValue = val;
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

@end
