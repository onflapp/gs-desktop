/* Song.h - this file is part of Cynthiune
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

#ifndef Song_H
#define Song_H

@class NSDate;
@class NSNumber;
@class NSString;

@protocol Format;

typedef enum _SongStatus
{
  SongOK = 0,
  SongFileNotFound = 1,
  SongFormatNotRecognized = 2,
  SongStreamError = 3,
} SongStatus;

@interface Song : NSObject <NSCoding>
{
  NSString *filename;

  BOOL isSeekable;
  NSString *title;
  NSString *artist;
  NSString *album;
  NSString *genre; 
  NSString *year;
  NSString *trackNumber;
  NSNumber *duration;

  NSDate *date;
  unsigned long long size;

  SongStatus status;

  Class formatClass;
}

+ (Song *) songWithFilename: (NSString *) filename;

- (id) init;
- (id) initWithFilename: (NSString *) filename;

- (NSObject <Format> *) openStreamForSong;

- (void) setFilename: (NSString *) newfilename;
- (NSString *) filename;
- (NSString *) shortFilename;

- (SongStatus) status;

- (BOOL) isSeekable;

- (BOOL) songInfosCanBeModified;

- (NSString *) title;
- (NSString *) artist;
- (NSString *) album;
- (NSString *) genre;
- (NSString *) trackNumber;
- (NSString *) year;

- (void) setTitle: (NSString *) newTitle
           artist: (NSString *) newArtist
            album: (NSString *) newAlbum
            genre: (NSString *) newGenre
      trackNumber: (NSString *) newTrackNumber
             year: (NSString *) newYear;

- (NSNumber *) duration;

- (NSString *) playlistRepresentation;

- (NSComparisonResult) compareByPlaylistRepresentation: (Song *) aSong;
- (NSComparisonResult) reverseCompareByPlaylistRepresentation: (Song *) aSong;
- (NSComparisonResult) compareByDuration: (Song *) aSong;
- (NSComparisonResult) reverseCompareByDuration: (Song *) aSong;

@end

#endif /* Song_H */
