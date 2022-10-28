/* GraphWriter.m - this file is part of Cynthiune
 *
 * Copyright (C) 2004 Wolfgang Sourdeau
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

#import <AppKit/AppKit.h>
#import <unistd.h>
#import <esd.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>
#import <Cynthiune/utils.h>

#import "GraphWriter.h"

#define LOCALIZED(X) _b ([GraphWriter class], X)

@implementation GraphWriter : NSObject

- (void) setParentPlayer: (id) aPlayer;
{
  parentPlayer = aPlayer;
}

+ (NSArray *) bundleClasses
{
  return [NSArray arrayWithObject: [self class]];
}

- (id) init
{
  if ((self = [super init]))
    {
      buffer = NULL;
      bufferLen = 0;
      remaining = 0;
      position = NULL;
      stamp = 0.0;
    }

  return self;
}

- (BOOL) openDevice
{
  return YES;
}

- (BOOL) prepareDeviceWithChannels: (unsigned int) numberOfChannels
                           andRate: (unsigned long) sampleRate
{
  channels = numberOfChannels;
  rate = sampleRate;

  if (buffer)
    free (buffer);
  bufferLen = sizeof (short) * numberOfChannels * numberOfSeconds * sampleRate;
//   NSLog (@"bufferLen = %d bytes", bufferLen);
  remaining = bufferLen;
  buffer = malloc (bufferLen);
  position = (char *) buffer;

  return YES;
}

- (void) playChunk: (NSData *) chunk
{
  unsigned int length;
  const char *sourcePtr;

  if (remaining > 0)
    {
      sourcePtr = [chunk bytes];
      length = [chunk length];
      if (remaining < length)
        length = remaining;

      memcpy (position, sourcePtr, length);
      remaining -= length;
      position += length;
    }

  [NSTimer scheduledTimerWithTimeInterval: 0.001
           target: parentPlayer
           selector: @selector (chunkFinishedPlaying)
           userInfo: nil
           repeats: NO];

//   [parentPlayer chunkFinishedPlaying];
}

- (void) _writeBuffer
{
  unsigned int counter;
  signed short *sample;
  FILE *graphFile;

  graphFile = fopen (graphFilename, "w+b");
  if (graphFile)
    {
      for (counter = 0;
           counter < numberOfSeconds * rate * channels;
           counter += channels)
        {
          sample = buffer + counter;
          if (channels == 1)
            fprintf (graphFile, "%d,%d\n", counter, *sample);
          else
            fprintf (graphFile,
                     "%d,%d,%d\n",
                     (counter / 2), *sample, *(sample + 1));
        }
      fclose (graphFile);
    }
  else
    NSLog (@"fopen returned null: %s", strerror (errno));
}

- (void) closeDevice
{
  if (buffer)
    {
      [self _writeBuffer];
      free (buffer);
      buffer = NULL;
    }
}

@end
