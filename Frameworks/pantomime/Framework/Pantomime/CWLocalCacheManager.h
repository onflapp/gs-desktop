/*
**  CWLocalCacheManager.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2013-2019 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola
**          Sebastan Reitenbach
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

#ifndef _Pantomime_H_CWLocalCacheManager
#define _Pantomime_H_CWLocalCacheManager

#include <Pantomime/CWCacheManager.h>

@class CWFolder;
@class CWLocalMessage;
@class NSDate;

/*!
  @class CWLocalCacheManager
  @discussion This class provides trivial extensions to the
              CWCacheManager superclass for CWLocalFolder instances.
*/
@interface CWLocalCacheManager: CWCacheManager
{
  @private
    CWFolder *_folder;

    unsigned int _modification_date; // FIXME this should become NSTimeInterval or at least longer
    NSUInteger _size;
}

- (void) readAllMessages;
- (void) readMessagesInRange: (NSRange) theRange;

/*!
  @method initWithPath:folder:
  @discussion This is the designated initialization method
              for the local cache manager.
  @param thePath The path where the cache file is.
  @param theFolder The CWLocalFolder instance to be used together
                   with the cache file.
  @result A CWLocalCacheManager instance, nil otherwise.
*/
- (id) initWithPath: (NSString *) thePath  folder: (id) theFolder;

/*!
  @method modificationDate
  @discussion This method is used to obtain the modification date
              of the receiver. That is, the last time the cache
	      was written to disk.
  @result The date.
*/
- (NSDate *) modificationDate;

/*!
  @method setModificationDate:
  @discussion This method is used to set the modification date
              of the receiver. Normally you should not invoke
              this method directly.
  @param theDate The new date value.
*/
- (void) setModificationDate: (NSDate *) theDate;

/*!
  @method fileSize
  @discussion This method is used to obtain the size of the
              associated CWLocalFolder's mailbox.
  @result The size.
*/
- (NSUInteger) fileSize;

/*!
  @method setFileSize:
  @discussion This method is used to set the size of the
              associated LocalFolder's mailbox.
	      Normally you should not invoke
              this method directly.
  @param theSize The new size value.
*/
- (void) setFileSize: (unsigned int) theSize;

/*!
  @method writeRecord:
  @discussion This method is used to write a cache record to disk.
  @param theRecord The record to write.
*/
- (void) writeRecord: (cache_record *) theRecord;
@end

#endif // _Pantomime_H_LocalCacheManager
