/* DictionaryCoder.m - this file is part of Cynthiune
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

#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import <Cynthiune/utils.h>

#import "DictionaryCoder.h"

@implementation DictionaryCoder : NSCoder

- (id) init
{
  if ((self = [super init]))
    {
      dictionary = [[NSMutableDictionary alloc] init];
    }

  return self;
}

- (void) dealloc
{
  [dictionary release];
  [super dealloc];
}

- (void) encodeObject: (id) anObject forKey: (NSString *) aKey
{
  [dictionary setObject: anObject forKey: aKey];
}

- (void) encodeBool: (BOOL) aBool forKey: (NSString*) aKey
{
  NSNumber *boolValue;

  boolValue = [NSNumber numberWithBool: aBool];
  [dictionary setObject: boolValue forKey: aKey];
}

- (void) encodeInt: (int) anInteger forKey: (NSString*) aKey
{
  NSNumber *intValue;

  intValue = [NSNumber numberWithInt: anInteger];
  [dictionary setObject: intValue forKey: aKey];
}

- (void) encodeInt64: (int64_t) anInteger forKey: (NSString*) aKey
{
  NSNumber *int64Value;

  int64Value = [NSNumber numberWithLongLong: anInteger];
  [dictionary setObject: int64Value forKey: aKey];
}

- (id) decodeObjectForKey: (NSString *) aKey
{
  id object;

  if (aKey)
    object = [dictionary objectForKey: aKey];
  else
    {
      object = nil;
      raiseException (@"'nil' key", @"nil 'key' parameter");
    }

  return object;
}

- (BOOL) decodeBoolForKey: (NSString*) aKey
{
  BOOL boolValue;

  if (aKey)
    boolValue = [[dictionary objectForKey: aKey] boolValue];
  else
    {
      boolValue = NO;
      raiseException (@"'nil' key", @"nil 'key' parameter");
    }

  return boolValue;
}

- (int) decodeIntForKey: (NSString*) aKey
{
  int intValue;

  if (aKey)
    intValue = [[dictionary objectForKey: aKey] intValue];
  else
    {
      intValue = -1;
      raiseException (@"'nil' key", @"nil 'key' parameter");
    }

  return intValue;
}

- (int64_t) decodeInt64ForKey: (NSString*) aKey
{
  int64_t int64Value;
  id object;

  if (aKey)
    {
      object = [dictionary objectForKey: aKey];
      int64Value = ((object) ? [object longLongValue] : 0LL);
    }
  else
    {
      int64Value = -1;
      raiseException (@"'nil' key", @"nil 'key' parameter");
    }

  return int64Value;
}

@end
