/* FormatTester.m - this file is part of Cynthiune
 *
 * Copyright (C) 2003, 2004  Wolfgang Sourdeau
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

#import <Foundation/NSArray.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSString.h>

#import <Cynthiune/Format.h>

#import "FormatTester.h"

@implementation FormatTester : NSObject

+ (id) formatTester
{
  static FormatTester *singleton = nil;

  if (!singleton)
    singleton = [self new];

  return singleton;
}

- (id) init
{
  if ((self = [super init]))
    {
      formatList = [NSMutableArray array];
      extensionsList = [NSMutableArray array];
      [formatList retain];
      [extensionsList retain];
    }

  return self;
}

- (void) registerFormatClass: (Class) aClass
{
  if ([aClass conformsToProtocol: @protocol(Format)])
    {
      [formatList addObject: aClass];
      [extensionsList
        addObjectsFromArray: [aClass acceptedFileExtensions]];
    }
  else
    NSLog (@"Class '%@' not conform to 'Format' protocol...\n",
           NSStringFromClass (aClass));
}

- (NSArray *) acceptedFileExtensions
{
  return extensionsList;
}

- (Class) formatClassAtIndex: (unsigned int) formatNumber
{
  Class formatClass;

  if (formatNumber < [formatList count])
    formatClass = [formatList objectAtIndex: formatNumber];
  else
    formatClass = Nil;

  return formatClass;
}

- (BOOL)   formatClass: (Class) formatClass
  acceptsFileExtension: (NSString *) extension
{
  unsigned int count, max;
  BOOL result;
  NSArray *extensions;
  NSString *currentExtension;

  result = NO;

  if ([formatList containsObject: formatClass])
    {
      extensions = [formatClass acceptedFileExtensions];
      max = [extensions count];
      count = 0;

      while (count < max && !result)
        {
          currentExtension = [extensions objectAtIndex: count];
          result = ([extension caseInsensitiveCompare: currentExtension]
                    == NSOrderedSame);
          count++;
        }
    }
  
  return result;
}

- (Class) formatClassForFileExtension: (NSString *) extension
{
  unsigned int count, max;
  Class currentFormatClass, resultClass;

  count = 0;
  max = [formatList count];
  resultClass = nil;

  while (count < max && !resultClass)
    {
      currentFormatClass = [formatList objectAtIndex: count];
      if ([self formatClass: currentFormatClass
                acceptsFileExtension: extension])
        resultClass = currentFormatClass;
      count++;
    }

  return resultClass;
}

- (int) formatNumberForFile: (NSString *) file
{
  Class testClass;
  int formatNumber, count;

  formatNumber = -1;
  count = 0;

  while (formatNumber == -1
         && count < [formatList count])
    {
      testClass = [formatList objectAtIndex: count];

      if (([testClass canTestFileHeaders]
           && [testClass streamTestOpen: file])
          || [self formatClass: testClass
                   acceptsFileExtension: [file pathExtension]])
        formatNumber = count;
      else
        count++;
    }

  return formatNumber;
}

- (Class) formatClassForFile: (NSString *) file
{
  int formatNumber;
  Class formatClass;

  formatNumber = [self formatNumberForFile: file];

  if (formatNumber > -1)
    formatClass = [formatList objectAtIndex: formatNumber];
  else
    formatClass = Nil;

  return formatClass;
}

- (BOOL) extensionIsSupported: (NSString *) extension
{
  NSMutableArray *extensions;
  NSString *currentExtension;
  BOOL result;
  unsigned int count, max;

  result = NO;

  extensions = [NSMutableArray arrayWithObjects: @"m3u", @"pls", @"cPls", nil];
  [extensions addObjectsFromArray: extensionsList];

  count = 0;
  max = [extensions count];
  while (!result && count < max)
    {
      currentExtension = [extensions objectAtIndex: count];
      result = ([currentExtension caseInsensitiveCompare: extension]
                == NSOrderedSame);
      count++;
    }

  return result;
}

- (BOOL) fileIsPlaylist: (NSString *) filename
{
  NSString *extension;

  extension = [filename pathExtension];

  return ([extension caseInsensitiveCompare: @"cPls"] == NSOrderedSame
          || [extension caseInsensitiveCompare: @"m3u"] == NSOrderedSame
          || [extension caseInsensitiveCompare: @"pls"] == NSOrderedSame);
}

@end
