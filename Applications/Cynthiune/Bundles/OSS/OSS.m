/* OSS.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004 Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <wolfgang@contre.com>
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifndef _REENTRANT
#define _REENTRANT 1
#endif

#import <AppKit/NSApplication.h>

#import <Foundation/NSFileHandle.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSRunLoop.h>

#import <errno.h>
#import <sys/ioctl.h>
#ifdef __OpenBSD__
#import <soundcard.h>
#else
#import <sys/soundcard.h>
#endif

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>

#import "OSS.h"
#import "OSSPreference.h"

#define LOCALIZED(X) _b ([OSS class], X)
#define DspError(X) \
        NSLog (@"An error occured when sending '%s' ioctl to DSP:%s", \
               X, strerror(errno))

static NSNotificationCenter *nc;
static NSArray *loopModes;

@implementation OSS : NSObject

+ (void) initialize
{
  nc = [NSNotificationCenter defaultCenter];
  loopModes = [NSArray arrayWithObjects: NSDefaultRunLoopMode,
                       NSEventTrackingRunLoopMode, nil];
  [loopModes retain];
}

+ (NSString *) bundleDescription
{
  return @"Output plug-in for the Linux OSS driver";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2002-2004  Wolfgang Sourdeau",
                  nil];
}

+ (BOOL) isThreaded
{
  return NO;
}

+ (void) unload
{
  [loopModes release];
}

- (void) setParentPlayer: (id) aPlayer;
{
  parentPlayer = aPlayer;
}

- (id) init
{
  if ((self = [super init]))
    {
      parentPlayer = nil;
      dsp = nil;
    }

  return self;
}

- (BOOL) _setRateAndChannels
{  
  int dspFd, format;
  BOOL result;

  dspFd = [dsp fileDescriptor];
  result = NO;

  if (ioctl (dspFd, SNDCTL_DSP_RESET) == -1)
    DspError ("SNDCTL_DSP_RESET");
  else
    {
      format = AFMT_S16_LE;
      if (ioctl (dspFd, SNDCTL_DSP_SETFMT, &format) == -1)
          DspError ("SNDCTL_DSP_SETFMT");
      else
        {
          if (ioctl (dspFd, SNDCTL_DSP_SPEED, &rate) == -1)
            DspError ("SNDCTL_DSP_SPEED");
          else
            {
              if (ioctl (dspFd, SNDCTL_DSP_CHANNELS, &channels) == -1)
                DspError ("SNDCTL_DSP_CHANNELS");
              else
                result = YES;
            }
        }
    }

  return result;
}

- (BOOL) prepareDeviceWithChannels: (unsigned int) numberOfChannels
                           andRate: (unsigned long) sampleRate
		    withEndianness: (Endianness) e
{
  channels = numberOfChannels;
  rate = sampleRate;
  endianness = e;

  return ((dsp) ? [self _setRateAndChannels] : YES);
}

- (BOOL) openDevice
{
  OSSPreference *preference;
  BOOL result;

  preference = [OSSPreference instance];
  dsp = [NSFileHandle fileHandleForWritingAtPath: [preference dspDevice]];
  if (dsp)
    {
      [dsp retain];
      [nc addObserver: self
          selector: @selector (_writeCompleteNotification:)
          name: GSFileHandleWriteCompletionNotification
          object: dsp];
      result = [self _setRateAndChannels];
    }
  else 
    result = NO;

  return result;
}

- (void) closeDevice
{
  [dsp closeFile];
  [dsp release];
  dsp = nil;
}

- (void) _writeCompleteNotification: (NSNotification *) aNotification
{
  [parentPlayer chunkFinishedPlaying];
}

- (void) playChunk: (NSData *) chunk
{
  [dsp writeInBackgroundAndNotify: chunk forModes: loopModes];
}

@end
