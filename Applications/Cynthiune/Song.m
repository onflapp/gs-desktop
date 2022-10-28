/* Song.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002, 2003 Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <wolfgang@contre.com>
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

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSPathUtilities.h>

#import <Cynthiune/Format.h>
#import <Cynthiune/NSStringExtensions.h>
#import <Cynthiune/Tags.h>
#import <Cynthiune/utils.h>

#import "FormatTester.h"
#import "Song.h"

#define LOCALIZED(X) NSLocalizedString (X, nil)

@implementation Song : NSObject

+ (Song *) songWithFilename: (NSString *) aFilename
{
  Song *newSong;

  newSong = [[self alloc] initWithFilename: aFilename];
  [newSong autorelease];

  return newSong;
}

- (id) init
{
  if ((self = [super init]))
    {
      filename = nil;
      status = SongFileNotFound;
      isSeekable = NO;
      title = nil;
      artist = nil;
      album = nil;
      genre = nil; 
      trackNumber = nil;
      year = nil;
      formatClass = Nil;
      duration = nil;
      size = 0;
      date = nil;
    }

  return self;
}

- (BOOL)isEqual:(id)object
{
  if (object == self)
    return YES;
  if ([object class] != [self class])
    return NO;
  return [filename isEqualToString:[object filename]];
}

- (id) initWithFilename: (NSString *) aFilename
{
  self = [self init];
  [self setFilename: aFilename];

  return self;
}

- (void) _detectFormatClass
{
  FormatTester *formatTester;

  formatTester = [FormatTester formatTester];
  formatClass =
    [formatTester formatClassForFileExtension: [filename pathExtension]];
  if (!formatClass)
    formatClass = [formatTester formatClassForFile: filename];

  if (!formatClass)
    status = SongFormatNotRecognized;
}

- (NSObject <Format> *) openStreamForSong
{
  NSObject <Format> *stream;

  stream = nil;

  if (filename
      && [[NSFileManager defaultManager] fileExistsAtPath: filename])
    {
      if (!formatClass)
        [self _detectFormatClass];

      if (formatClass)
        {
          stream = [formatClass new];
          if ([stream streamOpen: filename])
            {
              [stream autorelease];
              status = SongOK;
            }
          else
            {
              [stream release];
              stream = nil;
              status = SongStreamError;
            }
        }
    }
  else
    status = SongFileNotFound;

  return stream;
}

- (BOOL) _fileWasModified
{
  NSFileManager *fileManager;
  NSDictionary *attributes;
  NSDate *newDate;
  unsigned long long newSize;
  BOOL modified;

  modified = NO;

  fileManager = [NSFileManager defaultManager];
  attributes = [fileManager fileAttributesAtPath: filename
                            traverseLink: YES];
  if (attributes)
    {
      newDate = [attributes fileModificationDate];
      newSize = [attributes fileSize];

      if (!(date && [date isEqualToDate: newDate]))
        {
          modified = YES;
          SET (date, newDate);
        }

      if (size != newSize)
        {
          modified = YES;
          size = newSize;
        }
    }
  else
    {
      status = SongFileNotFound;
      modified = YES;
    }

  return modified;
}

- (NSEnumerator *) _tagsClassesForProtocol: (Protocol *) protocol
{
  NSString *className;
  NSMutableArray *classes;
  NSEnumerator *classEnumerator;
  Class class;

  classes = [NSMutableArray new];
  [classes autorelease];

  if (!formatClass)
    [self _detectFormatClass];

  if (formatClass)
    {
      classEnumerator = [[formatClass compatibleTagBundles] objectEnumerator];
      className = [classEnumerator nextObject];
      while (className)
        {
          class = NSClassFromString (className);
          if (class && [class conformsToProtocol: protocol])
            [classes addObject: className];
          className = [classEnumerator nextObject];
        }
    }

  return [classes objectEnumerator];
}

- (void) _refreshSongInfos
{
  id <Format> stream;
  NSEnumerator *readingClasses;
  NSString *readingClass;

  readingClasses = [self _tagsClassesForProtocol: @protocol (TagsReading)];
  readingClass = [readingClasses nextObject];
  while (readingClass
         && ![NSClassFromString (readingClass) readTitle: &title
                                artist: &artist
                                album: &album
                                trackNumber: &trackNumber
                                genre: &genre
                                year: &year
                                ofFilename: filename])
    readingClass = [readingClasses nextObject];

  if ([title length] == 0)
    {
      title = [NSString stringWithFormat: @"[%@]",
                        makeTitleFromFilename (filename)];
      [title retain];
    }

  stream = [self openStreamForSong];
  if (stream)
    {
      isSeekable = [stream isSeekable];
      SET (duration, [NSNumber numberWithUnsignedInt: [stream readDuration]]);
      [stream streamClose];
    }
}

- (void) _readInfos
{
  if (fileIsAcceptable (filename))
    {
      if ([self _fileWasModified])
        [self _refreshSongInfos];
    }
  else
    status = SongFileNotFound;

  if (status != SongOK)
    {
      if (date)
        {
          [date release];
          date = nil;
        }
      size = 0;
      SET (duration, [NSNumber numberWithUnsignedInt: 0]);
    }
}

- (void) setFilename: (NSString *) aFilename
{
  SET (filename, [aFilename stringByStandardizingPath]);
  if (!fileIsAcceptable (filename))
    status = SongFileNotFound;
  else
    status = SongOK;
}

- (NSString *) filename
{
  RETURNSTRING (filename);
}

- (NSString *) shortFilename
{
  return ((filename)
          ? [NSString stringWithString: [filename lastPathComponent]]
          : @"");
}

- (NSNumber *) duration
{
  [self _readInfos];

  return duration;
}

- (BOOL) songInfosCanBeModified
{
  NSEnumerator *writingClasses;
  NSFileManager *fm;
  NSString *writingClass;

  writingClasses = [self _tagsClassesForProtocol: @protocol (TagsWriting)];
  writingClass = [writingClasses nextObject];
  fm = [NSFileManager defaultManager];

  return (writingClass && [fm isWritableFileAtPath: filename]);
}

- (NSString *) title
{
  [self _readInfos];

  RETURNSTRING (title);
}

- (NSString *) artist
{
  [self _readInfos];

  RETURNSTRING (artist);
}

- (NSString *) album
{
  [self _readInfos];

  RETURNSTRING (album);
}

- (NSString *) genre
{
  [self _readInfos];

  RETURNSTRING (genre);
}

- (NSString *) trackNumber
{
  [self _readInfos];

  RETURNSTRING (trackNumber);
}

- (NSString *) year
{
  [self _readInfos];

  RETURNSTRING (year);
}

- (void) setTitle: (NSString *) newTitle
           artist: (NSString *) newArtist
            album: (NSString *) newAlbum
            genre: (NSString *) newGenre
      trackNumber: (NSString *) newTrackNumber
             year: (NSString *) newYear
{
  NSString *savedTitle, *savedArtist, *savedAlbum, *savedGenre,
    *savedTrackNumber, *savedYear;
  NSString *writingClass;
  NSEnumerator *writingClasses;

  savedTitle = ([title isEqualToString: newTitle]) ? nil : newTitle;
  savedArtist = ([artist isEqualToString: newArtist]) ? nil : newArtist;
  savedAlbum = ([album isEqualToString: newAlbum]) ? nil : newAlbum;
  savedGenre = ([genre isEqualToString: newGenre]) ? nil : newGenre;
  savedTrackNumber = (([trackNumber isEqualToString: newTrackNumber])
                      ? nil
                      : newTrackNumber);
  savedYear = ([year isEqualToString: newYear]) ? nil : newYear;

  writingClasses = [self _tagsClassesForProtocol: @protocol (TagsWriting)];
  writingClass = [writingClasses nextObject];
  while (writingClass
         && ![NSClassFromString (writingClass) setTitle: savedTitle
                                artist: savedArtist
                                album: savedAlbum
                                trackNumber: savedTrackNumber
                                genre: savedGenre
                                year: savedYear
                                ofFilename: filename])
    writingClass = [writingClasses nextObject];
}

- (NSString *) playlistRepresentation
{
  NSMutableString *string;

  [self _readInfos];

  string = [NSMutableString string];

  switch (status)
    {
    case SongOK:
      if ([trackNumber length])
        [string appendFormat: @"%@. ", trackNumber];

      if ([title length])
        {
          [string appendString: title];
          if ([artist length])
            [string appendFormat: @" - %@", artist];
        }
      else
        {
          if ([artist length])
            [string appendString: artist];
        }

      if ([album length])
        {
          if ([title length] || [artist length])
            [string appendString: @" "];
          [string appendFormat: @"(%@)", album];
        }
      break;
    case SongFileNotFound:
      [string appendFormat: LOCALIZED (@"[not found: %@]"), filename];
      break;
    case SongFormatNotRecognized:
      [string appendFormat: LOCALIZED (@"[unknown format: %@]"), filename];
      break;
    case SongStreamError:
      [string appendFormat: LOCALIZED (@"[format error: %@]"), filename];
      break;
    }

  return string;
}

- (SongStatus) status
{
  [self _readInfos];

  return status;
}

- (BOOL) isSeekable
{
  return isSeekable;
}

- (NSComparisonResult) compareByPlaylistRepresentation: (Song *) aSong
{
  NSComparisonResult result;
  NSString *selfDirectory, *songDirectory;

  selfDirectory = [filename stringByDeletingLastPathComponent];
  songDirectory = [[aSong filename] stringByDeletingLastPathComponent];
  result = [selfDirectory caseInsensitiveCompare: songDirectory];
  if (result == NSOrderedSame)
    {
      result = [album caseInsensitiveCompare: [aSong album]];
      if (result == NSOrderedSame)
        {
          result = [trackNumber numericallyCompare: [aSong trackNumber]];
          if (result == NSOrderedSame)
            {
              result = [artist caseInsensitiveCompare: [aSong artist]];
              if (result == NSOrderedSame)
                result = [title caseInsensitiveCompare: [aSong title]];
            }
        }
    }

  return result;
}

- (NSComparisonResult) reverseCompareByPlaylistRepresentation: (Song *) aSong
{
  return
    reverseComparisonResult ([self compareByPlaylistRepresentation: aSong]);
}

- (NSComparisonResult) compareByDuration: (Song *) aSong
{
  return [duration compare: [aSong duration]];
}

- (NSComparisonResult) reverseCompareByDuration: (Song *) aSong
{
  return reverseComparisonResult ([duration compare: [aSong duration]]);
}

- (void) dealloc
{
  RELEASEIFSET (filename);
  RELEASEIFSET (title);
  RELEASEIFSET (artist);
  RELEASEIFSET (album);
  RELEASEIFSET (genre); 
  RELEASEIFSET (trackNumber);
  RELEASEIFSET (duration);
  RELEASEIFSET (date);

  [super dealloc];
}

/* NSCoding protocol */
- (void) encodeWithCoder: (NSCoder *) encoder
{
  [self _readInfos];

  [encoder encodeObject: filename forKey: @"filename"];
  if (title)
    [encoder encodeObject: title forKey: @"title"];
  if (artist)
    [encoder encodeObject: artist forKey: @"artist"];
  if (album)
    [encoder encodeObject: album forKey: @"album"];
  if (trackNumber)
    [encoder encodeObject: trackNumber forKey: @"trackNumber"];
  if (genre)
    [encoder encodeObject: genre forKey: @"genre"];
  if (year)
    [encoder encodeObject: year forKey: @"year"];
  [encoder encodeObject: duration forKey: @"duration"];
  if (date)
    [encoder encodeObject: date forKey: @"date"];
  [encoder encodeBool: isSeekable forKey: @"isSeekable"];
  [encoder encodeInt: status forKey: @"status"];
  [encoder encodeInt64: size forKey: @"size"];
  [encoder encodeObject: [self playlistRepresentation]
           forKey: @"playlistRepresentation"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  if ((self = [self init]))
    {
      SET (filename, [decoder decodeObjectForKey: @"filename"]);
      SET (title, [decoder decodeObjectForKey: @"title"]);
      SET (artist, [decoder decodeObjectForKey: @"artist"]);
      SET (album, [decoder decodeObjectForKey: @"album"]);
      SET (trackNumber, [decoder decodeObjectForKey: @"trackNumber"]);
      SET (genre, [decoder decodeObjectForKey: @"genre"]);
      SET (year, [decoder decodeObjectForKey: @"year"]);
      SET (duration, [decoder decodeObjectForKey: @"duration"]);
      SET (date, [decoder decodeObjectForKey: @"date"]);
      isSeekable = [decoder decodeBoolForKey: @"isSeekable"];
      status = [decoder decodeIntForKey: @"status"];
      size = [decoder decodeIntForKey: @"size"];
    }

  return self;
}

@end
