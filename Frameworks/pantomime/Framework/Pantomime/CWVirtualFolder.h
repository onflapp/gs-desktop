/*
**  CWVirtualFolder.h
**
**  Copyright (c) 2003-2004 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWVirtualFolder
#define _Pantomime_H_CWVirtualFolder

#include <Pantomime/CWFolder.h>

#import <Foundation/NSArray.h>

/*!
  @class CWVirtualFolder
  @abstract Description pending. Do not use.
  @discussion Description pending. Do not use.
*/
@interface CWVirtualFolder : CWFolder
{
  @private
    NSMutableArray *_allFolders;
}

/*!
  @method addFolder:
  @discussion Description pending. Do not use.
  @param theFolder Description pending. Do not use.
*/
- (void) addFolder: (CWFolder *) theFolder;

/*!
  @method removeFolder:
  @discussion Description pending. Do not use.
  @param theFolder Description pending. Do not use.
*/
- (void) removeFolder: (CWFolder *) theFolder;

/*!
  @method setDelegate:
  @discussion Description pending. Do not use.
  @param theDelegate Description pending. Do not use.
*/
- (void) setDelegate: (id) theDelegate;

@end 

#endif // _Pantomime_H_CWVirtualFolder
