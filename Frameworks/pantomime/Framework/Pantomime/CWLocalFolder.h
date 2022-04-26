/*
**  CWLocalFolder.h
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

#ifndef _Pantomime_H_CWLocalFolder
#define _Pantomime_H_CWLocalFolder

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWFolder.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>

#include <stdio.h>

/*!
  @class CWLocalFolder
  @discussion This class, which extends the CWFolder class, is used to
              implement local-mailboxes (mbox or maildir format)
	      specific features.
*/
@interface CWLocalFolder : CWFolder
{
  NSString *_path;
  
  PantomimeFolderFormat _type;
  int fd;
  FILE *stream;
}

/*!
  @method initWithPath:
  @discussion This method is used to initialize the receiver
              with the folder at the specified path. Normally,
	      you should not invoke this method directly. You
	      should rather use one of the -folderForName:...
	      method found in CWLocalStore. This method
	      will open the mailbox at the specified path.
  @param thePath The path of the folder.
  @result An instance of CWLocalFolder, nil on error.
*/
- (id) initWithPath: (NSString *) thePath;

/*!
  @method parse
  @discussion This method is used to parse some or message headers (and only that)
              of the receiver. On completion, it posts a PantomimeFolderPrefetchCompleted
	      notification (and calls -folderPrefetchCompleted: on the delegate, if any).
	      This method call is blocking. Among the headers that are always parsed are:
	      Cc, Date, From, In-Reply-To, Message-ID, References, Status, Subject,
	      To and X-Status.
  @param theBOOL If YES, all headers are parsed. Otherwise, only some are.
*/
- (void) parse: (BOOL) theBOOL;

/*!
  @method fd
  @discussion This method is used to get the associated file descriptor
              of the receiver.
  @result The file descriptor, -1 if none was set.
*/
- (int) fd;

/*!
  @method setFD:
  @discussion This method is used to set the associated file descriptor
              of the receiver. Normally, you should never invoke this
	      method directly.
  @param theFD The associated file descriptor.
*/
- (void) setFD: (int) theFD;

/*!
  @method path
  @discussion This method is used to obtain the full path of the folder.
  @result The full path.
*/
- (NSString *) path;

/*!
  @method setPath:
  @discussion This method is used to set the full path of the folder.
  @param thePath The full path.
*/
- (void) setPath: (NSString *) thePath;

/*!
  @method stream
  @discussion This method is used to get the associated stream
              of the receiver.
  @result The stream, NULL if none was set.
*/
- (FILE *) stream;

/*!
  @method setStream:
  @discussion This method is used to set the associated stream
              of the receiver. Normally, you should never invoke this
	      method directly.
  @param theStream The associated stream.
*/
- (void) setStream: (FILE *) theStream;

/*!
  @method type
  @discussion This method is used to get the type of folder
              the receiver is. Possible values are part of the
	      PantomimeFolderFormat enum.
  @result The type of the folder.
*/
- (PantomimeFolderFormat) type;

/*!
  @method setType:
  @discussion This method is used to set the type of the receiver.
              Accepted values are part of the PantomimeFolderFormat enum.
  @param theType The type of the receiver.
*/
- (void) setType: (PantomimeFolderFormat) theType;

@end

#endif // _Pantomime_H_CWLocalFolder
