/* AudioFile.m - this file is part of Cynthiune
 *
 * Copyright (C) 2004 Wolfgang Sourdeau
 *               2012 The Free Software Foundation
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
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

#import <Foundation/Foundation.h>
#include <audiofile.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Format.h>
#import <Cynthiune/utils.h>

#import "AudioFileBundle.h"

@implementation AudioFile : NSObject

+ (void) initialize
{
  afSetErrorHandler (NULL);
}

// CynthiuneBundle Protocol
+ (NSString *) bundleDescription
{
  return @"Extension plug-in for AIFF, AU, AVR, IFF, NIST, SND and WAV audio formats";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2004  Wolfgang Sourdeau",
                  nil];
}

+ (NSArray *) compatibleTagBundles
{
  return nil;
}

// Player Protocol
+ (NSArray *) acceptedFileExtensions
{
  return [NSArray arrayWithObjects: @"aif", @"aifc", @"aiff", @"au", @"avr",
                  @"iff", @"nist", @"snd", @"wav", nil];
}

+ (BOOL) canTestFileHeaders
{
  return YES;
}

+ (BOOL) streamTestOpen: (NSString *) fileName
{
  AFfilehandle testFile;
  int vers, fileFormat;
  BOOL result;

  result = NO;
  testFile = afOpenFile ([fileName cString], "r", NULL);
  if (testFile)
    {
      fileFormat = afGetFileFormat (testFile, &vers);
      result = (fileFormat != AF_FILE_UNKNOWN);
      afCloseFile (testFile);
    }

  return result;
}

- (BOOL) streamOpen: (NSString *) fileName
{
  int format;

  file = afOpenFile ([fileName cString], "r", NULL);

  if (file)
    {
      frameSize = afGetVirtualFrameSize(file, AF_DEFAULT_TRACK, 1);
      afGetVirtualSampleFormat (file, AF_DEFAULT_TRACK, &format, &width);
      if (format == AF_SAMPFMT_UNSIGNED)
        afSetVirtualSampleFormat (file, AF_DEFAULT_TRACK,
                                  AF_SAMPFMT_TWOSCOMP, width);
    }

  return (file != NULL);
}

- (void) streamClose
{
  afCloseFile (file);
}

- (int) _readNext8BitChunk: (unsigned char *) buffer
                  withSize: (unsigned int) bufferSize
{
  int size, conversionSize;
  unsigned char *conversionBuffer;

  conversionBuffer = malloc (bufferSize);
  conversionSize =
    (int) (afReadFrames (file, AF_DEFAULT_TRACK,
                         conversionBuffer,
                         (int) (bufferSize / frameSize / 2)));
  size = conversionSize * frameSize * 2;
  convert8to16 (conversionBuffer, buffer, conversionSize);
  free (conversionBuffer);

  return size;
}

- (int) readNextChunk: (unsigned char *) buffer
	     withSize: (unsigned int) bufferSize
{
  return ((width == 16)
          ? (int) (afReadFrames (file, AF_DEFAULT_TRACK, buffer,
                                 (int) (bufferSize / frameSize))
                   * frameSize)
          : [self _readNext8BitChunk: buffer withSize: bufferSize] );
}

- (unsigned int) readChannels
{
  return afGetChannels (file, AF_DEFAULT_TRACK);
}

- (unsigned long) readRate
{
  return (unsigned long) afGetRate (file, AF_DEFAULT_TRACK);
}

- (Endianness) endianness
{
  return NativeEndian;
}

- (unsigned int) readDuration
{
  return (afGetTrackBytes (file, AF_DEFAULT_TRACK)
          / (afGetChannels (file, AF_DEFAULT_TRACK)
             * afGetRate (file, AF_DEFAULT_TRACK)
             * width / 8));
}

- (NSString *) _getAudioFileIDOfType: (int) idType
                             withMax: (int) max
{
  int *ids;
  int id, count, size;
  NSString *result;
  char *cResult;

  result = @"";

  ids = malloc (max);
  afGetMiscIDs (file, ids);
  for (count = 0; count < max; count++)
    {
      id = *(ids + count);
      if (afGetMiscType (file, id) == idType)
        {
          size = afGetMiscSize (file, id);
          if (size > 0)
            {
              cResult = malloc (size + 1);
              *(cResult + size) = 0;
              afReadMisc (file, id, cResult, size);
              result = [NSString stringWithCString: cResult];
              free (cResult);
            }
        }
    }
  free (ids);

  return result;
}

- (NSString *) _getAudioFileIDOfType: (int) idType
{
  int max;
  NSString *result;

  max = afGetMiscIDs (file, NULL);
  if (max > 0)
    result = [self _getAudioFileIDOfType: idType withMax: max];
  else
    result = @"";

  return result;;
}

- (NSString *) readTitle
{
  return [self _getAudioFileIDOfType: AF_MISC_NAME];
}

- (NSString *) readGenre
{
  return @"";
}

- (NSString *) readArtist
{
  return [self _getAudioFileIDOfType: AF_MISC_AUTH];
}

- (NSString *) readAlbum
{
  return @"";
}

- (NSString *) readYear
{
  return [self _getAudioFileIDOfType: AF_MISC_ICRD];
}

- (NSString *) readTrackNumber
{
  return @"";
}

- (BOOL) isSeekable
{
  return NO;
}

- (void) seek: (unsigned int) aPos
{
}

@end
