/*
**  CWTCPConnection.h
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

#ifndef _Pantomime_H_CWTCPConnection
#define _Pantomime_H_CWTCPConnection

#include <Pantomime/CWConnection.h>

#define id openssl_id
#define MD5 MDFIVE
#include <openssl/ssl.h>
#undef MD5
#undef id

#import <Foundation/NSObject.h>

/*!
  @class CWTCPConnection
  @discussion This class, which implements the CWConnection protocol,
              offers an elegant interface to a TCP connection. See
	      the documentation of the CWConnection protocol in order
	      to see all the methods one can use on an instance
	      of this class. Normally, you should never have to use
	      this class or one of its methods directly.
*/
@interface CWTCPConnection : NSObject <CWConnection>
{
  @public
    BOOL ssl_handshaking;
  
  @private
    NSString *_name;

    unsigned int _connectionTimeout;
    unsigned int _port;
    int _fd;

    BOOL _dns_resolution_completed;

    SSL_CTX *_ctx;
    SSL *_ssl;
}

/*!
  @method startSSL
  @discussion This method is used to start the SSL handshaking
              on an altready established TCP connection.
  @result 0 on success, < 0 on error.
*/
- (int) startSSL;

/*!
  @method isSSL
  @discussion This method is used to verify if the connection
              TCP connection is using SSL or not.
  @result YES if using SSL, NO otherwise.
*/
- (BOOL) isSSL;

@end

#endif // _Pantomime_H_CWTCPConnection
