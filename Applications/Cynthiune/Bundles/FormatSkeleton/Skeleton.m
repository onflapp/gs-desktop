/* $FORMAT$.m - this file is part of Cynthiune
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

#import <Foundation/Foundation.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Format.h>

#import "$FORMAT$.h"

#define LOCALIZED(X) _b ([$FORMAT$ class], X)

@implementation $FORMAT$ : NSObject

+ (NSArray *) bundleClasses
{
  return [NSArray arrayWithObject: [self class]];
}

- (BOOL) streamOpen: (NSString *) fileName
{
  return NO;
}

+ (BOOL) canTestFileHeaders
{
  return NO;
}

+ (BOOL) streamTestOpen: (NSString *) fileName
{
  return NO;
}

+ (NSString *) errorText: (int) error
{
  return @"";
}

- (int) readNextChunk: (unsigned char *) buffer
	     withSize: (unsigned int) bufferSize
{
  return 0;
}

- (int) lastError
{
  return 0;
}

- (unsigned int) readChannels
{
  return 0;
}

- (unsigned long) readRate
{
  return 0;
}

- (unsigned int) readDuration
{
  return 0;
}

- (NSString *) readTitle
{
  return @"";
}

- (NSString *) readGenre
{
  return @"";
}

- (NSString *) readArtist
{
  return @"";
}

- (NSString *) readAlbum
{
  return @"";
}

- (NSString *) readTrackNumber
{
  return @"";
}

- (void) streamClose
{
}

// Player Protocol
+ (NSArray *) acceptedFileExtensions
{
  return [NSArray arrayWithObjects: nil];
}

- (BOOL) isSeekable
{
  return NO;
}

- (void) seek: (unsigned int) aPos
{
}

@end
