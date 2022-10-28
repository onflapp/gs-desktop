/* PlaylistArchiver.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
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

#define _GNU_SOURCE
#import <string.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSString.h>

#import <Cynthiune/Preference.h>

#import "DictionaryCoder.h"
#import "GeneralPreference.h"
#import "Song.h"

#import "PlaylistArchiver.h"

#ifdef __MACOSX__

@implementation NSObject (CynthiuneExtension)

+ (id) subclassResponsibility: (SEL) aSel
{
  return nil;
}

@end

#endif /* __MACOSX__ */

@implementation PlaylistArchiver : NSObject

+ (NSArray *) _encodeMetadataFromArray: (NSArray *) anArray
{
  NSMutableArray *metadata;
  NSEnumerator *enumerator;
  DictionaryCoder *currentCoder;
  Song *currentSong;

  metadata = [NSMutableArray arrayWithCapacity: [anArray count]];
  enumerator = [anArray objectEnumerator];
  currentSong = [enumerator nextObject];
  while (currentSong)
    {
      currentCoder = [DictionaryCoder new];
      [currentCoder autorelease];
      [currentSong encodeWithCoder: currentCoder];
      [metadata addObject: currentCoder];
      currentSong = [enumerator nextObject];
    }

  return metadata;
}

+ (BOOL) _saveDictionaries: (NSArray *) dictionaries
                    toFile: (NSString *) filename
{
  NSData *fileContent;
  NSString *content;
  NSString *targetDirectory;
  BOOL result, absoluteReferences;

  absoluteReferences =
    [[GeneralPreference instance] absolutePlaylistReferences];
  targetDirectory = [[filename stringByDeletingLastPathComponent] stringByStandardizingPath];
  content = [self fileContentFromDictionaries: dictionaries
                  inReferenceDirectory: targetDirectory
                  withAbsoluteFilenameReferences: absoluteReferences];
  if (content && [content length])
    {
      fileContent = [NSData dataWithBytes: [content cString]
                            length: [content length]];
      result = [[NSFileManager defaultManager]
                 createFileAtPath: filename
                 contents: fileContent
                 attributes: nil];
    }
  else
    result = NO;

  return result;
}

+ (BOOL) archiveRootObject: (id) anObject
                    toFile: (NSString *) filename
{
  return [self
           _saveDictionaries: [self _encodeMetadataFromArray: anObject]
           toFile: filename];
}

+ (NSString *) fileContentFromDictionaries: (NSArray *) dictionaries
                      inReferenceDirectory: (NSString *) directory
            withAbsoluteFilenameReferences: (BOOL) absolute
{
  [self subclassResponsibility: _cmd];

  return nil;
}

@end

@implementation PlaylistUnarchiver : NSObject

+ (NSArray *) _decodeArrayFromMetadata: (NSArray *) metadata
{
  NSMutableArray *anArray;
  NSEnumerator *enumerator;
  DictionaryCoder *currentCoder;
  Song *currentSong;

  anArray = [NSMutableArray arrayWithCapacity: [metadata count]];
  enumerator = [metadata objectEnumerator];
  currentCoder = [enumerator nextObject];
  while (currentCoder)
    {
      currentSong = [[Song alloc] initWithCoder: currentCoder];
      [currentSong autorelease];
      [anArray addObject: currentSong];
      currentCoder = [enumerator nextObject];
    }

  return anArray;
}

+ (NSArray *) _loadDictionariesFromFile: (NSString *) filename
{
  return [self dictionariesFromFileContent:
                 [NSString stringWithContentsOfFile: filename]
               inReferenceDirectory:
                 [filename stringByDeletingLastPathComponent]];
}

+ (id) unarchiveObjectWithFile: (NSString*) filename
{
  return [self _decodeArrayFromMetadata:
                 [self _loadDictionariesFromFile: filename]];
}

+ (NSArray *) dictionariesFromFileContent: (NSString *) content
                     inReferenceDirectory: (NSString *) directory
{
  [self subclassResponsibility: _cmd];

  return nil;
}

+ (NSArray *) dictionariesFromFilenames: (NSArray *) filenames
{
  NSMutableArray *dictionaries;
  NSEnumerator *files;
  NSString *currentFile;
  DictionaryCoder *currentCoder;

  dictionaries = [NSMutableArray new];
  [dictionaries autorelease];

  files = [filenames objectEnumerator];
  currentFile = [files nextObject];
  while (currentFile)
    {
      currentCoder = [DictionaryCoder new];
      [currentCoder autorelease];
      [currentCoder encodeObject: currentFile forKey: @"filename"];
      [dictionaries addObject: currentCoder];
      currentFile = [files nextObject];
    }
  
  return dictionaries;
}

@end
