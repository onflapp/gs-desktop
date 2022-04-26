/*
**  CWStore.h
**
**  Copyright (c) 2001-2006 Ludovic Marcotte
**  Copyright (c) 2018      Riccardo Mottola
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

#ifndef _Pantomime_H_CWStore
#define _Pantomime_H_CWStore

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSString.h>

#include <Pantomime/CWConstants.h>

/*!
  @const PantomimeFolderCreateCompleted
*/
extern NSString* PantomimeFolderCreateCompleted;

/*!
  @const PantomimeFolderCreateFailed
*/
extern NSString* PantomimeFolderCreateFailed;

/*!
  @const PantomimeFolderDeleteCompleted
*/
extern NSString* PantomimeFolderDeleteCompleted;

/*!
  @const PantomimeFolderDeleteFailed
*/
extern NSString* PantomimeFolderDeleteFailed;

/*!
  @const PantomimeFolderRenameCompleted
*/
extern NSString* PantomimeFolderRenameCompleted;

/*!
  @const PantomimeFolderRenameFailed
*/
extern NSString* PantomimeFolderRenameFailed;


@class CWFolder;
@class CWURLName;

/*!
  @protocol CWStore
  @discussion This protocol defines a basic set of methods that classes implementing
              the protocol must implement in order to offer all the required
	      functionalities of a message store. CWIMAPStore, CWLocalStore and CWPOP3Store
	      are classes that currently implement this protocol.
*/
@protocol CWStore

/*!
  @method initWithURL:
  @discussion This method is used to initialize a Store instance using
              the specified URL. <i>theURL</i>.
  @param theURL The URL, as a CWURLName instance.
  @result A CWStore subclass instance, nil on error.
*/
- (id) initWithURL: (CWURLName *) theURL;

/*!
  @method defaultFolder
  @discussion This method is used to obtain the default folder
              of the receiver. For example, CWPOP3Store will always
	      return the "INBOX" folder as no other folder is
	      accessible in POP3.
  @result A CWFolder subclass instance.
*/
- (id) defaultFolder;

/*!
  @method folderForName:
  @discussion This method is used to obtain a CWFolder instance
              with the specifed name.
  @param theName The name of the folder to obtain.
  @result A CWFolder subclass instance.
*/
- (id) folderForName: (NSString *) theName;

/*!
  @method folderForURL:
  @discussion This method is used to obtain a Folder instance
              with the specifed URL. <i>theURL</i> must be in form which
	      is understood by the CWURLName class.
  @param theURL The URL, as a NSString instance.
  @result A CWFolder subclass instance.
*/
- (id) folderForURL: (NSString *) theURL;

/*!
  @method folderEnumerator
  @discussion This method is used to get the list of all available
              folders on the receiver. The name of the folders
	      are returned, not actual CWFolder subclass instances.
  @result The list of folder names.
*/
- (NSEnumerator *) folderEnumerator;

/*!
  @method subscribedFolderEnumerator
  @discussion This method is used to get the list of subscribed
              folders on the receiver. The name of the folders
	      are returned, not actual CWFolder subclass instances.
	      This generally returns a subset of the list
	      returned by -folderEnumerator.
  @result The list of folder names.
*/
- (NSEnumerator *) subscribedFolderEnumerator;

/*!
  @method openFoldersEnumerator
  @discussion This method is used to obtain all the CWFolder subclass
              instance which are in the open state in the receiver.
  @result The list of open folders.
*/
- (NSEnumerator *) openFoldersEnumerator;

/*!
  @method removeFolderFromOpenFolders:
  @discussion This method is used to remove the specified folder
              from the list of open folders in the receiver.
	      Normally, you should never invoke this method directly.
  @param theFolder The CWFolder subclass instance to remove from the
                   list of open folders.
*/
- (void) removeFolderFromOpenFolders: (CWFolder *) theFolder;

/*!
  @method folderForNameIsOpen:
  @discussion This method is used to verify if the folder
              with the specified name is in an open state
	      in the receiver.
  @result YES if it is in an open state, NO otherwise.
*/
- (BOOL) folderForNameIsOpen: (NSString *) theName;

/*!
  @method folderTypeForFolderName:
  @discussion This method is used to obtain the folder type
              of the specified folder name. The returned value
	      is part of the folderTypeForFolderName enum.
  @param theName The name of the folder.
  @result The type of the folder.
*/
- (PantomimeFolderType) folderTypeForFolderName: (NSString *) theName;

/*!
  @method folderSeparator
  @discussion This method is used to obtain the folder separator
              of the receiver. The separator hierarchically
	      separates folders. Returned values are generatlly
	      either '/' or '.'.
  @result The folder separator, 0 if none was set. For example,
          in CWIMAPStore, this method will return NULL if -folderEnumerator
	  or -subscribedFolderEnumerator was not invoked before
	  calling this method.
*/
- (unichar) folderSeparator;

/*!
  @method close
  @discussion This method is used to close the receiver.
              Classes implementing the CWStore protocol will
	      also release all resources, like open folders,
	      CWConnection instances, etc.
*/
- (void) close;

/*!
  @method createFolderWithName:type:contents:
  @discussion This method is used to create a new folder
              with the specified name, type and contents.
	      On success, it posts the PantomimeFolderCreateCompleted notification
	      and calls -folderCreateCompleted: on the delegate.
	      On failure, it posts the PantomimeFolderCreateFailed notification
	      and calls -folderCreateFailed: on the delegate.
  @param theName The name of the folder to create. It must be a full path.
  @param theType The folder type. Accepted values are part of the PantomimeFolderFormat enum.
  @param theContents The initial content of the folder. It must be in mbox format.
*/
- (void) createFolderWithName: (NSString *) theName 
                         type: (PantomimeFolderFormat) theType
                     contents: (NSData *) theContents;

/*!
  @method deleteFolderWithName:
  @discussion This method is used to delete the folder
              specified by <i>theName</i>. On success, it posts the
	      PantomimeFolderDeleteCompleted notification. On error, it posts
	      the PantomimeFolderDeleteFailed notification.
  @param theName The name of the folder to delete.
*/
- (void) deleteFolderWithName: (NSString *) theName;

/*!
  @method renameFolderWithName:toName:
  @discussion This method is used to rename a folder. On success, this method
              posts a PantomimeFolderRenameCompleted notification. On error,
	      it posts a PantomimeFolderRenameFailed notification.
  @param theName The name of the folder to rename.
  @param theNewName The name of the folder to rename it to.
*/
- (void) renameFolderWithName: (NSString *) theName
                       toName: (NSString *) theNewName;
@end

#endif // _Pantomime_H_CWStore
