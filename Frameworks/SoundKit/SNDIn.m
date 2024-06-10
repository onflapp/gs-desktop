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

#import <SoundKit/SNDIn.h>

#import "PASource.h"
#import "PACard.h"

@implementation SNDIn

@synthesize source;

- (void)dealloc
{
  NSDebugLLog(@"Memory", @"[SNDIn] dealloc");
  self.source  = nil;
  [super dealloc];
}

- (NSString *)name
{
  return self.source.description;
}
- (NSString *)description
{
  return [NSString stringWithFormat:@"PulseAudio Source `%@`", self.source.description];
}

// For debugging
- (void)printDescription
{
  fprintf(stderr, "+++ SNDDevice: %s +++++++++++++++++++++++++++++++++++++++++\n",
          [[super description] cString]);
  [super printDescription];
  
  fprintf(stderr, "+++ SNDIn: %s +++\n", [[self description] cString]);
  fprintf(stderr, "\t             Source : %s (%lu)\n",  [self.source.name cString],
          [self.source retainCount]);
  fprintf(stderr, "\t Source Description : %s\n",  [self.source.description cString]);
  fprintf(stderr, "\t        Active Port : %s\n",  [self.source.activePort cString]);
  fprintf(stderr, "\t         Card Index : %lu\n", self.source.cardIndex);
  fprintf(stderr, "\t       Card Profile : %s\n",  [super.card.activeProfile cString]);
  fprintf(stderr, "\t      Channel Count : %lu\n", self.source.channelCount);
  
  fprintf(stderr, "\t             Volume : %lu\n", self.source.volume);
  NSUInteger i;
  for (i = 0; i < self.source.channelCount; i++) {
    fprintf(stderr, "\t           Volume %lu : %lu\n", i,
      [[self.source.channelVolumes objectAtIndex:i] unsignedIntegerValue]);
  }
  
  fprintf(stderr, "\t              Muted : %s\n", self.source.mute ? "Yes" : "No");
  fprintf(stderr, "\t       Retain Count : %lu\n", [self retainCount]);

  fprintf(stderr, "\t    Available Ports : \n");
  for (NSDictionary *port in [self availablePorts]) {
    NSString *portDesc, *portString;
    portDesc = [port objectForKey:@"Description"];
    if ([portDesc isEqualToString:self.source.activePort])
      portString = [NSString stringWithFormat:@"%s%@%s", "\e[1m- ", portDesc, "\e[0m"];
    else
      portString = [NSString stringWithFormat:@"%s%@%s", "- ", portDesc, ""];
    fprintf(stderr, "\t                    %s\n", [portString cString]);
  }
}

/*--- Source proxy ---*/
- (NSArray *)availablePorts
{
  if (self.source == nil) {
    NSLog(@"SNDIn: avaliablePorts was called without Source was being set.");
    return nil;
  }
  return self.source.ports;
}
- (NSString *)activePort
{
  return self.source.activePort;
}
- (void)setActivePort:(NSString *)portName
{
  [self.source applyActivePort:portName];
}

- (NSUInteger)volumeSteps
{
  return self.source.volumeSteps;
}
- (NSUInteger)volume
{
  return [self.source volume];
}
- (void)setVolume:(NSUInteger)volume
{
  [self.source applyVolume:volume];
}
- (CGFloat)balance
{
  return self.source.balance;
}
- (void)setBalance:(CGFloat)balance
{
  [self.source applyBalance:balance];
}

- (void)setMute:(BOOL)isMute
{
  [self.source applyMute:isMute];
}
- (BOOL)isMute
{
  return (BOOL)self.source.mute;
}

// Flags
- (BOOL)hasHardwareVolumeControl
{
  return (self.source.flags & PA_SOURCE_HW_VOLUME_CTRL) ? YES : NO;
}
- (BOOL)hasHardwareMuteControl
{
  return (self.source.flags & PA_SOURCE_HW_MUTE_CTRL) ? YES : NO;
}
- (BOOL)hasFlatVolume
{
  return (self.source.flags & PA_SOURCE_FLAT_VOLUME) ? YES : NO;
}
- (BOOL)canQueryLatency
{
  return (self.source.flags & PA_SOURCE_LATENCY) ? YES : NO;
}
- (BOOL)canChangeLatency
{
  return (self.source.flags & PA_SOURCE_DYNAMIC_LATENCY) ? YES : NO;
}
- (BOOL)isHardware
{
  return (self.source.flags & PA_SOURCE_HARDWARE) ? YES : NO;
}
- (BOOL)isNetwork
{
  return (self.source.flags & PA_SOURCE_NETWORK) ? YES : NO;
}
// State
- (SNDDeviceState)deviceState
{
  return self.source.state;
}
// Sample
- (NSUInteger)sampleRate
{
  return self.source.sampleRate;
}
- (NSUInteger)sampleChannelCount
{
  return self.source.sampleChannelCount;
}
- (NSInteger)sampleFormat
{
  return self.source.sampleFormat;
}
// Formats
- (NSArray *)formats
{
  return self.source.formats;
}
// Channel map
- (NSArray *)channelNames
{
  NSMutableArray *cn = [NSMutableArray new];
  pa_channel_map *channel_map = [self.source channel_map];

  if (channel_map->channels > 0) {
    unsigned i;
    for (i = 0; i < channel_map->channels; i++) {
      [cn addObject:[super channelPositionToName:channel_map->map[i]]];
    }
  }
  return [[[NSArray array] initWithArray:cn] autorelease];
}

@end
