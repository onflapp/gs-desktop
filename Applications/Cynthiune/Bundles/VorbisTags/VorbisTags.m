/* VorbisTags.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005, 2006  Wolfgang Sourdeau
 *
 * Portions Copyright (C) 2002  Yen-Ju  <yjchenx@hotmail.com>
 *          Copyright (C) ????  Rob Burns <rburns@softhome.net>
 * Those portions were taken from the Poe vorbis editor's OGGEdit class
 * and adapted to fit the TagsWriting Cynthiune formal protocol.
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

#import <vorbis/vorbisfile.h>

#import <Cynthiune/utils.h>

#import "VorbisTags.h"
#import "vcedit.h"

#define LOCALIZED(X) _b ([VorbisTags class], X)

static size_t
oggReadFunc (void *ptr, size_t size, size_t nmemb, void *datasource)
{
  NSFileHandle *fileHandle;
  NSData *data;
  size_t length;

  fileHandle = datasource;
  data = [fileHandle readDataOfLength: size * nmemb];
  length = [data length];
  memcpy (ptr, [data bytes], length);

  return length;
}

static int
oggSeekFunc (void *datasource, ogg_int64_t offset, int whence)
{
  NSFileHandle *fileHandle;
  unsigned long long realOffset;

  fileHandle = datasource;

  switch (whence)
    {
    case SEEK_SET:
      realOffset = offset;
      break;
    case SEEK_CUR:
      realOffset = [fileHandle offsetInFile] + offset;
      break;
    case SEEK_END:
      realOffset = [fileHandle seekToEndOfFile] + offset;
      break;
    default:
      NSLog (@"unrecognize value for whence: %d", whence);
      realOffset = [fileHandle offsetInFile];
    }

  [fileHandle seekToFileOffset: realOffset];

  return 0;
}

static int
oggCloseFunc (void *datasource)
{
  NSFileHandle *fileHandle;

  fileHandle = datasource;
  [fileHandle closeFile];

  return 0;
}

static long
oggTellFunc (void *datasource)
{
  NSFileHandle *fileHandle;

  fileHandle = datasource;

  return [fileHandle offsetInFile];
}

static ov_callbacks oggCallbacks = { oggReadFunc, oggSeekFunc,
                                     oggCloseFunc, oggTellFunc };

@implementation VorbisTags : NSObject

+ (NSString *) bundleDescription
{
  return @"A bundle to read/set the tags of Vorbis files";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2005  Wolfgang Sourdeau",
                  nil];
}

+ (void) _setString: (NSString **) string
          toComment: (char*) comment
         fromOvFile: (OggVorbis_File *) ovFile
{
  const char *cComment;
  vorbis_comment *vComment;
  char **cPointer;
  BOOL found = NO;
  int len;

  vComment = ov_comment (ovFile, -1);
  if (vComment)
    {
      cPointer = vComment->user_comments;
      cComment = *cPointer;
      len = strlen (comment);

      while (cComment && !found)
        {
          if (strncasecmp (comment, cComment, len) == 0)
            {
              cComment += len + 1;
              found = YES;
            }
          else
            {
              cPointer++;
              cComment = *cPointer;
            }
        }
      
      if (cComment)
        SET (*string, [NSString stringWithUTF8String: cComment]);
    }
}

+ (BOOL) readTitle: (NSString **) title
            artist: (NSString **) artist
             album: (NSString **) album
       trackNumber: (NSString **) trackNumber
             genre: (NSString **) genre
              year: (NSString **) year
        ofFilename: (NSString *) filename
{
  NSFileHandle *fileHandle;
  OggVorbis_File *ovFile;
  BOOL result;

  result = NO;
  fileHandle = [NSFileHandle fileHandleForReadingAtPath: filename];

  if (fileHandle)
    {
      ovFile = calloc (sizeof (OggVorbis_File), 1); 
      ov_open_callbacks (fileHandle, ovFile, NULL, 0L, oggCallbacks);
      [self _setString: title toComment: "title" fromOvFile: ovFile];
      [self _setString: artist toComment: "artist" fromOvFile: ovFile];
      [self _setString: album toComment: "album" fromOvFile: ovFile];
      [self _setString: trackNumber toComment: "tracknumber"
            fromOvFile: ovFile];
      [self _setString: genre toComment: "genre" fromOvFile: ovFile];
      [self _setString: year toComment: "date" fromOvFile: ovFile];
      ov_clear (ovFile);
    }

  return result;
}

+ (BOOL)  setTitle: (NSString *) title
            artist: (NSString *) artist
             album: (NSString *) album
       trackNumber: (NSString *) trackNumber
             genre: (NSString *) genre
              year: (NSString *) year
        ofFilename: (NSString *) filename;
{
  FILE *in, *out;
  vcedit_state *state;
  vorbis_comment *vc;
  NSString *newfile;
  BOOL result;
  NSFileManager *fm;

  fm = [NSFileManager defaultManager];
  
  result = NO;

  in = fopen ([filename cString], "rb");
  if (in)
    {
      fseek (in, 0L, SEEK_SET);

      state = vcedit_new_state ();

      if (vcedit_open (state, in) >= 0)
        {
          vc = vcedit_comments(state);
          vorbis_comment_clear (vc);
          vorbis_comment_init (vc);

          if (title)
            vorbis_comment_add_tag (vc, "title", (char *) [title UTF8String]);
          if (artist)
            vorbis_comment_add_tag (vc, "artist", (char *) [artist UTF8String]);
          if (album)
            vorbis_comment_add_tag (vc, "album", (char *) [album UTF8String]);
          if (trackNumber)
            vorbis_comment_add_tag (vc, "tracknumber", (char *) [trackNumber UTF8String]);
          if (genre)
            vorbis_comment_add_tag (vc, "genre", (char *) [genre UTF8String]);
          if (year)
            vorbis_comment_add_tag (vc, "date", (char *) [year UTF8String]);

          newfile = [filename stringByAppendingString: @"_temp"];
          out = fopen([newfile cString], "wb+");

          if (out)
            {
              if (vcedit_write (state, out) >= 0)
                {
                  fclose (out);
                  [fm removeFileAtPath: filename handler: nil];
                  [fm movePath: newfile toPath: filename handler: nil];
                  result = YES;
                }
            }

          vorbis_comment_clear (vc);
        }

      vcedit_clear (state);
      fclose(in);
    }


  return result;
}

@end
