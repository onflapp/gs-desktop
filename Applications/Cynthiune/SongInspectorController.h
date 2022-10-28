/* SongInspectorController.h - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
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

#ifndef SongInspectorController_H
#define SongInspectorController_H

@class NSPanel;
@class Song;

@interface SongInspectorController : NSObject
{
  id filenameField;

  id titleField;
  id albumField;
  id trackField;
  id artistField;
  id genreField;
  id yearField;

  id albumLabel;
  id artistLabel;
  id genreLabel;
  id titleLabel;
  id trackLabel;
  id yearLabel;

  id pageSelector;

  id resetButton;
  id saveButton;

  id lookupButton;
  id lookupStatusLabel;
  id lookupAnimation;

  NSPanel *inspectorPanel;

  Song *song;

  BOOL visible;

  BOOL threadRunning;
  BOOL threadShouldDie;
//   pthread_t lookupThreadId;

  id delegate;
}

+ (SongInspectorController *) songInspectorController;

- (void) setDelegate: (id) delegate;
- (id) delegate;

#ifndef __WIN32__
- (void) mbLookup: (id)sender;
#endif

- (void) reset: (id)sender;
- (void) save: (id)sender;
 
- (void) setSong: (Song *) song;
- (Song *) song;

- (void) toggleDisplay;

@end

@interface NSObject (SongInspectorControllerDelegate)

- (void) songInspectorWasShown: (NSNotification *) notification;
- (void) songInspectorWasHidden: (NSNotification *) notification;
- (void) songInspectorDidUpdateSong: (NSNotification *) notification;

@end

#endif /* SongInspectorController_H */
