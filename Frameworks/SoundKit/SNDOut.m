//
// Project: SoundKit framework.
//
// Copyright (C) 2019 Sergii Stoian
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

//#import <dispatch/dispatch.h>

#import "PACard.h"
#import "PASink.h"
#import "SNDOut.h"

@implementation SNDOut

@synthesize sink;

- (void)dealloc
{
  NSDebugLLog(@"Memory", @"[SNDOut] dealloc");
  self.sink = nil;
  [super dealloc];
}

- (NSString *)name
{
  return self.sink.description;
}
- (NSString *)description
{
  return [NSString stringWithFormat:@"PulseAudio Sink `%@`", self.sink.description];
}
// For debugging
- (void)printDescription
{
  fprintf(stderr, "+++ SNDDevice: %s +++++++++++++++++++++++++++++++++++++++++\n",
          [[super description] cString]);
  [super printDescription];
  
  fprintf(stderr, "+++ SNDOut: %s +++\n", [[self description] cString]);
  fprintf(stderr, "\t               Sink : %s (%lu)\n",  [self.sink.name cString],
          [self.sink retainCount]);
  fprintf(stderr, "\t   Sink Description : %s\n",  [self.sink.description cString]);
  fprintf(stderr, "\t        Active Port : %s\n",  [self.sink.activePort cString]);
  fprintf(stderr, "\t         Card Index : %lu\n", self.sink.cardIndex);
  fprintf(stderr, "\t       Card Profile : %s\n",  [super.card.activeProfile cString]);
  fprintf(stderr, "\t      Channel Count : %lu\n", self.sink.channelCount);
  
  fprintf(stderr, "\t             Volume : %lu\n", self.sink.volume);
  NSUInteger i;
  for (i = 0; i < self.sink.channelCount; i++) {
    fprintf(stderr, "\t           Volume %lu : %lu\n", i,
      [[self.sink.channelVolumes objectAtIndex:i] unsignedIntegerValue]);
  }
  
  fprintf(stderr, "\t              Muted : %s\n", self.sink.mute ? "Yes" : "No");
  fprintf(stderr, "\t       Retain Count : %lu\n", [self retainCount]);

  fprintf(stderr, "\t    Available Ports : \n");
  for (NSDictionary *port in [self availablePorts]) {
    NSString *portDesc, *portString;
    portDesc = [port objectForKey:@"Description"];
    if ([portDesc isEqualToString:self.sink.activePort])
      portString = [NSString stringWithFormat:@"%s%@%s", "\e[1m- ", portDesc, "\e[0m"];
    else
      portString = [NSString stringWithFormat:@"%s%@%s", "- ", portDesc, ""];
    fprintf(stderr, "\t                    %s\n", [portString cString]);
  }
}

/*--- Sink proxy ---*/
- (NSArray *)availablePorts
{
  if (self.sink == nil) {
    NSLog(@"SNDOut: avaliablePorts was called without Sink was being set.");
    return nil;
  }
  return self.sink.ports;
}
- (NSString *)activePort
{
  return self.sink.activePort;
}
- (void)setActivePort:(NSString *)portName
{
  [self.sink applyActivePort:portName];
}

- (NSUInteger)volumeSteps
{
  NSUInteger v = self.sink.volumeSteps;
  if (v == 0) v = 65537;
  return v;
}
- (NSUInteger)volume
{
  return [self.sink volume];
}
- (void)setVolume:(NSUInteger)volume
{
  [self.sink applyVolume:volume];
}
- (CGFloat)balance
{
  return self.sink.balance;
}
- (void)setBalance:(CGFloat)balance
{
  [self.sink applyBalance:balance];
}

- (void)setMute:(BOOL)isMute
{
  [self.sink applyMute:isMute];
}
- (BOOL)isMute
{
  return (BOOL)self.sink.mute;
}

// Flags
- (BOOL)hasHardwareVolumeControl
{
  return (self.sink.flags & PA_SINK_HW_VOLUME_CTRL) ? YES : NO;
}
- (BOOL)hasHardwareMuteControl
{
  return (self.sink.flags & PA_SINK_HW_MUTE_CTRL) ? YES : NO;
}
- (BOOL)hasFlatVolume
{
  return (self.sink.flags & PA_SINK_FLAT_VOLUME) ? YES : NO;
}
- (BOOL)canQueryLatency
{
  return (self.sink.flags & PA_SINK_LATENCY) ? YES : NO;
}
- (BOOL)canChangeLatency
{
  return (self.sink.flags & PA_SINK_DYNAMIC_LATENCY) ? YES : NO;
}
- (BOOL)canSetFormats
{
  return (self.sink.flags & PA_SINK_SET_FORMATS) ? YES : NO;
}
- (BOOL)isHardware
{
  return (self.sink.flags & PA_SINK_HARDWARE) ? YES : NO;
}
- (BOOL)isNetwork
{
  return (self.sink.flags & PA_SINK_NETWORK) ? YES : NO;
}
// State
- (SNDDeviceState)deviceState
{
  return self.sink.state;
}
// Sample
- (NSUInteger)sampleRate
{
  return self.sink.sampleRate;
}
- (NSUInteger)sampleChannelCount
{
  return self.sink.sampleChannelCount;
}
- (NSInteger)sampleFormat
{
  return self.sink.sampleFormat;
}
// Formats
- (NSArray *)formats
{
  return self.sink.formats;
}
// Channel map
- (NSArray *)channelNames
{
  NSMutableArray *cn = [NSMutableArray new];
  pa_channel_map *channel_map = [self.sink channel_map];

  if (channel_map->channels > 0) {
    unsigned i;
    for (i = 0; i < channel_map->channels; i++) {
      [cn addObject:[super channelPositionToName:channel_map->map[i]]];
    }
  }
  return [[[NSArray array] initWithArray:cn] autorelease];
}

@end
