/*
**  CWIMAPCacheManager.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2018      Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
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

#ifndef _Pantomime_H_CWIMAPCacheManager
#define _Pantomime_H_CWIMAPCacheManager

#import <Foundation/NSMapTable.h>

#include <Pantomime/CWCacheManager.h>

@class CWFolder;
@class CWIMAPMessage;

/*!
  @class CWIMAPCacheManager
  @discussion This class provides trivial extensions to the
              CWCacheManager superclass for CWIMAPFolder instances.
*/
@interface CWIMAPCacheManager: CWCacheManager
{
  @private
    NSMapTable *_table;
    unsigned int _UIDValidity;

    CWFolder *_folder;
}

- (id) initWithPath: (NSString *) thePath  folder: (CWFolder *) theFolder;

- (void) readAllMessages;

- (void) readMessagesInRange: (NSRange) theRange;

/*!
  @method messageWithUID:
  @discussion This method is used to obtain the CWIMAPMessage instance
              from the receiver's cache.
  @param theUID The UID of the message to obtain from the cache.
  @result The instance, nil if not present in the receiver's cache.
*/
- (CWIMAPMessage *) messageWithUID: (NSUInteger) theUID;


/*!
  @method removeMessageWithUID:
  @discussion This method is used to remove the associated
              message from the cache based on the supplied UID.
  @param theUID The UID of the message to remove from the cache.
*/
- (void) removeMessageWithUID: (NSUInteger) theUID;

/*!
  @method UIDValidity
  @discussion This method is used to obtain the UID validity
              value of the receiver's cache. If it doesn't
	      match the UID validity of its associated
	      CWIMAPFolder instance, you should invalidate the cache.
  @result The UID validity.
*/
- (unsigned int) UIDValidity;

/*!
  @method setUIDValidity:
  @discussion This method is used to set the UID validity value
              of the receiver's cache.
  @param theUIDValidity The value to set.
*/
- (void) setUIDValidity: (unsigned int) theUIDValidity;

/*!
  @method writeRecord:message:
  @discussion This method is used to write a cache record to disk.
  @param theRecord The record to write.
  @param theMessage The message associated to the record <i>theRecord</i>.
*/
- (void) writeRecord: (cache_record *) theRecord  message: (id) theMessage;
@end

#endif // _Pantomime_H_CWIMAPCacheManager
