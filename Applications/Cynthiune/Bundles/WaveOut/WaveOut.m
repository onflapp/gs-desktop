/* WaveOut.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005  Wolfgang Sourdeau
 *               2012 The Free Software Foundation Inc
 *
 * Author: Wolfgang Sourdeau <wolfgang@contre.com>
 *         Riccardo Mottola <rm@gnu.org>
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

#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>
#import <Cynthiune/Preference.h>

#include <windows.h>

#import "WaveOut.h"

#define LOCALIZED(X) _b ([WaveOut class], X)

static void CALLBACK
_waveCallback (HWAVE hWave, UINT uMsg, DWORD dwInstance,
               DWORD dwParam1, DWORD dwParam2)
{
  CWaveOut *self;
  WAVEHDR **slot;

  if (uMsg == WOM_DONE)
    {
      self = (CWaveOut *) dwInstance;

      slot = self->blocks;
      while (*slot)
        slot++;
      *slot = (WAVEHDR *) dwParam1;
    }
}

static void
FreeBlock (LPWAVEHDR waveBlock)
{
  free (waveBlock->lpData);
  free (waveBlock);
}

@implementation WaveOut : NSObject

+ (NSString *) bundleDescription
{
  return @"Output plug-in for the WaveOut device";
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

- (void) setParentPlayer: (id) aPlayer;
{
  parentPlayer = aPlayer;
}

- (id) init
{
  if ((self = [super init]))
    {
      parentPlayer = nil;
      nBlocks = 0;
      dev = NULL;
      blocks = calloc (MAX_BLOCKS, sizeof (WAVEHDR *));
    }

  return self;
}

- (void) dealloc
{
  free (blocks);
  [super dealloc];
}

- (BOOL) prepareDeviceWithChannels: (unsigned int) numberOfChannels
                           andRate: (unsigned long) sampleRate
		    withEndianness: (Endianness) e
{
  return (numberOfChannels != 0 && sampleRate != 0);
}

- (void) _loopIteration
{
  LPWAVEHDR wh;
  MMRESULT res;
  char errorBuffer[100];

  wh = calloc (sizeof (WAVEHDR), 1);
  wh->dwBufferLength = bufferSize;
  wh->lpData = malloc (bufferSize);
  memcpy (wh->lpData, buffer, bufferSize);

  res = waveOutPrepareHeader (dev, wh, sizeof (WAVEHDR));
  if (res == MMSYSERR_NOERROR)
    {
      res = waveOutWrite(dev, wh, sizeof (WAVEHDR));
      if (res == MMSYSERR_NOERROR)
        nBlocks++;
      else
        {
          waveOutGetErrorText (res, errorBuffer, 100);
          FreeBlock (wh);
          NSLog (@"error: %s", errorBuffer);
        }
    }
  else
    {
      waveOutGetErrorText (res, errorBuffer, 100);
      FreeBlock (wh);
      NSLog (@"error: %s", errorBuffer);
    }
}

- (void) _freeBlocks
{
  unsigned int count;
  WAVEHDR **slot;

  count = 0;
  while (count < MAX_BLOCKS && nBlocks)
    {
      slot = self->blocks + count;
      if (*slot)
        {
          waveOutUnprepareHeader (dev, *slot, sizeof (WAVEHDR));
          FreeBlock (*slot);
          *slot = NULL;
          nBlocks--;
        }

      count++;
    }
}

- (void) _threadLoop
{
  NSAutoreleasePool *pool;

  pool = [NSAutoreleasePool new];

  while (!stopRequested)
    {
      if (nBlocks >= MAX_BLOCKS)
        {
          [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.2]];
          [self _freeBlocks];
        }
      else
        {
          bufferSize = [parentPlayer readNextChunk: buffer
                                     withSize: DEFAULT_BUFFER_SIZE];
          if (bufferSize > 0)
            [self _loopIteration];
        }

      if ([pool autoreleaseCount] > 50)
        [pool emptyPool];
    }

  [self _freeBlocks];
  while (nBlocks > 0)
    {
      [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
      [self _freeBlocks];
    }
  stopRequested = NO;

  [pool release];
}

- (BOOL) openDevice
{
  BOOL result;
  MMRESULT res;
  WAVEFORMATEX outFormatex;

  result = NO;

  if (waveOutGetNumDevs ())
    {
      outFormatex.wFormatTag      = WAVE_FORMAT_PCM;
      outFormatex.wBitsPerSample  = 16;
      outFormatex.nChannels       = 2;
      outFormatex.nSamplesPerSec  = 44100; /* FIXME */
      outFormatex.nBlockAlign     = 4;
      outFormatex.nAvgBytesPerSec = (outFormatex.nSamplesPerSec
                                     * outFormatex.nBlockAlign);

      res = waveOutOpen (&dev, WAVE_MAPPER, &outFormatex,
                         (DWORD) _waveCallback, (DWORD) self,
                         CALLBACK_FUNCTION);

      if (res != MMSYSERR_NOERROR)
        {
          switch (res)
            {
            case MMSYSERR_ALLOCATED:
              MessageBox (NULL, "Device Is Already Open", "Error...", MB_OK);
              break;
            case MMSYSERR_BADDEVICEID:
              MessageBox (NULL, "The Specified Device Is out of range",
                          "Error...", MB_OK);
              break;
            case MMSYSERR_NODRIVER:
              MessageBox (NULL, "There is no audio driver in this system.",
                          "Error...", MB_OK);
              break;
            case MMSYSERR_NOMEM:
              MessageBox (NULL, "Unable to allocate sound memory.", "Error...",
                          MB_OK);
              break;
            case WAVERR_BADFORMAT:
              MessageBox (NULL, "This audio format is not supported.",
                          "Error...", MB_OK);
              break;
            case WAVERR_SYNC:
              MessageBox (NULL, "The device is synchronous.", "Error...",
                          MB_OK);
              break;
            default:
              MessageBox (NULL, "Unknown Media Error", "Error...", MB_OK);
              break;
            }
        }
      else
        {
          result = YES;
          waveOutReset (dev);
        }
    }

   return result;
}

- (void) closeDevice
{
  while (stopRequested)
    [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
  waveOutReset (dev);
  waveOutClose (dev);
}

- (BOOL) startThread
{
  [NSThread detachNewThreadSelector: @selector (_threadLoop)
            toTarget: self
            withObject: nil];

  return YES;
}

- (void) stopThread
{
  stopRequested = YES;
}

@end
