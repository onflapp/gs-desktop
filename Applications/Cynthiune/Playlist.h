/* Playlist.h - this file is part of Cynthiune
 *
 * Copyright (C) 2005  Wolfgang Sourdeau
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

#ifndef Playlist_H
#define Playlist_H

@class NSNumber;
@class NSMutableArray;
@class Song;

@interface Playlist : NSObject
{
  id delegate;
  NSMutableArray *list;
  NSMutableArray *shuffleList;
}

- (id) init;

- (void) setDelegate: (id) object;
- (id) delegate;

- (void) addSong: (Song *) song;
- (void) addSongsInArray: (NSArray *) array;
- (void) insertSong: (Song *) song
            atIndex: (unsigned int) index;

- (void) deleteSong: (Song *) song;
- (void) deleteAllSongs;
- (void) deleteAllSongsQuietly;
- (void) deleteSongsInArray: (NSArray *) array;
- (NSArray *) arrayOfInvalidSongs;

- (void) replaceSongsWithArray: (NSArray *) array;

- (Song *) songAtIndex: (unsigned int) index;
- (unsigned int) indexOfSong: (Song *) song;

- (unsigned int) moveSongsAtIndexes: (NSArray *) indexes
                            toIndex: (unsigned int) index;

- (Song *) firstSong;
- (Song *) lastSong;
- (Song *) firstValidSong;
- (Song *) lastValidSong;

- (Song *) songAfter: (Song *) song;
- (Song *) songBefore: (Song *) song;
- (Song *) validSongAfter: (Song *) song;
- (Song *) validSongBefore: (Song *) song;

- (unsigned int) numberOfSongs;

- (NSNumber *) duration;

- (void) loadFromFile: (NSString *) file;
- (void) saveToFile: (NSString *) file;

- (void) sortByPlaylistRepresentation: (BOOL) reverseOrder;
- (void) sortByDuration: (BOOL) reverseOrder;

- (void) setShuffle: (BOOL) shuffle;
- (BOOL) shuffle;
- (void) shuffleFromSong: (Song *) shuffle;

@end

#endif /* Playlist_H */
