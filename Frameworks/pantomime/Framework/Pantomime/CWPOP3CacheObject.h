/*
**  CWPOP3CacheObject.h
**
**  Copyright (c) 2001-2004 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWPOP3CacheObject
#define _Pantomime_H_CWPOP3CacheObject

#import <Foundation/NSCalendarDate.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/*!
  @class CWPOP3CacheObject
  @discussion This class provides a simple placeholder for storing
              a POP3 unique message identifier combined with a
	      received date.
*/
@interface CWPOP3CacheObject : NSObject <NSCoding>
{
  @private
    NSCalendarDate *_date;
    NSString *_UID;
}

/*!
  @method initWithUID: date:
  @discussion This method is the designated initializer for
              the CWPOP3CacheObject class.
  @param theUID The POP3 UID of the message
  @param theDate The date value of when the message
                 has been downloaded from the POP3 server.
  @result The instance, nil on error.
*/
- (id) initWithUID: (NSString *) theUID
              date: (NSCalendarDate *) theDate;

/*!
  @method date
  @discussion This method is used to obtain the date value
              of when the message has been downloaded from
	      the POP3 server.
  @result The date value, nil if none was set.
*/
- (NSCalendarDate *) date;

/*!
  @method setDate:
  @discussion This method is used to set the date value
              of when the message has been downloaded from
	      the POP3 server.
  @param theDate The new date value.
*/
- (void) setDate: (NSCalendarDate *) theDate;

/*!
  @method setUID:
  @discussion This method is used to set the POP3 unique
              identifier of the receiver.
  @param theUID The new UID value.
*/
- (void) setUID: (NSString *) theUID;

/*!
  @method UID
  @discussion This method to obtain the POP3 unique
              identifier of the receiver.
  @result The unique identifier.
*/
- (NSString *) UID;

@end

#endif // _Pantomime_H_CWPOP3CacheObject
