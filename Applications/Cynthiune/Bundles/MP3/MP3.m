/* MP3.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2005 Wolfgang Sourdeau
 *               2012 The GNUstep Application Team
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

#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <mad.h>
#include <id3tag.h>

#import <Foundation/Foundation.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Format.h>
#import <Cynthiune/utils.h>

#import "xing.h"
#import "MP3.h"

#define LOCALIZED(X) _b ([MP3 class], X)

#define MAD_AVERAGE_FRAMES 10
#define MAX_LOSTSYNCS IBUFFER_SIZE * 5

/* header testing */
static inline int
seekOffset (FILE *_f)
{
  char testchar;
  int counter;
  BOOL eof;

  counter = -1;
  testchar = 0;
  eof = NO;

  while (!eof && !testchar)
    {
      eof = (fread (&testchar, 1, 1, _f) != 1);
      counter++;
    }

  if (!eof)
    fseek (_f, counter, SEEK_SET);

  return ((eof) ? -1 : counter);
}

static inline BOOL
testRiffHeader (char *buffer, FILE *_f, int offset)
{
  char tag;
  BOOL result;

  if (strncmp (buffer, "WAVE", 4) == 0)
    {
      fseek (_f, 20 + offset, SEEK_SET);
      fread (&tag, 1, 1, _f);
      result = (tag == 80 || tag == 85);
    }
  else
    result = NO;

  return result;
}

static inline BOOL
testMP3Header (const char *buffer)
{
  unsigned short *header;

  header = (unsigned short *) buffer;

  return ((NSHostByteOrder() == NS_LittleEndian)
          ? ((*header & 0xfeff) == 0xfaff
             || (*header & 0xfeff) == 0xfcff
             || (*header & 0xf8ff) == 0xf0ff
             || (*header & 0xf8ff) == 0xe0ff)
          : ((*header & 0xfffe) == 0xfffa
             || (*header & 0xfffe) == 0xfffc
             || (*header & 0xfff8) == 0xfff0
             || (*header & 0xfff8) == 0xffe0));
}

/* data decoding */
static inline int
calcInputRemain (MadStream *stream, unsigned char *iBuffer)
{
  int inputRemain;

  if (stream->next_frame)
    {
      inputRemain = stream->bufend - stream->next_frame;
      if (inputRemain > IBUFFER_SIZE)
        {
          NSLog (@"remain too large to handle (%d), skipping...",
                 inputRemain);
          inputRemain = 0;
        }
      else
        memcpy (iBuffer, stream->next_frame, inputRemain);
    }
  else
    inputRemain = 0;

  return inputRemain;
}

static signed long
audioLinearDither (MadFixed sample, audioDither *dither)
{
  unsigned int scalebits;
  MadFixed output, mask, random;

  /* noise shape */
  sample += dither->error[0] - dither->error[1] + dither->error[2];

  dither->error[2] = dither->error[1];
  dither->error[1] = dither->error[0] / 2;

  /* bias */
  output = sample + (1L << (MAD_F_FRACBITS - 16));

  scalebits = MAD_F_FRACBITS - 15;
  mask = (1L << scalebits) - 1;

  /* dither */
  random = (dither->random * 0x0019660dL + 0x3c6ef35fL) & 0xffffffffL;;
  output += (random & mask) - (dither->random & mask);
  dither->random = random;

  /* clip */
  if (output > (MAD_F_ONE - 1))
    {
      output = MAD_F_ONE - 1;

      if (sample > MAD_F_ONE - 1)
        sample = MAD_F_ONE - 1;
    }
  else if (output < -MAD_F_ONE)
    {
      output = -MAD_F_ONE;

      if (sample < -MAD_F_ONE)
        sample = -MAD_F_ONE;
    }

  /* quantize */
  output &= ~mask;

  /* error feedback */
  dither->error[0] = sample - output;

  /* scale */
  return output >> scalebits;
}

static inline void
fillPCMBuffer (MP3 *self, unsigned char *buffer, int start, int limit)
{
  int i;
  unsigned char *oBPtr;
  register signed int sample;

  oBPtr = buffer;

  i = start;
  while (i < limit)
    {
      sample = audioLinearDither (self->synth.pcm.samples[0][i],
                                  &(self->leftDither));
      *oBPtr++ = sample >> 0;
      *oBPtr++ = sample >> 8;
      if (self->channels == 2)
        {
          sample = audioLinearDither (self->synth.pcm.samples[1][i],
                                      &(self->rightDither));
          *oBPtr++ = sample >> 0;
          *oBPtr++ = sample >> 8;
        }
      i++;
    }
}

static int
translateBufferToPCM (MP3 *self, unsigned char *buffer, int bufferSize)
{
  int start, limit, mult, delta;

  mult = 2 * self->channels;
  if (self->oRemain)
    {
      start = self->synth.pcm.length - self->oRemain;
      limit = self->synth.pcm.length;
    }
  else
    {
      start = 0;
      limit = (bufferSize / mult);
      if (self->synth.pcm.length < limit)
        limit = self->synth.pcm.length;
    }

  delta = (limit - start) * mult - bufferSize;
  if (delta > 0)
    limit -= delta / mult;

  fillPCMBuffer (self, buffer, start, limit);

  self->oRemain = self->synth.pcm.length - limit;

  return ((limit - start) * mult);
}

// static const char *MadErrorString(const struct mad_stream *Stream)
// {
// 	switch(Stream->error)
// 	{
// 		/* Generic unrecoverable errors. */
// 		case MAD_ERROR_BUFLEN:
// 			return("input buffer too small (or EOF)");
// 		case MAD_ERROR_BUFPTR:
// 			return("invalid (null) buffer pointer");
// 		case MAD_ERROR_NOMEM:
// 			return("not enough memory");

// 		/* Frame header related unrecoverable errors. */
// 		case MAD_ERROR_LOSTSYNC:
// 			return("lost synchronization");
// 		case MAD_ERROR_BADLAYER:
// 			return("reserved header layer value");
// 		case MAD_ERROR_BADBITRATE:
// 			return("forbidden bitrate value");
// 		case MAD_ERROR_BADSAMPLERATE:
// 			return("reserved sample frequency value");
// 		case MAD_ERROR_BADEMPHASIS:
// 			return("reserved emphasis value");

// 		/* Recoverable errors */
// 		case MAD_ERROR_BADCRC:
// 			return("CRC check failed");
// 		case MAD_ERROR_BADBITALLOC:
// 			return("forbidden bit allocation value");
// 		case MAD_ERROR_BADSCALEFACTOR:
// 			return("bad scalefactor index");
// 		case MAD_ERROR_BADFRAMELEN:
// 			return("bad frame length");
// 		case MAD_ERROR_BADBIGVALUES:
// 			return("bad big_values count");
// 		case MAD_ERROR_BADBLOCKTYPE:
// 			return("reserved block_type");
// 		case MAD_ERROR_BADSCFSI:
// 			return("bad scalefactor selection info");
// 		case MAD_ERROR_BADDATAPTR:
// 			return("bad main_data_begin pointer");
// 		case MAD_ERROR_BADPART3LEN:
// 			return("bad audio data length");
// 		case MAD_ERROR_BADHUFFTABLE:
// 			return("bad Huffman table select");
// 		case MAD_ERROR_BADHUFFDATA:
// 			return("Huffman data overrun");
// 		case MAD_ERROR_BADSTEREO:
// 			return("incompatible block_type for JS");

// 		/* Unknown error. This switch may be out of sync with libmad's
// 		 * defined error codes.
// 		 */
// 		default:
// 			return("Unknown error code");
// 	}
// }

static inline InputBufferStatus
decodeInputBuffer (MP3 *self, int iRBytes)
{
  InputBufferStatus bufferStatus;
  signed long tagSize;

  mad_stream_buffer (&(self->stream), self->iBuffer,
                     iRBytes + self->iRemain);
  if (mad_frame_decode (&(self->frame), &(self->stream)))
    {
      if ((self->stream.error & 0x100))
        {
          self->lostSyncs++;
          tagSize = id3_tag_query (self->stream.this_frame,
                                   self->stream.bufend
                                   - self->stream.this_frame);
          if (tagSize > 0)
            mad_stream_skip (&self->stream, tagSize);
          bufferStatus = ((self->lostSyncs == MAX_LOSTSYNCS)
                          ? BufferHasUnrecoverableError
                          : BufferHasRecoverableError);
        }
      else if (MAD_RECOVERABLE (self->stream.error)
               || self->stream.error == MAD_ERROR_BUFLEN)
        bufferStatus = BufferHasRecoverableError;
      else
        {
          NSLog (@"%s: unrecoverable frame level error (%s)",
                 __FILE__, mad_stream_errorstr (&(self->stream)));
          bufferStatus = BufferHasUnrecoverableError;
        }
    }
  else
    bufferStatus = BufferHasNoError;

  return bufferStatus;
}

@implementation MP3 : NSObject

+ (NSString *) bundleDescription
{
  return @"Extension plug-in for the MP2, MP3 v1/v2/v2.5 audio formats";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2002-2005  Wolfgang Sourdeau",
                  nil];
}

+ (NSArray *) compatibleTagBundles
{
  return [NSArray arrayWithObjects: @"ID3Tag", @"Taglib", nil];
}

- (Endianness) endianness
{
  return LittleEndian;
}

- (void) _resetIVars
{
  metadataRead = NO;
  channels = 0;
  rate = 0;
  duration = 0;
  size = 0;
  iRemain = 0;
  oRemain = 0;
  memset (iBuffer, 0, IBUFFER_SIZE);

  lostSyncs = 0;
}

- (void) _readStreamMetaData
{
  int iRBytes;
  unsigned int frameCount, rSize;
  InputBufferStatus bufferStatus;
  mad_timer_t madTimer;
  struct xing xingData;
  BOOL done;

  madTimer = mad_timer_zero;

  xing_init (&xingData);
  mad_stream_init (&stream);
  mad_frame_init (&frame);

  frameCount = 0;
  rSize = 0;

  done = NO;

  while (!done)
    {
      stream.error = 0;
      iRemain = calcInputRemain (&stream, iBuffer);

      iRBytes = fread (iBuffer + iRemain, sizeof (char),
                       IBUFFER_SIZE - iRemain, mf);

      if (iRBytes > 0 && !feof (mf))
        {
          bufferStatus = decodeInputBuffer ((MP3 *) self, iRBytes);
          if (bufferStatus == BufferHasNoError)
            {
              frameCount++;
              rSize += stream.next_frame - stream.this_frame;
              mad_timer_add (&madTimer, frame.header.duration);
              rate = frame.header.samplerate;
              channels = MAD_NCHANNELS (&(frame.header));
              if (frameCount == 1)
                {
                  if (!xing_parse (&xingData,
                                  stream.anc_ptr, stream.anc_bitlen))
                    {
                      mad_timer_multiply (&madTimer, xingData.frames);
                      done = YES;
                    }
                }
 
              if (frameCount >= MAD_AVERAGE_FRAMES)
                {
                  frameCount = size * MAD_AVERAGE_FRAMES / rSize;

                  madTimer.seconds /= MAD_AVERAGE_FRAMES;
                  madTimer.fraction /= MAD_AVERAGE_FRAMES;
                  mad_timer_multiply (&madTimer, frameCount);
                  done = YES;
                }
            }
          else if (bufferStatus == BufferHasUnrecoverableError)
            done = YES;
        }
      else
        done = YES;
    }

  duration = mad_timer_count (madTimer, MAD_UNITS_SECONDS);

  mad_frame_finish (&frame);
  mad_stream_finish (&stream);

  memset (iBuffer, 0, IBUFFER_SIZE);
  rewind (mf);

  metadataRead = YES;
}

- (void) _readSize: (const char *) filename;
{
  struct stat stat_val;

  stat (filename, &stat_val);
  size = stat_val.st_size;
}

- (BOOL) streamOpen: (NSString *) fileName
{
  const char *filename;

  filename = [fileName cString];
  mf = fopen (filename, "rb");

  if (mf)
    {
      [self _resetIVars];
      [self _readSize: filename];
      SET( openFilename, fileName );
      mad_stream_init (&stream);
      mad_frame_init (&frame);
      mad_synth_init (&synth);
    }
  else
    NSLog (@"%s: no handle...", __FILE__);

  return (mf != NULL);
}

+ (BOOL) canTestFileHeaders
{
  return YES;
}

+ (BOOL) streamTestOpen: (NSString *) fileName
{
  FILE *_f;
  char buffer[4];
  BOOL result;
  int offset;

  _f = fopen ([fileName cString], "rb");

  if (_f)
    {
      offset = seekOffset (_f);

      if (offset > -1)
        {
          fread (buffer, 1, 4, _f);
          if (!strncmp (buffer, "RIFF", 4))
            {
              fseek (_f, 8 + offset, SEEK_SET);
              fread (buffer, 1, 4, _f);
              result = testRiffHeader (buffer, _f, offset);
            }
          else
            result = (testMP3Header (buffer)
                      || !strncmp (buffer, "ID3", 3));
        }
      else
        result = NO;

      fclose (_f);
    }
  else
    result = NO;

  return result;
}

// - (NSString *) errorText
// {
//   return @"[error unimplemented]";
// }

/* FIXME: we should put some error handling here... */
- (int) readNextChunk: (unsigned char *) buffer
	     withSize: (unsigned int) bufferSize
{
  int iRBytes, decodedBytes;
  InputBufferStatus bufferStatus;
  BOOL done;

  lostSyncs = 0;

  if (oRemain)
    decodedBytes = translateBufferToPCM ((MP3 *) self, buffer, bufferSize);
  else
    {
      done = NO;
      decodedBytes = 0;

      while (!done)
        {
          stream.error = 0;
          iRemain = calcInputRemain (&stream, iBuffer);

          iRBytes = fread (iBuffer + iRemain, sizeof (char),
                           IBUFFER_SIZE - iRemain, mf);

          if (iRBytes > 0 && !feof (mf))
            {
              bufferStatus = decodeInputBuffer ((MP3 *) self, iRBytes);
              if (bufferStatus == BufferHasNoError)
                {
                  mad_synth_frame (&(self->synth), &(self->frame));
                  decodedBytes = translateBufferToPCM ((MP3 *) self,
                                                       buffer, bufferSize);
                  done = YES;
                }
              else if (bufferStatus == BufferHasUnrecoverableError)
                done = YES;
            }
          else
            done = YES;
        }
    }

  return decodedBytes;
}

- (unsigned int) readChannels
{
  if (!metadataRead)
    [self _readStreamMetaData];

  return channels;
}

- (unsigned long) readRate
{
  if (!metadataRead)
    [self _readStreamMetaData];

  return rate;
}

- (unsigned int) readDuration
{
  if (!metadataRead)
    [self _readStreamMetaData];

  return duration;
}

- (void) streamClose
{
  mad_synth_finish (&synth);
  mad_frame_finish (&frame);
  mad_stream_finish (&stream);

  if (mf)
    fclose (mf);
}

// Player Protocol
+ (NSArray *) acceptedFileExtensions
{
  return [NSArray arrayWithObjects: @"mp2", @"mp3", @"mpa",
                  @"mpga", @"mpega", nil];
}

/* FIXME: this might not be true */
- (BOOL) isSeekable
{
  return YES;
}

- (void) seek: (unsigned int) aPos
{
  unsigned long filePos;
  float factor;

  if (size)
    {
      factor = (float) size / duration;
      filePos = aPos * factor;
      fseek (mf, filePos, SEEK_SET);
    }
  else
    NSLog (@"size not computed?");
}

@end
