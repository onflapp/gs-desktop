/* GeneralPreference.h - this file is part of Cynthiune
 *
 * Copyright (C) 2003 Wolfgang Sourdeau
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

#ifndef OUTPUTPREFERENCE_H
#define OUTPUTPREFERENCE_H

#import <Foundation/NSObject.h>

@class NSBox;
@class NSMutableArray;
@class NSMutableDictionary;
@class NSTextField;
@class NSWindow;

@protocol Preference;

@interface GeneralPreference : NSObject <Preference>
{
  NSMutableDictionary *preference;

  NSMutableArray *playersList;

  NSWindow *prefsWindow;

  id outputBundleSelector;
  id playlistFormatSelector;
  id playlistReferenceTypeToggle;
  id stickyWinToggle;
  id saveWindowsInformationToggle;

#ifdef __MACOSX__
  id texturedWindowsToggle;
#endif

  NSBox *windowsBox;
  NSBox *playlistsBox;
  NSBox *outputModuleBox;
  NSTextField *playlistsFormatLabel;
}

- (GeneralPreference *) init;

- (void) registerOutputClass: (Class) aClass;

- (Class) preferredOutputClass;
- (NSString *) preferredPlaylistFormat;
- (BOOL) absolutePlaylistReferences;
#ifdef __MACOSX__
- (BOOL) windowsAreTextured;
#endif
- (BOOL) windowsAreSticky;
- (BOOL) saveWindowsInformation;

- (void) saveInformation: (NSWindow *) aWindow
               forWindow: (NSString *) windowName;
- (void) restoreInformation: (NSWindow *) aWindow
                  forWindow: (NSString *) windowName;

/* as a target */
- (void) outputBundleChanged: (id) sender;
- (void) playlistFormatChanged: (id) sender;
- (void) playlistReferenceTypeChanged: (id) sender;
#ifdef __MACOSX__
- (void) texturedWindowsChanged: (id) sender;
#endif
- (void) stickyWindowsChanged: (id) sender;
- (void) saveWindowsInformationChanged: (id) sender;

@end


#endif /* OUTPUTPREFERENCE_H */
