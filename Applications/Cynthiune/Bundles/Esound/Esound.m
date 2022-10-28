/* Esound.m - this file is part of Cynthiune
 *
 * Copyright (C) 2003, 2004 Wolfgang Sourdeau
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

#import <unistd.h>
#import <esd.h>

#import <AppKit/NSApplication.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSThread.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>
#import <Cynthiune/Preference.h>
#import <Cynthiune/utils.h>

#import "Esound.h"
#import "EsoundPreference.h"

#define LOCALIZED(X) _b ([Esound class], X)

static NSNotificationCenter *nc = nil;
static NSArray *loopModes;

@implementation Esound : NSObject

+ (void) initialize
{
  nc = [NSNotificationCenter defaultCenter];
  loopModes = [NSArray arrayWithObjects: NSDefaultRunLoopMode,
                       NSEventTrackingRunLoopMode, nil];
  [loopModes retain];
}

+ (void) unload
{
  [loopModes release];
}

+ (NSString *) bundleDescription
{
  return @"Output plug-in for the Esound sound daemon";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2003, 2004  Wolfgang Sourdeau",
                  nil];
}

+ (BOOL) isThreaded
{
  return NO;
}

- (void) setParentPlayer: (id) aPlayer;
{
  parentPlayer = aPlayer;
}

- (id) init
{
  if ((self = [super init]))
    {
      esd = nil;
    }

  return self;
}

- (int) _openSocket
{
  int esdSocket;
  NSString *hostString;
  EsoundPreference *esoundPreference;

  esoundPreference = [EsoundPreference instance];

  if ([esoundPreference socketIsTCP])
    {
      hostString = [esoundPreference tcpHostConnectString];
      esdSocket = esd_play_stream ((ESD_BITS16 | ESD_STREAM
                                    | ESD_PLAY | channels),
                                   rate, [hostString cString],
                                   "Cynthiune stream");
    }
  else
    esdSocket = esd_play_stream_fallback ((ESD_BITS16 | ESD_STREAM
                                           | ESD_PLAY | channels),
                                          rate, NULL,
                                          "Cynthiune stream");

  return esdSocket;
}

- (BOOL) openDevice
{
  int esdSocket, try;

  try = 0;
  esdSocket = [self _openSocket];
  while (esdSocket < 1 && try < 5)
    {
      try++;
      [NSThread sleepUntilDate:
                  [NSDate dateWithTimeIntervalSinceNow: 0.2]];
      esdSocket = [self _openSocket];
    }

  if (esdSocket > 0)
    {
      esd = [[NSFileHandle alloc] initWithFileDescriptor: esdSocket];
      if (esd)
        [nc addObserver: self
            selector: @selector (_writeCompleteNotification:)
            name: GSFileHandleWriteCompletionNotification
            object: esd];
      else
        close (esdSocket);
    }

  return (esd != nil);
}

- (void) closeDevice
{
  [esd closeFile];
  [esd release];
  esd = nil;
}

- (BOOL) prepareDeviceWithChannels: (unsigned int) numberOfChannels
                           andRate: (unsigned long) sampleRate
		    withEndianness: (Endianness) e
{
  BOOL result;

  result = YES;
  rate = sampleRate;

  switch (numberOfChannels)
    {
    case 1:
      channels = ESD_MONO;
      break;
    case 2:
      channels = ESD_STEREO;
      break;
    default:
      result = NO;
    }

  if (result && esd)
    {
      [self closeDevice];
      result = [self openDevice];
    }

  return result;
}

- (void) _writeCompleteNotification: (NSNotification *) aNotification
{
  [parentPlayer chunkFinishedPlaying];
}

- (void) playChunk: (NSData *) chunk
{
  [esd writeInBackgroundAndNotify: chunk forModes: loopModes];
}

@end
