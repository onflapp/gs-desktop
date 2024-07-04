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

#import "PAClient.h"
#import "PAStream.h"
#import "PASink.h"
#import "PASinkInput.h"


// typedef struct pa_sink_input_info {
//   uint32_t   index; // Index of the sink input
//   const char *name; // Name of the sink input

//   uint32_t   client; // Index of the client this sink input belongs to, or PA_INVALID_INDEX
//   uint32_t   sink;  // Index of the connected sink
//   int mute;  // Stream muted
//   int corked;  // Stream corked
  
//   pa_sample_spec sample_spec;  // The sample specification of the sink input.
//   const char *resample_method;  // The resampling method used by this sink input.
  
//   pa_channel_map channel_map;  // Channel map
//   // Stream has volume. 
//   // If not set, then the meaning of this struct's volume member is unspecified.
//   int has_volume;
//   // The volume can be set. 
//   // If not set, the volume can still change even though clients can't control the volume.
//   int volume_writable;
//   // The volume of this sink input.
//   pa_cvolume volume;
  
//   // Latency due to buffering in sink input, see pa_timing_info for details.
//   pa_usec_t buffer_usec;
//   // Latency of the sink device, see pa_timing_info for details.
//   pa_usec_t sink_usec;

//   // Index of the module this sink input belongs to, or PA_INVALID_INDEX
//   uint32_t owner_module;
//   // Driver name
//   const char *driver;
//   // Property list
//   pa_proplist *proplist;
//   // Stream format information.
//   pa_format_info *format;
// } pa_sink_input_info;

@implementation PASinkInput

@synthesize context;
@synthesize index;
@synthesize name;
@synthesize clientIndex;
@synthesize sinkIndex;
@synthesize mediaRole;

@synthesize hasVolume;
@synthesize isVolumeWritable;

@synthesize channelCount;
@synthesize balance;
@synthesize channelVolumes;
@synthesize corked;

@synthesize mute;

- (void)dealloc
{
  self.name = nil;
  self.channelVolumes = nil;

  [super dealloc];
}

- (void)_updateVolume:(const pa_sink_input_info *)info
{
  NSMutableArray *vol;
  NSNumber       *v;
  BOOL           isVolumeChanged = NO;
  CGFloat        balance;

  self.hasVolume = info->has_volume;
  self.isVolumeWritable = info->volume_writable;

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
    self.channelVolumes = [[NSArray alloc] initWithArray:vol];
  }
  [vol release];
}
- (void)_updateChannels:(const pa_sink_input_info *)info
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
- (void)_updateMediaRole:(pa_sink_input_info *)info
{
  const char *media_role = pa_proplist_gets(info->proplist, PA_PROP_MEDIA_ROLE);

  if (media_role != NULL) {
    self.mediaRole = [[NSString alloc] initWithCString:media_role];
  }
  else {
    self.mediaRole = nil;
  }
}


- (id)updateWithValue:(NSValue *)val
{
  pa_sink_input_info *info = NULL;
  NSMutableArray *vol;
  NSNumber *v;
  
  //Zinfo = malloc(sizeof(const pa_sink_input_info));
  //Z[val getValue:info];
  info = [val pointerValue];

  self.name = [[NSString alloc] initWithCString:info->name];

  self.index = info->index;
  self.clientIndex = info->client;
  self.sinkIndex = info->sink;
  
  self.mute = info->mute;
  self.corked = info->corked;

  [self _updateVolume:info];
  [self _updateChannels:info];
  [self _updateMediaRole:info];

 
  //Zfree((void *)info);

  return self;
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
  
  o = pa_context_set_sink_input_volume(self.context, self.index, new_volume, NULL, self);
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
  pa_cvolume   *volume;
  pa_operation *o;

  volume = malloc(sizeof(pa_cvolume));
  pa_cvolume_init(volume);
  pa_cvolume_set(volume, self.channelCount, self.volume);
  
  pa_cvolume_set_balance(volume, _channel_map, balance);
  o = pa_context_set_sink_input_volume(self.context, self.index, volume, NULL, self);
  if (o) {
    pa_operation_unref(o);
  }
  
  free(volume);

  //process events right after
  [[NSRunLoop currentRunLoop] runUntilDate:
    [NSDate dateWithTimeIntervalSinceNow:0.0]];
}
- (void)applyMute:(BOOL)isMute
{
  pa_operation *o;
  
  o = pa_context_set_sink_input_mute(self.context, self.index, isMute, NULL, NULL);
  if (o) {
    pa_operation_unref(o);
  }
}

@end
