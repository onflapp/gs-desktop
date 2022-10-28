/* Ogg.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002, 2003 Wolfgang Sourdeau
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

#import <Foundation/Foundation.h>

#import <string.h>
#import <vorbis/vorbisfile.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Format.h>

#import "Ogg.h"

#define LOCALIZED(X) _b ([Ogg class], X)

static size_t
oggReadFunc (void *ptr, size_t size, size_t nmemb, void *datasource)
{
  NSFileHandle *fileHandle;
  NSData *data;
  size_t length;

  fileHandle = datasource;
  data = [fileHandle readDataOfLength: size * nmemb];
  length = [data length];
  memcpy (ptr, [data bytes], length);

  return length;
}

static int
oggSeekFunc (void *datasource, ogg_int64_t offset, int whence)
{
  NSFileHandle *fileHandle;
  unsigned long long realOffset;

  fileHandle = datasource;

  switch (whence)
    {
    case SEEK_SET:
      realOffset = offset;
      break;
    case SEEK_CUR:
      realOffset = [fileHandle offsetInFile] + offset;
      break;
    case SEEK_END:
      realOffset = [fileHandle seekToEndOfFile] + offset;
      break;
    default:
      NSLog (@"unrecognize value for whence: %d", whence);
      realOffset = [fileHandle offsetInFile];
    }

  [fileHandle seekToFileOffset: realOffset];

  return 0;
}

static int
oggCloseFunc (void *datasource)
{
  NSFileHandle *fileHandle;

  fileHandle = datasource;
  [fileHandle closeFile];
  [fileHandle release];

  return 0;
}

static long
oggTellFunc (void *datasource)
{
  NSFileHandle *fileHandle;

  fileHandle = datasource;

  return [fileHandle offsetInFile];
}

static ov_callbacks oggCallbacks = { oggReadFunc, oggSeekFunc,
                                     oggCloseFunc, oggTellFunc };

@implementation Ogg : NSObject

+ (NSString *) bundleDescription
{
  return @"Extension plug-in for the Ogg Vorbis audio format";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2002-2005  Wolfgang Sourdeau",
                  nil];
}

+ (NSArray *) compatibleTagBundles
{
  return [NSArray arrayWithObjects: @"VorbisTags", @"Taglib", nil];
}

- (BOOL) streamOpen: (NSString *) fileName
{
  NSFileHandle *_fileHandle;

  _fileHandle = [NSFileHandle fileHandleForReadingAtPath: fileName];
  bitStream = 0;

  if (_fileHandle)
    {
      _ov_file = calloc (sizeof (OggVorbis_File), 1); 
      lastError = ov_open_callbacks (_fileHandle, _ov_file, NULL, 0L,
                                     oggCallbacks);
      if (lastError)
	[_fileHandle closeFile];
      else
        [_fileHandle retain];
    }
  else
    {
      NSLog (@"No native handle...");
      lastError = OV_EREAD;
    }

  return (lastError == 0);
}

+ (BOOL) canTestFileHeaders
{
  return YES;
}

+ (BOOL) streamTestOpen: (NSString *) fileName
{
  NSFileHandle *_fileHandle;
  BOOL result = NO;
  int vorbisError;
  OggVorbis_File *_ov_test_file;

  _fileHandle = [NSFileHandle fileHandleForReadingAtPath: fileName];

  if (_fileHandle)
    {
      _ov_test_file = calloc (sizeof (OggVorbis_File), 1); 
      vorbisError = ov_open_callbacks (_fileHandle, _ov_test_file, NULL, 0L,
                                       oggCallbacks);
      if (vorbisError)
	{
          if (vorbisError != OV_ENOTVORBIS)
            NSLog (@"Ogg: streamTestOpen: %@", [self errorText: vorbisError]);
	  [_fileHandle closeFile];
	}
      else
	{
	  result = YES;
          [_fileHandle retain];
	  ov_clear (_ov_test_file);
	}
    }

  return result;
}

+ (NSString *) errorText: (int) error
{
  char *cErrorMessage;

  switch (error)
    {
    case OV_EREAD:
      cErrorMessage = "A read from media returned an error";
      break;
    case OV_ENOTVORBIS:
      cErrorMessage = "Bitstream is not Vorbis data";
      break;
    case OV_EVERSION:
      cErrorMessage = "Vorbis version mismatch";
      break;
    case OV_EBADHEADER:
      cErrorMessage = "Invalid Vorbis bitstream header";
      break;
    case OV_EFAULT:
      cErrorMessage = "Internal logic fault";
      break;
    case OV_ENOSEEK:
      cErrorMessage = "Bitstream is not seekable";
      break;
    case OV_EINVAL:
      cErrorMessage = "Invalid argument value";
      break;
    case OV_EBADLINK:
      cErrorMessage = "Invalid stream section supplied to libvorbisfile, or"
	" the requested link is corrupt";
      break;
    case 0:
      cErrorMessage = "(No error)";
      break;
    default:
      cErrorMessage = "(undefined error)";
    }

  return [NSString stringWithUTF8String: cErrorMessage];
}

- (int) readNextChunk: (unsigned char *) buffer
	     withSize: (unsigned int) bufferSize
{
  int bytes_read;

  if (_ov_file)
    {
      bytes_read = ov_read (_ov_file, (char *) buffer, bufferSize,
			    0, 2, 1, &bitStream);
      if (bytes_read < 0)
	lastError = bytes_read;
    }
  else
    {
      lastError = OV_EFAULT;
      bytes_read = -1;
    }

  return bytes_read;
}

- (int) lastError
{
  return lastError;
}

- (unsigned int) readChannels
{
  return (_ov_file->vi->channels);
}

- (unsigned long) readRate
{
  return (_ov_file->vi->rate);
}

- (Endianness) endianness
{
  return NativeEndian;
}

- (unsigned int) readDuration
{
  return (ov_time_total (_ov_file, -1));
}

- (void) streamClose
{
  ov_clear (_ov_file);
  _ov_file = NULL;
}

// Player Protocol
+ (NSArray *) acceptedFileExtensions
{
  return [NSArray arrayWithObject: @"ogg"];
}

- (BOOL) isSeekable
{
  return (BOOL) ov_seekable (_ov_file);
}

- (void) seek: (unsigned int) aPos
{
  ogg_int64_t pcmPos;
  pcmPos = aPos * [self readChannels] * [self readRate] / 2;
#ifdef __MACOSX__
  ov_pcm_seek (_ov_file, pcmPos);
#else
  ov_pcm_seek_lap (_ov_file, pcmPos);
#endif
}

@end
