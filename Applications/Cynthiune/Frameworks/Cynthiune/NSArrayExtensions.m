/* NSArrayExtensions.m - this file is part of Cynthiune
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

#define _GNU_SOURCE 1

#import <time.h>
#import <stdlib.h>

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "NSArrayExtensions.h"
#import "utils.h"

@implementation NSArray (CynthiuneExtension)

// + (NSArray *) arrayFromPlaylistFile: (NSString *) filename
// {
//   NSArray *array;

//   if (filename)
//     {
//       if (fileIsAcceptable (filename))
//         {
//         }
//       else
//         raiseException (@"invalid filename", @"'filename' parameter should"
//                         @" represent a valid and readable file");
//     }
//   else
//     raiseException (@"'nil' filename", @"the 'filename' parameter cannot be nil");

//   return array;
// }

// - (BOOL) containsAllSubarray: (NSArray *) subarray
// {
//   NSEnumerator *enumerator;
//   id object;
//   BOOL result;

//   result = YES;

//   enumerator = [subarray objectEnumerator];
//   object = [enumerator nextObject];
//   while (object && result)
//     {
//       result = [self containsObject: object];
//       object = [enumerator nextObject];
//     }

//   return result;
// }

- (NSArray *) subarrayWithObjectsAtIndexes: (NSArray *) indexes
{
  NSEnumerator *enumerator;
  NSMutableArray *subarray;
  id index;

  subarray = [NSMutableArray new];
  [subarray autorelease];

  enumerator = [indexes objectEnumerator];

  index = [enumerator nextObject];
  while (index)
    {
      [subarray addObject: [self objectAtIndex: [index intValue]]];
      index = [enumerator nextObject];
    }

  return subarray;
}

- (unsigned int) numberOfValuesBelowValue: (int) value
{
  NSEnumerator *enumerator;
  NSNumber *object;
  unsigned int count;
  int currentValue;

  count = 0;
  enumerator = [self objectEnumerator];

  object = [enumerator nextObject];
  while (object)
    {
      currentValue = [object intValue];
      if (currentValue < value)
        count++;
      object = [enumerator nextObject];
    }

  return count;
}

@end

@implementation NSMutableArray (CynthiuneExtension)

- (void) addObjectsFromArray: (NSArray*) otherArray
                     atIndex: (unsigned int) index
{
  NSEnumerator *enumerator;
  unsigned int offset;
  id object;

  offset = 0;

  enumerator = [otherArray objectEnumerator];
  object = [enumerator nextObject];

  while (object)
    {
      [self insertObject: object atIndex: index + offset];
      offset++;
      object = [enumerator nextObject];
    }
}

- (unsigned int) moveObjectsAtIndexes: (NSArray *) indexes
                              toIndex: (unsigned int) index
{
  unsigned int newIndex;
  NSArray *objects;

  newIndex = 0;

  if (indexes)
    {
      if (index <= [self count])
        {
          newIndex = (index - [indexes numberOfValuesBelowValue: index]);
          objects = [self subarrayWithObjectsAtIndexes: indexes];
          [self removeObjectsInArray: objects];
          if (newIndex == [self count] + 1)
            newIndex--;
          [self addObjectsFromArray: objects atIndex: newIndex];
        }
      else
        indexOutOfBoundsException (index, [self count] + 1);
    }
  else
    raiseException (@"'nil' array", @"nil 'indexes' parameter");

  return newIndex;
}

- (void) addObjectRandomly: (id) object
{
  unsigned int randomPos;
  time_t now;
  static time_t seedModifier;

  if (object)
    {
      seedModifier++;
      time (&now);
      srand (now + seedModifier);

      randomPos = ((float) [self count] * rand ()) / RAND_MAX + .5;
      [self insertObject: object atIndex: randomPos];
    }
  else
    raiseException (@"'nil' object", @"nil 'object' parameter");
}

- (void) rotateUpToObject: (id) object
{
  id currentObject;

  if (object)
    {
      if ([self containsObject: object])
        {
          currentObject = [self objectAtIndex: 0];
          while (currentObject != object)
            {
              [currentObject retain];
              [self removeObjectAtIndex: 0];
              [self addObject: currentObject];
              [currentObject release];
              currentObject = [self objectAtIndex: 0];
            }
        }
      else
        raiseException (@"Object not in array",
                        @"the given object was not found in the array");
    }
  else
    raiseException (@"'nil' object", @"nil 'object' parameter");
}

@end
