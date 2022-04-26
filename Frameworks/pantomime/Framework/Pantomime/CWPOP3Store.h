/*
**  CWPOP3Store.h
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

#ifndef _Pantomime_H_CWPOP3Store
#define _Pantomime_H_CWPOP3Store

#include <Pantomime/CWService.h>
#include <Pantomime/CWStore.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/*!
  @typedef POP3Command
  @abstract Supported POP3 commands.
  @discussion This enum lists the supported POP3 commands available
              in Pantomime's POP3 client code.
  @constant POP3_APOP APOP authentication command.
  @constant POP3_AUTHORIZATION Special command so that we know we are
                               in the authorization state.
  @constant POP3_DELE The POP3 DELE command. See RFC 1939 for details.
  @constant POP3_LIST The POP3 LIST command. See RFC 1939 for details.
  @constant POP3_NOOP The POP3 NOOP command. See RFC 1939 for details.
  @constant POP3_PASS The POP3 PASS command. See RFC 1939 for details.
  @constant POP3_QUIT The POP3 QUIT command. See RFC 1939 for details.
  @constant POP3_RETR The POP3 RETR command. See RFC 1939 for details.
  @constant POP3_RETR_AND_INITIALIZE Same as POP3_RETR but also initialize the message with the received content.
  @constant POP3_STAT The POP3 STAT command. See RFC 1939 for details.
  @constant POP3_STLS The STLS POP3 command - see RFC2595.
  @constant POP3_TOP The POP3 TOP command. See RFC 1939 for details.
  @constant POP3_UIDL The POP3 UIDL command. See RFC 1939 for details.
  @constant POP3_USER The POP3 USER command. See RFC 1939 for details.
  @constant POP3_EMPTY_QUEUE Special command to empty the command queue.
  @constant POP3_EXPUNGE_COMPLETED Special command to indicate we are 
                                   done expunging the deleted messages.
*/
typedef enum {
  POP3_APOP = 0x100,
  POP3_AUTHORIZATION,
  POP3_CAPA,
  POP3_DELE,
  POP3_LIST,
  POP3_NOOP,
  POP3_PASS,
  POP3_QUIT,
  POP3_RETR,
  POP3_RETR_AND_INITIALIZE,
  POP3_STAT,
  POP3_STLS,
  POP3_TOP,
  POP3_UIDL,
  POP3_USER,
  POP3_EMPTY_QUEUE,      
  POP3_EXPUNGE_COMPLETED
} POP3Command;

@class CWPOP3Folder;

/*!
  @class CWPOP3Store
  @abstract Pantomime POP3 client code.
  @discussion This class, which extends the CWService class and implements
              the CWStore protocol, is Pantomime's POP3 client code.
*/ 
@interface CWPOP3Store : CWService <CWStore>
{
  @private
    NSString *_timestamp;
    CWPOP3Folder *_folder;
}


/*!
  @method timestamp
  @discussion This method is used to obtain the timestamp in the
              server's greeting. Servers must send that if they do
	      support APOP.
  @result The timestamp, as a NSString instance.
*/
- (NSString *) timestamp;

/*!
  @method sendCommand:arguments:...
  @discussion This method is used to send commands to the POP3 server.
              Normally, you should not call this method directly.
  @param theCommand The POP3 command to send.
  @param theFormat The format defining the variable arguments list.
*/
- (void) sendCommand: (POP3Command) theCommand  arguments: (NSString *) theFormat, ...;

@end

#endif // _Pantomime_H_CWPOP3Store
