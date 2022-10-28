/* SongInspectorController.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
 *               2012 The Free Software Foundation
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

#import <AppKit/NSButton.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSTextField.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>

#ifdef HAVE_MUSICBRAINZ
#ifdef MUSICBRAINZ_5
#include <musicbrainz5/mb5_c.h>
#else
#include <musicbrainz3/mb_c.h>
#endif
#endif

#import <Cynthiune/Format.h>
#import <Cynthiune/NSViewExtensions.h>
#import <Cynthiune/utils.h>

#import "CynthiuneAnimatedImageView.h"

#import "MBResultsPanel.h"
#import "Song.h"
#import "SongInspectorController.h"

#define LOCALIZED(X) NSLocalizedString (X, nil)
#define busyTrmId "c457a4a8-b342-4ec9-8f13-b6bd26c0e400"

static NSNotificationCenter *nc = nil;

NSString *SongInspectorWasShownNotification = @"SongInspectorWasShownNotification";
NSString *SongInspectorWasHiddenNotification = @"SongInspectorWasHiddenNotification";
NSString *SongInspectorDidUpdateSongNotification = @"SongInspectorDidUpdateSongNotification";

@implementation SongInspectorController : NSObject

+ (void) initialize
{
  nc = [NSNotificationCenter defaultCenter];
}

+ (SongInspectorController *) songInspectorController
{
  static SongInspectorController *singleton = nil;

  if (!singleton)
    singleton = [self new];

  return singleton;
}

- (id) init
{
  self = [super init];
  if (self)
    {
      song = nil;

      [NSBundle loadNibNamed: @"SongInspector" owner: self];

      [titleField setDelegate: self];
      [albumField setDelegate: self];
      [trackField setDelegate: self];
      [artistField setDelegate: self];
      [genreField setDelegate: self];
      [yearField setDelegate: self];

      [lookupAnimation addFramesFromImagenames: @"anim-logo-1", @"anim-logo-2",
                       @"anim-logo-3", @"anim-logo-4", @"anim-logo-5",
                       @"anim-logo-6", @"anim-logo-7", @"anim-logo-8", nil];
      [lookupAnimation setInterval: .05];

      threadRunning = NO;
      threadShouldDie = NO;
    }

  return self;
}

/* untestable method */
- (void) dealloc
{
  if (delegate)
    [nc removeObserver: delegate name: nil object: self];
  [super dealloc];
}

- (void) _enableWindowButtons
{
  [resetButton setEnabled: YES];
  [saveButton setEnabled: YES];
}

- (void) _disableWindowButtons
{
  [resetButton setEnabled: NO];
  [saveButton setEnabled: NO];
}

- (void) _setFieldsEditable: (BOOL) editable
{
  [titleField setEditable: editable];
  [albumField setEditable: editable];
  [trackField setEditable: editable];
  [artistField setEditable: editable];
  [genreField setEditable: editable];
  [yearField setEditable: editable];

  if (editable)
    {
      if (!threadRunning)
        {
#ifdef HAVE_MUSICBRAINZ
          [lookupButton setEnabled: YES];
          [lookupButton setImage: [NSImage imageNamed: @"lookup-mb-on"]];
          [lookupStatusLabel setStringValue: @""];
#else	  
          [lookupButton setEnabled: NO];
          [lookupButton setImage: [NSImage imageNamed: @"lookup-mb-off"]];
          [lookupStatusLabel setStringValue: LOCALIZED (@"MB lookup disabled")];
#endif
          [lookupAnimation setImage: nil];
        }
    }
  else
    {
      [lookupButton setEnabled: NO];
      [lookupButton setImage: [NSImage imageNamed: @"lookup-mb-off"]];
      [lookupAnimation setImage: [NSImage imageNamed: @"lock"]];
      [lookupStatusLabel setStringValue: @""];
    }

}

- (void) _updateFields
{
  [self _disableWindowButtons];

  if (song)
    {
      [filenameField setStringValue: [song filename]];
      [titleField setStringValue: [song title]];
      [albumField setStringValue: [song album]];
      [trackField setStringValue: [song trackNumber]];
      [artistField setStringValue: [song artist]];
      [genreField setStringValue: [song genre]];
      [yearField setStringValue: [song year]];

      [self _setFieldsEditable: [song songInfosCanBeModified]];
    }
  else
    {
      [filenameField setStringValue: LOCALIZED (@"No song selected")];
      [titleField setStringValue: @""];
      [albumField setStringValue: @""];
      [trackField setStringValue: @""];
      [artistField setStringValue: @""];
      [genreField setStringValue: @""];
      [yearField setStringValue: @""];

      [self _setFieldsEditable: NO];
    }
}

- (void) _updateSelector
{
  id <NSMenuItem> menuItem;
  int count, max;

  max = [pageSelector numberOfItems];
  for (count = 0; count < max; count++)
    {
      menuItem = [pageSelector itemAtIndex: count];
      [menuItem setTitle: LOCALIZED ([menuItem title])];
    }

  [pageSelector sizeToFit];
  [pageSelector centerViewHorizontally];
}

- (void) _updateWidgets
{
  [titleLabel setStringValue: LOCALIZED (@"Title")];
  [albumLabel setStringValue: LOCALIZED (@"Album")];
  [trackLabel setStringValue: LOCALIZED (@"Track")];
  [artistLabel setStringValue: LOCALIZED (@"Artist")];
  [genreLabel setStringValue: LOCALIZED (@"Genre")];
  [yearLabel setStringValue: LOCALIZED (@"Year")];

  [resetButton setTitle: LOCALIZED (@"Reset")];
  [saveButton setTitle: LOCALIZED (@"Save")];

  [resetButton sizeToFit];
  [saveButton sizeToFit];
  [resetButton arrangeViewLeftTo: saveButton];

  [lookupButton setToolTip: LOCALIZED (@"Lookup through MusicBrainz...")];
  [lookupButton setImage: [NSImage imageNamed: @"lookup-mb-off"]];

//   [lookupButton sizeToFit];
//   [lookupButton centerViewHorizontally];

  [inspectorPanel setTitle: LOCALIZED (@"Song Inspector")];
  [inspectorPanel setDelegate: self];
}

- (void) awakeFromNib
{
  [self _updateSelector];
  [self _updateWidgets];
  [self _updateFields];
}

- (void) setDelegate: (id) anObject
{
  if (delegate)
    [nc removeObserver: delegate name: nil object: self];

  delegate = anObject;

  if ([delegate respondsToSelector: @selector(songInspectorWasShown:)])
    [nc addObserver: delegate
	selector: @selector (songInspectorWasShown:)
	name: SongInspectorWasShownNotification
	object: self];
  if ([delegate respondsToSelector: @selector(songInspectorWasHidden:)])
    [nc addObserver: delegate
	selector: @selector (songInspectorWasHidden:)
	name: SongInspectorWasHiddenNotification
	object: self];
  if ([delegate respondsToSelector: @selector(songInspectorDidUpdateSong:)])
    [nc addObserver: delegate
	selector: @selector (songInspectorDidUpdateSong:)
	name: SongInspectorDidUpdateSongNotification
	object: self];
}

- (id) delegate
{
  return delegate;
}

- (void) setSong: (Song *) newSong
{
  if (song != newSong)
    {
      if (threadRunning)
        threadShouldDie = YES;
      SET (song, newSong);
      [self _updateFields];
    }
}

- (Song *) song
{
  return song;
}

/* button actions */
- (void) reset: (id) sender
{
  [self _updateFields];
}

- (void) save: (id) sender
{
  [self _disableWindowButtons];

  [song setTitle: [titleField stringValue]
        artist: [artistField stringValue]
        album: [albumField stringValue]
        genre: [genreField stringValue]
        trackNumber: [trackField stringValue]
        year: [yearField stringValue]];

  [nc postNotificationName: SongInspectorDidUpdateSongNotification
      object: self
      userInfo: [NSDictionary dictionaryWithObject: song
                              forKey: @"song"]];
}

- (void) updateField: (NSTextField *) field
          withString: (NSString *) string
{
  if (!threadShouldDie)
    [field performSelectorOnMainThread: @selector (setStringValue:)
           withObject: string
           waitUntilDone: NO];
}

- (BOOL) _updateInfoField: (NSTextField *) field
               withString: (NSString *) string
{
  BOOL result;

  if (!string)
    string = @"";

  if (![[field stringValue] isEqualToString: string])
    {
      [field setStringValue: string];
      result = YES;
    }
  else
    result = NO;

  return result;
}

- (void) _updateFieldsWithTrackInfos: (NSDictionary *) trackInfos
{
  BOOL changes;

  changes = [self _updateInfoField: titleField
                  withString: [trackInfos objectForKey: @"title"]];
  changes |= [self _updateInfoField: albumField
                   withString: [trackInfos objectForKey: @"album"]];
  changes |= [self _updateInfoField: trackField
                   withString: [trackInfos objectForKey: @"trackNumber"]];
  changes |= [self _updateInfoField: artistField
                   withString: [trackInfos objectForKey: @"artist"]];
  changes |= [self _updateInfoField: yearField
                   withString: [trackInfos objectForKey: @"year"]];

  if (changes)
    [self _enableWindowButtons];
}

- (void) _updateSongFields: (NSArray *) allTrackInfos
{
  unsigned int numberOfTracks;

  numberOfTracks = [allTrackInfos count];
  [lookupStatusLabel
    setStringValue: [NSString stringWithFormat:
                                LOCALIZED (@"Received %d result(s)"),
                              numberOfTracks]];
  if (numberOfTracks == 1)
    [self _updateFieldsWithTrackInfos: [allTrackInfos objectAtIndex: 0]];
  else if (numberOfTracks > 1)
    [[MBResultsPanel resultsPanel] showPanelForTrackInfos: allTrackInfos
                                   aboveWindow: inspectorPanel
                                   target: self
                                   selector: @selector (_updateFieldsWithTrackInfos:)];
}

#ifdef HAVE_MUSICBRAINZ
#ifdef MUSICBRAINZ_5
- (NSDictionary *) readMB: (Mb5RecordingList) mb
#else
- (NSDictionary *) readMB: (MbResultList) mb
#endif
                    track: (int) track
{
  NSMutableDictionary *trackInfos;
  NSString *string;
  char cString[256];
#ifdef MUSICBRAINZ_5
  Mb5Recording rec;
  Mb5ReleaseList albums;
  Mb5Artist artist;
  Mb5Release rel;
  Mb5ArtistCredit credit;
  Mb5NameCreditList clist;
  Mb5NameCredit name_credit;
#else
  MbTrack rec;
  MbRelease rel;
  MbArtist artist;
#endif

  trackInfos = [NSMutableDictionary new];
  [trackInfos autorelease];

#ifdef MUSICBRAINZ_5
  rec = mb5_recording_list_item (mb, track);
#else
  rec = mb_result_list_get_track (mb, track);
#endif

  if (rec)
    {
#ifdef MUSICBRAINZ_5
      mb5_recording_get_title (rec, cString, sizeof (cString));
#else
      mb_track_get_title (rec, cString, sizeof (cString));
#endif
      string = [NSString stringWithUTF8String: cString];
      [trackInfos setObject: string forKey: @"title"];

#ifdef MUSICBRAINZ_5
      albums = mb5_recording_get_releaselist (rec);
      rel = mb5_release_list_item (albums, 0);
      mb5_release_get_title (rel, cString, sizeof (cString));
#else
      /* FIXME: It appears that `rel' is not the release/album but the
	 track; subsequently `mb_release_get_title' returns the song
	 title and not the release title.  */
      rel = mb_result_list_get_release (mb, track);
      mb_release_get_title (rel, cString, sizeof (cString));
#endif
      string = [NSString stringWithUTF8String: cString];
      [trackInfos setObject: string forKey: @"album"];

#ifdef MUSICBRAINZ_5
      /* FIXME: Figure out how to extract the release date with
	 libmusicbrainz3.  */
      mb5_release_get_date (rel, cString, sizeof (cString));
      *(cString + 4) = 0;
      string = [NSString stringWithUTF8String: cString];
      [trackInfos setObject: string forKey: @"year"];

      /* Obtain the artist name.  Slightly convoluted, but it looks
	 like there's no other way.  */
      credit = mb5_recording_get_artistcredit (rec);
      clist = mb5_artistcredit_get_namecreditlist (credit);
      name_credit = mb5_namecredit_list_item (clist, 0);
      artist = mb5_namecredit_get_artist (name_credit);
      mb5_artist_get_name (artist, cString, sizeof (cString));
#else
      artist = mb_track_get_artist (rec);
      mb_artist_get_name (artist, cString, 256);
#endif
      string = [NSString stringWithUTF8String: cString];
      [trackInfos setObject: string forKey: @"artist"];
    }

  return trackInfos;
}

#ifdef MUSICBRAINZ_5
- (void) _parseMB: (Mb5RecordingList) mb
#else
- (void) _parseMB: (MbResultList) mb
#endif
{
  int count, results;
  NSMutableArray *allTrackInfos;

#ifdef MUSICBRAINZ_5
  results = mb5_recording_list_size (mb);
#else
  results = mb_result_list_get_size (mb);
#endif

  allTrackInfos = [[NSMutableArray alloc] initWithCapacity: results];
  [allTrackInfos autorelease];

  for (count = 0; count < results; count++)
    [allTrackInfos addObject: [self readMB: mb track: count]];

  [self performSelectorOnMainThread: @selector (_updateSongFields:)
        withObject: allTrackInfos
        waitUntilDone: YES];
}

- (void) lookupThread
{
  NSAutoreleasePool *pool;
#ifdef MUSICBRAINZ_5
  Mb5Query query;
  Mb5Metadata metadata;
  Mb5RecordingList mb;
  char **p_names, **p_values;
  char error[256];
#else
  MbQuery query;
  MbTrackFilter filter;
  MbResultList mb;
#endif

  pool = [NSAutoreleasePool new];

  [self updateField: lookupStatusLabel
	 withString: LOCALIZED (@"Querying the MusicBrainz server...")];

#ifdef MUSICBRAINZ_5
  query = mb5_query_new ("Cynthiune", NULL, 0);
#else
  query = mb_query_new (NULL, "Cynthiune");
#endif

  if (query)
    {
#ifdef MUSICBRAINZ_5
      p_names = malloc (2 * sizeof (char *));
      p_values = malloc (2 * sizeof (char *));
      p_names[0] = malloc (10);
      p_values[0] = malloc (256);
      strcpy (p_names[0], "query");
      strcpy (p_values[0], [[song title] UTF8String]);

      if (strlen (p_values[0]) > 0)
	{
	  metadata = mb5_query_query (query, "recording", "", "", 1,
				      p_names, p_values);
	  mb5_query_get_lasterrormessage (query, error, sizeof (error));

	  if (metadata)
	    {
	      mb = mb5_metadata_get_recordinglist (metadata);
	      [self _parseMB: mb];

	      mb5_metadata_delete (metadata);
	    }
#else
      if ([[song title] UTF8String] != NULL)
	{
	  filter = mb_track_filter_new ();
	  mb_track_filter_title (filter, [[song title] UTF8String]);
	  if ([[song artist] UTF8String] != NULL)
	    mb_track_filter_artist_name (filter, [[song artist] UTF8String]);
	  mb = mb_query_get_tracks (query, filter);
	  [self _parseMB: mb];

	  mb_track_filter_free (filter);
	}
#endif
#ifdef MUSICBRAINZ_5
      else
	[self updateField: lookupStatusLabel
	       withString: [NSString stringWithFormat:
				       LOCALIZED (@"Error while querying the\n"
						  @"Musicbrainz server: %s"),
				     error]];

	}
      free (p_names[0]);
      free (p_values[0]);
      free (p_names);
      free (p_values);
#endif
    }

#ifdef MUSICBRAINZ_5
  mb5_query_delete (query);
#else
  mb_query_free (query);
#endif

  [self performSelectorOnMainThread: @selector (lookupThreadEnded)
        withObject: nil
        waitUntilDone: NO];

  [pool release];
}
#endif

- (void) mbLookup: (id)sender
{
  if (song)
    {
      if (!threadRunning)
        {
          threadRunning = YES;
          [lookupAnimation startAnimation];
          [lookupButton setEnabled: NO];
          [lookupButton setImage: [NSImage imageNamed: @"lookup-mb-off"]];
          [NSThread detachNewThreadSelector: @selector (lookupThread)
                    toTarget: self
                    withObject: nil];
        }
    }
  else
    NSLog (@"how could that method be called?");
}

- (void) lookupThreadEnded
{
  threadRunning = NO;
  threadShouldDie = NO;
  [lookupAnimation stopAnimation];
  if (song && [song songInfosCanBeModified])
    {
      [lookupButton setEnabled: YES];
      [lookupButton setImage: [NSImage imageNamed: @"lookup-mb-on"]];
    }
}

- (void) toggleDisplay
{
  if ([inspectorPanel isVisible])
    [inspectorPanel close];
  else
    [inspectorPanel makeKeyAndOrderFront: self];
}

/* inspector delegate */
- (void) windowDidBecomeKey: (NSNotification*) aNotif
{
  if ([aNotif object] == inspectorPanel)
    [nc postNotificationName: SongInspectorWasShownNotification object: self];
}

- (void) windowWillClose: (NSNotification *) aNotif
{
  if ([aNotif object] == inspectorPanel)
    [nc postNotificationName: SongInspectorWasHiddenNotification object: self];
}

/* textfields delegate */

- (void) controlTextDidChange:(NSNotification *)aNotification
{
  [self _enableWindowButtons];
}

@end
