/*
**  CWMIMEMultipart.h
**
**  Copyright (c) 2001-2004 Ludovic Marcotte
**  Copyright (C) 2013-2017 The GNUstep team
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola
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

#ifndef _Pantomime_H_CWMIMEMultipart
#define _Pantomime_H_CWMIMEMultipart

#import <Foundation/NSArray.h>
#import <Foundation/NSObject.h>

#if defined(__APPLE__) && (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
#ifndef NSUInteger
#define NSUInteger unsigned int
#endif
#endif

@class CWPart;

/*!
  @class CWMIMEMultipart
  @discussion This class is used to define a composite multipart.
              It holds CWPart instances.
*/
@interface CWMIMEMultipart : NSObject
{
  @private
    NSMutableArray *_parts;
}

/*!
  @method addPart:
  @discussion This method is used to add new body part
              to the multipart instance.
  @param thePart The CWPart instance to add.
*/
- (void) addPart: (CWPart *) thePart;

/*!
  @method removePart:
  @discussion This method is used to remove an existing body part
              from the multipart instance.
  @param thePart The CWPart instance to remove.
*/
- (void) removePart: (CWPart *) thePart;

/*!
  @method count
  @discussion This method returns the number of CWPart objects
              present in the receiver.
  @result The number of Part instances.
*/
- (NSUInteger) count;

/*!
  @method partAtIndex:
  @discussion This method is used to get the CWPart instance
              at the specified index.
  @param theIndex The index of the CWPart instance to get.
  @result The CWPart instance. If the index is out of bounds,
          an NSRangeException is raised.
*/
- (CWPart *) partAtIndex: (NSUInteger) theIndex;

@end

#endif // _Pantomime_H_CWMIMEMultipart 
