/* CynthiuneController.m - this file is part of Cynthiune
 *
 * Copyright (C) 2003-2005  Wolfgang Sourdeau
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


#import <Foundation/Foundation.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSWindow.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Preference.h>
#ifdef __MACOSX__ /* NSStandardLibraryPaths */
#import <Cynthiune/utils.h>
#endif /* __MACOSX__ */

#ifdef GNUSTEP
#import <GNUstepGUI/GSDisplayServer.h>
#endif

#import "BundleManager.h"
#import "GeneralPreference.h"
#import "CynthiuneController.h"
#import "PlaylistController.h"
#import "PreferencesController.h"

#define LOCALIZED(X) NSLocalizedString (X, nil)

#define STICK_DELTA 20.0

static void
localizeMenu (NSMenu *menu)
{
  id <NSMenuItem> menuItem;
  unsigned int count, max;

  [menu setTitle: LOCALIZED ([menu title])];

  max = [menu numberOfItems];
  for (count = 0; count < max; count++)
    {
      menuItem = [menu itemAtIndex: count];
      if (menuItem && ![menuItem isSeparatorItem])
        {
          [menuItem setTitle: LOCALIZED ([menuItem title])];
          if ([menuItem hasSubmenu])
            localizeMenu ([menuItem submenu]);
        }
    }
}

@implementation CynthiuneController : NSObject

+ (void) initialize
{
  NSArray *sendTypes;

  sendTypes = [NSArray arrayWithObject: NSFilenamesPboardType];
  [NSApp registerServicesMenuSendTypes: sendTypes
         returnTypes: nil];
}

#ifdef __MACOSX__
- (void) _initPlaylistWindowButtons
{
  NSRect emptyRect;
  NSButton *button;
  int buttons[] = {NSWindowToolbarButton, NSWindowCloseButton,
                   NSWindowMiniaturizeButton, NSWindowZoomButton};
  int count;

  emptyRect = NSMakeRect (0, 0, 0, 0);
  for (count = 0; count < (sizeof (buttons) / sizeof (int)); count++)
    {
      button = [playlistWindow standardWindowButton: buttons[count]];
      [button setFrame: emptyRect];
    }

  [playlistWindow setViewsNeedDisplay: YES];
}
#endif /* __MACOSX__ */

- (void) awakeFromNib
{
  NSToolbar *toolbar;

  [playerWindow setMiniwindowImage: [NSImage imageNamed: @"Cynthiune"]];

  localizeMenu ([NSApp mainMenu]);

  [self _parseArguments];
  [playlistController initializeWidgets];
  toolbar = [playlistController playlistToolbar];
  [playlistWindow setToolbar: toolbar];
#ifdef __MACOSX__
  [self _initPlaylistWindowButtons];
#endif
  [self _initWindowsPosition];

#if defined (GNUSTEP)
  if ([GSCurrentServer () handlesWindowDecorations])
    {
      WindowsTitleSize = 22;
      WindowsBorderSize = 8.0;
    }
#endif /* GNUSTEP */

  [playlistWindow setTitle: LOCALIZED (@"Playlist")];
  [playlistWindow setExcludedFromWindowsMenu: YES];
  [playlistWindow setResizeIncrements: NSMakeSize (1, 16)];

  [playlistSwitch setImage: [NSImage imageNamed: @"playlist"]];
  [playlistSwitch setAlternateImage: [NSImage imageNamed: @"playlist-pushed"]];
  [playlistSwitch setState: playlistWindowIsVisible];

  [playerWindow setNextResponder: playlistWindow];
}

- (unsigned int) _computeDeltaXOfFrame: (NSRect) mainFrame
                             withFrame: (NSRect) aFrame
{
  unsigned int cond;
  float a1, a2, x1, x2;

  x1 = aFrame.origin.x;
  x2 = aFrame.origin.x + aFrame.size.width;
  a1 = mainFrame.origin.x;
  a2 = mainFrame.origin.x + mainFrame.size.width;

  if (x1 <= (a1 + STICK_DELTA)
      && x1 >= (a1 - STICK_DELTA))
    {
      cond = 2;
      deltaX = 0.0;
    }
  else if (x2 <= (a2 + STICK_DELTA)
           && x2 >= (a2 - STICK_DELTA))
    {
      cond = 3;
      deltaX = x1 - x2 + a2 - a1;
    }
  else if (x2 <= (a1 + STICK_DELTA)
           && x2 >= (a1 - STICK_DELTA))
    {
      cond = 4;
      deltaX = x1 - x2 - 2.0;
    }
  else if (x1 <= (a2 + STICK_DELTA)
           && x1 >= (a2 - STICK_DELTA))
    {
      cond = 5;
      deltaX = a2 - a1 + 2.0;
    }
  else if ((x1 > a1 && x1 < a2)
           || (x2 > a1 && x2 < a2)
           || (x1 < a1 && x2 > a2))
    {
      cond = 1;
      deltaX = x1 - a1;
    }
  else
    cond = 0;

  return cond;
}

- (unsigned int) _computeDeltaYOfFrame: (NSRect) mainFrame
                             withFrame: (NSRect) aFrame 
{
  unsigned int cond;
  float b1, b2, y1, y2;

  y1 = aFrame.origin.y;
  y2 = aFrame.origin.y + aFrame.size.height;
  b1 = mainFrame.origin.y;
  b2 = mainFrame.origin.y + mainFrame.size.height;

  if (y1 <= (b1 + STICK_DELTA)
      && y1 >= (b1 - STICK_DELTA))
    {
      cond = 2;
      deltaY = 0.0;
    }
  else if (y2 <= (b2 + STICK_DELTA)
           && y2 >= (b2 - STICK_DELTA))
    {
      cond = 3;
      deltaY = y1 - y2 + b2 - b1;
    }
  else if (y2 + WindowsTitleSize <= (b1 + STICK_DELTA)
           && y2 + WindowsTitleSize >= (b1 - STICK_DELTA))
    {
      cond = 4;
      deltaY = y1 - y2 - WindowsTitleSize;
    }
  else if (y1 <= (b2 + WindowsTitleSize + STICK_DELTA)
           && y1 >= (b2 + WindowsTitleSize - STICK_DELTA))
    {
      cond = 5;
      deltaY = b2 - b1 + WindowsTitleSize + WindowsBorderSize;
    }
  else if ((y1 > b1 && y1 < b2)
           || (y2 > b1 && y2 < b2)
           || (y1 < b1 && y2 > b2))
    {
      cond = 1;
      deltaY = y1 - b1;
    }
  else
    cond = 0;

  return cond;
}

- (void) _recheckIfIsStuck
{
  unsigned int condX, condY;
  NSRect mainFrame, playlistFrame;

  mainFrame = [playerWindow frame];
  playlistFrame = [playlistWindow frame];

  condX = [self _computeDeltaXOfFrame: mainFrame
                withFrame: playlistFrame];
  condY = [self _computeDeltaYOfFrame: mainFrame
                withFrame: playlistFrame];
  isStuck = (condX && condY
             && (condX > 3 || condY > 3));
}

- (void) _initWindowsPosition
{
  GeneralPreference *generalPreference;

  generalPreference = [GeneralPreference instance];
  if ([generalPreference saveWindowsInformation])
    {
      [generalPreference restoreInformation: playerWindow
                         forWindow: @"PlayerWindow"];
      [generalPreference restoreInformation: playlistWindow
                         forWindow: @"PlaylistWindow"];
      [playerWindow makeKeyAndOrderFront: self];
      [playlistWindow makeKeyAndOrderFront: self];
      playlistWindowIsVisible = YES;
      [self _recheckIfIsStuck];
    }
  else
    {
      [playerWindow center];
      [playerWindow makeKeyAndOrderFront: self];
      playlistWindowIsVisible = NO;
    }
}

- (void) _ensureDirectory: (NSString *) directory
{
  NSFileManager *fm;
  NSEnumerator *pathComponents;
  NSString *currentPathComponent, *directories;
  BOOL isDir, error;

  fm = [NSFileManager defaultManager];
  error = NO;

  pathComponents = [[directory pathComponents] objectEnumerator];
  directories = [pathComponents nextObject];
  currentPathComponent = [pathComponents nextObject];

  while (currentPathComponent && !error)
    {
      directories = [directories
                      stringByAppendingPathComponent: currentPathComponent];
      if (!([fm fileExistsAtPath: directories isDirectory: &isDir]
            && isDir))
        error = ![fm createDirectoryAtPath: directories attributes: nil];
      currentPathComponent = [pathComponents nextObject];
    }
}

- (void) _checkUserCynthiuneDirectory
{
  NSArray *paths;
  NSString *cynthiuneDirectory;

  paths = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory,
                                               NSUserDomainMask, YES);
  if (paths)
    {
      cynthiuneDirectory = [[paths objectAtIndex: 0]
                             stringByAppendingPathComponent: @"Cynthiune"];
      [self _ensureDirectory: cynthiuneDirectory];
    }
}

- (id) init
{
  BundleManager *bundleManager;

  if ((self = [super init]))
    {
      WindowsTitleSize = 0.0;
      WindowsBorderSize = 0.0;
      [self _checkUserCynthiuneDirectory];
      bundleManager = [BundleManager bundleManager];
      [bundleManager loadBundles];
//       step = 0;
    }

  return self;
}

- (void) _parseArguments
{
  NSArray *arguments;
  NSString *currArg;
  unsigned int count, max;

  arguments = [[NSProcessInfo processInfo] arguments];
  max = [arguments count];

  for (count = 1; count < max; count++)
    {
      currArg = [arguments objectAtIndex: count];
      if (![currArg hasPrefix: @"-"])
        [playlistController openSongFromNSApp: currArg];
    }
}

/* this seems to crash for the moment... */
// - (void) updateMiniwindowTitle: (NSString *) aTitle
// {
//   [playerWindow setMiniwindowTitle: aTitle];
// }

- (void) openFile: (id) anObject
{
  [playlistController addSongFromNSApp: self];
}

- (void) preferencesWindow: (id) anObject
{
  [[PreferencesController preferencesController] loadPreferencesWindow];
}

/* as delegate */

- (BOOL) application: (NSApplication *) application
	    openFile: (NSString *) filename
{
  [playlistController openSongFromNSApp: filename];

  return YES;
}

- (void) togglePlaylistWindow: (id) sender
{
  [self setPlaylistWindowVisible: [sender state]];
}

- (void) setPlaylistWindowVisible: (BOOL) isVisible
{
  if (isVisible)
    {
      if (!playlistWindowIsVisible)
        {
          [playlistWindow makeKeyAndOrderFront: self];
          playlistWindowIsVisible = YES;
        }
    }
  else
    {
      if (playlistWindowIsVisible)
        {
          [playlistWindow orderOut: self];
          playlistWindowIsVisible = NO;
        }
    }
}

/* notifications */
- (void) windowWillClose: (NSNotification *) aNotification
{
  GeneralPreference *generalPreference;
  static BOOL closing = NO;

  if (!closing)
    {
      closing = YES;

      generalPreference = [GeneralPreference instance];
      if ([generalPreference saveWindowsInformation])
        {
          [generalPreference saveInformation: playerWindow
                             forWindow: @"PlayerWindow"];
          [generalPreference saveInformation: playlistWindow
                             forWindow: @"PlaylistWindow"];
        }

      [NSApp terminate: [aNotification object]];
    }
}

- (void) windowDidDeminiaturize: (NSNotification *) aNotification
{
  if (playlistWindowIsVisible)
    [playlistWindow orderFront: self];
}

- (void) windowDidMiniaturize: (NSNotification *) aNotification
{
  if (playlistWindowIsVisible)
    [playlistWindow orderOut: self];
}

- (void) repositionPlaylistWindow
{
  NSPoint newOrigin;
  NSRect playerFrame, playlistFrame;

  playerFrame = [playerWindow frame];
  playlistFrame = [playlistWindow frame];

  newOrigin = playerFrame.origin;
  newOrigin.x += deltaX;
  newOrigin.y += deltaY;
  playlistFrame.origin = newOrigin;

  [playlistWindow setFrame: playlistFrame display: NO];
}

- (void) _playerWindowDidMove
{
  NSRect frame;
  GeneralPreference *generalPreference;
  static BOOL _inited = NO;

  generalPreference = [GeneralPreference instance];
  if (!_inited)
    {
      _inited = YES;

      if (![generalPreference saveWindowsInformation])
        {
          frame = [playlistWindow frame];
          isStuck = YES;
          deltaX = 0.0;
          deltaY = -frame.size.height - 2.0;
          [self repositionPlaylistWindow];
        }
    }
  else
    if ([generalPreference windowsAreSticky] && isStuck)
      [self repositionPlaylistWindow];
}

- (void) _playlistWindowDidMove
{
  GeneralPreference *generalPreference;

  generalPreference = [GeneralPreference instance];
  if ([generalPreference windowsAreSticky])
    {
      [self _recheckIfIsStuck];
      if (isStuck)
        [self repositionPlaylistWindow];
    }
}

- (void) windowDidMove: (NSNotification *) aNotification
{
  id object;

  object = [aNotification object];
  if (object == playerWindow)
    [self _playerWindowDidMove];
  else if (object == playlistWindow)
    [self _playlistWindowDidMove];
  else
    NSLog (@"%s(%d): unexpected notification object:\n  %@",
           __FILE__, __LINE__, [object description]);
}

- (void) windowDidResize: (NSNotification *) aNotification
{
  GeneralPreference *generalPreference;

  generalPreference = [GeneralPreference instance];
  if ([aNotification object] == playlistWindow
      && [generalPreference windowsAreSticky]
      && isStuck)
    [self _recheckIfIsStuck];
}

// - (void) windowDidBecomeMain: (NSNotification *) aNotification
// {
//   NSWindow *otherWindow;

//   if (!step)
//     keyWindow = [aNotification object];

//   otherWindow = ((keyWindow == playerWindow)
//                  ? playlistWindow
//                  : playerWindow);

//   NSLog (@"step %d", step);

//   NSLog (@"keyWindow: %d; other: %d", [keyWindow isKeyWindow], [otherWindow isKeyWindow]);

//   switch (step)
//     {
//     case 0:
//       NSLog (@"key: %@", [keyWindow title]);
//       step++;
//       [keyWindow orderFront: self];
//       [keyWindow resignKeyWindow];
//       [otherWindow makeKeyAndOrderFront: self];
// //       [otherWindow becomeKeyWindow];
//       break;
//     case 1:
//       step++;
//       [keyWindow makeKeyAndOrderFront: self];
//       [otherWindow resignKeyWindow];
// //       [otherWindow becomeKeyWindow];
//       break;
//     case 2:
//       if (keyWindow == playlistWindow)
//         step++;
//       else
//         {
//           keyWindow = nil;
//           step = 0;
//         }
//       break;
//     default:
//       keyWindow = nil;
//       step = 0;
//     }
// }

- (void) applicationWillTerminate: (NSNotification *) notification
{
  [playlistController savePlayerState];
}

/* Services */
- (id) validRequestorForSendType: (NSString *)sendType
                      returnType: (NSString *)returnType
{
  return [playlistController validRequestorForSendType: sendType
                             returnType: returnType];
}

@end
