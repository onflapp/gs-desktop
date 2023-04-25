/* -*- mode: objc -*-

 Project: FTP

 Copyright (C) 2005-2016 Free Software Foundation

 Author: Riccardo Mottola

 Created: 2005-04-21

 Generic client class, to be subclassed.

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#import <Foundation/Foundation.h>

#import "fileElement.h"

/**
 * Class that represents an object to access files, be them remote or local.
 * It must be subclassed to be useful. This object holds porperties genrealy
 * valid for both local and remote instances as the working directory and the
 * home directory of the user. It also defines common methods for creating,
 * changing and deleting directories.
 */
@interface Client : NSObject
{
  id       controller;
  NSString *workingDir;
  NSString *homeDir;
}

- (id)init;
- (id)initWithController:(id)cont;

/** returns the current working directory */
- (bycopy NSString *)workingDir;

- (void)setWorkingDirWithCString:(char *)dir;
- (void)setWorkingDir:(NSString *)dir;
- (void)changeWorkingDir:(NSString *)dir;
- (BOOL)createNewDir:(NSString *)dir;
- (BOOL)deleteFile:(FileElement *)file beingAt:(int)depth;
- (BOOL)renameFile:(FileElement *)file to:(NSString *)name;

- (bycopy NSArray *)workDirSplit;

/** returns an array with the directory listing */
- (bycopy NSArray *)dirContents;

/** returns the current home directory */
- (bycopy NSString *)homeDir;

@end


