/* NSStringExtensions.m - this file is part of Cynthiune
 *
 * Copyright (C) 2004 Wolfgang Sourdeau
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
#import <Foundation/NSPathUtilities.h>

#import "NSStringExtensions.h"
#import "utils.h"

@implementation NSString (CynthiuneExtension)

- (NSComparisonResult) numericallyCompare: (NSString *) aString
{
  NSComparisonResult result;
  int firstValue, secondValue;

  firstValue = [self intValue];
  secondValue = [aString intValue];
  if (firstValue < secondValue)
    result = NSOrderedAscending;
  else if (firstValue > secondValue)
    result = NSOrderedDescending;
  else
    result = NSOrderedSame;

  return result;
}

- (NSString *) _relativePathFromDirectoryToFile: (NSString *) filename
{
  NSArray *filePathComponents, *directoryPathComponents;
  unsigned int deltaPoint, count, max;
  NSString *path;

  path = @"";
  directoryPathComponents = [self pathComponents];
  filePathComponents = [filename pathComponents];

  max = [directoryPathComponents count];
  count = 0;
  while (count < max
         && [[directoryPathComponents objectAtIndex: count]
              isEqualToString: [filePathComponents objectAtIndex: count]])
    count++;
  deltaPoint = count;

  for (count = deltaPoint; count < max; count++)
    path = [path stringByAppendingPathComponent: @".."];
  max = [filePathComponents count];
  for (count = deltaPoint; count < max; count++)
    path = [path stringByAppendingPathComponent:
                   [filePathComponents objectAtIndex: count]];

  return path;
}

- (NSString *) relativePathFromDirectoryToFile: (NSString *) filename
{
  NSString *path;

  path = @"";
  if (filename)
    {
      if ([self isAbsolutePath])
        {
          if ([filename isAbsolutePath])
            path = [self _relativePathFromDirectoryToFile: filename];
          else
            raiseException (@"relative file reference",
                            @"the reference file should be an"
                            @" absolute filename");
        }
      else
        raiseException (@"relative directory reference",
                        @"the reference directory should be an"
                        @" absolute filename");
    }
  else
    raiseException (@"'nil' string", @"nil 'filename' parameter");

  return path;
}

- (NSArray *) linesFromFileContent
{
  NSArray *fileLines;

  fileLines = [self componentsSeparatedByString: @"\r\n"];
  if ([self isEqualToString: [fileLines objectAtIndex: 0]])
    fileLines = [self componentsSeparatedByString: @"\n"];

  return fileLines;
}

@end
