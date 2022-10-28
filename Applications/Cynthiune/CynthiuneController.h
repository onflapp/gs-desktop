/* CynthiuneController.h - this file is part of Cynthiune
 *
 * Copyright (C) 2003, 2004  Wolfgang Sourdeau
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

#ifndef CynthiuneController_H
#define CynthiuneController_H

#import "CynthiuneWindow.h"

@class NSApplication;
@class NSButton;
@class NSNotification;
@class NSWindow;
@class NSString;
@class NSTimer;

@class PlaylistController;

@protocol Output;

@interface CynthiuneController : NSObject
{
  BOOL bundlesLoaded;

  PlaylistController *playlistController;

  NSWindow *playerWindow;
  NSWindow *playlistWindow;
  NSButton *playlistSwitch;
  BOOL isStuck;
  BOOL playlistWindowIsVisible;

  int WindowsTitleSize;
  int WindowsBorderSize;
  float deltaX, deltaY;

  id bugReportMenuItem;
}

- (id) init;

- (BOOL) application: (NSApplication *) anApp
            openFile: (NSString *) aFilename;

- (void) openFile: (id) anObject;
- (void) preferencesWindow: (id) anObject;

- (void) togglePlaylistWindow: (id) sender;
- (void) setPlaylistWindowVisible: (BOOL) isVisible;

- (void) _parseArguments;
- (void) _initWindowsPosition;

@end

#endif /* CynthiuneController_H */
