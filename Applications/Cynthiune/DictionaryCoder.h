/* DictionaryCoder.h - this file is part of Cynthiune
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

#ifndef DICTIONARYCODER_H
#define DICTIONARYCODER_H

#import <Foundation/NSCoder.h>

@class NSMutableDictionary;
@class NSString;

@interface DictionaryCoder : NSCoder
{
  NSMutableDictionary *dictionary;
}

- (void) encodeObject: (id) anObject forKey: (NSString *) aKey;
- (void) encodeBool: (BOOL) aBool forKey: (NSString *) aKey;
- (void) encodeInt: (int) anInteger forKey: (NSString *) aKey;
- (void) encodeInt64: (int64_t) anInteger forKey: (NSString *) aKey;

- (id) decodeObjectForKey: (NSString *) aKey;
- (BOOL) decodeBoolForKey: (NSString *) aKey;
- (int) decodeIntForKey: (NSString *) aKey;
- (int64_t) decodeInt64ForKey: (NSString *) aKey;

@end

#endif /* DICTIONARYCODER_H */
