/* PreferencesController.h - this file is part of Cynthiune
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

#ifndef PreferencesController_H
#define PreferencesController_H

@class NSBox;
@class NSMutableDictionary;
@class NSWindow;

@class CynthiunePopUpButton;

@interface PreferencesController : NSObject
{
  BOOL windowIsVisible;

  NSMutableArray *preferenceList;

  Class currentBundleClass;

  NSWindow *prefsWindow;
  CynthiunePopUpButton *bundleSelector;
  NSBox *bundleViewBox;
  NSView *currentView;
}

+ (PreferencesController *) preferencesController;

- (PreferencesController *) init;

- (void) registerPreferenceClass: (Class) aClass;

- (void) loadPreferencesWindow;
- (void) loadPreferencesWindowAndSelectMenuEntry: (NSString *) entry;

- (void) setBundleView: (id) bundlePrefsView;
- (void) setBundleClass: (Class) aClass;

- (void) bundleChanged: (id)sender;

@end

#endif /* PreferencesController_H */
