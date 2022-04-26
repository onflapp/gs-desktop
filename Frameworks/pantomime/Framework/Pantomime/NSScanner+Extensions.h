/*
**  NSScanner+Extensions.h
**
**  Copyright (c) 2005 Ludovic Marcotte
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

#ifndef _Pantomime_H_NSScanner_Extensions
#define _Pantomime_H_NSScanner_Extensions

#import <Foundation/NSScanner.h>

/*!
  @category NSScanner (PantomimeScannerExtensions)
  @abstract Pantomime extensions to NSScanner.
  @discussion This category provides useful extensions to the
              default NSScanner class.
*/
@interface NSScanner (PantomimeScannerExtensions)

/*!
  @method scanUnsignedInt:
  @discussion This method is used to scan an unsigned int.
  @param theValue The value in which the unsigned int
         will be stored.
  @result YES if we find a decimal unsigned int, no otherwise.
*/            
- (BOOL) scanUnsignedInt: (unsigned int *) theValue;

@end

#endif // _Pantomime_H_NSFileManager_Extensions
