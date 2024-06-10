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

#import <Foundation/Foundation.h>
#import <pulse/pulseaudio.h>

@interface PASinkInput : NSObject
{
  pa_channel_map *_channel_map;

  pa_context *context;
  NSUInteger index;
  NSString   *name;
  NSUInteger clientIndex;
  NSUInteger sinkIndex;
  NSString   *mediaRole;

  BOOL       hasVolume;
  BOOL       isVolumeWritable;

  NSUInteger channelCount;
  CGFloat    balance;
  NSArray    *channelVolumes;
  BOOL       corked;

  BOOL  mute;
}

@property (assign) pa_context *context;
@property (assign) NSUInteger index;
@property (retain) NSString   *name;
@property (assign) NSUInteger clientIndex;
@property (assign) NSUInteger sinkIndex;
@property (retain) NSString   *mediaRole;

@property (assign) BOOL       hasVolume;
@property (assign) BOOL       isVolumeWritable;

@property (assign) NSUInteger channelCount;
@property (assign) CGFloat    balance;
@property (retain) NSArray    *channelVolumes;
@property (assign) BOOL       corked;

@property (assign)  BOOL  mute;

- (id)updateWithValue:(NSValue *)val;

- (NSUInteger)volume;
- (void)applyVolume:(NSUInteger)v;
- (void)applyBalance:(CGFloat)balance;
- (void)applyMute:(BOOL)isMute;

@end
