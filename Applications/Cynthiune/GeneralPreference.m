/* GeneralPreference.m - this file is part of Cynthiune
 *
 * Copyright (C) 2003 Wolfgang Sourdeau
 *               2012 The Free Software Foundation, Inc
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

#import <AppKit/NSBox.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSTextField.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import <Cynthiune/NSViewExtensions.h>
#import <Cynthiune/Output.h>
#import <Cynthiune/Preference.h>

#import "PreferencesController.h"
#import "GeneralPreference.h"

#define LOCALIZED(X) NSLocalizedString (X, nil)

#ifdef __MACOSX__
#define defaultOutputBundle @"MacOSXPlayer"
#else
#ifdef __linux__
#define defaultOutputBundle @"ALSA"
#else
#ifdef __OpenBSD__
#define defaultOutputBundle @"Sndio"
#else
#ifdef __WIN32__
#define defaultOutputBundle @"WaveOut"
#else
#define defaultOutputBundle @"OSS"
#endif
#endif
#endif
#endif

#define defaultPlaylistFormat @"m3u"

@implementation GeneralPreference : NSObject

+ (id) instance
{
  static GeneralPreference *singleton = nil;

  if (!singleton)
    singleton = [self new];

  return singleton;
}

- (void) _initDefaults
{
  NSString *outputBundle, *playlistFormat;
  NSNumber *windowsAreSticky, *saveWindowsInformation,
    *playlistReferenceType;
  NSMutableDictionary *windowsInformation;
  static BOOL initted = NO;
#ifdef __MACOSX__
  NSNumber *windowsAreTextured;
#endif
  
  if (!initted)
    {
      outputBundle = [preference objectForKey: @"OutputBundle"];
      if (!outputBundle
          || !([playersList containsObject: NSClassFromString (outputBundle)]))
        {
          outputBundle = defaultOutputBundle;
          [preference setObject: outputBundle forKey: @"OutputBundle"];
        }

      playlistFormat = [preference objectForKey: @"PlaylistFormat"];
      if (!playlistFormat
          || !([playlistFormat isEqualToString: @"m3u"]
               || [playlistFormat isEqualToString: @"pls"]))
        {
          playlistFormat = defaultPlaylistFormat;
          [preference setObject: playlistFormat
                      forKey: @"PlaylistFormat"];
        }

      playlistReferenceType =
        [preference objectForKey: @"AbsolutePlaylistReferences"];
      if (!playlistReferenceType)
        {
          playlistReferenceType = [NSNumber numberWithBool: NO];
          [preference setObject: playlistReferenceType
                      forKey: @"AbsolutePlaylistReferences"];
        }

#ifdef __MACOSX__
      windowsAreTextured = [preference objectForKey: @"TexturedWindows"];
      if (!windowsAreTextured)
        {
          windowsAreTextured = [NSNumber numberWithBool: NO];
          [preference setObject: windowsAreTextured
                      forKey: @"TexturedWindows"];
        }
#endif

      windowsAreSticky = [preference objectForKey: @"StickyWindows"];
      if (!windowsAreSticky)
        {
          windowsAreSticky = [NSNumber numberWithBool: YES];
          [preference setObject: windowsAreSticky
                      forKey: @"StickyWindows"];
        }

      saveWindowsInformation =
        [preference objectForKey: @"SaveWindowsInformation"];
      if (!saveWindowsInformation)
        {
          saveWindowsInformation = [NSNumber numberWithBool: YES];
          [preference setObject: saveWindowsInformation
                      forKey: @"SaveWindowsInformation"];
        }

      windowsInformation = [preference objectForKey: @"WindowsInformation"];
      if (!windowsInformation)
        {
          windowsInformation = [NSMutableDictionary dictionaryWithCapacity: 1];
        }
      else
	{
	  /* reading a preference looses the mutable attribute */
	  windowsInformation = [NSMutableDictionary dictionaryWithDictionary: windowsInformation];
	}
      [preference setObject: windowsInformation
		     forKey: @"WindowsInformation"];
      initted = YES;
    }
}

- (GeneralPreference *) init
{
  NSDictionary *tmpDict;

  if ((self = [super init]))
    {
      playersList = [NSMutableArray new];
      tmpDict = [[NSUserDefaults standardUserDefaults]
                     dictionaryForKey: @"GeneralPreference"];
      preference = [NSMutableDictionary dictionaryWithDictionary: tmpDict];
      [preference retain];
    }

  return self;
}

- (void) save
{
  NSUserDefaults *defaults;

  defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject: preference forKey: @"GeneralPreference"];
  [defaults synchronize];
}

- (void) registerOutputClass: (Class) aClass
{
  if ([aClass conformsToProtocol: @protocol(Output)])
    {
      if (![playersList containsObject: aClass])
        [playersList addObject: aClass];
    }
  else
    NSLog (@"Class '%@' not conform to the 'Output' protocol...\n",
           NSStringFromClass (aClass));
}

- (Class) preferredOutputClass
{
  [self _initDefaults];

  return NSClassFromString ([preference objectForKey: @"OutputBundle"]);
}

- (NSString *) preferredPlaylistFormat
{
  [self _initDefaults];

  return [preference objectForKey: @"PlaylistFormat"];
}

- (BOOL) absolutePlaylistReferences
{
  [self _initDefaults];

  return [[preference objectForKey: @"AbsolutePlaylistReferences"] boolValue];
}

#ifdef __MACOSX__
- (BOOL) windowsAreTextured
{
  NSNumber *windowsAreTextured;

  [self _initDefaults];

  windowsAreTextured = [preference objectForKey: @"TexturedWindows"];

  return [windowsAreTextured boolValue];
}
#endif

- (BOOL) windowsAreSticky
{
  NSNumber *windowsAreSticky;

  [self _initDefaults];

  windowsAreSticky = [preference objectForKey: @"StickyWindows"];

  return [windowsAreSticky boolValue];
}

- (BOOL) saveWindowsInformation
{
  NSNumber *saveWindowsInformation;

  saveWindowsInformation =
    [preference objectForKey: @"SaveWindowsInformation"];

  return [saveWindowsInformation boolValue];
}

- (void) saveInformation: (NSWindow *) aWindow
               forWindow: (NSString *) windowName
{
  NSMutableArray *information;
  NSMutableDictionary *windowsInformation;
  NSString *frameString;

  windowsInformation = [preference objectForKey: @"WindowsInformation"];
  information = [NSMutableArray arrayWithCapacity: 3];
  frameString = [aWindow stringWithSavedFrame];
  [information addObject: frameString];
  [windowsInformation setObject: information forKey: windowName];
  [self save];
}

- (void) restoreInformation: (NSWindow *) aWindow
                  forWindow: (NSString *) windowName
{
  NSMutableDictionary *windowsInformation;
  NSString *frameString;
  NSArray *information;

  windowsInformation = [preference objectForKey: @"WindowsInformation"];
  information = [windowsInformation objectForKey: windowName];
  if (information)
    {
      frameString = [information objectAtIndex: 0];
      [aWindow setFrameFromString: frameString];
    }
}

// Preference protocol
- (NSString *) preferenceTitle
{
  return LOCALIZED (@"General");
}

- (NSView *) preferenceSheet
{
  NSView *aView;

  [NSBundle loadNibNamed: @"GeneralPreference" owner: self];
  aView = [prefsWindow contentView];
  [aView retain];
  [aView removeFromSuperview];
  [prefsWindow release];
  [aView autorelease];

  return aView;
}

- (void) _initializeSelector
{
  int count, max;
  Class currentClass;

  [outputBundleSelector removeAllItems];

  max = [playersList count];
  if (max > 0)
    {
      for (count = 0; count < max; count++)
        {
          currentClass = [playersList objectAtIndex: count];
          [outputBundleSelector
            addItemWithTitle: NSStringFromClass (currentClass)];
        }
    }
  else
    [outputBundleSelector addItemWithTitle: LOCALIZED (@"None")];

  [outputBundleSelector sizeToFit];
  [outputBundleSelector centerViewHorizontally];
}

- (void) awakeFromNib
{
  NSString *outputBundle;
  NSString *playlistFormat;
  NSNumber *toggleBool;

  [self _initDefaults];

#ifdef __MACOSX__
  [texturedWindowsToggle setTitle: LOCALIZED (@"Textured")];
#endif

  [stickyWinToggle setTitle: LOCALIZED (@"Sticky")];
  [saveWindowsInformationToggle setTitle: LOCALIZED (@"Remember location")];
  [windowsBox setTitle: LOCALIZED (@"Windows")];
  [playlistsBox setTitle: LOCALIZED (@"Playlists")];
  [playlistReferenceTypeToggle setTitle:
                                 LOCALIZED (@"Use absolute filenames")];
  [outputModuleBox setTitle: LOCALIZED (@"Output module")];
  [playlistsFormatLabel setStringValue: LOCALIZED (@"Format")];

  [self _initializeSelector];

  outputBundle = [preference objectForKey: @"OutputBundle"];
  [outputBundleSelector selectItemWithTitle: outputBundle];

  playlistFormat = [self preferredPlaylistFormat];
  [playlistFormatSelector selectItemWithTitle:
                            [playlistFormat uppercaseString]];

  toggleBool = [preference objectForKey: @"AbsolutePlaylistReferences"];
  [playlistReferenceTypeToggle setState: [toggleBool boolValue]];

#ifdef __MACOSX__
  toggleBool = [preference objectForKey: @"TexturedWindows"];
  [texturedWindowsToggle setState: [toggleBool boolValue]];
#endif

  toggleBool = [preference objectForKey: @"StickyWindows"];
  [stickyWinToggle setState: [toggleBool boolValue]];

  toggleBool = [preference objectForKey: @"SaveWindowsInformation"];
  [saveWindowsInformationToggle setState: [toggleBool boolValue]];
}

- (void) dealloc
{
  [playersList release];
  [preference release];
  [super dealloc];
}

/* as a target */
- (void) outputBundleChanged: (id) sender
{
  NSString *newTitle;

  newTitle = [sender titleOfSelectedItem];
  [sender setTitle: newTitle];
  [sender synchronizeTitleAndSelectedItem];
  [preference setObject: newTitle forKey: @"OutputBundle"];
}

- (void) playlistFormatChanged: (id) sender
{
  NSString *newTitle;

  newTitle = [sender titleOfSelectedItem];
  [sender setTitle: newTitle];
  [sender synchronizeTitleAndSelectedItem];
  [preference setObject: [newTitle lowercaseString]
              forKey: @"PlaylistFormat"];
}

- (void) playlistReferenceTypeChanged: (id) sender
{
  [preference setObject: [NSNumber numberWithBool: [sender state]]
              forKey: @"AbsolutePlaylistReferences"];
}

#ifdef __MACOSX__
- (void) texturedWindowsChanged: (id) sender
{
  [preference setObject: [NSNumber numberWithBool: [sender state]]
              forKey: @"TexturedWindows"];
}
#endif

- (void) stickyWindowsChanged: (id) sender
{
  [preference setObject: [NSNumber numberWithBool: [sender state]]
              forKey: @"StickyWindows"];
}

- (void) saveWindowsInformationChanged: (id) sender
{
  [preference setObject: [NSNumber numberWithBool: [sender state]]
              forKey: @"SaveWindowsInformation"];
}

@end
