/* ALSA.h - this file is part of Cynthiune                       -*-objc-*-
 *
 * Copyright (C) 2010 Free Software Foundation, Inc.
 *
 * Author: Yavor Doganov <yavor@gnu.org>
 *
 * Cynthiune is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * Cynthiune is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef ALSA_H
#define ALSA_H

#import <Cynthiune/Output.h>

@interface ALSA : NSObject <CynthiuneBundle, Output>
{
  id parentPlayer;
  snd_pcm_t *pcm_handle;
  snd_pcm_format_t en;
  NSLock *devLock;

  BOOL stopRequested;

  unsigned int channels;
  unsigned long rate;

  unsigned char buffer[DEFAULT_BUFFER_SIZE];
}
@end

#endif /* ALSA_H */
