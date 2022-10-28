/* PlaylistArchiver.h - this file is part of Cynthiune
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

#ifndef PLAYLISTARCHIVER_H
#define PLAYLISTARCHIVER_H

#import <Foundation/NSObject.h>

@class NSArray;
@class NSString;

#ifdef __MACOSX__

@interface NSObject (CynthiuneExtension)

+ (id) subclassResponsibility: (SEL) aSel;

@end

#endif /* __MACOSX__ */

@interface PlaylistArchiver : NSObject

+ (BOOL) archiveRootObject: (id) anObject
                    toFile: (NSString *) filename;

+ (NSString *) fileContentFromDictionaries: (NSArray *) dictionaries
                      inReferenceDirectory: (NSString *) directory
            withAbsoluteFilenameReferences: (BOOL) absolute;

@end

@interface PlaylistUnarchiver : NSObject

+ (id) unarchiveObjectWithFile: (NSString*) filename;
+ (NSArray *) dictionariesFromFilenames: (NSArray *) filenames;

+ (NSArray *) dictionariesFromFileContent: (NSString *) content
                     inReferenceDirectory: (NSString *) directory;

@end

#endif /* PLAYLISTARCHIVER_H */
