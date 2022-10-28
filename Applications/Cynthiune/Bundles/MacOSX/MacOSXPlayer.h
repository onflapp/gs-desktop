/* MacOSXPlayer.h - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004  Wolfgang Sourdeau
 *               2012 he GNUstep Application Team
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

#ifndef MacOSXPlayer_H
#define MacOSXPlayer_H

#import <Cynthiune/Output.h>

@interface MacOSXPlayer : NSObject <CynthiuneBundle, Output>
{
  id parentPlayer;

  int bytes;

  unsigned int channels;
  unsigned long rate;

  unsigned int bufferNumber;
  unsigned char buffer[2][DEFAULT_BUFFER_SIZE];

  BOOL isOpen;
  BOOL isBigEndian;

  AudioUnit outputUnit;
  AudioConverterRef converter;
  AudioStreamBasicDescription inputFormat, outputFormat;
}

@end

typedef struct {
    @defs(MacOSXPlayer);
} PlayerRef;

#endif /* MacOSXPlayer_H */
