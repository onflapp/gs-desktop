/* ID3Tag.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
 *               2012 The Free Software Foundation, Inc
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
 *         The GNUstep Application Team
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
#import <Cynthiune/utils.h>

#include <id3tag.h>

#import "ID3Tag.h"

#define LOCALIZED(X) _b ([ID3Tag class], X)

@interface NSString (ID3TagExtension)

+ (NSString *) stringWithUCS4String: (const id3_ucs4_t *) ucs4Value;
- (id3_ucs4_t *) UCS4String;

@end

@implementation NSString (ID3TagExtension)

+ (NSString *) stringWithUCS4String: (const id3_ucs4_t *) ucs4Value
{
  NSString *newString;
  id3_utf8_t *UTF8String;

  UTF8String = id3_ucs4_utf8duplicate (ucs4Value);
  newString = [NSString stringWithUTF8String: (char *) UTF8String];
  free (UTF8String);

  return newString;
}

- (id3_ucs4_t *) UCS4String
{
  return id3_utf8_ucs4duplicate ((id3_utf8_t *) [self UTF8String]);
}

@end

@implementation ID3Tag : NSObject

+ (NSString *) bundleDescription
{
  return @"A bundle to read/set the ID3 tags of audio files";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2005  Wolfgang Sourdeau",
                  nil];
}

+ (NSString *) _readComment: (char *) commentTag
                    fromTag: (Id3Tag *) id3Tag
{
  NSString *comment;
  Id3Frame *id3Frame;
  Id3Field *field;
  const id3_ucs4_t *string;

  comment = nil;
  id3Frame = id3_tag_findframe (id3Tag, commentTag, 0);
  if (id3Frame)
    {
      field = id3_frame_field (id3Frame, 1);
      if (field
          && id3_field_type (field) == ID3_FIELD_TYPE_STRINGLIST)
        {
          string = id3_field_getstrings (field, 0);
          if (string)
            {
              if (!strcmp(commentTag, ID3_FRAME_GENRE))
                string = id3_genre_name (string);
              comment = [NSString stringWithUCS4String: string];
            }
        }
    }

  return comment;
}

+ (BOOL) readTitle: (NSString **) title
            artist: (NSString **) artist
             album: (NSString **) album
       trackNumber: (NSString **) trackNumber
             genre: (NSString **) genre
              year: (NSString **) year
        ofFilename: (NSString *) filename
{
  Id3File *id3File;
  Id3Tag *id3Tag;

  id3File = id3_file_open ([filename cString], ID3_FILE_MODE_READONLY);
  if (id3File)
    {
      id3Tag = id3_file_tag (id3File);

      if (id3Tag)
        {
          SET (*title, [self _readComment: ID3_FRAME_TITLE fromTag: id3Tag]);
          SET (*artist,
               [self _readComment: ID3_FRAME_ARTIST fromTag: id3Tag]);
          SET (*album, [self _readComment: ID3_FRAME_ALBUM fromTag: id3Tag]);
          SET (*trackNumber,
               [self _readComment: ID3_FRAME_TRACK fromTag: id3Tag]);
          SET (*genre, [self _readComment: ID3_FRAME_GENRE fromTag: id3Tag]);
          SET (*year, [self _readComment: ID3_FRAME_YEAR fromTag: id3Tag]);

          id3_tag_delete (id3Tag);
        }

      id3_file_close (id3File);
    }

  return YES;
}

+ (id3_ucs4_t *) _genreValue: (NSString *) genre
{
  id3_ucs4_t *genreName;
  int genreIndex;

  genreName = [genre UCS4String];
  genreIndex = id3_genre_number (genreName);
  free (genreName);
  return [[NSString stringWithFormat: @"%d", genreIndex] UCS4String];
}

+ (unsigned int) _updateComment: (char *) comment
                             to: (NSString *) value
                          ofTag: (Id3Tag *) tag
{
  Id3Frame *frame;
  Id3Field *field;
  id3_ucs4_t *ucs4Value;
  unsigned int rc;

  rc = 0;

  if ([value length] > 0)
    {
      frame = id3_tag_findframe (tag, comment, 0);
      if (!frame) 
        {
          frame = id3_frame_new (comment);
          id3_tag_attachframe (tag, frame);
        }

      field = id3_frame_field (frame, 1);
      field->type = ID3_FIELD_TYPE_STRINGLIST;

//       if (comment == ID3_FRAME_GENRE)
//         ucs4Value = [self _genreValue: value];
//       else
      ucs4Value = [value UCS4String];

      rc = id3_field_setstrings (field, 1, &ucs4Value);
      free (ucs4Value);
    }
  else
    while ((frame = id3_tag_findframe (tag, comment, 0))
           && rc == 0)
      rc = id3_tag_detachframe (tag, frame);

  return rc;
}

+ (BOOL) setTitle: (NSString *) title
           artist: (NSString *) artist
            album: (NSString *) album
      trackNumber: (NSString *) trackNumber
            genre: (NSString *) genre
             year: (NSString *) year
       ofFilename: (NSString *) filename
{
  Id3File *id3File;
  Id3Tag *id3Tag;
  int rc;
  BOOL result;

  id3File = id3_file_open ([filename cString], ID3_FILE_MODE_READWRITE);
  if (id3File)
    {
      id3Tag = id3_file_tag (id3File);
      if (!id3Tag)
        {
          id3Tag = id3_tag_new ();
          id3_tag_clearframes (id3Tag);
        }

      rc = 0;
      if (title)
        rc += [self _updateComment: ID3_FRAME_TITLE
                    to: title
                    ofTag: id3Tag];
      if (artist)
        rc += [self _updateComment: ID3_FRAME_ARTIST
                    to: artist
                    ofTag: id3Tag];
      if (album)
        rc += [self _updateComment: ID3_FRAME_ALBUM
                    to: album
                    ofTag: id3Tag];
      if (trackNumber)
        rc += [self _updateComment: ID3_FRAME_TRACK
                    to: trackNumber
                    ofTag: id3Tag];
      if (genre)
        rc += [self _updateComment: ID3_FRAME_GENRE
                    to: genre
                    ofTag: id3Tag];
      if (year)
        rc += [self _updateComment: ID3_FRAME_YEAR
                    to: year
                    ofTag: id3Tag];

      if (rc == 0)
        result = (id3_file_update (id3File) == 0);
      else
        result = NO;

      id3_file_close (id3File);
    }
  else
    result = NO;

  return result;
}

@end
