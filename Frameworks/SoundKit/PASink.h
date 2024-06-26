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

#import <pulse/pulseaudio.h>
#import <Foundation/Foundation.h>

@interface PASink : NSObject
{
  pa_channel_map *_channel_map;

  NSUInteger cardIndex;
  NSUInteger index;
  pa_context *context;
  NSString   *name;
  NSString   *description;
  NSArray    *ports;

  NSInteger  flags;
  NSInteger  state;
  NSUInteger sampleRate;
  NSUInteger sampleChannelCount;
  NSInteger  sampleFormat;
  NSArray    *formats;

  // KVO-compliant
  NSString   *activePort;
  NSUInteger channelCount;
  NSUInteger volumeSteps;
  NSUInteger baseVolume;
  CGFloat    balance;
  NSArray    *channelVolumes;
  BOOL       mute;
}

@property (assign) NSUInteger cardIndex;
@property (assign) NSUInteger index;
@property (assign) pa_context *context;
@property (retain) NSString   *name;
@property (retain) NSString   *description;
@property (retain) NSArray    *ports;

@property (assign) NSInteger  flags;
@property (assign) NSInteger  state;
@property (assign) NSUInteger sampleRate;
@property (assign) NSUInteger sampleChannelCount;
@property (assign) NSInteger  sampleFormat;
@property (retain) NSArray    *formats;

// KVO-compliant
@property (retain) NSString   *activePort;
@property (assign) NSUInteger channelCount;
@property (assign) NSUInteger volumeSteps;
@property (assign) NSUInteger baseVolume;
@property (assign) CGFloat    balance;
@property (retain) NSArray    *channelVolumes;
@property (assign) BOOL       mute;

- (id)updateWithValue:(NSValue *)value;

- (void)applyActivePort:(NSString *)portName;
- (void)applyMute:(BOOL)isMute;
- (NSUInteger)volume;
- (void)applyVolume:(NSUInteger)v;
- (void)applyBalance:(CGFloat)balance;

- (pa_channel_map *)channel_map;
@end
