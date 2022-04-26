/*
**  CWPOP3Message.h
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

#ifndef _Pantomime_H_CWPOP3Message
#define _Pantomime_H_CWPOP3Message

#import <Foundation/NSCoder.h>

#include <Pantomime/CWMessage.h>

/*!
  @class CWPOP3Message
  @discussion This class, which extends CWMessage, adds POP3 specific information.
*/
@interface CWPOP3Message : CWMessage <NSCoding>
{
  @private
    NSString *_UID;
}

/*!
  @method UID
  @discussion This method is used to obtain the UID of a message.
  @result The UID of the message. RFC 1939 says:
          "The unique-id of a message is an arbitrary server-determined
          string, consisting of one to 70 characters in the range 0x21
          to 0x7E, which uniquely identifies a message within a
          maildrop and which persists across sessions.".
*/
- (NSString *) UID;

/*!
  @method setUID:
  @discussion This method is used to set the UID of a message.
              Normally, you shouldn't invoke this method directly.
  @param theUID The UID of the message.
*/
- (void) setUID: (NSString *) theUID;

/*!
  @method rawSource
  @discussion POP3 specific implementation of the rawSource method. This method
              is always non-blocking. It might return nil if the raw source of the
	      message hasn't yet been fetched from the POP3 server. The POP3Store
	      notifies the delegate when the fetch has been completed using the
	      PantomimeMessagePrefetchCompleted notification. It also calls 
	      -messagePrefetchCompleted on the delegate, if any.
  @result The raw source of the message, nil if not yet fully fetched.
*/
- (NSData *) rawSource;

/*!
  @method setFlags:
  @discussion This method, which overrides the one found in
              CWMessage, can be used to delete message on the
	      POP3 server. The only fact that is honored
	      from this method is PantomimeDeleted. If not
	      specified in theFlags, this method does nothing.
  @param theIndex The flags to use.
*/
- (void) setFlags: (CWFlags *) theFlags;
@end

#endif // _Pantomime_H_CWPOP3Message
