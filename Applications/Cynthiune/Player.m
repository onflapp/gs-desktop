/* Player.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004  Wolfgang Sourdeau
 *               2012 The Free Software Foundation
 *
 * Author: Wolfgang Sourdeau <wolfgang@contre.com>
 *         Riccardo Mottola <rm@gnu.org>
 *      
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

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>

#import <Cynthiune/Format.h>
#import <Cynthiune/Output.h>
#import <Cynthiune/Preference.h>

#import <string.h>

#ifdef GOOM
#import <goom/goom.h>
#endif

#import "GeneralPreference.h"

#define PLAYER_M 1
#import "Player.h"

static NSNotificationCenter *nc = nil;

NSString *PlayerPlayingNotification = @"PlayerPlayingNotification";
NSString *PlayerStoppedNotification = @"PlayerStoppedNotification";
NSString *PlayerPausedNotification = @"PlayerPausedNotification";
NSString *PlayerResumedNotification = @"PlayerResumedNotification";
NSString *PlayerSongEndedNotification = @"PlayerSongEndedNotification";

@implementation Player : NSObject

+ (void) initialize
{
  nc = [NSNotificationCenter defaultCenter];
}

- (id) init
{
  if ((self = [super init]))
    {
      output = nil;
      outputIsThreaded = NO;
      stream = nil;
      streamLock = [NSLock new];
      delegate = nil;
      paused = NO;
      playing = NO;
      awaitingNewStream = NO;
      closingThread = NO;
      streamsToClose = [NSMutableArray new];
      rate = 0;
      channels = 0;
      endianness = LittleEndian;
#ifdef GOOM
      feedGoom = NO;
      bufferedSize = 0;
//       goomBufferPtr = goomBuffer;
//       lock = [NSLock new];
#endif
    }

  return self;
}

- (void) dealloc
{
  if (delegate)
    [nc removeObserver: delegate name: nil object: self];
  [streamsToClose release];
  [streamLock release];
  [super dealloc];
}

- (void) setDelegate: (id) anObject
{
  if (delegate)
    [nc removeObserver: delegate name: nil object: self];

  delegate = anObject;

  if ([delegate respondsToSelector: @selector (playerPlaying:)])
    [nc addObserver: delegate
	selector: @selector (playerPlaying:)
	name: PlayerPlayingNotification
	object: self];
  if ([delegate respondsToSelector: @selector (playerStopped:)])
    [nc addObserver: delegate
	selector: @selector (playerStopped:)
	name: PlayerStoppedNotification
	object: self];
  if ([delegate respondsToSelector: @selector (playerPaused:)])
    [nc addObserver: delegate
	selector: @selector (playerPaused:)
	name: PlayerPausedNotification
	object: self];
  if ([delegate respondsToSelector: @selector (playerResumed:)])
    [nc addObserver: delegate
	selector: @selector (playerResumed:)
	name: PlayerResumedNotification
	object: self];
  if ([delegate respondsToSelector: @selector (playerSongEnded:)])
    [nc addObserver: delegate
	selector: @selector (playerSongEnded:)
	name: PlayerSongEndedNotification
	object: self];
}

- (id) delegate
{
  return delegate;
}

#ifdef GOOM

- (void) goomThread
{
  NSAutoreleasePool *pool;

  pool = [NSAutoreleasePool new];
  while (1)
    {
//       while ((unsigned int) goomBufferPtr
//              < (unsigned int) goomBuffer + 2048)
//       while (!bufferedSize)
//       while (!feedGoom)
      [NSThread sleepUntilDate:
                  [NSDate dateWithTimeIntervalSinceNow: 1.0 / 10]];
      goom_update (goom, goomBuffer, 0, .0, NULL, NULL);
//       bufferedSize = 0;
//       [lock lock];
//       memcpy (goomBuffer, goomBuffer + 2048, GOOM_BUFFER_SIZE - 2048);
//       goomBufferPtr -= 2048;
//       [lock unlock];
    }

  [pool release];
//   NSLog (@"goom thread exiting...");
}

- (void) _updateGoomWithBuffer: (char *) buffer
                       andSize: (unsigned int) size
{
  unsigned int feedSize;

  if ((bufferedSize + size) >= 2048)
    feedSize = 2048 - bufferedSize;
  else
    feedSize = size;
  memcpy (goomBuffer + bufferedSize, buffer, feedSize);

  bufferedSize += feedSize;
  if (bufferedSize == 2048)
    bufferedSize = 0;
}

#endif

- (void) _playLoopIteration
{
  unsigned char buffer[DEFAULT_BUFFER_SIZE];
  int size;
  NSData *streamChunk;

  size = [stream readNextChunk: buffer withSize: DEFAULT_BUFFER_SIZE];

  if (size > 0)
    {
      totalBytes += size;
      streamChunk = [NSData dataWithBytes: buffer length: size];
      [output playChunk: streamChunk];
#ifdef GOOM
      [self _updateGoomWithBuffer: buffer andSize: size];
#endif
    }
  else
    {
      awaitingNewStream = YES;
      [nc postNotificationName: PlayerSongEndedNotification object: self];
    }
}

- (void) _handleEndOfSong
{
  [nc postNotificationName: PlayerSongEndedNotification object: self];
}

- (void) _closePendingStreams
{
  static BOOL inProcess = NO;
  NSEnumerator *streamEnumerator;
  NSObject <Format> *streamToClose;

  if (!inProcess) {
    inProcess = YES;
    streamEnumerator = [streamsToClose reverseObjectEnumerator];
    streamToClose = [streamEnumerator nextObject];
    while (streamToClose) {
      [streamToClose streamClose];
      [streamToClose release];
      [streamsToClose removeObject: streamToClose];
      streamToClose = [streamEnumerator nextObject];
    }
    inProcess = NO;
  }
}

- (int) readNextChunk: (unsigned char *) buffer
             withSize: (unsigned int) bufferSize
{
  int inputSize;

  while (awaitingNewStream
         && !closingThread)
    [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];

  if ([streamsToClose count]) {
    [self performSelectorOnMainThread: @selector (_closePendingStreams)
          withObject: nil
          waitUntilDone: NO];
  }

  if (!closingThread)
    {
      [streamLock lock];
      inputSize = [stream readNextChunk: buffer withSize: bufferSize];
      [streamLock unlock];

      if (inputSize > 0)
        {
          totalBytes += inputSize;
#ifdef GOOM
      /* FIXME: should execute on main thread */
//       [self _updateGoomWithBuffer: buffer andSize: size];
#endif
        }
      else
        {
          awaitingNewStream = YES;
          inputSize = 0;
          [self performSelectorOnMainThread: @selector (_handleEndOfSong)
                withObject: nil
                waitUntilDone: NO];
        }
    }
  else
    inputSize = 0;

  return inputSize;
}

- (void) _reInitOutputIfNeeded: (NSObject <Format> *) newStream
{
  unsigned int newChannels;
  unsigned long newRate;
  Endianness newEndianness;

  newChannels = [newStream readChannels];
  newRate = [newStream readRate];
  newEndianness = [newStream endianness];

  if (rate != newRate
      || channels != newChannels
      || endianness != newEndianness)
    {
      if ([output prepareDeviceWithChannels: newChannels andRate: newRate withEndianness: newEndianness])
        {
          rate = newRate;
          channels = newChannels;
	  endianness = newEndianness;
        }
      else
        NSLog (@"error preparing output for %d channels at a rate of %lu",
               newChannels, newRate);
    }
}

- (void) setStream: (NSObject <Format> *) newStream
{
  NSObject <Format> *oldStream;
  totalBytes = 0;

  oldStream = stream;
  if (newStream)
    {
      [newStream retain];
      if (output)
        [self _reInitOutputIfNeeded: newStream];
      stream = newStream;
      if (awaitingNewStream)
        {
          awaitingNewStream = NO;
          if (!outputIsThreaded)
            [self _playLoopIteration];
        }
    }
  else
    stream = nil;

  if (oldStream)
    {
      if (outputIsThreaded)
        [streamsToClose addObject: oldStream];
      else
        {
          [oldStream streamClose];
          [oldStream release];
        }
    }
}

- (int) timer
{
  return ((rate && channels)
          ? totalBytes / (rate * channels * 2)
          : 0);
}

- (BOOL) playing
{
  return playing;
}

- (void) _ensureOutput
{
  GeneralPreference *generalPreference;
  Class outputClass;

  generalPreference = [GeneralPreference instance];
  outputClass = [generalPreference preferredOutputClass];
  if (output && [output class] != outputClass)
    {
      [output release];
      output = nil;
      rate = 0;
      channels = 0;
      endianness = LittleEndian;
      [self _reInitOutputIfNeeded: stream];
    }

  if (!output)
    {
      outputIsThreaded = [outputClass isThreaded];
      output = [outputClass new];
      [output setParentPlayer: self];
      [self _reInitOutputIfNeeded: stream];
    }
}

- (void) play
{
  [self _ensureOutput];

  if ([output openDevice])
    {
      playing = YES;
      [nc postNotificationName: PlayerPlayingNotification
          object: self];
      if (outputIsThreaded)
        {
          closingThread = NO;
          [output startThread];
        }
      else
        [self _playLoopIteration];
    }
}

- (void) stop
{
  if (outputIsThreaded
      && !paused)
    {
      closingThread = YES;
      [output stopThread];
    }
  [output closeDevice];
  [stream streamClose];
  [stream release];
  stream = nil;
  playing = NO;
  if (paused)
    {
      paused = NO;
      [nc postNotificationName: PlayerResumedNotification object: self];
    }
  awaitingNewStream = NO;
  [nc postNotificationName: PlayerStoppedNotification object: self];
}

- (void) setPaused: (BOOL) aBool
{
  if (!paused && aBool)
    {
      paused = YES;
      if (outputIsThreaded)
        [output stopThread];
      [nc postNotificationName: PlayerPausedNotification object: self];
    }
  else if (paused && !aBool)
    {
      paused = NO;
      if (outputIsThreaded)
        [output startThread];
      else
        [self _playLoopIteration];
      [nc postNotificationName: PlayerResumedNotification object: self];
    }
}

- (BOOL) paused
{
  return paused;
}

- (void) seek: (unsigned int) seconds
{
  [streamLock lock];
  [stream seek: seconds];
  [streamLock unlock];
  totalBytes = seconds * rate * channels * 2;
}

- (void) chunkFinishedPlaying
{
  if (playing && !paused)
    [self _playLoopIteration];
}

#ifdef GOOM

- (void) setGoom: (PluginInfo *) goomPI
{
  BOOL start;

  start = (!goom);
  goom = goomPI;
  if (start)
    [NSThread detachNewThreadSelector: @selector (goomThread)
              toTarget: self
              withObject: nil];
}

#endif

@end
