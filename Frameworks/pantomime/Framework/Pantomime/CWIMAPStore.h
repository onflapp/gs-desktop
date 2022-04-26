/*
**  CWIMAPStore.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWIMAPStore
#define _Pantomime_H_CWIMAPStore

#include <Pantomime/CWConnection.h>
#include <Pantomime/CWConstants.h>
#include <Pantomime/CWService.h>
#include <Pantomime/CWStore.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/*!
  @typedef IMAPCommand
  @abstract Supported IMAP commands.
  @discussion This enum lists the supported IMAP commands available in Pantomime's IMAP client code.
  @constant IMAP_APPEND The IMAP APPEND command - see 6.3.11. APPEND Command of RFC 3501. 
  @constant IMAP_AUTHENTICATE_CRAM_MD5 CRAM-MD5 authentication.
  @constant IMAP_AUTHENTICATE_LOGIN LOGIN authentication
  @constant IMAP_AUTHORIZATION Special command so that we know we are in the authorization state.
  @constant IMAP_CAPABILITY The IMAP CAPABILITY command - see 6.1.1. CAPABILITY Command of RFC 3501.
  @constant IMAP_CLOSE The IMAP CLOSE command - see 6.4.2. CLOSE Command of RFC 3501.
  @constant IMAP_CREATE The IMAP CREATE command - see 6.3.3. CREATE Command of RFC 3501.
  @constant IMAP_DELETE The IMAP DELETE command - see 6.3.4. DELETE Command of RFC 3501.
  @constant IMAP_EXAMINE The IMAP EXAMINE command - see 6.3.2. EXAMINE Command of RFC 3501.
  @constant IMAP_EXPUNGE The IMAP EXPUNGE command - see 6.4.3. EXPUNGE Command of RFC 3501.
  @constant IMAP_LIST The IMAP LIST command - see 6.3.8. LIST Command of RFC 3501.
  @constant IMAP_LOGIN The IMAP LOGIN command - see 6.2.3. LOGIN Command of RFC 3501.
  @constant IMAP_LOGOUT The IMAP LOGOUT command - see 6.1.3. LOGOUT Command of RFC 3501.
  @constant IMAP_LSUB The IMAP LSUB command - see 6.3.9. LSUB Command of RFC 3501.
  @constant IMAP_NOOP The IMAP NOOP command - see 6.1.2. NOOP Command of RFC 3501.
  @constant IMAP_RENAME The IMAP RENAME command - see 6.3.5. RENAME Command of RFC 3501.
  @constant IMAP_SELECT The IMAP SELECT command - see 6.3.1. SELECT Command of RFC 3501.
  @constant IMAP_STARTTLS The STARTTLS IMAP command - see RFC2595.
  @constant IMAP_STATUS The IMAP STATUS command - see 6.3.10. STATUS Command of RFC 3501.
  @constant IMAP_SUBSCRIBE The IMAP SUBSCRIBE command - see 6.3.6. SUBSCRIBE Command of RFC 3501.
  @constant IMAP_UID_COPY The IMAP COPY command - see 6.4.7. COPY Command of RFC 3501.
  @constant IMAP_UID_FETCH_BODY_TEXT The IMAP FETCH command - see 6.4.5. FETCH Command of RFC 3501.
  @constant IMAP_UID_FETCH_HEADER_FIELDS The IMAP FETCH command - see 6.4.5. FETCH Command of RFC 3501.
  @constant IMAP_UID_FETCH_HEADER_FIELDS_NOT The IMAP FETCH command - see 6.4.5. FETCH Command of RFC 3501.
  @constant IMAP_UID_FETCH_RFC822 The IMAP FETCH command - see 6.4.5. FETCH Command of RFC 3501.
  @constant IMAP_UID_SEARCH The IMAP SEARCH command - see 6.4.4. SEARCH Command of RFC 3501.
                            Used to update the IMAP Folder cache.
  @constant IMAP_UID_SEARCH_ALL The IMAP SEARCH command - see 6.4.4. SEARCH Command of RFC 3501.
  @constant IMAP_UID_SEARCH_ANSWERED Special command used to update the IMAP Folder cache.
  @constant IMAP_UID_SEARCH_FLAGGED Special command used to update the IMAP Folder cache.
  @constant IMAP_UID_SEARCH_UNSEEN Special command used to update the IMAP Folder cache.
  @constant IMAP_UID_STORE The IMAP STORE command - see 6.4.6. STORE Command of RFC 3501.
  @constant IMAP_UNSUBSCRIBE The IMAP UNSUBSCRIBE command - see 6.3.7. UNSUBSCRIBE Command of RFC 3501.
  @constant IMAP_EMPTY_QUEUE Special command to empty the command queue.
*/
typedef enum {
  IMAP_APPEND = 0x1,
  IMAP_AUTHENTICATE_CRAM_MD5,
  IMAP_AUTHENTICATE_LOGIN,
  IMAP_AUTHORIZATION,
  IMAP_CAPABILITY,
  IMAP_CLOSE,
  IMAP_CREATE,
  IMAP_DELETE,
  IMAP_EXAMINE,
  IMAP_EXPUNGE,
  IMAP_LIST,
  IMAP_LOGIN,
  IMAP_LOGOUT,
  IMAP_LSUB,
  IMAP_NOOP,
  IMAP_RENAME,
  IMAP_SELECT,
  IMAP_STARTTLS,
  IMAP_STATUS,
  IMAP_SUBSCRIBE,
  IMAP_UID_COPY,
  IMAP_UID_FETCH_BODY_TEXT,
  IMAP_UID_FETCH_HEADER_FIELDS,
  IMAP_UID_FETCH_HEADER_FIELDS_NOT,
  IMAP_UID_FETCH_RFC822,
  IMAP_UID_SEARCH,
  IMAP_UID_SEARCH_ALL,
  IMAP_UID_SEARCH_ANSWERED,
  IMAP_UID_SEARCH_FLAGGED,
  IMAP_UID_SEARCH_UNSEEN,
  IMAP_UID_STORE,
  IMAP_UNSUBSCRIBE,
  IMAP_EMPTY_QUEUE
} IMAPCommand;

/*!
  @const PantomimeFolderSubscribeCompleted
*/
extern NSString *PantomimeFolderSubscribeCompleted;

/*!
  @const PantomimeFolderSubscribeFailed
*/
extern NSString *PantomimeFolderSubscribeFailed;

/*!
  @const PantomimeFolderUnsubscribeCompleted
*/
extern NSString *PantomimeFolderUnsubscribeCompleted;

/*!
  @const PantomimeFolderUnsubscribeFailed
*/
extern NSString *PantomimeFolderUnsubscribeFailed;

/*!
  @const PantomimeFolderStatusCompleted
*/
extern NSString *PantomimeFolderStatusCompleted;

/*!
  @const PantomimeFolderStatusFailed
*/
extern NSString *PantomimeFolderStatusFailed;


@class CWConnection;
@class CWFlags;
@class CWIMAPCacheManager;
@class CWIMAPFolder;
@class CWIMAPMessage;
@class CWIMAPQueueObject;
@class CWTCPConnection;

/*!
  @class CWIMAPStore
  @abstract Pantomime IMAP client code.
  @discussion This class, which extends the CWService class and implements
              the CWStore protocol, is Pantomime's IMAP client code.
*/ 
@interface CWIMAPStore : CWService <CWStore>
{
  @private
    CWIMAPQueueObject *_currentQueueObject;
  
    NSMutableDictionary *_folders;
    NSMutableDictionary *_openFolders;
    NSMutableDictionary *_folderStatus;
    NSMutableArray *_subscribedFolders;
 
    CWIMAPFolder *_selectedFolder;

    unichar _folderSeparator;
    int _tag;
}

/*!
  @method folderForName:mode:prefetch:
  @discussion This method is used to get the folder with
              the specified name and mode.
  @param theName The name of the folder to obtain.
  @param theMode The mode to use. The value is one of the PantomimeFolderMode enum.
  @param aBOOL YES if prefetch should be done on the folder, NO otherwise.
  @result A CWIMAPFolder instance.
*/
- (CWIMAPFolder *) folderForName: (NSString *) theName
                            mode: (PantomimeFolderMode) theMode
                        prefetch: (BOOL) aBOOL;

/*!
  @method folderForName:select:
  @discussion This method is used to obtain the folder with
              the specified name. If <i>aBOOL</i> is YES,
	      the folder will be selected. Otherwise, a non-selected
	      folder will be returned which is used to proceed with
	      an append operation. Note that when <i>aBOOL</i> is
	      equal to NO, the returned folder is NOT part of the
	      list of opened folders.
  @param theName The name of the folder to obtain.
  @param aBOOL YES to select the folder, NO otherwise.
  @result A CWIMAPFolder instance.
*/
- (CWIMAPFolder *) folderForName: (NSString *) theName
                          select: (BOOL) aBOOL;

/*!
  @method nextTag
  @discussion This method is used to obtain the next IMAP tag
              that will be sent to the IMAP server. Normally
	      you shouldn't call this method directly.
  @result The tag as a NSData instance.
*/
- (NSData *) nextTag;

/*!
  @method lastTag
  @discussion This method is used to obtain the last IMAP tag
              sent to the IMAP server.
  @result The tag as a NSData instance.
*/
- (NSData *) lastTag;

/*!
  @method subscribeToFolderWithName:
  @discussion This method is used to subscribe to the specified folder.
              The method will post a PantomimeFolderSubscribeCompleted notification
	      (and call -folderSubscribeCompleted: on the delegate, if any) if
	      it succeeded. If not, it will post a PantomimeFolderSubscribeFailed
	      notification (and call -folderSubscribeFailed: on the delegate, if any)
  @param theName The name of the folder to subscribe to.
*/
- (void) subscribeToFolderWithName: (NSString *) theName;

/*!
  @method unsubscribeToFolderWithName:
  @discussion This method is used to unsubscribe to the specified folder.
              The method will post a PantomimeFolderUnsubscribeCompleted notification
	      (and call -folderUnsubscribeCompleted: on the delegate, if any) if
	      it succeeded. If not, it will post a PantomimeFolderUnsubscribeFailed
	      notification (and call -folderUnsubscribeFailed: on the delegate, if any)
  @param theName The name of the folder to subscribe to.
*/
- (void) unsubscribeToFolderWithName: (NSString *) theName;

/*!
  @method folderStatus:
  @discussion This method is used to obtain the status of the specified
              folder names in <i>theArray</i>. It is fully asynchronous.
	      The first time it is invoked, it'll perform its work asynchronously
	      and post a PantomimeFolderStatusCompleted notification (and call
	      -folderStatusCompleted on the delegate, if any) if succeeded. If not,
	      it will post a PantomimeFolderStatusFailed notification (and call
	      -folderStatusFailed: on the delegate, if any). Further calls
	      of this method on the same set of folders will immediately return
	      the status information.
  @param theArray The array of folder names.
  @result A NSDictionary instance for which the keys are the folder names (NSString instance)
          and the values are CWFolderInformation instance if the information was
	  loaded, nil otherwise.
*/
- (NSDictionary *) folderStatus: (NSArray *) theArray;

/*!
  @method sendCommand:info:arguments: ...
  @discussion This method is used to send commands to the IMAP server.
              Normally, you should not call this method directly.
  @param theCommand The IMAP command to send.
  @param theInfo The addition info to pass.
  @param theFormat The format defining the variable arguments list.
*/
- (void) sendCommand: (IMAPCommand) theCommand  info: (NSDictionary *) theInfo  arguments: (NSString *) theFormat, ...;

@end

#endif // _Pantomime_H_IMAPStore
