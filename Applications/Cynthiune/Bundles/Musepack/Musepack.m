/* Musepack.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005, 2006  Wolfgang Sourdeau
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

#import <ctype.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSString.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Format.h>
#import <Cynthiune/utils.h>

#ifdef MUSEPACK_API_126
#import <mpcdec/mpcdec.h>
#else
#import <mpc/mpcdec.h>
#endif

#import "Musepack.h"
#import "CNSFileHandle.h"

#define LOCALIZED(X) _b ([Musepack class], X)

#define minClip    (-1 << (16 - 1))
#define maxClip    ((1 << (16 - 1)) - 1)
#define floatScale (1 << (16 - 1))

#ifdef MPC_FIXED_POINT
static inline int
ShiftSigned (MPC_SAMPLE_FORMAT val, int shift)
{
  if (shift > 0)
    val <<= shift;
  else if (shift < 0)
    val >>= -shift;

  return (int) val;
}
#endif

static mpc_reader *
MPCReaderNew (NSFileHandle *handle)
{
  mpc_reader *reader;

  reader = malloc (sizeof (mpc_reader));
  reader->read = CNSFileHandleRead;
  reader->canseek = CNSFileHandleCanSeek;
  reader->seek = CNSFileHandleSeek;
  reader->tell = CNSFileHandleTell;
  reader->get_size = CNSFileHandleGetSize;
  reader->data = handle;
  [handle retain];

  return reader;
}

static void
MPCReaderDelete (mpc_reader *reader)
{
  [(NSFileHandle *) reader->data release];
#ifdef MUSEPACK_API_126
  free (reader);
#else
  mpc_reader_exit_stdio (reader);
#endif
}

static mpc_streaminfo *
MPCStreamInfoNew ()
{
  mpc_streaminfo *streamInfo;

  streamInfo = malloc (sizeof (mpc_streaminfo));
#ifdef MUSEPACK_API_126
  mpc_streaminfo_init (streamInfo);
#endif

  return streamInfo;
}

#ifdef MUSEPACK_API_126
static mpc_decoder *
MPCDecoderNew (mpc_reader *reader, mpc_streaminfo *streamInfo)
{
  mpc_decoder *decoder;

  decoder = malloc (sizeof (mpc_decoder));
  mpc_decoder_setup (decoder, reader);
  mpc_decoder_initialize (decoder, streamInfo);

  return decoder;
}
#endif

static inline void
CopyBuffer (const MPC_SAMPLE_FORMAT *buffer, unsigned char *destBuffer,
            unsigned int length)
{
  int val;
  unsigned int count;
  unsigned short *destPtr;

  destPtr = (unsigned short *) destBuffer;

  for (count = 0; count < length; count++)
    {
#ifdef MPC_FIXED_POINT
      val = ShiftSigned (buffer[count], 16 - MPC_FIXED_POINT_SCALE_SHIFT);
#else
      val = (int) (buffer[count] * floatScale);
#endif
      if (val < minClip)
        val = minClip;
      else if (val > maxClip)
        val = maxClip;
      *destPtr = val;
      destPtr++;
    }
}

@implementation Musepack : NSObject

+ (NSString *) bundleDescription
{
  return @"Extension plug-in for MPEG+ audio format";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2005, 2006  Wolfgang Sourdeau",
                  nil];
}

+ (NSArray *) compatibleTagBundles
{
  return [NSArray arrayWithObjects: @"Taglib", nil];
}

- (void) _resetIVars
{
  fileHandle = nil;
  mpcReader = NULL;
  mpcStreamInfo = NULL;
  mpcDecoder = NULL;
  remaining = 0;
  framePtr = NULL;
}

- (id) init
{
  if ((self = [super init]))
    [self _resetIVars];

  return self;
}

- (BOOL) streamOpen: (NSString *) fileName
{
  BOOL result;

  fileHandle = [NSFileHandle fileHandleForReadingAtPath: fileName];
  if (fileHandle)
    {
      [fileHandle retain];
      mpcReader = MPCReaderNew (fileHandle);
#ifndef MUSEPACK_API_126
      if (!mpcReader)
	return MPC_FALSE;
#endif
      mpcStreamInfo = MPCStreamInfoNew ();
#ifdef MUSEPACK_API_126
      mpc_streaminfo_read (mpcStreamInfo, mpcReader);

      mpcDecoder = MPCDecoderNew (mpcReader, mpcStreamInfo);
#else
      mpcDecoder = mpc_demux_init (mpcReader);
      if (!mpcDecoder)
        return MPC_FALSE;
      mpc_demux_get_info (mpcDecoder, mpcStreamInfo);
#endif

      result = YES;
    }
  else
    result = NO;

  return result;
}

+ (BOOL) canTestFileHeaders
{
  return YES;
}

+ (BOOL) streamTestOpen: (NSString *) fileName
{
  NSFileHandle *testFileHandle;
  mpc_reader *testReader;
#ifndef MUSEPACK_API_126
  mpc_demux *testDecoder;
#else
  mpc_streaminfo *testStreamInfo;
#endif
  BOOL result;

  testFileHandle = [NSFileHandle fileHandleForReadingAtPath: fileName];
  if (testFileHandle)
    {
      testReader = MPCReaderNew (testFileHandle);
#ifdef MUSEPACK_API_126
      testStreamInfo = MPCStreamInfoNew ();
      result = !mpc_streaminfo_read (testStreamInfo, testReader);
      free (testStreamInfo);
      MPCReaderDelete (testReader);
#else
      testDecoder = mpc_demux_init (testReader);
      if (testDecoder)
        {
          result = YES;
          mpc_demux_exit (testDecoder);
        }
      else
	{
	  result = NO;
	}
      if (testReader)
	{
          MPCReaderDelete (testReader);
	}
#endif
    }
  else
    result = NO;

  return result;
}

+ (NSString *) errorText: (int) error
{
  return @"";
}

- (int) readNextChunk: (unsigned char *) buffer
	     withSize: (unsigned int) bufferSize
{
  int bytes, status;
#ifdef MUSEPACK_API_126
  unsigned int vbrAcc, vbrBits;
#else
  mpc_frame_info frame;
  mpc_status err;
#endif
  unsigned long frames, samples;

  status = 1;
#ifndef MUSEPACK_API_126
  frame.buffer = sampleBuffer;
#endif

#ifdef MUSEPACK_API_126
  if (!remaining)
#else
  while (!remaining)
#endif
    {
#ifdef MUSEPACK_API_126
      samples = mpc_decoder_decode (mpcDecoder, sampleBuffer,
                                    &vbrAcc, &vbrBits);
      if (!samples)
        status = 0;
      else if (samples == (unsigned long) -1)
        status = -1;
#else
      err = mpc_demux_decode (mpcDecoder, &frame);
      if (err != MPC_STATUS_OK)
        {
          status = -1;
          break;
        }
      else if (frame.bits == -1)
        {
          status = 0;
          break;
        }
#endif
      else
        {
#ifndef MUSEPACK_API_126
	  samples = frame.samples;
#endif
          frames = samples * mpcStreamInfo->channels;
          CopyBuffer (sampleBuffer, frameBuffer, frames);
          remaining = frames * 2;
          framePtr = frameBuffer;
        }
    }

  if (status > 0)
    {
      bytes = ((bufferSize < remaining) ? bufferSize : remaining);
      memcpy (buffer, framePtr, bytes);
#if (BYTE_ORDER == BIG_ENDIAN)
      invertBytesInBuffer ((char *) buffer, bytes);
#endif
      framePtr += bytes;
      remaining -= bytes;
    }
  else
    bytes = 0;

  return ((status > 0) ? bytes : status);
}

- (int) lastError
{
  return 0;
}

- (unsigned int) readChannels
{
  return mpcStreamInfo->channels;
}

- (unsigned long) readRate
{
  return mpcStreamInfo->sample_freq;
}

- (Endianness) endianness
{
  return NativeEndian;
}

- (unsigned int) readDuration
{
#ifdef MUSEPACK_API_126
  return mpcStreamInfo->pcm_samples / mpcStreamInfo->sample_freq;
#else
  return (unsigned int) mpc_streaminfo_get_length (mpcStreamInfo);
#endif
}

- (void) streamClose
{
  if (fileHandle)
    {
      [fileHandle closeFile];
      [fileHandle release];
    }
#ifndef MUSEPACK_API_126
  if (mpcDecoder)
    mpc_demux_exit (mpcDecoder);
#endif
  if (mpcReader)
    MPCReaderDelete (mpcReader);
#ifdef MUSEPACK_API_126
  if (mpcStreamInfo)
    free (mpcStreamInfo);
  if (mpcDecoder)
    free (mpcDecoder);
#endif
  [self _resetIVars];
}

// Player Protocol
+ (NSArray *) acceptedFileExtensions
{
  return [NSArray arrayWithObjects: @"mpc", @"mp+", @"mpp", nil];
}

- (BOOL) isSeekable
{
  return YES;
}

- (void) seek: (unsigned int) aPos
{
#ifdef MUSEPACK_API_126
  mpc_decoder_seek_seconds (mpcDecoder, (double) aPos);
#else
  mpc_demux_seek_second (mpcDecoder, (double) aPos);
#endif
}

@end
