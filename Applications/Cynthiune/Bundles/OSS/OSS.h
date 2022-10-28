/* OSS.h - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004 Wolfgang Sourdeau
 *               2012 The Free Software Foundation
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

#ifndef OSS_H
#define OSS_H

#import <Foundation/NSObject.h>
#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>

@class NSFileHandle;

@protocol CynthiuneBundle;
@protocol Output;

@interface OSS : NSObject <CynthiuneBundle, Output>
{
  id parentPlayer;

  NSFileHandle *dsp;

  unsigned int channels;
  unsigned long rate;
  Endianness endianness;
}

@end

#endif /* OSS_H */
