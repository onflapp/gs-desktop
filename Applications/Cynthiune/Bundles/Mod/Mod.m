/* Mod.m - this file is part of Cynthiune
 *
 * Copyright (C) 2004 Rob Burns, Gurkan Sengun, Wolfgang Sourdeau
 *
 * Authors: Rob Burns <rburns@softhome.net>
 *          Gurkan Sengun <gurkan@linuks.mine.nu>
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

#import <ctype.h>
#import <stdlib.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSString.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Format.h>
#import <Cynthiune/utils.h>

#import <modplug.h>

#import "Mod.h"

#define LOCALIZED(X) _b ([Mod class], X)

#define NBR_OF_CHANNELS 2
#define FRAME_RATE 44100

@implementation Mod : NSObject

+ (void) initialize
{
  ModPlug_Settings settings;

#ifdef __MACOSX__
  [super initialize];
#endif
  ModPlug_GetSettings (&settings);

  settings.mFlags |= MODPLUG_ENABLE_OVERSAMPLING;
  settings.mResamplingMode = MODPLUG_RESAMPLE_FIR;
  settings.mChannels = NBR_OF_CHANNELS;
  settings.mBits = 16;
  settings.mFrequency = FRAME_RATE;

  ModPlug_SetSettings (&settings);
}

+ (NSString *) bundleDescription
{
  return @"Extension plug-in for various music tracker file formats";
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

- (BOOL) streamOpen: (NSString *) fileName;
{
  NSFileHandle *fileHandle;
  NSData *content;
  BOOL result;

  result = NO;
  fileHandle = [NSFileHandle fileHandleForReadingAtPath: fileName];

  if (fileHandle)
    {
      content = [fileHandle readDataToEndOfFile];
      _mp_file = ModPlug_Load ([content bytes], [content length]);
      if (_mp_file)
        result = YES;
      else
        NSLog (@"Mod: could not load '%@'", fileName);
      [fileHandle closeFile];
    }
  else
    NSLog (@"Mod: no native handle...");

  return result;
}

+ (BOOL) canTestFileHeaders
{
  return NO;
}

+ (BOOL) streamTestOpen: (NSString *) fileName
{
  return NO;
}

- (int) readNextChunk: (unsigned char*) buffer
	     withSize: (unsigned int) bufferSize
{
  int count;

  if (_mp_file)
    {
      count = ModPlug_Read (_mp_file, buffer, bufferSize);
#if (BYTE_ORDER == BIG_ENDIAN)
      invertBytesInBuffer ((char *) buffer, count);
#endif
    }
  else
    count = -1;

  return count;
}

- (unsigned int) readChannels
{
  return NBR_OF_CHANNELS;
}

- (unsigned long) readRate
{
  return FRAME_RATE;
}

- (Endianness) endianness
{
  return NativeEndian;
}

- (unsigned int) readDuration
{
  return (ModPlug_GetLength (_mp_file) / 1000);
}

- (NSString *) readTitle
{
  return [NSString stringWithCString: ModPlug_GetName (_mp_file)];
}

- (NSString *) readGenre
{
  return @"";
}

- (NSString *) readArtist
{
  return @"";
}

- (NSString *) readAlbum
{
  return @"";
}

- (NSString *) readYear
{
  return @"";
}

- (NSString *) readTrackNumber
{
  return @"";
}

- (void) streamClose
{
  ModPlug_Unload (_mp_file);
  _mp_file = NULL;
}

// Player Protocol
+ (NSArray *) acceptedFileExtensions
{
  return [NSArray arrayWithObjects:
             @"669", @"amf", @"ams", @"dbm", @"dmf", @"dsm", @"far", @"it",
             @"j2b", @"mdl", @"med", @"mod", @"mt2", @"mtm", @"okt", @"psm",
             @"ptm", @"s3m", @"stm", @"ult", @"umx", @"mod", @"xm", nil];
}

- (BOOL) isSeekable
{
  return YES;
}

- (void) seek: (unsigned int) aPos
{
  ModPlug_Seek (_mp_file, aPos * 1000);
}

@end
