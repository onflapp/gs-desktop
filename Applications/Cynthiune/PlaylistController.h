/* PlaylistController.h - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004  Wolfgang Sourdeau
 *               2013 The Free Software Foundation
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

#ifndef PlaylistController_H
#define PlaylistController_H

#if defined(__APPLE__) && (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
#ifndef NSUInteger
#define NSUInteger unsigned
#endif
#ifndef NSInteger
#define NSInteger int
#endif
#ifndef CGFloat
#define CGFloat float
#endif
#endif

@class NSTimer;
@class NSToolbar;

@class InfoDisplayController;
@class CynthiuneController;
@class Player;
@class Playlist;
@class PlaylistViewController;
@class Song;
@class SongInspectorController;

@interface PlaylistController : NSObject
{
  id previousButton;
  id playButton;
  id pauseButton;
  id stopButton;
  id ejectButton;
  id nextButton;

  id addButton;
  id removeButton;
//   id removeAllButton;
  id cleanupButton;
//   id saveButton;
  id saveAsButton;
  id songInspectorButton;

  id repeatButton;
  id shuffleButton;

  id repeatMenuItem;
  id shuffleMenuItem;
  id songInspectorMenuItem;

  id timerButton;

  id progressSlider;

  id playlistStatusLabel;

//   id drawer;

  /* non-ui */
  InfoDisplayController *infoDisplayController;
  PlaylistViewController *playlistViewController;
  SongInspectorController *songInspectorController;

  Player *player;
  NSTimer *timer;

  Playlist *playlist;
  NSString *playlistFilename;

  Song *currentPlayerSong;
  Song *notifiedFirstSong;

  BOOL repeat;
}

/* player console */
- (void) previousSong: (id) sender;
- (void) startPlayer: (id) sender;
- (void) pausePlayer: (id) sender;
- (void) stopPlayer: (id) sender;
- (void) nextSong: (id) sender;
- (void) eject: (id) sender;

- (void) songCursorChange: (id) sender;

- (void) changeTimeDisplay: (id) sender;

- (void) toggleRepeat: (id) sender;
- (void) toggleShuffle: (id) sender;

- (void) toggleSongInspector: (id) sender;

/* menu actions */
- (void) addSongs: (id) sender;

- (void) addPlaylist: (id) sender;

- (void) removeSelectedSongs: (id) sender;
- (void) removeAllSongs: (id) sender;
- (void) cleanupPlaylist: (id) sender;

- (void) saveList: (id) sender;
- (void) saveListAs: (id) sender;

/* interface for CynthiuneController */
- (void) initializeWidgets;
- (NSToolbar *) playlistToolbar;

- (void) addSongFromNSApp: (id) sender;
- (void) openSongFromNSApp: (NSString *) songFilename;

- (id) validRequestorForSendType: (NSString *) sendType
                      returnType: (NSString *) returnType;

- (void) savePlayerState;

/* interface for PlaylistViewController */
- (void) tableDoubleClick: (int) row;
- (void) tableFilenamesDropped: (NSArray *) filenames;

- (void) updateStatusLabel;
- (void) updateSongInspector;

@end

#endif /* PlaylistController_H */
