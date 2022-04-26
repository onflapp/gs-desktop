/*
**  CWFlags.h
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

#ifndef _Pantomime_H_CWFlags
#define _Pantomime_H_CWFlags

#import <Foundation/NSCoder.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#include <Pantomime/CWConstants.h>

/*!
  @class CWFlags
  @abstract This class provides an interface to message flags.
  @discussion This class provides methods to deal with message flags. Each message
              has a set of flags, like answered, deleted, seen, unread, etc.
	      See the PantomimeFlag enum for the list of possible values.
*/
@interface CWFlags : NSObject <NSCoding, NSCopying>
{
  @public
    PantomimeFlag flags;
}

/*!
  @method initWithFlags:
  @discussion This is the designed initializer for the CWFlags class.
  @param theFlags The initial set of flags the CWFlags instance will hold.
                  Flags are part of the PantomimeFlag enum and can be
		  combined with a bitwise OR.
  @result A Flags instance.
*/
- (id) initWithFlags: (PantomimeFlag) theFlags;

/*!
  @method add:
  @discussion This method is used to add (combine) an additional
              flag to an existing set of flags.
  @param theFlag The flag to add. This value is one of the values
                 of the PantomimeFlag enum.
*/
- (void) add: (PantomimeFlag) theFlag;

/*!
  @method addFlagsFromData:
  @discussion This method is used to add flags contained in a 
              NSData instance. Such flags are come normally from
	      parsing a mailbox that contains Status or X-Status
	      headers or from the maildir's info.
  @param theData The NSData instance from which to parse the flags.
  @param theFormat The format we are parsing.
*/
- (void) addFlagsFromData: (NSData *) theData
                   format: (PantomimeFolderFormat) theFormat;

/*!
  @method contain:
  @discussion This method is used to verify if a specific file
              is present in the flags set.
  @param theFlag The flag to verify the presence in the set. Possible
                 values are part of the PantomimeFlag enum.
  @result YES if the flag is present, NO otherwise.
*/
- (BOOL) contain: (PantomimeFlag) theFlag;

/*!
  @method replaceWithFlags:
  @discussion This method is used to replace all flags from the receiver
              with the ones specified in <i>theFlags</i>.
  @param theFlags The CWFlags instance which holds the new set of flags.
*/
- (void) replaceWithFlags: (CWFlags *) theFlags;

/*!
  @method remove:
  @discussion This method is used to remove a flag from the receicer's
              set of flags. The possibile values are part of the PantomimeFlag enum.
  @param theFlag The flag to remove from the set of flags.
*/
- (void) remove: (PantomimeFlag) theFlag;

/*!
  @method removeAll
  @discussion This method is used to remove all flags from the receiver.
*/
- (void) removeAll;

/*!
  @method statusString
  @discussion This method is used to return a string value of the flags.
              This representation is commonly used by MUA:s like Pine
	      and belongs to the "Status:" header.
  @result A string value of the flags.
*/
- (NSString *) statusString;

/*!
  @method xstatusString
  @discussion This method is used to return a string value of the flags.
              This representation is commonly used by MUA:s like Pine
	      and belongs to the "X-Status:" header.
  @result A string value of the flags.
*/
- (NSString *) xstatusString;

/*!
  @method maildirString
  @discussion This method is used to return a string value of the flags.
              This representation is used by the maildir format. It
	      corresponds to the info semantics and is equivalent
	      to the Status field of the mbox format. The returned
	      string always begins with "2,".
  @result A string value of the flags.
*/
- (NSString *) maildirString;

@end

#endif // _Pantomime_H_CWFlags
