/* MP3.h - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004 Wolfgang Sourdeau
 *               2012 The Free Software Foundation 
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

#ifndef MP3_H
#define MP3_H

@protocol Format;

/* original 5x buffer is too big
   1x is small on most machines
   2x appears to be a decent compromise.
   Needs to be infestigated further
*/
#define IBUFFER_SIZE 2 * 8192

typedef mad_fixed_t MadFixed;

typedef struct _audioDither {
  MadFixed error[3];
  MadFixed random;
} audioDither;

typedef enum _InputBufferStatus
{
  BufferHasUnrecoverableError = -2,
  BufferHasRecoverableError = -1,
  BufferHasNoError = 0
} InputBufferStatus;

typedef struct mad_frame MadFrame;
typedef struct mad_header MadHeader;
typedef struct mad_stream MadStream;
typedef struct mad_synth MadSynth;
typedef struct mad_bitptr MadBitPtr;

@interface MP3 : NSObject <CynthiuneBundle, Format>
{
  BOOL metadataRead;
  
  unsigned long rate;

  unsigned int duration;
  unsigned int size;

  FILE *mf;
 
  NSString *openFilename;

  BOOL opened;

  /* public ivars accessed as a C struct */
  @public MadFrame frame;
  @public MadStream stream;
  @public MadSynth synth;
  @public audioDither leftDither;
  @public audioDither rightDither;
  @public unsigned int channels;
  @public int iRemain;
  @public int oRemain;
  @public unsigned char iBuffer[IBUFFER_SIZE];
  @public unsigned int lostSyncs;
}

@end


#endif /* MP3_H */
