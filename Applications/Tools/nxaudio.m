/* Copyright (C) 2020 Free Software Foundation, Inc.

   Written by: onflapp
   Created: September 2020

   This file is part of the NEXTSPACE Project

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   You should have received a copy of the GNU General Public
   License along with this program; see the file COPYING.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

   */

#import	<AppKit/AppKit.h>
#import "nxaudio.h"

@implementation SoundController

- (id) init
{
  if ((self = [super init])) {
    status = -1;
    [NSUserDefaults standardUserDefaults]; //prevents crash in the serverStateChanged
  }
  return self;
}

- (BOOL) connectAndWait {
  // 1. Connect to PulseAudio on locahost
  soundServer = [SNDServer sharedServer];
  [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(serverStateChanged:)
               name:SNDServerStateDidChangeNotification
             object:soundServer];

  // 2. Wait for server to be ready
  if (soundServer.status == SNDServerNoConnnectionState) {
    [soundServer connect];
  }

  NSInteger i;
  for (i = 100; i > 0; i--) {
    NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
    [[NSRunLoop currentRunLoop] runUntilDate: limit];

    if (status == 1) return YES;
    else if (status == 0) return NO;
  }

  return NO;
}

- (void)setOutputVolumeUp {
  NSInteger max = max_volume;
  NSInteger d = max / 20;
  NSInteger v = [soundOut volume] + d;
  if (v > max) v = max;
  [soundOut setVolume:v];
}

- (void)setOutputVolumeDown {
  NSInteger max = max_volume;
  NSInteger d = max / 20;
  NSInteger v = [soundOut volume] - d;
  if (v < 0) v = 0;
  [soundOut setVolume:v];
}

- (void)setOutputVolume:(NSInteger) val {
  NSInteger v = ((float)max_volume * ((float)val / 100));
  [soundOut setVolume:v];
}

- (void)setOutputVolumeMute {
  [soundOut setMute:![soundOut isMute]];
}

- (void)serverStateChanged:(NSNotification *)notif
{
  if ([notif object] != soundServer) {
    NSLog(@"Received other SNDServer state change notification.");
    return;
  }
  if (soundServer.status == SNDServerReadyState) {
    soundOut = [[soundServer defaultOutput] retain];
    soundIn = [[soundServer defaultInput] retain];

    max_volume = [soundOut volumeSteps] - 1;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(deviceDidUpdate:)
               name:SNDDeviceDidChangeNotification
             object:nil];

    float val = ((float)[soundOut volume] / (float)max_volume);
    NSLog(@"output: %d", (int)(val*100));
    status = 1;
  }
  else if (soundServer.status == SNDServerFailedState ||
           soundServer.status == SNDServerTerminatedState) {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    soundServer = nil;
    status = 0;
  }
}

// --- Device notifications
- (void)deviceDidUpdate:(NSNotification *)aNotif
{
  id device = [aNotif object]; // SNDOut or SNDIn

  if ([device isKindOfClass:[SNDOut class]]) {

    SNDOut *output = (SNDOut *)device;
    if (output.sink == soundOut.sink) {
      //[muteButton setState:[soundOut isMute]];
      //[volumeSlider setIntegerValue:[soundOut volume]];
    }
  }
}

@end

void printUsage() {
  fprintf(stderr, "Usage: nxaudio\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Help: conntrol audio from command line\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  --set volume\n");
  fprintf(stderr, "  --mute\n");
  fprintf(stderr, "  --increase\n");
  fprintf(stderr, "  --decrease\n");
  fprintf(stderr, "\n");
}

int main(int argc, char** argv, char** env)
{
  NSProcessInfo *pInfo;
  NSArray *arguments;
  CREATE_AUTORELEASE_POOL(pool);

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env_c];
#endif

  pInfo = [NSProcessInfo processInfo];
  arguments = [pInfo arguments];

  @try {
    if ([arguments count] == 1) {
      printUsage();
      exit(1);
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--set"] && [arguments count] >= 2 ) {
      SoundController* controller = [[SoundController alloc] init];
      if ([controller connectAndWait]) {
        NSInteger v = [[arguments objectAtIndex:2] integerValue];
        [controller setOutputVolume:v];
      }
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--increase"]) {
      SoundController* controller = [[SoundController alloc] init];
      if ([controller connectAndWait]) {
        [controller setOutputVolumeUp];
      }
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--decrease"]) {
      SoundController* controller = [[SoundController alloc] init];
      if ([controller connectAndWait]) {
        [controller setOutputVolumeDown];
      }
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--mute"]) {
      SoundController* controller = [[SoundController alloc] init];
      if ([controller connectAndWait]) {
        [controller setOutputVolumeMute];
      }
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--status"]) {
      SoundController* controller = [[SoundController alloc] init];
      if ([controller connectAndWait]) {
        NSLog(@"audio controller:%@", controller);
      }
    }
    else {
      printUsage();
      exit(1);
    }
  }
  @catch (NSException* ex) {
    NSLog(@"exception: %@", ex);
    printUsage();
    exit(6);
  }

  RELEASE(pool);

  exit(EXIT_SUCCESS);
}

