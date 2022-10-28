/* Format.h - this file is part of Cynthiune
 *
 * Copyright (C) 2003 Wolfgang Sourdeau
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

#ifndef Format_H
#define Format_H

#import <Foundation/NSObjCRuntime.h>

typedef enum
{
  NativeEndian = 0,
  LittleEndian = 1,
  BigEndian = 2
} Endianness;

@class NSString;
@protocol NSObject;

@protocol Format <NSObject>

+ (BOOL) canTestFileHeaders;
+ (BOOL) streamTestOpen: (NSString *) fileName;

+ (NSArray *) acceptedFileExtensions;
+ (NSArray *) compatibleTagBundles;

- (BOOL) streamOpen: (NSString *) fileName;
- (void) streamClose;
- (int) readNextChunk: (unsigned char *) buffer
             withSize: (unsigned int) bufferSize;

- (BOOL) isSeekable;
- (void) seek: (unsigned int) seconds;

- (unsigned int) readChannels;
- (unsigned long) readRate;
- (Endianness) endianness;

- (unsigned int) readDuration;

@end

#endif /* Format_H */
