/*
**  CWFolderInformation.h
**
**  Copyright (c) 2002-2004 Ludovic Marcotte
**  Copyright (C) 2017-2018 Riccardo Mottola
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

#ifndef _Pantomime_H_CWFolderInformation
#define _Pantomime_H_CWFolderInformation

#import <Foundation/NSObject.h>
#import <Pantomime/CWConstants.h>

/*!
  @class CWFolderInformation
  @discussion This class provides a container to cache folder information like
              the number of messages and unread messages the folder holds, and
	      its total size. Normally you won't use this class directly but
	      CWFolder's subclasses return instances of this class, when
	      calling -folderStatus on a CWFolder instance.
*/      
@interface CWFolderInformation : NSObject
{
  @private
    NSUInteger _nb_of_messages;
    NSUInteger _nb_of_unread_messages;
    NSUInteger _size;
}

/*!
  @method nbOfMessages
  @discussion This method is used to get the total number of messages value
              from this container object.
  @result The total number of messages.
*/
- (NSUInteger) nbOfMessages;

/*!
  @method setNbOfMessages:
  @discussion This method is used to set the total number of messages
              of this container object.
  @param theValue The number of messages.
*/
- (void) setNbOfMessages: (NSUInteger) theValue;

/*!
  @method nbOfUnreadMessages
  @discussion This method is used to get the total number of unread messages value
              from this container object.
  @result The total number of unread messages.
*/
- (NSUInteger) nbOfUnreadMessages;

/*!
  @method setNbOfUnreadMessages:
  @discussion This method is used to set the total number of unread messages
              of this container object.
  @param theValue The number of unread messages.
*/
- (void) setNbOfUnreadMessages: (NSUInteger) theValue;

/*!
  @method size
  @discussion This method is used to get the total size of this container object.
  @result The total size.
*/
- (NSUInteger) size;

/*!
  @method setSize:
  @discussion This method is used to set the total size of this container object.
  @param theSize The total size.
*/
- (void) setSize: (NSUInteger) theSize;

@end

#endif // _Pantomime_H_CWFolderInformation
