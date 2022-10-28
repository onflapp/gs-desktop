/* CWMFile.h - this file is part of $PROJECT_NAME_HERE$
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

#ifndef CWMFILE_H
#define CWMFILE_H

typedef void **WMFile;
typedef void **WMStream;

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

WMFile *WMFileOpen (const char *filename);
void WMFileClose (WMFile *wmFile);

unsigned int WMFileAudioStreamCount (WMFile *);
WMStream *WMFileGetAudioStream (WMFile *file);
void WMStreamClose (WMStream *stream);

void WMStreamStartStreaming (WMStream *stream);
void WMStreamStopStreaming (WMStream *stream);

unsigned int WMStreamGetFrameSize (WMStream *stream);
void WMStreamGetInfos (WMStream *stream,
                       unsigned int *channels,
                       unsigned long *rate,
                       unsigned int *duration);
int WMStreamReadFrames (WMStream *stream,
                        void *buffer, unsigned int bufferSize,
                        unsigned int samples, unsigned int *samplesRead,
                        unsigned int *bytesRead);
void WMStreamSeekTime (WMStream *stream, unsigned int position);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* CWMFILE_H */
