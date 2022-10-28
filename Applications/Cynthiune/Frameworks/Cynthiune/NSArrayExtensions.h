/* NSArrayExtensions.h - this file is part of Cynthiune
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

#ifndef NSARRAYEXTENSIONS_H
#define NSARRAYEXTENSIONS_H

#import <Foundation/NSArray.h>

@class NSString;

@interface NSArray (CynthiuneExtension)

// + (NSArray *) arrayFromPlaylistFile: (NSString *) filename;
// - (BOOL) containsAllSubarray: (NSArray *) subarray;

- (NSArray *) subarrayWithObjectsAtIndexes: (NSArray *) indexes;

- (unsigned int) numberOfValuesBelowValue: (int) index;

@end

@interface NSMutableArray (CynthiuneExtension)

- (void) addObjectsFromArray: (NSArray*) otherArray
                     atIndex: (unsigned int) index;
- (unsigned int) moveObjectsAtIndexes: (NSArray *) indexes
                              toIndex: (unsigned int) index;
- (void) addObjectRandomly: (id) object;

- (void) rotateUpToObject: (id) object;

@end

#endif /* NSARRAYEXTENSIONS_H */
