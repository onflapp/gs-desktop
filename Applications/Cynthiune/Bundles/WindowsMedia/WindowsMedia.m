/* WindowsMedia.m - this file is part of Cynthiune
 *
 * Copyright (C) 2004, 2005 Wolfgang Sourdeau
 *               2012 The Free Software Foundation
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
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
#import <Foundation/NSString.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Format.h>

#import "WindowsMedia.h"

#define LOCALIZED(X) _b ([WindowsMedia class], X)

@implementation WindowsMedia : NSObject

+ (NSString *) bundleDescription
{
  return @"Extension plug-in for the ASF/WMA audio formats";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2004  Wolfgang Sourdeau",
                  nil];
}

+ (NSArray *) compatibleTagBundles
{
  return [NSArray arrayWithObjects: @"ASFTags", nil];
}

- (id) init
{
  if ((self = [super init]))
    {
      file = NULL;
      stream = NULL;
      frameBuffer = NULL;
      framePtr = NULL;
      frameSize = 0;
      remaining = 0;

      channels = 0;
      rate = 0;
      duration = 0;
    }

  return self;
}

- (BOOL) streamOpen: (NSString *) fileName
{
  BOOL result;

  result = NO;

  file = WMFileOpen ([fileName cString]);
  if (file)
    {
      stream = WMFileGetAudioStream (file);
      if (stream)
        {
          WMStreamGetInfos (stream, &channels, &rate, &duration);
          WMStreamStartStreaming (stream);
          result = YES;
        }
      else
        {
          WMFileClose (file);
          file = NULL;
        }
    }

  return result;
}

+ (BOOL) canTestFileHeaders
{
  return YES;
}

+ (BOOL) streamTestOpen: (NSString *) fileName
{
  WMFile *testFile;
  BOOL result;

  result = NO;

  testFile = WMFileOpen ([fileName cString]);
  if (testFile)
    {
      result = (WMFileAudioStreamCount (testFile)
                && WMFileGetAudioStream (testFile));
      WMFileClose (testFile);
    }

  return result;
}

+ (NSString *) errorText: (int) error
{
  return @"";
}

- (int) readNextChunk: (unsigned char *) buffer
	     withSize: (unsigned int) bufferSize
{
  int result;
  unsigned int bytes, readBytes, readSamples;

  if (!remaining)
    {
      if (frameBuffer)
        free (frameBuffer);
      frameSize = WMStreamGetFrameSize (stream);
      frameBuffer = malloc (frameSize);

      framePtr = frameBuffer;
      result = WMStreamReadFrames (stream, frameBuffer, frameSize, frameSize,
                                   &readSamples, &readBytes);

      remaining = ((result > -1) ? readBytes : 0);
    }

  bytes = ((bufferSize < remaining) ? bufferSize : remaining);
  memcpy (buffer, framePtr, bytes);
  framePtr += bytes;
  remaining -= bytes;

  return bytes;
}

- (int) lastError
{
  return 0;
}

- (unsigned int) readChannels
{
  return channels;
}

- (unsigned long) readRate
{
  return rate;
}

- (Endianness) endianness
{
  return NativeEndian;
}

- (unsigned int) readDuration
{
  return duration;
}

- (void) streamClose
{
  WMStreamStopStreaming (stream);
  if (frameBuffer)
    free (frameBuffer);
  if (stream)
    WMStreamClose (stream);
  if (file)
    WMFileClose (file);
}

// Player Protocol
+ (NSArray *) acceptedFileExtensions
{
  return [NSArray arrayWithObjects: @"asf", @"wma", nil];
}

- (BOOL) isSeekable
{
  return YES;
}

- (void) seek: (unsigned int) aPos
{
  WMStreamSeekTime (stream, aPos);
}

@end
