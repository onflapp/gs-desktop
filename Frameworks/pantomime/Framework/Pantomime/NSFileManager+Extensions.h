/*
**  NSFileManager+Extensions.h
**
**  Copyright (c) 2004-2007 Ludovic Marcotte
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef _Pantomime_H_NSFileManager_Extensions
#define _Pantomime_H_NSFileManager_Extensions

#import <Foundation/NSFileManager.h>

@class NSString;

/*!
  @category NSFileManager (PantomimeFileManagerExtensions)
  @abstract Pantomime extensions to NSFileManager.
  @discussion This category provides useful extensions to the
              default NSFileManager class.
*/
@interface NSFileManager (PantomimeFileManagerExtensions)

/*!
  @method enforceMode: atPath:
  @discussion This method is used to enforce the specified
              POSIX file permissions at <i>thePath</i>.
  @param theMode The POSIX file permissions to use.
  @param thePath The path where to enforce the permissions.
*/            
- (void) enforceMode: (unsigned long) theMode
              atPath: (NSString *) thePath;
@end

#endif // _Pantomime_H_NSFileManager_Extensions
