/* PreferencesController.m - this file is part of Cynthiune
 *
 * Copyright (C) 2003 Wolfgang Sourdeau
 *               2012 The Free Software Foundation
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
 *         Riccardo Mottola <rm@gnu.org>
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

#import <AppKit/NSApplication.h>
#import <AppKit/NSBox.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSWindow.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#import <Cynthiune/Preference.h>
#import <Cynthiune/NSViewExtensions.h>

#import "CynthiunePopUpButton.h"
#import "GeneralPreference.h"
#import "PreferencesController.h"

#define LOCALIZED(X) NSLocalizedString (X, nil)

@implementation PreferencesController : NSObject

+ (PreferencesController *) preferencesController
{
  static PreferencesController *singleton = nil;

  if (!singleton)
    singleton = [self new];

  return singleton;
}

- (PreferencesController *) init
{
  if ((self = [super init]))
    {
      currentView = nil;
      windowIsVisible = NO;
      preferenceList = [NSMutableArray new];
      [preferenceList addObject: [GeneralPreference class]];
    }

  return self;
}

- (void) registerPreferenceClass: (Class) aClass
{
  if ([aClass conformsToProtocol: @protocol(Preference)]
      && ![preferenceList containsObject: aClass])
    [preferenceList addObject: aClass];
}

- (void) _setupMenuEntries
{
  Class currentClass;
  id <Preference> instance;
  int count, max;

  [bundleSelector removeAllItems];
  max = [preferenceList count];

  if (max)
    for (count = 0; count < max; count++)
      {
        currentClass = [preferenceList objectAtIndex: count];
        instance = [currentClass instance];
        [bundleSelector addItemWithTitle: [instance preferenceTitle]];
      }
  else
    [bundleSelector addItemWithTitle: LOCALIZED (@"None")];
}

- (void) loadPreferencesWindow
{
  Class bundleClass;

  if (!windowIsVisible)
    {
      [NSBundle loadNibNamed: @"Preferences" owner: self];
      [self _setupMenuEntries];

      bundleClass = [preferenceList objectAtIndex: 0];
      [self setBundleClass: bundleClass];

      [bundleSelector sizeToFit];
      [bundleSelector centerViewHorizontally];
      [prefsWindow setLevel: NSModalPanelWindowLevel];
      [prefsWindow setTitle: LOCALIZED (@"Preferences")];
      [prefsWindow center];
      [prefsWindow orderWindow: NSWindowAbove
                   relativeTo: [[NSApp mainWindow] windowNumber]];
      [prefsWindow makeKeyAndOrderFront: self];
      [prefsWindow setDelegate: self];
      windowIsVisible = YES;
    }
}

- (void) loadPreferencesWindowAndSelectMenuEntry: (NSString *) entry
{
  [self loadPreferencesWindow];
  [bundleSelector selectItemWithTitle: entry];
}

- (void) windowWillClose: (NSNotification *) aNotif
{
  id <Preference> instance;

  windowIsVisible = NO;
  instance = [currentBundleClass instance];
  [instance save];
}

- (void) setBundleClass: (Class) aClass
{
  NSView *prefsView;
  id <Preference> instance;

  instance = [aClass instance];
  prefsView = [instance preferenceSheet];
  [self setBundleView: prefsView];

  currentBundleClass = aClass;
}

- (void) bundleChanged: (id)sender
{
  NSString *newTitle;
  Class bundleClass;
  id <Preference> instance;

  newTitle = [sender titleOfSelectedItem];
  [sender setTitle: newTitle];
  [sender synchronizeTitleAndSelectedItem];
  bundleClass = [preferenceList objectAtIndex: [sender indexOfSelectedItem]];
  if (bundleClass != currentBundleClass)
    {
      instance = [currentBundleClass instance];
      [instance save];
      [self setBundleClass: bundleClass];
    }
}

- (void) setBundleView: (id) bundlePrefsView
{
  NSRect boxViewFrame, viewFrame;
  NSArray *subviews;
  NSView *contentView;

  contentView = [bundleViewBox contentView];
  subviews = [contentView subviews];
  if ([subviews count])
    [[subviews objectAtIndex: 0] removeFromSuperview];

  if (bundlePrefsView)
    {
      boxViewFrame = [contentView bounds];
      viewFrame = [bundlePrefsView frame];
      viewFrame.origin.x = (boxViewFrame.size.width
                            - viewFrame.size.width) / 2;
      viewFrame.origin.y = (boxViewFrame.size.height
                            - viewFrame.size.height) / 2;

      viewFrame = [contentView centerScanRect: viewFrame];
      [bundlePrefsView setFrame: viewFrame];
      [contentView addSubview: bundlePrefsView];
    }

  [bundleViewBox setNeedsDisplay: YES];
}

@end
