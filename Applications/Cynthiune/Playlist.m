/* Playlist.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005  Wolfgang Sourdeau
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

#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>

#import <Cynthiune/NSArrayExtensions.h>
#import <Cynthiune/utils.h>

#import "M3UArchiver.h"
#import "PLSArchiver.h"
#import "Playlist.h"
#import "Song.h"

static NSNotificationCenter *nc = nil;

static NSString *PlaylistChangedNotification = @"PlaylistChangedNotification";

@implementation Playlist : NSObject

+ (void) initialize
{
  if (!nc)
    nc = [NSNotificationCenter defaultCenter];
}

- (id) init
{
  if ((self = [super init]))
    {
      list = [NSMutableArray new];
      shuffleList = nil;
      delegate = nil;
    }

  return self;
}

/* untestable method */
- (void) dealloc
{
  [list release];
  if (shuffleList)
    [shuffleList release];
  if (delegate)
    [nc removeObserver: delegate name: nil object: self];
  [super dealloc];
}

- (void) setDelegate: (id) object
{
  if (delegate)
    [nc removeObserver: delegate name: nil object: self];

  delegate = object;

  if ([object respondsToSelector: @selector(playlistChanged:)])
    {
      [nc addObserver: object
          selector: @selector (playlistChanged:)
          name: PlaylistChangedNotification
          object: self];
    }
}

- (id) delegate
{
  return delegate;
}

- (void) postNotificationWithSongAsFirst: (Song *) song
{
  [nc postNotificationName: PlaylistChangedNotification
      object: self
      userInfo: [NSDictionary dictionaryWithObject: song
                              forKey: @"firstSong"]];
}

- (void) addSong: (Song *) song
{
  if ([list containsObject: song])
    NSLog(@"Skipping duplicate song: %@", [song filename]);
  else
    {
      [list addObject: song];
      if (shuffleList)
        [shuffleList addObjectRandomly: song];
      [self postNotificationWithSongAsFirst: song];
    }
}

- (void) addSongsInArray: (NSArray *) array
{
  NSEnumerator *songEnumerator;
  id song;
  unsigned int max;
  Song *firstSong;

  if (array)
    {
      firstSong = nil;
      max = [list count];
      songEnumerator = [array objectEnumerator];
      song = [songEnumerator nextObject];
      while (song)
        {
          if ([song isKindOfClass: [Song class]])
            {
              if ([list containsObject: song])
		NSLog(@"Skipping duplicate song: %@", [song filename]);
              else
                {
                  if (!firstSong)
                    firstSong = song;
                  [list addObject: song];
                  if (shuffleList)
                    [shuffleList addObjectRandomly: song];
                }
            }
          else
            raiseException (@"bad object in array",
                            @"'array' may only contain Song instances");
          song = [songEnumerator nextObject];
        }
      if ([list count] > max)
        [self postNotificationWithSongAsFirst: firstSong];
    }
  else
    raiseException (@"'nil' array", @"nil 'array' parameter");
}

- (void) insertSong: (Song *) song
            atIndex: (unsigned int) index
{
  if ([list containsObject: song])
    NSLog(@"Skipping duplicate song: %@", [song filename]);
  else
    {
      [list insertObject: song atIndex: index];
      if (shuffleList)
        [shuffleList addObjectRandomly: song];
      [self postNotificationWithSongAsFirst: song];
    }
}

- (void) deleteSong: (Song *) song
{
  if (song)
    {
      if ([list containsObject: song])
        {
          [list removeObject: song];
          if (shuffleList)
            [shuffleList removeObject: song];
          [nc postNotificationName: PlaylistChangedNotification object: self];
        }
      else
        raiseException (@"Song not in list", @"the given song was not found"
                        @" in the list");
    }
  else
    raiseException (@"'nil' song", @"nil 'song' parameter");
}

- (void) deleteAllSongs
{
  if ([list count])
    {
      [list removeAllObjects];
      [shuffleList removeAllObjects];
      [nc postNotificationName: PlaylistChangedNotification object: self];
    }
}

- (void) deleteAllSongsQuietly
{
  [list removeAllObjects];
  [shuffleList removeAllObjects];
}

- (void) deleteSongsInArray: (NSArray *) array
{
  NSEnumerator *songEnumerator;
  id song;
  unsigned int max;

  if (array)
    {
      max = [list count];
      songEnumerator = [array objectEnumerator];
      song = [songEnumerator nextObject];
      while (song)
        {
          if ([song isKindOfClass: [Song class]])
            {
              if ([list containsObject: song])
                {
                  [list removeObject: song];
                  if (shuffleList)
                    [shuffleList removeObject: song];
                }
              else
                raiseException (@"Song not in list",
                                @"the given song was not found in the list");
            }
          else
            raiseException (@"bad object in array",
                            @"'array' may only contain Song instances");
          song = [songEnumerator nextObject];
        }
      if ([list count] < max)
        [nc postNotificationName: PlaylistChangedNotification object: self];
    }
  else
    raiseException (@"'nil' array", @"nil 'array' parameter");
}

- (NSArray *) arrayOfInvalidSongs
{
  NSEnumerator *songEnumerator;
  NSMutableArray *invalidSongs;
  Song *song;
  unsigned int max;

  invalidSongs = [NSMutableArray new];
  max = [list count];
  if (max)
    {
      songEnumerator = [list reverseObjectEnumerator];
      song = [songEnumerator nextObject];
      while (song)
        {
          if ([song status] != SongOK)
            [invalidSongs addObject: song];
          song = [songEnumerator nextObject];
        }
      if ([list count] < max)
        [nc postNotificationName: PlaylistChangedNotification object: self];
    }

  [invalidSongs autorelease];

  return invalidSongs;
}

- (void) replaceSongsWithArray: (NSArray *) array
{
  NSEnumerator *songEnumerator;
  id object;
  BOOL arraysAreEqual;

  if (array)
    {
      arraysAreEqual = [list isEqualToArray: array];
      [list removeAllObjects];
      if (shuffleList)
        [shuffleList removeAllObjects];
      songEnumerator = [array objectEnumerator];
      object = [songEnumerator nextObject];
      while (object)
        {
          if ([object isKindOfClass: [Song class]])
            {
              [list addObject: object];
              if (shuffleList)
                [shuffleList addObjectRandomly: object];
            }
          else
            raiseException (@"bad object in array",
                            @"'array' may only contain Song instances");
          object = [songEnumerator nextObject];
        }
      if (!arraysAreEqual)
        [nc postNotificationName: PlaylistChangedNotification object: self];
    }
  else
    raiseException (@"'nil' array", @"nil 'array' parameter");
}

- (Song *) songAtIndex: (unsigned int) index
{
  Song *song;

  song = nil;
  if (index < [list count])
    song = [list objectAtIndex: index];
  else
    indexOutOfBoundsException (index, [list count]);

  return song;
}

- (unsigned int) indexOfSong: (Song *) song
{
  unsigned int index;

  index = 0;
  if (song)
    {
      if ([list containsObject: song])
        index = [list indexOfObject: song];
      else
        raiseException (@"Song not in list", @"the given song was not found"
                        @" in the list");
    }
  else
    raiseException (@"'nil' song", @"nil 'song' parameter");

  return index;
}

- (unsigned int) moveSongsAtIndexes: (NSArray *) indexes
                            toIndex: (unsigned int) index
{
  unsigned int firstIndex;
  NSArray *listCopy;

  listCopy = [list copy];
  firstIndex = [list moveObjectsAtIndexes: indexes toIndex: index];
  if (![list isEqualToArray: listCopy])
    [nc postNotificationName: PlaylistChangedNotification object: self];

  return firstIndex;
}

- (Song *) firstSong
{
  return ([list count] ? [list objectAtIndex: 0] : nil);
}

- (Song *) lastSong
{
  unsigned int count;

  count = [list count];

  return (count ? [list objectAtIndex: count - 1] : nil);
}

- (Song *) _nextValidSongInEnumerator: (NSEnumerator *) songEnumerator
{
  Song *song, *result;

  result = nil;
  song = [songEnumerator nextObject];

  while (!result && song)
    if ([song status] == SongOK)
      result = song;
    else
      song = [songEnumerator nextObject];

  return result;
}

- (Song *) firstValidSong
{
  NSArray *realList;

  realList = ((shuffleList) ? shuffleList : list);

  return [self _nextValidSongInEnumerator: [realList objectEnumerator]];
}

- (Song *) lastValidSong
{
  NSArray *realList;

  realList = ((shuffleList) ? shuffleList : list);

  return [self _nextValidSongInEnumerator: [realList reverseObjectEnumerator]];
}

- (Song *) songAfter: (Song *) song
{
  Song *foundSong;
  unsigned int songIndex;
  NSArray *realList;

  foundSong = nil;

  if (song)
    {
      realList = ((shuffleList) ? shuffleList : list);
      if ([realList containsObject: song])
        {
          songIndex = [realList indexOfObject: song];
          if (songIndex < [realList count] - 1)
            foundSong = [realList objectAtIndex: (songIndex + 1)];
        }
      else
        raiseException (@"Song not in list", @"the given song was not found"
                        @" in the list");
    }
  else
    raiseException (@"'nil' song", @"nil 'song' parameter");

  return foundSong;
}

- (Song *) songBefore: (Song *) song
{
  Song *foundSong;
  unsigned int songIndex;
  NSArray *realList;

  foundSong = nil;

  if (song)
    {
      realList = ((shuffleList) ? shuffleList : list);
      if ([realList containsObject: song])
        {
          songIndex = [realList indexOfObject: song];
          if (songIndex > 0)
            foundSong = [realList objectAtIndex: (songIndex - 1)];
        }
      else
        raiseException (@"Song not in list", @"the given song was not found"
                        @" in the list");
    }
  else
    raiseException (@"'nil' song", @"nil 'song' parameter");

  return foundSong;
}

- (Song *) validSongAfter: (Song *) song
{
  Song *currentSong;

  currentSong = [self songAfter: song];
  while (currentSong && [currentSong status] != SongOK)
    currentSong = [self songAfter: currentSong];

  return currentSong;
}

- (Song *) validSongBefore: (Song *) song
{
  Song *currentSong;

  currentSong = [self songBefore: song];
  while (currentSong && [currentSong status] != SongOK)
    currentSong = [self songBefore: currentSong];

  return currentSong;
}

- (unsigned int) numberOfSongs
{
  return [list count];
}

- (NSNumber *) duration
{
  unsigned int intDuration;
  NSEnumerator *songEnumerator;
  Song *song;

  intDuration = 0;
  songEnumerator = [list objectEnumerator];
  song = [songEnumerator nextObject];

  while (song)
    {
      intDuration += [[song duration] intValue];
      song = [songEnumerator nextObject];
    }

  return [NSNumber numberWithUnsignedInt: intDuration];
}

/* unimplemented methods */
- (void) setShuffle: (BOOL) shuffle
{
  NSEnumerator *songEnumerator;
  id song;

  if (shuffle && !shuffleList)
    {
      shuffleList = [NSMutableArray new];
      songEnumerator = [list objectEnumerator];

      song = [songEnumerator nextObject];
      while (song)
        {
          [shuffleList addObjectRandomly: song];
          song = [songEnumerator nextObject];
        }
    }
  else if (!shuffle && shuffleList)
    {
      [shuffleList release];
      shuffleList = nil;
    }
}

- (BOOL) shuffle
{
  return (shuffleList != nil);
}

- (void) shuffleFromSong: (Song *) song
{
  if (song)
    {
      if ([list containsObject: song])
        [shuffleList rotateUpToObject: song];
      else
        raiseException (@"Song not in list", @"the given song was not found"
                        @" in the list");
    }
  else
    raiseException (@"'nil' song", @"nil 'song' parameter");
}

- (void) _sortListUsingSelector: (SEL) comparator
{
  NSArray *newList;

  newList = [list sortedArrayUsingSelector: comparator];
  if (![newList isEqualToArray: list])
    {
      [list setArray: newList];
      [nc postNotificationName: PlaylistChangedNotification object: self];
    }
}

- (void) sortByPlaylistRepresentation: (BOOL) reverseOrder
{
  [self _sortListUsingSelector: ((reverseOrder)
                                 ? @selector (reverseCompareByPlaylistRepresentation:)
                                 : @selector (compareByPlaylistRepresentation:))];
}

- (void) sortByDuration: (BOOL) reverseOrder
{
  [self _sortListUsingSelector: ((reverseOrder)
                                 ? @selector (reverseCompareByDuration:)
                                 : @selector (compareByDuration:))];
}

- (void) loadFromFile: (NSString *) file
{
  NSString *extension;
  NSArray *newList;
  Class archiver;

  extension = [file pathExtension];
  if ([extension caseInsensitiveCompare: @"cPls"] == NSOrderedSame)
    archiver = [NSKeyedUnarchiver class];
  else if ([extension caseInsensitiveCompare: @"m3u"] == NSOrderedSame)
    archiver = [M3UUnarchiver class];
  else if ([extension caseInsensitiveCompare: @"pls"] == NSOrderedSame)
    archiver = [PLSUnarchiver class];
  else
    archiver = Nil;

  if (archiver)
    {
      newList = [archiver unarchiveObjectWithFile: file];
      if (newList)
        [self addSongsInArray: newList];
    }
}

- (void) saveToFile: (NSString *) file
{
  NSString *extension;
  Class archiver;

  extension = [file pathExtension];
  if ([extension caseInsensitiveCompare: @"cPls"] == NSOrderedSame)
    archiver = [NSKeyedArchiver class];
  else if ([extension caseInsensitiveCompare: @"m3u"] == NSOrderedSame)
    archiver = [M3UArchiver class];
  else if ([extension caseInsensitiveCompare: @"pls"] == NSOrderedSame)
    archiver = [PLSArchiver class];
  else
    archiver = Nil;

  if (archiver)
    [archiver archiveRootObject: list toFile: file];
}

@end
