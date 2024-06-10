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

#include <pulse/ext-stream-restore.h>

#import "PAClient.h"
#import "PAStream.h"

// typedef struct pa_ext_stream_restore_info {
//   const char     *name;
//   int            mute;
//   pa_channel_map channel_map;
//   pa_cvolume     volume;
//   const char     *device;
// } pa_ext_stream_restore_info;

@implementation PAStream

@synthesize context;
@synthesize name;
@synthesize deviceName;

@synthesize volume;
@synthesize balance;
@synthesize mute;

- (void)dealloc
{
  if (info_copy) {
    free(info_copy);
  }
  [super dealloc];
}

- (NSUInteger)_volumeForInfo:(pa_ext_stream_restore_info *)info
{
  NSUInteger v, i;

  for (i = 0, v = 0; i < info->volume.channels; i++) {
    if (info->volume.values[i] > v)
      v = info->volume.values[i];
  }
  
  return v;
}

- (void)_updateMute:(pa_ext_stream_restore_info *)info
{
  BOOL isMute = info->mute ? YES : NO;

  if (self.mute != isMute) {
    self.mute = isMute;
  }
}

- (void)_updateBalance:(pa_ext_stream_restore_info *)info
{
  float balance = pa_cvolume_get_balance(&info->volume, &info->channel_map);

  if (self.balance != balance) {
    self.balance = balance;
  }
}

- (void)_updateVolume:(pa_ext_stream_restore_info *)info
{
  NSUInteger volume, i;

  for (i = 0, volume = 0; i < info->volume.channels; i++) {
    if (info->volume.values[i] > volume)
      volume = info->volume.values[i];
  }
  
  if (self.volume != volume) {
    self.volume = volume;
  }
}

- (id)updateWithValue:(NSValue *)value
{
  const pa_ext_stream_restore_info *info;
  
  //Zinfo = malloc(sizeof(const pa_ext_stream_restore_info));
  //Z[value getValue:(void *)info];
  info = [value pointerValue];

  if (info_copy == NULL) {
    info_copy = malloc(sizeof(struct pa_ext_stream_restore_info));
  }
  memcpy(info_copy, info, sizeof(*info));

  /****/
  self.name = [[NSString alloc] initWithCString:info->name];

  [self _updateMute:info_copy];
  [self _updateBalance:info_copy];
  [self _updateVolume:info_copy];
  // self.volume = [self _volumeForInfo:info_copy];
  /***/

  //Zfree((void *)info);

  return self;
}

- (NSString *)clientName
{
  NSArray *comps = [self.name componentsSeparatedByString:@":"];

  if ([comps count] > 1) {
    return [comps objectAtIndex:1];
  }

  return self.name;
}
- (NSString *)typeName
{
  NSArray *comps = [self.name componentsSeparatedByString:@":"];

  if ([comps count] > 1) {
    return [comps objectAtIndex:0];
  }

  return self.name;
}

- (void)applyVolume:(NSUInteger)volume
{
  pa_operation *o;
  
  NSUInteger i;
  for (i = 0; i < info_copy->volume.channels; i++) {
    info_copy->volume.values[i] = volume;
  }

  o = pa_ext_stream_restore_write(self.context, PA_UPDATE_REPLACE, info_copy,
                                  1, YES, NULL, NULL);
  if (o) {
    pa_operation_unref(o);
  }
}
- (void)applyBalance:(CGFloat)balance
{
  pa_operation *o;
  
  pa_cvolume_set_balance(&info_copy->volume, &info_copy->channel_map, balance);
  
  o = pa_ext_stream_restore_write(self.context, PA_UPDATE_REPLACE, info_copy,
                              1, YES, NULL, NULL);
  if (o) {
    pa_operation_unref(o);
  }
}
- (void)applyMute:(BOOL)isMute
{
  pa_operation *o;
  
  info_copy->mute = isMute;
  o = pa_ext_stream_restore_write(self.context, PA_UPDATE_REPLACE, info_copy,
                                  1, YES, NULL, NULL);
  if (o) {
    pa_operation_unref(o);
  }
}

@end
