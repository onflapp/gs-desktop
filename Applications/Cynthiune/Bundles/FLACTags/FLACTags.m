/* FLACTags.m - this file is part of Cynthiune
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

#define _GNU_SOURCE 1
#import <stdlib.h>
#import <string.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#import <Cynthiune/utils.h>

#import <FLAC/all.h>

#import "FLACTags.h"

#define LOCALIZED(X) _b ([FLACTags class], X)

static inline int
keyPositionInArray (const char *key)
{
  unsigned int count;
  signed int result, len;
  const char *keys[] = { "title", "artist", "album", "tracknumber", "genre",
                         "date" };

  result = -1;
  count = 0;
  while (count < 6 && result == -1)
    {
      len = strlen (keys[count]);
      if (strncasecmp (keys[count], key, len) == 0)
        result = count;
      else
        count++;
    }

  return result;
}

static inline void
processComment (FLAC__StreamMetadata_VorbisComment_Entry *vcEntry,
                NSString **arrayOfValues[])
{
  char *key, *value, *equalsign;
  signed int position;

  key = strndup ((char *) vcEntry->entry, vcEntry->length);
  equalsign = strchr (key, '=');
  if (equalsign)
    {
      *equalsign = 0;
      value = equalsign + 1;
      position = keyPositionInArray (key);
      if (position > -1)
        SET (*arrayOfValues[position], [NSString stringWithUTF8String: value]);
    }
  free (key);
}

static FLAC__StreamDecoderWriteStatus
writeCallback (const FLAC__StreamDecoder *fileDecoder, const FLAC__Frame *frame,
               const FLAC__int32 * const buffer[], void *clientData)
{
  return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE;
}

static void
metadataCallback (const FLAC__StreamDecoder *fileDecoder,
                  const FLAC__StreamMetadata *metadata,
                  void *clientData)
{
  unsigned int count;

  if (metadata->type == FLAC__METADATA_TYPE_VORBIS_COMMENT)
    {
      count = 0;
      while (count < metadata->data.vorbis_comment.num_comments)
        {
          processComment (metadata->data.vorbis_comment.comments + count,
                          clientData);
          count++;
        }
    }
}

static void
errorCallback (const FLAC__StreamDecoder *fileDecoder,
               FLAC__StreamDecoderErrorStatus status,
               void *clientData)
{
  NSLog (@"FLACTags: received error with status %d", status);
}

@implementation FLACTags : NSObject

+ (NSString *) bundleDescription
{
  return @"A bundle to read/set the tags of FLAC files";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObject: @"Copyright (C) 2006 Wolfgang Sourdeau"];
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
  FLAC__StreamDecoder *fileDecoder;
  BOOL result;
  NSString **arrayOfValues[] = { title, artist, album, trackNumber,
                                 genre, year };

  fileDecoder = FLAC__stream_decoder_new();
  if(FLAC__stream_decoder_init_file(fileDecoder,
		[filename cString], writeCallback, metadataCallback,
		errorCallback, arrayOfValues) != FLAC__STREAM_DECODER_INIT_STATUS_OK)
    {
      result = NO;
    }
  else
    {
      result = FLAC__stream_decoder_process_until_end_of_metadata(fileDecoder);
    }

  return result;
}

@end
