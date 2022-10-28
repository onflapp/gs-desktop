/* aRts.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
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

#import <Foundation/NSData.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSThread.h>

#import <artsc.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>
#import <Cynthiune/Preference.h>

#import "aRts.h"

#define LOCALIZED(X) _b ([aRts class], X)
#define artsStreamName "Cynthiune stream"

@implementation aRts : NSObject

+ (NSString *) bundleDescription
{
  return @"Output plug-in for the aRts sound daemon";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2005  Wolfgang Sourdeau",
                  nil];
}

+ (BOOL) isThreaded
{
  return YES;
}

- (id) init
{
  if ((self = [super init]))
    {
      outputStream = NULL;
      channels = 0;
      rate = 0;
      stopRequested = NO;
    }

  return self;
}

- (void) setParentPlayer: (id) aPlayer;
{
  parentPlayer = aPlayer;
}

- (BOOL) prepareDeviceWithChannels: (unsigned int) numberOfChannels
                           andRate: (unsigned long) sampleRate
		    withEndianness: (Endianness) e
{
  BOOL result;

  channels = numberOfChannels;
  rate = sampleRate;

  if (outputStream)
    {
      arts_close_stream (outputStream);
      outputStream = arts_play_stream (rate, 16, channels, artsStreamName);
      arts_stream_set (outputStream, ARTS_P_BLOCKING, 1);
      result = (outputStream != NULL);
    }
  else
    result = YES;

  return result;
}

- (BOOL) _launchServer
{
  NSTask *artsdTask;
  NSString *artsdPath;

  artsdTask = [NSTask new];
  [artsdTask autorelease];
  artsdPath = [NSString stringWithCString: ARTSD];
  [artsdTask setLaunchPath: artsdPath];
  [artsdTask launch];

  [NSThread sleepUntilDate:
              [NSDate dateWithTimeIntervalSinceNow: 0.2]];

  return [artsdTask isRunning];
}

- (BOOL) openDevice
{
  BOOL result;
  int code;

  if (outputStream)
    result = YES;
  else
    {
      /* FIXME: should add code to spawn the daemon */
      code = arts_init ();
      if (code == ARTS_E_NOSERVER)
        if ([self _launchServer])
          code = arts_init ();
      if (code == 0)
        {
          outputStream = arts_play_stream (rate, 16, channels, artsStreamName);
          arts_stream_set (outputStream, ARTS_P_BLOCKING, 1);
          result = (outputStream != NULL);
        }
      else
        {
          NSLog (@"failure opening device:\n%d, %s", code, arts_error_text (code));
          result = NO;
        }
    }

  return result;
}

- (void) closeDevice
{
  while (stopRequested)
    [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
  arts_close_stream (outputStream);
  outputStream = NULL;
  arts_free ();
}

- (void) threadLoop
{
  NSAutoreleasePool *pool;
  int bufferSize;

  pool = [NSAutoreleasePool new];

  while (!stopRequested)
    {
      bufferSize = [parentPlayer readNextChunk: buffer
                                 withSize: DEFAULT_BUFFER_SIZE];
      if (bufferSize > 0)
        arts_write (outputStream, buffer, bufferSize);

      if ([pool autoreleaseCount] > 50)
        [pool emptyPool];
    }

  stopRequested = NO;
  [pool release];
}

- (BOOL) startThread
{
  [NSThread detachNewThreadSelector: @selector (threadLoop)
            toTarget: self
            withObject: nil];

  return YES;
}

- (void) stopThread
{
  stopRequested = YES;
}

@end
