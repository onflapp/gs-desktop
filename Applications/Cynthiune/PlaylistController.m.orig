/* PlaylistController.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2006  Wolfgang Sourdeau
 *               2012 The Free Software Foundation, Inc
 *
 * Author: Wolfgang Sourdeau <wolfgang@contre.com>
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
#import <AppKit/NSButton.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSSlider.h>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSSavePanel.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarItem.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>

#import <Cynthiune/Format.h>
#import <Cynthiune/NSNumberExtensions.h>
#import <Cynthiune/NSTimerExtensions.h>
#import <Cynthiune/NSViewExtensions.h>
#import <Cynthiune/Preference.h>
#import <Cynthiune/utils.h>

#ifdef GOOM
#import <goom/goom.h>

#import "GoomView.h"
#endif /* GOOM */

#import "CynthiuneSliderCell.h"
#import "FormatTester.h"
#import "GeneralPreference.h"
#import "InfoDisplayController.h"
#import "Player.h"
#import "Playlist.h"
#import "PlaylistController.h"
#import "PlaylistView.h"
#import "Song.h"
#import "SongInspectorController.h"
#import "PlaylistViewController.h"

#define LOCALIZED(X) NSLocalizedString (X, nil)

static NSString *DefaultPlaylistName = @"Playlist.cPls";
static NSString *defaultPlaylistFile = nil;

static NSString *AddItemIdentifier = @"addButton";
static NSString *RemoveItemIdentifier = @"removeButton";
// static NSString *RemoveAllItemIdentifier = @"removeAllButton";
static NSString *CleanupItemIdentifier = @"cleanupButton";
// static NSString *SaveItemIdentifier = @"saveButton";
static NSString *SaveAsItemIdentifier = @"saveAsButton";
// static NSString *RepeatItemIdentifier = @"repeatButton";
// static NSString *ShuffleItemIdentifier = @"shuffleButton";
static NSString *SongInspectorItemIdentifier = @"songInspectorButton";

@implementation PlaylistController : NSObject

+ (void) initialize
{
  NSArray *dirs;

  if (!defaultPlaylistFile)
    {
      dirs = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory,
                                                  NSUserDomainMask, YES);
      defaultPlaylistFile =
        [[[dirs objectAtIndex: 0]
           stringByAppendingPathComponent: @"Cynthiune"]
          stringByAppendingPathComponent: DefaultPlaylistName];
      [defaultPlaylistFile retain];
    }
}

- (id) init
{
  if ((self = [super init]))
    {
      playlist = [Playlist new];
      [playlist setDelegate: self];
      player = [Player new];
      [player setDelegate: self];
      playlistFilename = nil;
      timer = nil;
      repeat = NO;
      currentPlayerSong = nil;
      notifiedFirstSong = nil;
      songInspectorController =
        [SongInspectorController songInspectorController];
      [songInspectorController setDelegate: self];
    }

  return self;
}

- (void) _initButtonImages
{
  [previousButton setImage: [NSImage imageNamed: @"previous"]];
  [previousButton setAlternateImage:
                    [NSImage imageNamed: @"previous-pushed"]];
  [previousButton setToolTip: LOCALIZED (@"Previous")];
  [playButton setImage: [NSImage imageNamed: @"play"]];
  [playButton setAlternateImage: [NSImage imageNamed: @"play-pushed"]];
  [playButton setToolTip: LOCALIZED (@"Play")];
  [pauseButton setImage: [NSImage imageNamed: @"pause"]];
  [pauseButton setAlternateImage: [NSImage imageNamed: @"pause-pushed"]];
  [pauseButton setToolTip: LOCALIZED (@"Pause")];
  [stopButton setImage: [NSImage imageNamed: @"stop-pushed"]];
  [stopButton setAlternateImage: [NSImage imageNamed: @"stop-pushed"]];
  [stopButton setToolTip: LOCALIZED (@"Stop")];
  [nextButton setImage: [NSImage imageNamed: @"next"]];
  [nextButton setAlternateImage: [NSImage imageNamed: @"next-pushed"]];
  [nextButton setToolTip: LOCALIZED (@"Next")];
  [ejectButton setImage: [NSImage imageNamed: @"eject"]];
  [ejectButton setAlternateImage: [NSImage imageNamed: @"eject-pushed"]];

  [repeatButton setImage: [NSImage imageNamed: @"repeat"]];
  [repeatButton setAlternateImage: [NSImage imageNamed: @"repeat-pushed"]];
  [repeatButton setToolTip: LOCALIZED (@"Repeat")];
  [shuffleButton setImage: [NSImage imageNamed: @"shuffle"]];
  [shuffleButton setAlternateImage: [NSImage imageNamed: @"shuffle-pushed"]];
  [shuffleButton setToolTip: LOCALIZED (@"Shuffle")];

//   [playButton setToolTip: @"Wanna dance?"];
// #define buttonGradient NSGradientConcaveWeak
//   [[playButton cell] setBezelStyle: NSLargeIconButtonBezelStyle];
//   [[previousButton cell] setBezelStyle: NSSmallIconButtonBezelStyle];
//   [[previousButton cell] setGradientType: buttonGradient];
//   [[playButton cell] setGradientType: NSGradientNone];
//   [[stopButton cell] setGradientType: buttonGradient];
//   [[nextButton cell] setGradientType: buttonGradient];
//   [[pauseButton cell] setGradientType: buttonGradient];
//   [[ejectButton cell] setGradientType: buttonGradient];
//   [[playlistButton cell] setGradientType: buttonGradient];
}

- (NSToolbarItem *) _toolbarButtonWithIdentifier: (NSString *) identifier
                                           title: (NSString *) title
                                  callbackToSelf: (SEL) selector
                                    andImageName: (NSString *) imageName
{
  NSToolbarItem *toolbarButton;
  NSString *locTitle;

  toolbarButton = [[NSToolbarItem alloc] initWithItemIdentifier: identifier];
  [toolbarButton setImage: [NSImage imageNamed: imageName]];
  if (title)
    {
      locTitle = LOCALIZED (title);
      [toolbarButton setLabel: locTitle];
      [toolbarButton setPaletteLabel: locTitle];
      [toolbarButton setToolTip: locTitle];
    }
  [toolbarButton setTarget: self];
  [toolbarButton setAction: selector];

  return toolbarButton;
}

- (void) _initToolbarButtons
{
  addButton = [self _toolbarButtonWithIdentifier: AddItemIdentifier
                    title: @"Add Songs..."
                    callbackToSelf: @selector (addSongs:)
                    andImageName: @"add"];
  removeButton = [self _toolbarButtonWithIdentifier: RemoveItemIdentifier
                       title: @"Remove Selection"
                       callbackToSelf: @selector (removeSelectedSongs:)
                       andImageName: @"remove"];
//   removeAllButton = [self _toolbarButtonWithIdentifier: RemoveAllItemIdentifier
//                           title: @"Remove All"
//                           callbackToSelf: @selector (removeAllSongs:)
//                           andImageName: @"remove-all"];
  cleanupButton = [self _toolbarButtonWithIdentifier: CleanupItemIdentifier
                        title: @"Cleanup"
                        callbackToSelf: @selector (cleanupPlaylist:)
                        andImageName: @"cleanup"];
//   saveButton = [self _toolbarButtonWithIdentifier: SaveItemIdentifier
//                      title: @"Save..."
//                      callbackToSelf: @selector (saveList:)
//                      andImageName: @"save"];
  saveAsButton = [self _toolbarButtonWithIdentifier: SaveAsItemIdentifier
                       title: @"Save As..."
                       callbackToSelf: @selector (saveListAs:)
                       andImageName: @"save-as"];

//   repeatButton = [self _toolbarButtonWithIdentifier: RepeatItemIdentifier
//                        title: @"Repeat"
//                        callbackToSelf: @selector (toggleRepeat:)
//                        andImageName: @"repeat"];
//   shuffleButton = [self _toolbarButtonWithIdentifier: ShuffleItemIdentifier
//                         title: @"Shuffle"
//                         callbackToSelf: @selector (toggleShuffle:)
//                         andImageName: @"shuffle"];

  songInspectorButton =
    [self _toolbarButtonWithIdentifier: SongInspectorItemIdentifier
          title: @"Song Inspector..."
          callbackToSelf: @selector (toggleSongInspector:)
          andImageName: @"song-inspector"];
}

- (void) updateStatusLabel
{
  NSMutableString *infos;
  NSArray *selection;

  infos = [NSMutableString stringWithFormat:
                             LOCALIZED (@"%d songs - total time: %@"),
                           [playlist numberOfSongs],
                           [[playlist duration] timeStringValue]];

  selection = [playlistViewController getSelectedSongs];
  if ([selection count])
    [infos appendFormat: LOCALIZED (@" - selection: %@"),
           [[playlistViewController durationOfSelection] timeStringValue]];

  [playlistStatusLabel setStringValue: infos];
}

- (void) _updatePlayerState
{
  NSUserDefaults *defaults;
  BOOL boolValue;
  int intValue;

  defaults = [NSUserDefaults standardUserDefaults];
  boolValue = [defaults boolForKey: @"RepeatMode"];
  if (boolValue)
    {
      [repeatButton setState: NSOnState];
      [self toggleRepeat: self];
    }
  boolValue = [defaults boolForKey: @"ShuffleMode"];
  if (boolValue)
    {
      [shuffleButton setState: NSOnState];
      [self toggleShuffle: self];
    }
  intValue = [defaults integerForKey: @"CurrentSongNumber"];
  if (intValue < [playlist numberOfSongs])
    {
      currentPlayerSong = [playlist songAtIndex: intValue];
      [playlistViewController setCurrentPlayerSong: currentPlayerSong];
    }
}

- (void) savePlayerState
{
  NSUserDefaults *defaults;

  defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool: repeat forKey: @"RepeatMode"];
  [defaults setBool: [playlist shuffle] forKey: @"ShuffleMode"];
  if (currentPlayerSong)
    [defaults setInteger: [playlist indexOfSong: currentPlayerSong]
              forKey: @"CurrentSongNumber"];
}

#ifdef GOOM

- (void) _createGoom
{
  NSWindow *goomPanel;
  GoomView *goomView;

  goomPanel = [[NSPanel alloc]
                initWithContentRect: NSMakeRect (100, 100, 660, 420)
                styleMask: NSTitledWindowMask
                backing: NSBackingStoreRetained
                defer: NO];
  goomView = [[GoomView alloc] initWithFrame: NSMakeRect (10, 10, 640, 400)];
  [[goomPanel contentView] addSubview: goomView];
  [goomPanel setTitle: @"Goom"];
  [goomPanel setLevel: NSFloatingWindowLevel];
  [goomPanel orderFront: self];
  [goomView setFPS: 10];

  [player setGoom: [goomView goom]];
}

#endif /* GOOM */

- (void) awakeFromNib
{
  [repeatMenuItem setState: NSOffState];
  [shuffleMenuItem setState: NSOffState];
  [songInspectorMenuItem setState: NSOffState];

  [playlist loadFromFile: defaultPlaylistFile];
  [playlistViewController setPlaylistController: self];
  [playlistViewController setPlaylist: playlist];

  [playlistStatusLabel setTextColor: [NSColor darkGrayColor]];

#ifdef GOOM
  [self _createGoom];
#endif /* GOOM */
}

- (void) _initProgressSlider
{
#ifdef GNUSTEP
  NSCell *oldCell, *cell;

  oldCell = [progressSlider cell];
  cell = [CynthiuneSliderCell new];
  [cell setBordered: NO];
  [cell setBezeled: NO];
  [cell setTarget: [oldCell target]];
  [cell setAction: [oldCell action]];
  [progressSlider setCell: cell];
#endif /* GNUSTEP */

  [progressSlider setEnabled: NO];
  [progressSlider setMinValue: 0.0];
  [progressSlider setIntValue: 0];
}

- (void) initializeWidgets
{
  [self _initButtonImages];
  [self _initToolbarButtons];
  [self _initProgressSlider];

  [self updateStatusLabel];
  [self _updatePlayerState];

  [pauseButton setEnabled: NO];
  [stopButton setEnabled: NO];

  [infoDisplayController initializeWidgets];
}

- (NSToolbar *) playlistToolbar
{
  NSToolbar *toolbar;

  toolbar = [[NSToolbar alloc] initWithIdentifier: @"PlaylistToolbar"];
  [toolbar autorelease];
  [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
  [toolbar setSizeMode: NSToolbarSizeModeSmall];
  [toolbar setDelegate: self];

  return toolbar;
}

- (void) toggleRepeat: (id) sender
{
  BOOL repeatState;
  int widgetState;

  widgetState = [repeatButton state];
  repeatState = ((widgetState == NSOnState) ? YES : NO);
  if (sender == repeatMenuItem)
    {
      repeatState = !repeatState;
      if (repeatState)
	[repeatButton setState:NSOnState];
      else
	[repeatButton setState:NSOffState];
    }
  widgetState = [repeatButton state];
  [repeatMenuItem setState: widgetState];
  repeat = ((widgetState == NSOnState) ? YES : NO);
}

- (void) toggleShuffle: (id) sender
{
  BOOL shuffleState;
  int widgetState;
  Song *shuffleSong;

  widgetState = [shuffleButton state];
  shuffleState = ((widgetState == NSOnState) ? YES : NO);
  if (sender == shuffleMenuItem)
    {
      shuffleState = !shuffleState;
      if (shuffleState)
	[shuffleButton setState:NSOnState];
      else
	[shuffleButton setState:NSOffState];
    }
  widgetState = [shuffleButton state];
  [shuffleMenuItem setState: widgetState];

  [playlist setShuffle: shuffleState];
  if (currentPlayerSong)
    shuffleSong = currentPlayerSong;
  else
    shuffleSong = [playlist firstSong];
  if (shuffleState && shuffleSong)
    [playlist shuffleFromSong: shuffleSong];
}

- (void) toggleSongInspector: (id) sender
{
  [songInspectorController toggleDisplay];
}

- (void) resetProgressSlider
{
  [progressSlider setIntValue: 0];
  if (currentPlayerSong)
    {
      [progressSlider setMaxValue: [[currentPlayerSong duration] doubleValue]];
      [progressSlider setEnabled: [currentPlayerSong isSeekable]];
    }
  else
    {
      [progressSlider setMaxValue: 0.0];
      [progressSlider setEnabled: NO];
    }
}

- (void) _updatePlayerSong: (Song *) song
{
  NSObject <Format> *stream;

  if (song)
    {
      stream = [song openStreamForSong];
      if (stream)
        {
          currentPlayerSong = song;
          [playlistViewController setCurrentPlayerSong: song];
          [player setStream: stream];
          if ([player playing])
            {
              [infoDisplayController updateInfoFieldsFromSong: song];
              [self resetProgressSlider];
            }
        }
    }
}

- (void) _saveDefaultOpenDirectoryFromOpenPanel: (NSOpenPanel *) oPanel
{
  NSUserDefaults *userDefaults;

  userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject: [oPanel directory]
                forKey: @"NSDefaultOpenDirectory"];
  [userDefaults synchronize];
}

- (NSArray *) _filteredSubtree: (NSString *) filename
{
  NSFileManager *fm;
  NSMutableArray *result;
  NSEnumerator *filenames;
  NSString *currentFilename, *absoluteFilename;
  BOOL isDir;

  result = [NSMutableArray new];
  [result autorelease];
  fm = [NSFileManager defaultManager];
  filenames = [[fm subpathsAtPath: filename] objectEnumerator];

  currentFilename = [filenames nextObject];
  while (currentFilename)
    {
      absoluteFilename =
        [filename stringByAppendingPathComponent: currentFilename];

      if (!([fm fileExistsAtPath: absoluteFilename isDirectory: &isDir]
            && isDir))
        [result addObject: absoluteFilename];
      currentFilename = [filenames nextObject];
    }

  [result sortUsingSelector: @selector (localizedCaseInsensitiveCompare:)];

  return result;
}

- (void) _feedPlaylistWithTreeOfFilenames: (NSArray *) filenames
{
  NSEnumerator *files;
  NSString *filename;
  FormatTester *formatTester;

  formatTester = [FormatTester formatTester];
  files = [filenames objectEnumerator];

  while ((filename = [files nextObject]) != nil)
    {
      if (fileIsAReadableDirectory (filename))
	{
          [self _feedPlaylistWithTreeOfFilenames:
                [self _filteredSubtree: filename]];
        }
      else if (fileIsAcceptable (filename))
        {
	  if ([formatTester fileIsPlaylist: filename])
	    {
             [playlist loadFromFile: filename];
	    }
          else if ([formatTester formatNumberForFile: filename] > -1)
	    {
              [playlist addSong: [Song songWithFilename: filename]];
            }
        }
    }
}

- (void) _oPanelDidEnd: (NSOpenPanel *) oPanel
            returnCode: (int) result
           contextInfo: (void *) contextInfo
{
  if (result == NSOKButton)
    {
      [self _saveDefaultOpenDirectoryFromOpenPanel: oPanel];
      notifiedFirstSong = nil;
      [self _feedPlaylistWithTreeOfFilenames: [oPanel filenames]];
      if (notifiedFirstSong && ![player playing])
        {
          [playlistViewController invalidateSortedColumn];
          [self _updatePlayerSong: notifiedFirstSong];
        }
    }
}

- (void) _startOPanelDidEnd: (NSOpenPanel *) oPanel
                 returnCode: (int) result
                contextInfo: (void *) contextInfo
{
  if (result == NSOKButton)
    {
      [self _saveDefaultOpenDirectoryFromOpenPanel: oPanel];
      notifiedFirstSong = nil;
      [self _feedPlaylistWithTreeOfFilenames: [oPanel filenames]];
      if (notifiedFirstSong)
        {
          [playlistViewController invalidateSortedColumn];
          [self _updatePlayerSong: notifiedFirstSong];
          [player play];
        }
    }
}

- (void) _ejectOPanelDidEnd: (NSOpenPanel *) oPanel
                 returnCode: (int) result
                contextInfo: (void *) contextInfo
{
  if (result == NSOKButton)
    {
      [self _saveDefaultOpenDirectoryFromOpenPanel: oPanel];
      if ([player playing])
        [player stop];

      currentPlayerSong = nil;
      [playlistViewController setCurrentPlayerSong: nil];
      [playlist deleteAllSongsQuietly];
      notifiedFirstSong = nil;
      [self _feedPlaylistWithTreeOfFilenames: [oPanel filenames]];
      if (notifiedFirstSong)
        {
          [playlistViewController invalidateSortedColumn];
          [self _updatePlayerSong: notifiedFirstSong];
          [player play];
        }
    }
}

/* load all files */
- (void) _runOpenPanelWithDidEndSelector: (SEL) selector
{
  NSOpenPanel *oPanel;
  int result;


  oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection: YES];
  [oPanel setCanChooseDirectories: YES];
  [oPanel setTitle: LOCALIZED (@"Add music files...")];

  [oPanel setDelegate: self];
  result = [oPanel runModalForTypes: nil];
  [self _oPanelDidEnd: oPanel returnCode: result contextInfo: nil];
}

/* load playlists only */
- (void) _runPlaylistOpenPanelWithDidEndSelector: (SEL) selector
{
  NSOpenPanel *oPanel;
  int result;
  NSArray *types;

  types = [[NSArray arrayWithObjects: @"m3u", @"pls", nil] retain];


  oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection: YES];
  [oPanel setCanChooseDirectories: NO];
  [oPanel setTitle: LOCALIZED (@"Open Playlist...")];
  [oPanel setDelegate: self];
  result = [oPanel runModalForTypes: types];
  [self _oPanelDidEnd: oPanel returnCode: result contextInfo: nil];
  [types release];
}

- (void) addSongs: (id) sender
{
  [self _runOpenPanelWithDidEndSelector: @selector(_oPanelDidEnd:returnCode:contextInfo:)];
}

- (void) addPlaylist: (id) sender
{
  [self _runPlaylistOpenPanelWithDidEndSelector: @selector(_oPanelDidEnd:returnCode:contextInfo:)];
}

- (Song *) _songAfterRemovalOfArray: (NSArray *) array
{
  Song *newSong;

  newSong = currentPlayerSong;
  while (newSong && [array containsObject: newSong])
    newSong = [playlist validSongAfter: newSong];

  if (!newSong)
    {
      newSong = currentPlayerSong;
      while (newSong && [array containsObject: newSong])
        newSong = [playlist validSongBefore: newSong];
    }

  return newSong;
}

- (void) _removeArrayOfSongs: (NSArray *) array
{
  Song *newSong;

  if ([array containsObject: currentPlayerSong])
    {
      newSong = [self _songAfterRemovalOfArray: array];
      if (newSong)
        {
          if (newSong != currentPlayerSong)
            [self _updatePlayerSong: newSong];
        }
      else
        {
          if (currentPlayerSong)
            {
              currentPlayerSong = nil;
              [playlistViewController setCurrentPlayerSong: nil];
              [self resetProgressSlider];
            }
          [player stop];
        }
    }
  if ([array count])
    [playlistViewController invalidateSortedColumn];
  [playlist deleteSongsInArray: array];
}

- (void) removeSelectedSongs: (id) sender
{
  [songInspectorController setSong: nil];
  [self _removeArrayOfSongs: [playlistViewController getSelectedSongs]];
  [playlistViewController deselectAll];
}

- (void) removeAllSongs: (id) sender
{
  if ([playlist numberOfSongs] > 0)
    [playlistViewController invalidateSortedColumn];
  if ([player playing])
    [player stop];
  if (currentPlayerSong)
    {
      currentPlayerSong = nil;
      [playlistViewController setCurrentPlayerSong: nil];
      [self resetProgressSlider];
    }

  [songInspectorController setSong: nil];
  [playlist deleteAllSongs];
}

- (void) cleanupPlaylist: (id) sender
{
  NSMutableArray *selectedSongs;
  NSArray *invalidSongs;

  invalidSongs = [playlist arrayOfInvalidSongs];
  if ([invalidSongs count])
    {
      if ([invalidSongs containsObject: [songInspectorController song]])
          [songInspectorController setSong: nil];
      selectedSongs = [NSMutableArray new];
      [selectedSongs addObjectsFromArray: [playlistViewController getSelectedSongs]];
      [selectedSongs removeObjectsInArray: invalidSongs];
      [self _removeArrayOfSongs: invalidSongs];
      [playlistViewController deselectAll];
      [playlistViewController selectSongsInArray: selectedSongs];
      [selectedSongs release];
    }
}

/* FIXME: when the user specifies an extension, don't use default format */
- (void) _sPanelDidEnd: (NSSavePanel *) sPanel
            returnCode: (int) result
           contextInfo: (NSString *) extension
{
  NSString *saveDir;

  if (result == NSOKButton)
    {
      saveDir = [sPanel directory];
      [[NSUserDefaults standardUserDefaults]
        setObject: saveDir
        forKey: @"NSDefaultSaveDirectory"];
      SET (playlistFilename, [sPanel filename]);
      [playlist saveToFile: playlistFilename];
    }
}

- (void) _runSaveListPanelWithExtension: (NSString *) extension
                             andSaveDir: (NSString *) saveDir
{
  NSSavePanel *sPanel;

  sPanel = [NSSavePanel savePanel];
  [sPanel setTitle: LOCALIZED (@"Save playlist as...")];
  [sPanel setRequiredFileType: extension];
  [sPanel setExtensionHidden: YES];
  [sPanel beginSheetForDirectory: saveDir
          file: playlistFilename
          modalForWindow: [NSApp mainWindow]
          modalDelegate: self
          didEndSelector: @selector (_sPanelDidEnd:returnCode:contextInfo:)
          contextInfo: extension];
}

- (void) saveList: (id) sender
{
  NSString *extension, *filename, *saveDir;
  NSUserDefaults *userDefaults;

  if (!playlistFilename)
    [self saveListAs: sender];
  else
    {
      extension = [[GeneralPreference instance] preferredPlaylistFormat];
      userDefaults = [NSUserDefaults standardUserDefaults];
      saveDir = [userDefaults stringForKey: @"NSDefaultSaveDirectory"];
      if (!saveDir || [saveDir isEqualToString: @""])
        saveDir = [userDefaults stringForKey: @"NSDefaultOpenDirectory"];

      filename = [playlistFilename stringByAppendingPathExtension: extension];
      [playlist
        saveToFile: [saveDir stringByAppendingPathComponent: filename]];
    }
}

- (void) saveListAs: (id) sender
{
  NSString *extension, *saveDir;
  NSUserDefaults *userDefaults;

  extension = [[GeneralPreference instance] preferredPlaylistFormat];
  userDefaults = [NSUserDefaults standardUserDefaults];
  saveDir = [userDefaults stringForKey: @"NSDefaultSaveDirectory"];
  if (!saveDir || [saveDir isEqualToString: @""])
    saveDir = [userDefaults stringForKey: @"NSDefaultOpenDirectory"];

  [self _runSaveListPanelWithExtension: extension andSaveDir: saveDir];
}

/* helper methods for CynthiuneController */
- (void) addSongFromNSApp: (id) sender
{
  [self _runOpenPanelWithDidEndSelector:
          @selector(_oPanelDidEnd:returnCode:contextInfo:)];
}

- (void) openSongFromNSApp: (NSString *) filename
{
  notifiedFirstSong = nil;

  [playlistViewController invalidateSortedColumn];
  [self _feedPlaylistWithTreeOfFilenames: [NSArray arrayWithObject: filename]];
  if (notifiedFirstSong && ![player playing])
    [self _updatePlayerSong: notifiedFirstSong];
}

/* player buttons */
- (void) startPlayer: (id) sender
{
  Song *song;

  if ([playlist numberOfSongs])
    {
      if (!currentPlayerSong || [currentPlayerSong status] != SongOK)
        song = [playlist firstValidSong];
      else
        song = currentPlayerSong;
      if (song)
        {
          [self _updatePlayerSong: song];
          if (![player playing])
            [player play];
        }
      else
        [self _runOpenPanelWithDidEndSelector: @selector(_startOPanelDidEnd:returnCode:contextInfo:)];
    }
  else
    [self _runOpenPanelWithDidEndSelector: @selector(_startOPanelDidEnd:returnCode:contextInfo:)];
}

- (void) pausePlayer: (id) sender
{
  if ([player playing])
    [player setPaused: ![player paused]];
}

- (void) previousSong: (id) sender
{
  Song *newSong;

  if (currentPlayerSong)
    {
      newSong = [playlist validSongBefore: currentPlayerSong];
      if (!newSong && repeat)
        newSong = [playlist lastValidSong];
    }
  else
    newSong = nil;

  [self _updatePlayerSong: newSong];
}

- (void) nextSong: (id) sender
{
  Song *newSong;

  if (currentPlayerSong)
    {
      newSong = [playlist validSongAfter: currentPlayerSong];
      if (!newSong && repeat)
        newSong = [playlist firstValidSong];
    }
  else
    newSong = [playlist firstValidSong];

  [self _updatePlayerSong: newSong];
}

- (void) stopPlayer: (id) sender
{
  [player stop];
}

- (void) eject: (id) sender
{
  [self _runOpenPanelWithDidEndSelector: @selector(_ejectOPanelDidEnd:returnCode:contextInfo:)];
}

/* playlistview delegate */
- (void) playlistViewActivateSelection: (PlaylistView *) view
{
  NSArray *selection;
  Song *song;

  selection = [playlistViewController getSelectedSongs];
  if ([selection count] > 0)
    {
      song = [selection objectAtIndex: 0];
      while ([song status] != SongOK
             || ![selection containsObject: song])
        song = [playlist validSongAfter: song];
      if (song)
        {
          [self _updatePlayerSong: song];
          if (![player playing])
            [player play];
        }
    }
}

- (void) tableDoubleClick: (int) row
{
  Song *song;

  song = [playlist songAtIndex: row];
  if ([playlist shuffle])
    [playlist shuffleFromSong: song];
  if ([song status] != SongOK)
    song = [playlist validSongAfter: song];
  [self _updatePlayerSong: song];
  if (currentPlayerSong)
    {
      if (![player playing])
        [player play];
      else if ([player paused])
        [player setPaused: NO];
    }
}

- (void) updateSongInspector
{
  NSArray *songs;

  songs = [playlistViewController getSelectedSongs];
  [songInspectorController setSong: (([songs count] == 1)
                                     ? [songs objectAtIndex: 0]
                                     : nil)];
}

- (void) tableFilenamesDropped: (NSArray *) filenames
{
  notifiedFirstSong = nil;
  [self _feedPlaylistWithTreeOfFilenames: filenames];
  if (notifiedFirstSong && ![player playing])
    [self _updatePlayerSong: notifiedFirstSong];
}

- (void) songCursorChange: (id) sender
{
  unsigned int time;

  time = [sender intValue];
  [infoDisplayController setTimerFromSeconds: time];
  [player seek: time];
}

- (void) changeTimeDisplay: (id) sender
{
  unsigned int time;

  if ([player playing])
    {
      time = [player timer];
      [infoDisplayController
        setReverseTimer: ![infoDisplayController timerIsReversed]];
      [infoDisplayController setTimerFromSeconds: time];
    }
}

- (void) _updateTimeDisplay
{
  unsigned int time;

  time = [player timer];
  [infoDisplayController setTimerFromSeconds: time];
  [progressSlider setIntValue: time];
}

- (void) _startTimeTimer
{
  if (timer)
    [timer invalidate];

  [self _updateTimeDisplay];
  timer = [NSTimer timerWithTimeInterval: 1
                   target: self
                   selector: @selector (_updateTimeDisplay)
                   userInfo: nil
                   repeats: YES];
  [timer explode];
}

- (void) _stopTimeTimer
{
  [timer invalidate];
  timer = nil;
}

/* as a player delegate... */
- (void) playerPlaying: (NSNotification*) aNotification
{
  double duration;

  [infoDisplayController updateInfoFieldsFromSong: currentPlayerSong];
  [infoDisplayController show];
  [self _startTimeTimer];
  duration = [[currentPlayerSong duration] doubleValue];
  [progressSlider setMaxValue: duration];

  [playButton setImage: [NSImage imageNamed: @"play-pushed"]];
  [playButton setEnabled: NO];

  [pauseButton setEnabled: YES];

  [stopButton setImage: [NSImage imageNamed: @"stop"]];
  [stopButton setAlternateImage: [NSImage imageNamed: @"stop-pushed"]];
  [stopButton setEnabled: YES];

  [playlistViewController setCurrentPlayerSong: currentPlayerSong];
  [self resetProgressSlider];
}

- (void) playerPaused: (NSNotification*) aNotification
{
  [self _stopTimeTimer];
  [pauseButton setState: YES];
}

- (void) playerResumed: (NSNotification*) aNotification
{
  [self _startTimeTimer];
  [pauseButton setState: NO];
}

- (void) playerStopped: (NSNotification*) aNotification
{
  [infoDisplayController hide];
  [self _stopTimeTimer];

  [playButton setImage: [NSImage imageNamed: @"play"]];
  [playButton setAlternateImage: [NSImage imageNamed: @"play-pushed"]];
  [playButton setEnabled: YES];
  [pauseButton setEnabled: NO];
  [stopButton setImage: [NSImage imageNamed: @"stop-pushed"]];
  [stopButton setEnabled: NO];

  [progressSlider setEnabled: NO];
  [progressSlider setMaxValue: 0];
}

- (void) playerSongEnded: (NSNotification*) aNotification
{
  Song *newSong;

  if (currentPlayerSong)
    {
      newSong = [playlist validSongAfter: currentPlayerSong];
      if (newSong)
        [self _updatePlayerSong: newSong];
      else
        {
          if (!repeat)
            [player stop];
          [self _updatePlayerSong: [playlist firstValidSong]];
        }
    }
  else
    {
      [player stop];
      [self _updatePlayerSong: [playlist firstValidSong]];
    }
}

/* Playlist delegate */
- (void) playlistChanged: (NSNotification *) aNotification
{
  NSDictionary *userInfo;

  [playlist saveToFile: defaultPlaylistFile];
  [playlistViewController updateView];
  [self updateStatusLabel];

  userInfo = [aNotification userInfo];
  if (!notifiedFirstSong)
    notifiedFirstSong = [userInfo objectForKey: @"firstSong"];
}

/* NSOpenPanel delegate */
-       (BOOL) panel: (id) sender
  shouldShowFilename: (NSString *) fileName
{
  NSFileManager *fileManager;
  FormatTester *formatTester;
  BOOL isDir, answer;

  fileManager = [NSFileManager defaultManager];
  formatTester = [FormatTester formatTester];

  answer = (([fileManager fileExistsAtPath: fileName isDirectory: &isDir]
             && isDir)
            || [formatTester extensionIsSupported: [fileName pathExtension]]);

  return answer;
}

/* Song inspector delegate */
- (void) songInspectorWasShown: (NSNotification *) aNotification
{
  [songInspectorMenuItem setState: NSOnState];
  [songInspectorButton setImage:
                         [NSImage imageNamed: @"song-inspector-pushed"]];
}

- (void) songInspectorWasHidden: (NSNotification *) aNotification
{
  [songInspectorMenuItem setState: NSOffState];
  [songInspectorButton setImage: [NSImage imageNamed: @"song-inspector"]];
}

- (void) songInspectorDidUpdateSong: (NSNotification *) aNotification
{
  if ([player playing]
      && currentPlayerSong == [[aNotification userInfo] objectForKey: @"song"])
    [infoDisplayController updateInfoFieldsFromSong: currentPlayerSong];
  [playlist saveToFile: defaultPlaylistFile];
  [playlistViewController updateView];
}

/* NSToolbar delegate */
- (NSToolbarItem *)  toolbar: (NSToolbar *) toolbar
       itemForItemIdentifier: (NSString *) itemIdentifier
   willBeInsertedIntoToolbar: (BOOL) flag
{
  NSToolbarItem *item;

  if ([itemIdentifier isEqualToString: AddItemIdentifier])
    item = addButton;
  else if ([itemIdentifier isEqualToString: RemoveItemIdentifier])
    item = removeButton;
//   else if ([itemIdentifier isEqualToString: RemoveAllItemIdentifier])
//     item = removeAllButton;
  else if ([itemIdentifier isEqualToString: CleanupItemIdentifier])
    item = cleanupButton;
//   else if ([itemIdentifier isEqualToString: SaveItemIdentifier])
//     item = saveButton;
  else if ([itemIdentifier isEqualToString: SaveAsItemIdentifier])
    item = saveAsButton;
//   else if ([itemIdentifier isEqualToString: RepeatItemIdentifier])
//     item = repeatButton;
//   else if ([itemIdentifier isEqualToString: ShuffleItemIdentifier])
//     item = shuffleButton;
  else if ([itemIdentifier isEqualToString: SongInspectorItemIdentifier])
    item = songInspectorButton;
  else
    item = nil;

  return item;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
  return [NSArray arrayWithObjects: AddItemIdentifier,
                  CleanupItemIdentifier,
                  RemoveItemIdentifier,
//                   RemoveAllItemIdentifier,
//                   RepeatItemIdentifier,
//                   SaveItemIdentifier,
                  SaveAsItemIdentifier,
//                   ShuffleItemIdentifier,
                  SongInspectorItemIdentifier,
                  NSToolbarCustomizeToolbarItemIdentifier,
                  NSToolbarSeparatorItemIdentifier,
                  NSToolbarSpaceItemIdentifier,
                  NSToolbarFlexibleSpaceItemIdentifier,
                  nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
  return [NSArray arrayWithObjects: AddItemIdentifier,
                  SaveAsItemIdentifier,
                  NSToolbarSeparatorItemIdentifier,
                  RemoveItemIdentifier,
                  CleanupItemIdentifier,
                  NSToolbarSeparatorItemIdentifier,
//                   RepeatItemIdentifier,
//                   ShuffleItemIdentifier,
//                   NSToolbarSeparatorItemIdentifier,
                  SongInspectorItemIdentifier,
                  nil];
}

/* Services */
- (id) validRequestorForSendType: (NSString *)sendType
                      returnType: (NSString *)returnType
{
  return ((sendType
           && [sendType isEqualToString: NSFilenamesPboardType]
           && ([playlistViewController getFirstSelectedRow] > -1))
          ? self
          : nil);
}

- (BOOL) writeSelectionToPasteboard: (NSPasteboard*) pboard
                              types: (NSArray*) types
{
  NSArray *declaredTypes, *filenames;
  BOOL answer;

  if ([types containsObject: NSFilenamesPboardType])
    {
      declaredTypes = [NSArray arrayWithObject: NSFilenamesPboardType];
      [pboard declareTypes: declaredTypes owner: self];
      filenames = [playlistViewController getSelectedSongsAsFilenames];
      answer = [pboard setPropertyList: filenames
                       forType: NSFilenamesPboardType];
    }
  else
    answer = NO;

  return answer;
}

@end
