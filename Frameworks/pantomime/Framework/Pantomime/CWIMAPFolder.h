/*
**  CWIMAPFolder.h
**
**  Copyright (c) 2001-2006 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWIMAPFolder
#define _Pantomime_H_CWIMAPFolder

#include <Pantomime/CWFolder.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCalendarDate.h>

#include <Pantomime/CWConstants.h>

/*!
  @const PantomimeMessagesCopyCompleted
  @discussion This notification is posted when CWIMAPFolder: -copyMessages:
              toFolder: has successfully completed. -messagesCopyCompleted:
	      is also called on the delegate, if any.
*/
extern NSString* PantomimeMessagesCopyCompleted;

/*!
  @const PantomimeMessagesCopyFailed
  @discussion This notification is posted when CWIMAPFolder: -copyMessages:
              toFolder: has failed to complete. -messagesCopyFailed:
	      is also called on the delegate, if any.
*/
extern NSString* PantomimeMessagesCopyFailed;

/*!
  @const PantomimeMessageStoreCompleted
  @discussion This notification is posted when CWIMAPFolder: -setFlags:
              messages: has successfully completed. -messageStoreCompleted:
	      is also called on the delegate, if any.
*/
extern NSString* PantomimeMessageStoreCompleted;

/*!
  @const PantomimeMessageStoreFailed
  @discussion This notification is posted when CWIMAPFolder: -setFlags:
              messages: has failed to completed. -messageStoreFailed:
	      is also called on the delegate, if any.
*/
extern NSString* PantomimeMessageStoreFailed;


/*!
  @class CWIMAPFolder
  @discussion This class, which extends the CWFolder class, is used to
              implement IMAP-specific features such as server-side
	      operations for copying messages between mailboxes.
*/
@interface CWIMAPFolder : CWFolder
{
  @private
    unsigned int _uid_validity;
    BOOL _selected;
}

/*!
  @method initWithName: mode:
  @discussion This method is used to initialize the receiver
              with <i>theName</i> using <i>theMode</i>. Normally,
	      you should not invoke this method directly.
	      You must rather use one of CWIMAPStore's folderForName: ...
	      method.
  @param theName The name of the folder.
  @param theMode The mode to use. Accepted values are part of the
                 PantomimeFolderMode enum.
  @result An CWIMAPFolder instance, nil on error.
*/
- (id) initWithName: (NSString *) theName
               mode: (PantomimeFolderMode) theMode;

/*!
  @method appendMessageFromRawSource:flags:internalDate
  @discussion This method is used to append a message from its raw source
              representation (RFC2822 compliant) to the underlying store. It differs from
	      -appendMessageFromRawSource:flags: in that this method supplies the
	      given date to the server to use as the INTERNALDATE. Not supplying this
	      date will cause some servers and clients to report the date of the message
	      as the current date and time, rather than that specified in the Received
	      header.
  @param theData The raw representation of the message to append.
  @param theFlags The flags of the message, nil if no flags need to be kept.
  @param theDate The INTERNALDATE of the message, or nil to use the current date.
*/
- (void) appendMessageFromRawSource: (NSData *) theData
                              flags:(CWFlags *) theFlags
                       internalDate: (NSCalendarDate *) theDate;

/*!
  @method copyMessages: toFolder:
  @discussion This method copies the messages in <i>theMessages</i> array from
              the receiver to the destination folder's name, <i>theFolder</i>.
	      On success, this method posts a PantomimeMessagesCopyCompleted notification
	      (and calls -messagesCopyCompleted: on the delegate, if any). On failure,
	      it posts a PantomimeMessagesCopyFailed notification (and calls
	      -messagesCopyFailed: on the delegate, if any). This method is
	      fully asynchronous.
  @param theMessages The messages to copy.
  @param theFolder The name of the target folder. The name must include
                   hierarchy separators if the target folder is a subfolder.
*/
- (void) copyMessages: (NSArray *) theMessages
             toFolder: (NSString *) theFolder;

/*!
  @method prefetch
  @discussion This method is used to cache part of the message headers
              from the IMAP server. On completion, it posts the PantomimeFolderPrefetchCompleted
	      notification (and calls -folderPrefetchCompleted: on the delegate, if any).
	      This method is fully asynchronous.
*/
- (void) prefetch;

/*!
  @method UIDValidity
  @discussion This method is used to obtain the UID validity of an IMAP folder.
              Refer to "2.3.1.1. Unique Identifier (UID) Message Attribute" of
	      RFC 3501 for a detailed description of this parameter.
  @result The UID validity of the folder.
*/
- (unsigned int) UIDValidity;

/*!
  @method setUIDValidity:
  @discussion This method is used to set the UID validity of the receiver.
              If the receiver has a cache (instance of CWIMAPCacheManager) and
	      the UID validity of its cache differs from <i>theUIDValidity</i>,
	      all cache entries are invalidated.
  @param theUIDValidity The UID validity value.
*/
- (void) setUIDValidity: (unsigned int) theUIDValidity;

/*!
  @method selected
  @discussion This method is used to verify if the folder is in
              a selected state.
  @result YES if it is in a selected state, NO otherwise.
*/
- (BOOL) selected;

/*!
  @method setSelected:
  @discussion This method is used to specify if the folder is in
              a selected state or not. You should never call
	      this method directly. Instead, call IMAPStore:
	      -folderForName: select:.
  @param theBOOL YES if it is in a selected state, NO otherwise.
*/
- (void) setSelected: (BOOL) theBOOL;

@end

#endif // _Pantomime_H_CWIMAPFolder
