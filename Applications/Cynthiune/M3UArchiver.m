/* M3UArchiver.m - this file is part of Cynthiune
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

#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSString.h>

#import <Cynthiune/NSStringExtensions.h>

#import "DictionaryCoder.h"

#import "M3UArchiver.h"

@implementation M3UArchiver : PlaylistArchiver

+ (NSString *) fileContentFromDictionaries: (NSArray *) dictionaries
                      inReferenceDirectory: (NSString *) directory
            withAbsoluteFilenameReferences: (BOOL) absolute
{
  DictionaryCoder *coder;
  NSString *filename;
  NSMutableString *ctString;
  NSEnumerator *enumerator;

  ctString = [NSMutableString stringWithString: @"#EXTM3U\r\n"];
  enumerator = [dictionaries objectEnumerator];
  coder = [enumerator nextObject];
  while (coder)
    {
      filename = [coder decodeObjectForKey: @"filename"];
      if (!absolute)
        filename = [directory relativePathFromDirectoryToFile: filename];
      [ctString appendFormat: @"#EXTINF:%@,%@\r\n%@\r\n",
                [coder decodeObjectForKey: @"duration"],
                [coder decodeObjectForKey: @"playlistRepresentation"],
                filename];
      coder = [enumerator nextObject];
    }

  return ctString;
}

@end

@implementation M3UUnarchiver : PlaylistUnarchiver

+ (NSArray *) _fileListFromLines: (NSArray *) arrayOfLines
            inReferenceDirectory: (NSString *) directory
{
  NSMutableArray *filelist;
  NSEnumerator *lines;
  NSString *currLine, *newString;

  filelist = [NSMutableArray new];
  [filelist autorelease];

  lines = [arrayOfLines objectEnumerator];
  currLine = [lines nextObject];
  while (currLine)
    {
      if (![currLine hasPrefix: @"#"] && [currLine length])
        {
          newString = [NSString stringWithString: currLine];
          if (![newString isAbsolutePath])
            newString = [directory stringByAppendingPathComponent: newString];
          newString = [newString stringByStandardizingPath];
          [filelist addObject: newString];
        }
      currLine = [lines nextObject];
    }

  return filelist;
}

+ (NSArray *) dictionariesFromFileContent: (NSString *) content
                     inReferenceDirectory: (NSString *) directory
{
  NSArray *files;

  files = [self _fileListFromLines: [content linesFromFileContent]
                 inReferenceDirectory: directory];

  return [self dictionariesFromFilenames: files];
}

@end
