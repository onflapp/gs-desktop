/* Musepack.h - this file is part of Cynthiune
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

#ifndef Musepack_H
#define Musepack_H

#define maxSamples 4 * 36 * 32

@interface Musepack : NSObject <CynthiuneBundle, Format>
{
  NSFileHandle *fileHandle;

  mpc_reader *mpcReader;
  mpc_streaminfo *mpcStreamInfo;
#ifdef MUSEPACK_API_126
  mpc_decoder *mpcDecoder;
#else
  mpc_demux *mpcDecoder;
#endif

  MPC_SAMPLE_FORMAT sampleBuffer[maxSamples];
  unsigned char frameBuffer[maxSamples * 4];
  unsigned char *framePtr;
  unsigned int remaining;
}

@end

#endif /* Musepack_H */
