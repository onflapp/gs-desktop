/* PlaylistViewController.h - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2005  Wolfgang Sourdeau
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

#ifndef PlaylistViewController_H
#define PlaylistViewController_H

@class NSArray;
@class NSNumber;
@class NSObject;
@class NSString;
@class NSNotificationCenter;

@class Playlist;
@class PlaylistController;
@class Song;

@interface PlaylistViewController : NSObject
{
  Playlist *playlist;
  PlaylistController *playlistController;

  id playlistView;          // table view

  /* sorting */
  NSString *sortColumn;
  NSComparisonResult sortDirection;

  /* current song pointer */
  Song *currentPlayerSong;
}

- (id) init;

- (void) setPlaylistController: (PlaylistController *) controller;

- (int) getFirstSelectedRow;
- (Song *) getFirstSelectedSong;
- (NSArray *) getSelectedSongs;
- (NSArray *) getSelectedSongsAsFilenames;

- (NSNumber *) durationOfSelection;

- (void) selectSongsInArray: (NSArray *) array;

- (void) invalidateSortedColumn;

- (void) updateView;
- (void) setPlaylist: (Playlist *) aPlaylist;

- (void) setCurrentPlayerSong: (Song *) newSong;

- (void) deselectAll;

@end

#endif /* PlaylistViewController_H */
