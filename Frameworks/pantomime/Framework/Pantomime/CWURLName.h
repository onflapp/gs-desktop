/*
**  CWURLName.h
**
**  Copyright (c) 2001-2004 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWURLName
#define _Pantomime_H_CWURLName

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/*!
  @class CWURLName
  @discussion This class provides support for handling POP3, IMAP and
              local URL schemes. The POP3 URL scheme is described in
	      RFC 2384. The IMAP URL scheme is described in RFC 2192
	      while the local URL scheme is a simple Pantomime scheme
	      to refer to local mailboxes.
*/
@interface CWURLName : NSObject
{
  @private
    NSString *_protocol;
    NSString *_foldername;
    NSString *_path;
  
    NSString *_host;
    unsigned int _port;

    NSString *_username;
    NSString *_password;
}

/*!
  @method initWithString:
  @discussion This method invokes -initWithString: path:
              with a <i>nil</i> path.
  @param theString The URL.
  @result A CWURLName instance, nil on error.
*/
- (id) initWithString: (NSString *) theString;

/*!
  @method initWithString: path:
  @discussion This is the designated initializer for the
              URLName class.
  @param theString The URL.
  @param thePath The path to the local mailstore.
  @result A CWURLName instance, nil on error.
*/
- (id) initWithString: (NSString *) theString
                 path: (NSString *) thePath;


/*!
  @method protocol
  @discussion This method is used to obtain the protocol part
              of an URL.
  @result POP3, IMAP or LOCAL.
*/
- (NSString *) protocol;

/*!
  @method foldername
  @discussion This method is used to obtain the name of the
              folder of the receiver.
  @result The name of the folder.
*/
- (NSString *) foldername;

/*!
  @method path
  @discussion This method is used to obtain the path to the mailstore.
  @result The full path.
*/
- (NSString *) path;

/*!
  @method host
  @discussion This method is used to obtain the host name part
              of an URL.
  @result The host name.
*/
- (NSString *) host;

/*!
  @method host
  @discussion This method is used to obtain the port part
              of an URL.
  @result The port.
*/
- (unsigned int) port;

/*!
  @method username
  @discussion This method is used to obtain the username part
              of an URL.
  @result The username.
*/
- (NSString *) username;

/*!
  @method password
  @discussion This method is used to obtain the password part
              of an URL.
  @result The password.
*/
- (NSString *) password;

/*!
  @method stringValue
  @discussion This method is used to obtain the string
              representation of the receiver. The returned
	      format is the same as one that could be
	      used by an initializer.
  @result The string value.
*/
- (NSString *) stringValue;

@end

#endif // _Pantomime_H_CWURLName
