/* utils.m - this file is part of Cynthiune
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

#define _GNU_SOURCE 1
#import <string.h>
#import <Foundation/Foundation.h>
#import <errno.h>

#if defined (__MACOSX__) || defined (__WIN32__)

char *
strndup (const char *string, unsigned int len)
{
  char *newString;

  if (strlen (string) > len)
    {
      newString = malloc (len + 1);
      strncpy (newString, string, len);
      *(newString + len) = 0;
    }
  else
    newString = strdup (string);

  return newString;
}

#endif

void
logRect (NSRect *rect)
{
  NSLog (@"rect = %@;", NSStringFromRect (*rect));
}

NSString *
_b (Class bundleClass, NSString *string)
{
  return [[NSBundle bundleForClass: bundleClass]
           localizedStringForKey: string value: @"" table: nil];
}

BOOL
fileIsAReadableDirectory (NSString *fileName)
{
  BOOL isDir;
  NSFileManager *fileManager;

  fileManager = [NSFileManager defaultManager];

  return ([fileManager fileExistsAtPath: fileName isDirectory: &isDir]
          && isDir
          && [fileManager isReadableFileAtPath: fileName]);
}

BOOL
fileIsAcceptable (NSString *fileName)
{
  BOOL answer;
  NSDictionary *fileAttributes;
  NSFileManager *fileManager;
  NSString *directory, *link;

  fileManager = [NSFileManager defaultManager];

  fileAttributes = 
    [fileManager fileAttributesAtPath: fileName traverseLink: NO];
  while ([fileManager fileExistsAtPath: fileName]
         && [[fileAttributes fileType]
              isEqualToString: NSFileTypeSymbolicLink])
    {
      link = [fileManager pathContentOfSymbolicLinkAtPath: fileName];
      directory = [fileName stringByDeletingLastPathComponent];
      if ([link isAbsolutePath])
        fileName = link;
      else
        fileName = [directory stringByAppendingPathComponent: link];
      fileAttributes = [fileManager fileAttributesAtPath: fileName
                                    traverseLink: NO];
    }

  answer = ([fileManager fileExistsAtPath: fileName]
            && [[fileAttributes fileType] isEqualToString: NSFileTypeRegular]);

  return answer;
}

void
invertBytesInBuffer (char *buffer, int length)
{
  unsigned int count;
  char tmpChar;
  char *ptr;

  if (length < 0)
    NSLog (@"invertBytesInBuffer: negative length: %d", length);
  else
    {
      if (length % 2)
        NSLog (@"invertBytesInBuffer: odd length: %d", length);
      else
        {
          count = 0;
          while (count < length)
            {
              ptr = buffer + count;
              tmpChar = *ptr;
              *ptr = *(ptr + 1);
              *(ptr + 1) = tmpChar;
              count += 2;
            }
        }
    }
}

void
convert8to16 (unsigned char *inBuffer,
              unsigned char *outBuffer,
              unsigned int size)
{
  unsigned int count, outCount;
  unsigned char conversionValue;

  outCount = 0;
  for (count = 0; count < size; count++)
    {
      conversionValue = *(inBuffer + count);
      *(outBuffer + outCount) = conversionValue;
      *(outBuffer + outCount + 1) = conversionValue;
      outCount += 2;
    }
}

NSComparisonResult
reverseComparisonResult (NSComparisonResult result)
{
  NSComparisonResult newResult;

  if (result == NSOrderedSame)
    newResult = NSOrderedSame;
  else
    newResult = ((result == NSOrderedAscending)
                 ? NSOrderedDescending
                 : NSOrderedAscending);

  return newResult;
}

NSString *
makeTitleFromFilename (NSString *fileName)
{
  NSString *title;

  title = [[fileName lastPathComponent] stringByDeletingPathExtension];
  
  return [title capitalizedString];
}
