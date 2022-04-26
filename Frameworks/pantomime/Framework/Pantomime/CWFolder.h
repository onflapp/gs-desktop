/*
**  CWFolder.h
**
**  Copyright (c) 2001-2006 Ludovic Marcotte
**  Copyright (C) 2013-2020 Riccardo Mottola
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

#ifndef _Pantomime_H_CWFolder
#define _Pantomime_H_CWFolder

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

#import <Pantomime/CWConstants.h>

@class CWFlags;
@class CWMessage;
@class CWCacheManager;

/*!
  @const PantomimeFolderAppendCompleted
*/
extern NSString* PantomimeFolderAppendCompleted;

/*!
  @const PantomimeFolderAppendFailed
*/
extern NSString* PantomimeFolderAppendFailed;

/*!
  @const PantomimeFolderCloseCompleted
*/
extern NSString* PantomimeFolderCloseCompleted;

/*!
  @const PantomimeFolderCloseFailed
*/
extern NSString* PantomimeFolderCloseFailed;

/*!
  @const PantomimeFolderExpungeCompleted
*/
extern NSString* PantomimeFolderExpungeCompleted;

/*!
  @const PantomimeFolderExpungeFailed
*/
extern NSString* PantomimeFolderExpungeFailed;

/*!
  @const PantomimeFolderListCompleted
*/
extern NSString* PantomimeFolderListCompleted;

/*!
  @const PantomimeFolderListFailed
*/
extern NSString* PantomimeFolderListFailed;

/*!
  @const PantomimeFolderListSubscribedCompleted
*/
extern NSString* PantomimeFolderListSubscribedCompleted;

/*!
  @const PantomimeFolderListSubscribedFailed
*/
extern NSString* PantomimeFolderListSubscribedFailed;

/*!
  @const PantomimeFolderOpenCompleted
*/
extern NSString* PantomimeFolderOpenCompleted;

/*!
  @const PantomimeFolderOpenFailed
*/
extern NSString* PantomimeFolderOpenFailed;

/*!
  @const PantomimeFolderPrefetchCompleted
*/
extern NSString* PantomimeFolderPrefetchCompleted;

/*!
  @const PantomimeFolderPrefetchFailed
*/
extern NSString* PantomimeFolderPrefetchFailed;

/*!
  @const PantomimeFolderSearchCompleted
*/
extern NSString* PantomimeFolderSearchCompleted;

/*!
  @const PantomimeFolderSearchFailed
*/
extern NSString* PantomimeFolderSearchFailed;


/*!
  @category NSObject (PantomimeFolderDelegate)
  @discussion This informal protocol defines methods that can implemented in
              CWFolder's delegate to control the behavior of the class 
	      or to obtain status information.
*/
@interface NSObject (PantomimeFolderDelegate)

/*!
  @method folderAppendCompleted:
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the last
	      message append operation was sucessful.
	      A PantomimeFolderAppendCompleted notification is
	      also posted.
  @param theNotification The notification holding the information.
*/
- (void) folderAppendCompleted: (NSNotification *) theNotification;

/*!
  @method folderAppendFailed:
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the last
	      message append operation failed.
	      A PantomimeFolderAppendCompleted notification is
	      also posted.
  @param theNotification The notification holding the information.
*/
- (void) folderAppendFailed: (NSNotification *) theNotification;

/*!
  @method folderCloseCompleted
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the close
	      operation completed.
  @param theNotification The notification holding the information.
 */
- (void) folderCloseCompleted: (NSNotification *) theNotification;

/*!
  @method folderCloseFailed
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the close
	      operation failed.
  @param theNotification The notification holding the information.
 */
- (void) folderCloseFailed: (NSNotification *) theNotification;

/*!
  @method folderExpungeCompleted
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the expunge
	      operation completed.
  @param theNotification The notification holding the information.
 */
- (void) folderExpungeCompleted: (NSNotification *) theNotification;

/*!
  @method folderExpungeFailed
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the expunge
	      operation failed.
  @param theNotification The notification holding the information.
 */
- (void) folderExpungeFailed: (NSNotification *) theNotification;

/*!
  @method folderListCompleted
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the mailbox listing
	      operation completed.
  @param theNotification The notification holding the information.
 */
- (void) folderListCompleted: (NSNotification *) theNotification;

/*!
  @method folderListFailed
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the mailbox listing
	      operation failed.
  @param theNotification The notification holding the information.
 */
- (void) folderListFailed: (NSNotification *) theNotification;

/*!
  @method folderListSubscribedCompleted
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the listing operation
	      of subscribed mailboxes completed.
  @param theNotification The notification holding the information.
 */
- (void) folderListSubscribedCompleted: (NSNotification *) theNotification;

/*!
  @method folderListSuscribedFailed
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the listing operation
	      of subscribed mailboxes failed.
  @param theNotification The notification holding the information.
 */
- (void) folderListSubscribedFailed: (NSNotification *) theNotification;

/*!
  @method folderOpenCompleted
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the open
	      operation completed.
  @param theNotification The notification holding the information.
 */
- (void) folderOpenCompleted: (NSNotification *) theNotification;

/*!
  @method folderOpenFailed
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the open
	      operation failed.
  @param theNotification The notification holding the information.
 */
- (void) folderOpenFailed: (NSNotification *) theNotification;

/*!
  @method folderPrefetchCompleted
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the prefetch
	      operation completed.
  @param theNotification The notification holding the information.
 */
- (void) folderPrefetchCompleted: (NSNotification *) theNotification;

/*!
  @method folderPrefetchFailed
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the prefetch
	      operation failed.
  @param theNotification The notification holding the information.
 */
- (void) folderPrefetchFailed: (NSNotification *) theNotification;

/*!
  @method folderSearchCompleted
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the search
	      operation completed.
  @param theNotification The notification holding the information.
 */
- (void) folderSearchCompleted: (NSNotification *) theNotification;

/*!
  @method folderSearchFailed
  @discussion This method is automatically invoked on the store's
              delegate in order to indicate that the search
	      operation failed.
  @param theNotification The notification holding the information.
 */
- (void) folderSearchFailed: (NSNotification *) theNotification;

@end

/*!
  @class CWFolder
  @abstract A CWFolder object holds CWMessage instances.
  @discussion This abstract class is used to represent a folder which holds messages.
              A folder is a synonym for mailbox. Normally, you should never create
              an instance of CWFolder directly but rather use the subclasses which
	      are CWIMAPFolder, CWLocalFolder and CWPOP3Folder. Futhermore, the corresponding
	      CWStore classes will instanciate the CWFolder subclasses for you.
*/
@interface CWFolder : NSObject 
{
  @public
    NSMutableArray *allMessages;

  @protected
    NSMutableDictionary *_properties;
    NSString *_name;

    CWCacheManager *_cacheManager;
    id _store;

    NSMutableArray *_allVisibleMessages;
    NSMutableArray *_allContainers;
   
    BOOL _show_deleted;
    BOOL _show_read;

    PantomimeFolderMode _mode;
}

/*!
  @method initWithName:
  @discussion This method initialize a folder with the
              specified name. The name can contain folder
	      separators in order to create subfolders.
	      The separator can be obtained from a
	      class that implements the CWStore protocol.
  @param theName The full path of the folder.
  @result The folder, nil in case of an error.
*/
- (id) initWithName: (NSString *) theName;

/*!
  @method name
  @discussion This method returns the name of the folder.
  @result The full name of the folder.
*/
- (NSString *) name;

/*!
  @method setName:
  @discussion Sets the name of a folder.
  @param theName The name of the folder.
*/
- (void) setName: (NSString *) theName;

/*!
  @method appendMessage:
  @discussion This method is used to add a message to
              a CWFolder instance. This method will NOT add
	      the message to the underlying store. You MUST
	      use -appendMessageFromRawSource: flags: if you
	      want the message to be saved to the underlying
	      store. Generally, you should not use this
	      method directly. If the folder was threaded,
	      this method will NOT thread the appended message.
  @param theMessage The message to append to the folder.
*/
- (void) appendMessage: (CWMessage *) theMessage;


/*!
  @method appendMessageFromRawSource:flags:
  @discussion This method is used to append a message
              from its raw source representation (RFC2822 compliant)
	      to the underlying store. This method will raise an
	      exception if it's invoked on an instance of CWFolder or
	      CWPOP3Folder instead of an instance of CWIMAPFolder and CWLocalFolder.
	      If the folder was threaded, this method will NOT thread the appended message.
	      Methods will be invoked on the delegate and notifications
	      will be posted. See the PantomimeFolderDelegate informal
	      protocol for more details.
  @param theData The raw representation of the message to append.
  @param theFlags The flags of the message, nil if no flags need to be kept.
*/
- (void) appendMessageFromRawSource: (NSData *) theData
                              flags: (CWFlags *) theFlags;

/*!
  @method allMessages
  @discussion This method is used to obtain all visible messages
              in the CWFolder instance. It hides messages marked
	      as Deleted if -setShowDeleted: was invoked with
	      NO as the parameter and the the same for messages
	      marked as read (see -setShowRead:). Note that the
	      messages MIGHT NOT been all completely initialized.
  @result An array of all visible messages.
*/
- (NSArray *) allMessages;

/*!
  @method setMessages:
  @discussion This method is used to replace all messages in the
               CWFolder instance by the ones specified in the array.
	       Normally, you shouldn't use this method directly.
  @param theMessages The array of messages.
*/
- (void) setMessages: (NSArray *) theMessages;

/*!
  @method messageAtIndex:
  @discussion This method is used to obtain the message at the
              specified index (which is zero-based). If the index
	      is out of bounds, nil is returned.
  @param theIndex The index of the message.
  @result The message at the specified index, nil otherwise.
*/
- (CWMessage *) messageAtIndex: (NSUInteger) theIndex;

/*!
  @method count
  @discussion This method is used to obtain the number of messages
              present in the folder. Hidden messages will NOT
	      be part of the value returned. So, for example, if
	      a folder has 10 messages, 2 of them have the
	      PantomimeDeleted flag set and -setShowDeleted: NO was
	      invoked on the folder, this method will return
	      8 as the messages count.
  @result The number of messages in the folder.
*/
- (NSUInteger) count;

/*!
  @method close
  @discussion This method is used to close the folder. 
              The subclasses of CWFolder MUST this method.
*/
- (void) close;

/*!
  @method expunge:
  @discussion This method is used to permanently remove
              messages marked as deleted in the folder.
*/
- (void) expunge;

/*!
  @method store
  @discussion This method returns the associated store
              to this folder. This will generally be an instance
	      of CWIMAPStore, CWLocalStore or CWPOP3Store.
  @result The associated store.
*/
- (id) store;

/*!
  @method setStore:
  @discussion This method is used to set the associated store
              to this folder. The store will NOT be retained
	      since it is the store which holds and retains
              the CWFolder instances.
  @param theStore The associated store.
*/
- (void) setStore: (id) theStore;

/*!
  @method removeMessage:
  @discussion  This method removes permenantly a message from 
               the folder. It is used when transferring message 
	       between folders in order to update the view or 
	       when expunge deletes messages from a view. If the
	       folder is threaded, this method will rethread the
	       folder before returning.
  @param theMessage The CWMessage instance to remove from the folder.
*/
- (void) removeMessage: (CWMessage *) theMessage;

/*!
  @method showDeleted
  @discussion This method returns YES if messages marked as deleted
              are shown in this folder, NO otherwise.
  @result A BOOL corresponding to the value.
*/
- (BOOL) showDeleted;

/*!
  @method setShowDeleted:
  @discussion This method is used to specify if we want to show or
              hide messages marked as deleted in this folder.
  @param theBOOL YES if we want to hide messages marked as deleted,
                 NO otherwise.
*/
- (void) setShowDeleted: (BOOL) theBOOL;

/*!
  @method showRead
  @discussion This method returns YES if messages marked as read
              are shown in this folder, NO otherwise.
  @result A BOOL corresponding to the value.
*/
- (BOOL) showRead;

/*!
  @method setShowRead:
  @discussion This method is used to specify if we want to show or
              hide messages marked as read in this folder.
  @param theBOOL YES if we want to hide messages marked as read,
                 NO otherwise.
*/
- (void) setShowRead: (BOOL) theBOOL;

/*!
  @method numberOfDeletedMessages
  @discussion This method returns the number of messages in this
              folder that have the PantomimeDeleted flag set.
  @result The number of message marked has deleted, 0 if none.
*/
- (NSUInteger) numberOfDeletedMessages;

/*!
  @method numberOfUnreadMessages
  @discussion This method returns the number of messages in this
              folder that do not have the PantomimeSeen flag set.
  @result The number of unread messages, 0 if none.
*/
- (NSUInteger) numberOfUnreadMessages;

/*!
  @method size
  @discussion This method returns the size of the folder. That is,
               it returns the sum of the size of all visible messages in
	       the folder.
  @result The size of the folder.
*/
- (unsigned long) size;

/*!
  @method updateCache
  @discussion This method is used to update our cache (_allVisibleMessages).
              Applications can call this method if they set the PantomimeDeleted flags to
              messages inside this folder. If not called, the cache won't be updated
              the messages having the flag PantomimeDeleted will still be visible.
*/
- (void) updateCache;

/*!
  @method allContainers
  @discussion This method returns the list of root containers when using
              message threading.
  @result Root containers if using message threading, nil otherwise.
*/
- (NSArray *) allContainers;

/*!
  @method thread
  @discussion This method implements Jamie Zawinski's message threading algorithm.
              The full algorithm is available here: http://www.jwz.org/doc/threading.html
	      After calling this method, -allContainers can be called to obtain the
	      root set of CWContainer instances.
*/
- (void) thread;

/*!
  @method unthread
  @discussion This method is used to release all resources taken by the
              message threading code. After calling this method,
	      -allContainers will return nil.
*/
- (void) unthread;

/*!
  @method search: mask: options:
  @discussion This method is used to search this folder using a criteria,
              mask and options. This method will post a PantomimeFolderSearchCompleted
	      (or invoked -folderSearchCompleted: on the delegate) once it has
	      completed its execution (or post PantomimeFolderSearchFailed or invoke
	      -folderSearchFailed on the delegate if it failed). This method will
	      do absolutely nothing on CWPOP3Folder instances as search operations
	      are not supported in POP3.
  @param theString The string to search for. This can be a regex for LocalFolder instances.
  @param theMask The mask to use. The values can be either one of the
                 PantomimeSearchMask enum. This parameter is ignored for IMAPFolder instances.
  @param theOptions The search options. Can be either PantomimeRegularExpression
                    or PantomimeCaseInsensitiveSearch. This parameter is ignored for
		    CWIMAPFolder instances.
*/
- (void) search: (NSString *) theString
           mask: (PantomimeSearchMask) theMask
        options: (PantomimeSearchOption) theOptions;

/*!
  @method cacheManager
  @discussion This method returns the associated cache manager for this folder.
	      For a CWIMAPFolder, a CWIMAPCacheManager instance will be returned.
              For a CWLocalFolder, a CWLocalFolderCacheManager instance will be returned.
	      For a CWPOP3Folder, a CWPOP3CacheManager instance will be returned.
  @result The associated cache manager instance, nil otherwise.
*/
- (CWCacheManager *) cacheManager;

/*!
  @method setCacheManager:
  @discussion This method is used to set the respective cache manager instance
              for this folder. Instance of CWIMAPCacheManager, CWLocalFolderCacheManager
	      or CWPOP3CacheManager will generally be used.
  @param theCacheManager The cache manager instance for this folder.
*/
- (void) setCacheManager: (id) theCacheManager;

/*!
  @method mode
  @discussion This method is used to get the mode of the folders. The returned
              values can be either PantomimeUnknownMode, PantomimeReadOnlyMode
	      or PantomimeReadWriteMode. Calling this method on an instance
	      of Folder (ie., not a subclass) will raise an exception.
  @result The mode of the folder.
*/
- (PantomimeFolderMode) mode;

/*!
  @method setMode:
  @discussion This method is used to adjust the mode on the specified folder.
              If has no impact on how the mailbox was open. For example,
	      if a mailbox was open as read-only, the mailbox will not
	      be re-opened as read-write after this method call.
  @param theMode The new mode.
*/
- (void) setMode: (PantomimeFolderMode) theMode;

/*!
  @method setFlags: messages:
  @discussion This method is used to set the same flags to a set of messages.
              This can be useful, especially when dealing with CWIMAPFolder
	      instances in order to NOT send many IMAP commands to the server
	      but rather send just one.
  @param theFlags The flags to set to all messages.
  @param theMessages The array of messages to which flags will be applied.
*/
- (void) setFlags: (CWFlags *) theFlags
         messages: (NSArray *) theMessages;

/*!
  @method propertyForKey:
  @discussion This method is used to get an extra property for the
              specified key.
  @result The property for the specified key, nil if key isn't found.
*/
- (id) propertyForKey: (id) theKey;

/*!
  @method setProperty: forKey:
  @discussion This method is used to set an extra property for the
              specified key on this folder. If nil is passed for
	      theProperty parameter, the value will actually be
	      REMOVED for theKey.
  @param theProperty The value of the property.
  @param theKey The key of the property.
*/
- (void) setProperty: (id) theProperty
              forKey: (id) theKey;
@end

#endif // _Pantomime_H_CWFolder
