/*
**  CWLocalStore.h
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

#ifndef _Pantomime_H_CWLocalStore
#define _Pantomime_H_CWLocalStore

#include <Pantomime/CWStore.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/*!
  @class CWLocalStore
  @abstract Pantomime local folders client code.
  @discussion This class, which implements the CWStore protocol, is Pantomime's code
              for accessing local folders such as mbox mailboxes, maildir mailboxes
	      and more..
*/ 
@interface CWLocalStore : NSObject <CWStore>
{
  @private
    NSMutableDictionary *_openFolders;
    NSMutableArray *_folders;
    NSString *_path;
    id _delegate;
    BOOL _secure;
}

/*!
  @method initWithPath:
  @discussion This is the designated initializer for the CWLocalStore class.
              This method is used to initialize the receiver with the
	      full path of where folders are located. Folders can be in
	      the mbox format, maildir format or directories which hold
	      mbox mailboxes.
  @param thePath The full path to the mail store.
*/
- (id) initWithPath: (NSString *) thePath;

/*!
  @method delegate
  @discussion This method is used to get the delegate of the CWLocalStore's instance.
  @result The delegate, nil if none was previously set.
*/
- (id) delegate;

/*!
  @method setDelegate:
  @discussion This method is used to set the CWLocalStore's delegate.
              The delegate will not be retained. The CWLocalStore class
	      will invoke methods on the delegate based on actions performed.
  @param theDelegate The delegate, which implements various callback methods.
*/
- (void) setDelegate: (id) theDelegate;

/*!
  @method path
  @discussion This method is used to obtain the full path to the mail store.
  @result The full path to the mail store.
*/
- (NSString *) path;

/*!
  @method setPath:
  @discussion This method is used to set the full path to the mail store.
  @param thePath The full path to the mail store.
*/
- (void) setPath: (NSString *) thePath;

/*!
  @method setEnforceMode:
  @discussion This method is used to enforce or not secure modes
              (0600 for files, 0700 for directories) on newly created
	      mailboxes. If not enforced, the default permissions
	      used by Foundation when creating files or directories
	      will be used. By default, secure modes are enforced.
  @param theBOOL YES to enforce secure modes, NO otherwise.
*/
- (void) setEnforceMode: (BOOL) theBOOL;

/*!
  @method isEnforcingMode
  @discussion This method is used to verify if secure modes
              are enforced.
  @result YES if secure modes are enforced, NO otherwise.
*/
- (BOOL) isEnforcingMode;

@end

#endif // _Pantomime_H_CWLocalStore
