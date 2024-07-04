/* -*- mode: objc -*- */
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

#import "PASink.h"

@implementation PASink

@synthesize cardIndex;
@synthesize index;
@synthesize context;
@synthesize name;
@synthesize description;
@synthesize ports;

@synthesize flags;
@synthesize state;
@synthesize sampleRate;
@synthesize sampleChannelCount;
@synthesize sampleFormat;
@synthesize formats;

// KVO-compliant
@synthesize activePort;
@synthesize channelCount;
@synthesize volumeSteps;
@synthesize baseVolume;
@synthesize balance;
@synthesize channelVolumes;
@synthesize mute;

- (void)dealloc
{
  self.description = nil;
  self.name = nil;
  self.activePort = nil;
  self.ports = nil;
  self.channelVolumes = nil;
  
  free(_channel_map);
  
 [super dealloc];
}

- (id)init
{
  self = [super init];
  _channel_map = NULL;
  return self;
}

- (pa_channel_map *)channel_map
{
  return _channel_map;
}

// --- Initialize and update
- (void)_updatePorts:(const pa_sink_info *)info
{
  NSMutableArray *ports;
  NSDictionary   *d;
  NSString       *newActivePort;

  if (info->n_ports > 0) {
    ports = [NSMutableArray new];
    unsigned i;
    for (i = 0; i < info->n_ports; i++) {
      d = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithCString:info->ports[i]->name], @"Name",
            [NSString stringWithCString:info->ports[i]->description], @"Description", nil];
      [ports addObject:d];
    }
    self.ports = [[NSArray alloc] initWithArray:ports];
  }

  if (info->active_port) {
    newActivePort = [[NSString alloc] initWithCString:info->active_port->description];
    if (self.activePort == nil || [self.activePort isEqualToString:newActivePort] == NO) {
      if (info->active_port != NULL) {
        self.activePort = newActivePort;
      }
      else {
        self.activePort = nil;
      }
    }
  }
}

- (void)_updateVolume:(const pa_sink_info *)info
{
  NSMutableArray *vol;
  NSNumber       *v;
  BOOL           isVolumeChanged = NO;
  CGFloat        balance;

  if (self.channelVolumes == nil) {
    isVolumeChanged = YES;
  }
  
  balance = pa_cvolume_get_balance(&info->volume, &info->channel_map);
  if (self.balance != balance) {
    self.balance = balance;
  }
  
  vol = [NSMutableArray new];
  int i;
  for (i = 0; i < info->volume.channels; i++) {
    v = [NSNumber numberWithUnsignedInteger:info->volume.values[i]];
    [vol addObject:v];
    if (isVolumeChanged == NO && [[self.channelVolumes objectAtIndex:i] isEqualToNumber:v] == NO) {
      isVolumeChanged = YES;
    }
  }
  if (isVolumeChanged != NO) {
    self.channelVolumes = [[NSArray alloc] initWithArray:vol]; // KVO compliance
  }
  [vol release];

  //
  self.volumeSteps = info->n_volume_steps;
  
  if (self.baseVolume != (NSUInteger)info->base_volume) {
    self.baseVolume = (NSUInteger)info->base_volume;
  }  
}

- (void)_updateChannels:(const pa_sink_info *)info
{
  self.channelCount = info->volume.channels;
  
  // Channel map
  if (_channel_map) {
    free(_channel_map);
  }
  _channel_map = malloc(sizeof(pa_channel_map));
  pa_channel_map_init(_channel_map);
  _channel_map->channels = info->channel_map.channels;
  int i;
  for (i = 0; i < _channel_map->channels; i++) {
    _channel_map->map[i] = info->channel_map.map[i];
  }
}

- (void)_updateFormats:(const pa_sink_info *)info
{
  NSMutableArray *formats;
  
  if (info->n_formats > 0) {
    formats = [NSMutableArray new];
    unsigned i;
    for (i = 0; i < info->n_formats; i++) {
      [formats addObject:[NSNumber numberWithInt:info->formats[i]->encoding]];
    }
    self.formats = [[NSArray alloc] initWithArray:formats];
  }
}

- (id)updateWithValue:(NSValue *)val
{
  const pa_sink_info *info;
  NSMutableArray     *ports, *vol, *formats;
  
  // Convert PA structure into NSDictionary
  //Zinfo = malloc(sizeof(const pa_sink_info));
  //Z[val getValue:(void *)info];
  info = [val pointerValue];

  // Indexes
  self.index = info->index;
  self.cardIndex = info->card;

  // Name and description
  if (self.description == nil && info->description) {
    self.description = [[NSString alloc] initWithCString:info->description];
  }
  
  if (self.name == nil && info->name) {
    self.name = [[NSString alloc] initWithCString:info->name];
  }

  // Ports
  [self _updatePorts:info];

  // Volume
  [self _updateVolume:info];

  if (self.mute != (BOOL)info->mute) {
    self.mute = (BOOL)info->mute;
  }

  if (_channel_map == NULL || pa_channel_map_equal(_channel_map, &info->channel_map)) {
    [self _updateChannels:info];
  }

  // Flags
  self.flags = info->flags;
  // State
  self.state = info->state;
  // Sample spec
  self.sampleRate = info->sample_spec.rate;
  self.sampleChannelCount = info->sample_spec.channels;
  self.sampleFormat = info->sample_spec.format;
  // Supported formats
  // [self _updateFormats:info];

  //Zfree ((void *)info);

  return self;
}

// --- Actions
- (void)applyActivePort:(NSString *)portName
{
  const char   *port;
  pa_operation *o;

  for (NSDictionary *p in self.ports) {
    if ([[p objectForKey:@"Description"] isEqualToString:portName]) {
      port = [[p objectForKey:@"Name"] cString];
      break;
    }
  }
  o = pa_context_set_sink_port_by_index(self.context, self.index, port, NULL, self);
  if (o) {
    pa_operation_unref(o);
  }
}

- (void)applyMute:(BOOL)isMute
{
  pa_operation *o;
  
  o = pa_context_set_sink_mute_by_index(self.context, self.index, (int)isMute, NULL, self);
  if (o) {
    pa_operation_unref(o);
  }
}

- (NSUInteger)volume
{
  NSUInteger v, i;

  for (i = 0, v = 0; i < self.channelCount; i++) {
    if ([[self.channelVolumes objectAtIndex:i] unsignedIntegerValue] > v)
      v = [[self.channelVolumes objectAtIndex:i] unsignedIntegerValue];
  }
  
  return v;
}

- (void)applyVolume:(NSUInteger)v
{
  pa_cvolume   *new_volume;
  pa_operation *o;

  new_volume = malloc(sizeof(pa_cvolume));
  pa_cvolume_init(new_volume);
  pa_cvolume_set(new_volume, self.channelCount, v);
  
  o = pa_context_set_sink_volume_by_index(self.context, self.index, new_volume, NULL, self);
  if (o) {
    pa_operation_unref(o);
  }
  
  free(new_volume);

  //process events right after
  [[NSRunLoop currentRunLoop] runUntilDate:
    [NSDate dateWithTimeIntervalSinceNow:0.0]];
}

- (void)applyBalance:(CGFloat)balance
{
  pa_cvolume  *volume;
  pa_operation *o;

  volume = malloc(sizeof(pa_cvolume));
  pa_cvolume_init(volume);
  pa_cvolume_set(volume, self.channelCount, self.volume);
  
  pa_cvolume_set_balance(volume, _channel_map, balance);
  o = pa_context_set_sink_volume_by_index(self.context, self.index, volume, NULL, self);
  if (o) {
    pa_operation_unref(o);
  }
  
  free(volume);

  //process events right after
  [[NSRunLoop currentRunLoop] runUntilDate:
    [NSDate dateWithTimeIntervalSinceNow:0.0]];
}

@end
