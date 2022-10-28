/* Taglib.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
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
#import <Cynthiune/Tags.h>
#import <Cynthiune/utils.h>

#define BOOL BOOL /* tag_c.h pollution */
#import <tag_c.h>

#import "Taglib.h"

#define LOCALIZED(X) _b ([Taglib class], X)

#define makeTag(T) [[NSString stringWithUTF8String: T] stringByTrimmingSpaces]

@implementation Taglib : NSObject

+ (NSString *) bundleDescription
{
  return @"A bundle to read/set the tags of audio files";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2005  Wolfgang Sourdeau",
                  nil];
}

+ (BOOL) readTitle: (NSString **) title
            artist: (NSString **) artist
             album: (NSString **) album
       trackNumber: (NSString **) trackNumber
             genre: (NSString **) genre
              year: (NSString **) year
        ofFilename: (NSString *) filename
{
  TagLib_File *file;
  TagLib_Tag *tag;
  unsigned int number;

  file = taglib_file_new ([filename cString]); 
  if (file)
    {
      tag = taglib_file_tag (file);
      if (tag)
        {
          SET (*title, makeTag (taglib_tag_title (tag)));
          SET (*artist, makeTag (taglib_tag_artist (tag)));
          SET (*album, makeTag (taglib_tag_album (tag)));
          SET (*genre, makeTag (taglib_tag_genre (tag)));

          number = taglib_tag_track (tag);
          if (number)
            {
              SET (*trackNumber,
                   ([NSString stringWithFormat: @"%d", number]));
            }
          number = taglib_tag_year (tag);
          if (number)
            {
              SET (*year, ([NSString stringWithFormat: @"%d", number]));
            }
          taglib_tag_free_strings();
        }
      taglib_file_free (file);
    }

  return YES;
}

+ (BOOL) setTitle: (NSString *) title
           artist: (NSString *) artist
            album: (NSString *) album
      trackNumber: (NSString *) trackNumber
            genre: (NSString *) genre
             year: (NSString *) year
       ofFilename: (NSString *) filename
{
  TagLib_File *file;
  TagLib_Tag *tag;
  unsigned int number;

  file = taglib_file_new ([filename cString]); 
  if (file)
    {
      tag = taglib_file_tag (file);
      if (tag)
        {
          if (title)
            taglib_tag_set_title (tag, [title UTF8String]);
          if (artist)
            taglib_tag_set_artist (tag, [artist UTF8String]);
          if (album)
            taglib_tag_set_album (tag, [album UTF8String]);
          if (genre)
            taglib_tag_set_genre (tag, [genre UTF8String]);
          if (trackNumber)
            {
              if ([trackNumber length])
                {
                  number = [trackNumber intValue];
                  if (number)
                    taglib_tag_set_track (tag, number);
                }
              else
                taglib_tag_set_track (tag, 0);
            }
          if (year)
            {
              if ([year length])
                {
                  number = [year intValue];
                  if (number)
                    taglib_tag_set_year (tag, number);
                }
              else
                taglib_tag_set_year (tag, 0);
            }
          taglib_file_save (file);
        }
      taglib_file_free (file);
    }

  return YES;
}

@end
