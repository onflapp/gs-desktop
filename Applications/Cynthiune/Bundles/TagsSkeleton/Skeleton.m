/* $TAGS$.m - this file is part of Cynthiune
 *
 * Copyright (C) 2006 Wolfgang Sourdeau
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

#import "$TAGS$.h"

#define LOCALIZED(X) _b ([$TAGS$ class], X)

@implementation $TAGS$ : NSObject

+ (NSString *) bundleDescription
{
  return @"A bundle to read/set the tags of audio files";
}

+ (NSArray *) bundleCopyrightStrings
{
  return @"Copyright (C) 2005 Joe Taghacker";
}

/* TagsReading protocol */
+ (BOOL) readTitle: (NSString **) title
            artist: (NSString **) artist
             album: (NSString **) album
       trackNumber: (NSString **) trackNumber
             genre: (NSString **) genre
              year: (NSString **) year
        ofFilename: (NSString *) filename
{
  return NO;
}

/* TagsWriting protocol */
+ (BOOL)  setTitle: (NSString *) title
            artist: (NSString *) artist
             album: (NSString *) album
       trackNumber: (NSString *) trackNumber
             genre: (NSString *) genre
              year: (NSString *) year
        ofFilename: (NSString *) filename
{
  return NO;
}

@end
