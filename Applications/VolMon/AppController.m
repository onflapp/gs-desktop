/* 
   Project: VolMon

   Author: Ondrej Florian,,,

   Created: 2022-10-21 09:49:06 +0200 by oflorian
   
   Application Controller
*/

#import "AppController.h"
#include <X11/Xlib.h>

@implementation AppController

- (id) init
{
  if ((self = [super init])) {
  }
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) awakeFromNib
{
  [[NSApp iconWindow] setContentView:controlView];
  [self resizeIconWindow];
}

- (void) resizeIconWindow 
{
  Display* dpy = XOpenDisplay(NULL);
  Window win = (Window)[[NSApp iconWindow]windowRef];

  XMoveResizeWindow(dpy, win, 5, 5, 54, 54);
  XFlush(dpy);
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

- (void)_updateControls
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
- (void)serverStateChanged:(NSNotification *)notif
{
  if ([notif object] != soundServer) {
    NSLog(@"Received other SNDServer state change notification.");
    return;
  }
  if (soundServer.status == SNDServerReadyState) {
    soundOut = [[soundServer defaultOutput] retain];
    soundIn = [[soundServer defaultInput] retain];
    
    if (soundOut) {
      [volumeSlider setMaxValue:[soundOut volumeSteps]-1];
    }
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(deviceDidUpdate:)
               name:SNDDeviceDidChangeNotification
             object:nil];
    [self _updateControls];    
  }
  else if (soundServer.status == SNDServerFailedState ||
           soundServer.status == SNDServerTerminatedState) {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    soundServer = nil;
  }
}

// --- Device notifications
- (void)deviceDidUpdate:(NSNotification *)aNotif
{
  id device = [aNotif object]; // SNDOut or SNDIn

  if ([device isKindOfClass:[SNDOut class]]) {
    SNDOut *output = (SNDOut *)device;
    if (output.sink == soundOut.sink) {
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
  }
  else if (sender == volumeSlider) {
    SNDDevice *device = (sender == volumeSlider) ? soundOut : soundIn;
    [device setVolume:[sender intValue]];
  }
}
- (void) showPrefPanel: (id)sender
{
}

@end
