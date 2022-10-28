/* CWMFile.cpp - this file is part of Cynthiune
 *
 * Copyright (C) 2004 Wolfgang Sourdeau
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

#ifndef NULL
#define NULL 0
#endif

#include <fstream>
#include <avifile.h>
#include <infotypes.h>

#include "CWMFile.h"

static bool
_testASFHeaders (const char *filename)
{
  std::fstream *_f;
  unsigned long header;
  bool result;

  result = false;

  _f = new std::fstream (filename, std::ios::in);
  if (_f)
    {
      _f->read ((char*) &header, 4);
#if (BYTE_ORDER == __LITTLE_ENDIAN)
      result = (header == 0x75b22630);
#else
      result = (header == 0x3026b275);
#endif
      delete _f;
    }

  return result;
}

WMFile *
WMFileOpen (const char *filename)
{
  return ((_testASFHeaders (filename))
          ? (WMFile *) avm::CreateReadFile (filename)
          : NULL);
}

void
WMFileClose (WMFile *file)
{
  delete ((avm::IReadFile *) file);
}

unsigned int
WMFileAudioStreamCount (WMFile *file)
{
  avm::IReadFile *readFile;

  readFile = (avm::IReadFile *) file;

  return (unsigned int) readFile->AudioStreamCount ();
}

WMStream *
WMFileGetAudioStream (WMFile *file)
{
  avm::IReadFile *readFile;

  readFile = (avm::IReadFile *) file;

  return ((WMStream *) readFile->GetStream (0, avm::IReadStream::Audio));
}

void
WMStreamClose (WMStream *stream)
{
}

void
WMStreamStartStreaming (WMStream *stream)
{
  avm::IReadStream *readStream;

  readStream = (avm::IReadStream *) stream;
  readStream->StartStreaming ();
}

void
WMStreamStopStreaming (WMStream *stream)
{
  avm::IReadStream *readStream;

  readStream = (avm::IReadStream *) stream;
  readStream->StopStreaming ();
}

unsigned int
WMStreamGetFrameSize (WMStream *stream)
{
  avm::IReadStream *readStream;

  readStream = (avm::IReadStream *) stream;

  return (unsigned int) readStream->GetFrameSize ();
}

void
WMStreamGetInfos (WMStream *stream,
                  unsigned int *channels,
                  unsigned long *rate,
                  unsigned int *duration)
{
  avm::IReadStream *readStream;
  avm::StreamInfo *streamInfo;

  readStream = (avm::IReadStream *) stream;
  streamInfo = readStream->GetStreamInfo ();
  if (channels)
    *channels = (unsigned int) streamInfo->GetAudioChannels ();
  if (rate)
    *rate = (unsigned long) streamInfo->GetAudioSamplesPerSec ();
  if (duration)
    *duration = (unsigned int) streamInfo->GetLengthTime ();
}

int
WMStreamReadFrames (WMStream *stream,
                    void *buffer, unsigned int bufferSize,
                    unsigned int samples, unsigned int *samplesRead,
                    unsigned int *bytesRead)
{
  size_t _samplesRead, _bytesRead;
  avm::IReadStream *readStream;
  int result;

  _samplesRead = 0;
  _bytesRead = 0;

  result = 0;

  readStream = (avm::IReadStream *) stream;
  while (!result && !_bytesRead)
    {
      size_t tmp_bufferSize = (size_t) bufferSize;
      result = ((readStream->Eof ())
              ? -1
	      : readStream->ReadFrames (buffer, tmp_bufferSize, tmp_bufferSize,
					_samplesRead, _bytesRead));
    }

  *samplesRead = _samplesRead;
  *bytesRead = _bytesRead;

  return result;
}

void
WMStreamSeekTime (WMStream *stream, unsigned int position)
{
  avm::IReadStream *readStream;

  readStream = (avm::IReadStream *) stream;

  readStream->SeekTime ((double) position);
}
