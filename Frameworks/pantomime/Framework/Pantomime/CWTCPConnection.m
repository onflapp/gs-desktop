/*
**  CWTCPConnection.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2016-2020 Riccardo Mottola
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

#import <Pantomime/CWTCPConnection.h>

#import <Pantomime/io.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/CWDNSManager.h>

#import <Foundation/NSException.h>
#import <Foundation/NSRunLoop.h> //test
#import <Foundation/NSValue.h>

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __MINGW32__
#include <winsock2.h>
#else
#include <netinet/in.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <netdb.h>
#endif
#include <sys/time.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>	// For read() and write() and close()

#ifdef MACOSX
#include <sys/uio.h>	// For read() and write() on OS X
#endif

#ifndef FIONBIO
#include <sys/filio.h>  // For FIONBIO on Solaris
#endif

#define DEFAULT_TIMEOUT 60

//
//
//
@interface CWTCPConnection (Private)

- (void) _DNSResolutionCompleted: (NSNotification *) theNotification;
- (void) _DNSResolutionFailed: (NSNotification *) theNotification;

@end


//
//
//
@implementation CWTCPConnection

+ (void) initialize
{
  SSL_library_init();
  SSL_load_error_strings();
}

//
//
//
- (id) initWithName: (NSString *) theName
	       port: (unsigned int) thePort
	 background: (BOOL) theBOOL
{
  return [self initWithName: theName
	       port: thePort
	       connectionTimeout: DEFAULT_TIMEOUT
	       readTimeout: DEFAULT_TIMEOUT
	       writeTimeout: DEFAULT_TIMEOUT
	       background: theBOOL];
}


//
// This methods throws an exception if the connection timeout
// is exhausted and the connection hasn't been established yet.
//
- (id) initWithName: (NSString *) theName
	       port: (unsigned int) thePort
  connectionTimeout: (unsigned int) theConnectionTimeout
	readTimeout: (unsigned int) theReadTimeout
       writeTimeout: (unsigned int) theWriteTimeout
	 background: (BOOL) theBOOL
{
  NSArray *addresses;

  struct sockaddr_in server;
#ifdef __MINGW32__
  u_long nonblock = 1;
#else
  int nonblock = 1;
#endif

  if (theName == nil || thePort <= 0)
    {
      AUTORELEASE(self);
      return nil;
    }

  self = [super init];
  if (self)
    {
  _connectionTimeout = theConnectionTimeout;
 
  ASSIGN(_name, theName);
  _port = thePort;

  _dns_resolution_completed = ssl_handshaking = NO;
  _ssl = NULL;
 
  // We get the file descriptor associated to a socket
  _fd = socket(PF_INET, SOCK_STREAM, 0);

  if (_fd == -1) 
    {
      AUTORELEASE(self);
      return nil;
    }
  
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_DNSResolutionCompleted:)
    name: PantomimeDNSResolutionCompleted
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_DNSResolutionFailed:)
    name: PantomimeDNSResolutionFailed
    object: nil];

  if (!theBOOL)
    {
      addresses = [[CWDNSManager singleInstance] addressesForName: theName  background: NO];
      
      if (!addresses)
	{
	  safe_close(_fd);
	  AUTORELEASE(self);
	  return nil;
	}

      _dns_resolution_completed = YES;

      server.sin_family = AF_INET;
      server.sin_addr.s_addr = [(NSNumber *)[addresses objectAtIndex: 0] unsignedIntValue];
      server.sin_port = htons(thePort);
      
      // If we don't connect in background, we must try to connect right away
      // and return on any errors.
      if (connect(_fd, (struct sockaddr *)&server, sizeof(server)) != 0)
	{
	  AUTORELEASE(self);
	  return nil;
	}
    }
  
  // We set the non-blocking I/O flag on _fd
#ifdef __MINGW32__
  if (ioctlsocket(_fd, FIONBIO, &nonblock) == -1)
#else
  if (ioctl(_fd, FIONBIO, &nonblock) == -1)
#endif
    {
      safe_close(_fd);
      AUTORELEASE(self);
      return nil;
    }

  if (theBOOL) [[CWDNSManager singleInstance] addressesForName: theName  background: YES];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  //NSLog(@"TCPConnection: -dealloc");
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(_name);

  if (_ssl)
    {
      SSL_free(_ssl);    
    }

  if (_ctx)
    {
      SSL_CTX_free(_ctx);
    }
  
  [super dealloc];
}


//
// This method is used to return the file descriptor
// associated with our socket.
//
- (int) fd
{
  return _fd;
}


//
//
//
- (BOOL) isConnected
{
  struct timeval timeout;
  fd_set fdset;
  int value;

  if (!_dns_resolution_completed)
    {
      return NO;
    }

  // We remove all descriptors from the set fdset
  FD_ZERO(&fdset);
  
  // We add the descriptor _fd to the fdset set
  FD_SET(_fd, &fdset);
  
  // We set the timeout for our connection
  timeout.tv_sec = 0;
  timeout.tv_usec = 1;
  
  value = select(_fd + 1, NULL, &fdset, NULL, &timeout);
  
  // An error occured..
  if (value == -1)
    {
      return NO;
    }
  // Our fdset has ready descriptors (for writability)
  else if (value > 0)
    {
#ifdef __MINGW32__
      int size;
#else
      socklen_t size;
#endif
      int error;
      
      size = sizeof(error);
      
      // We get the options at the socket level (so we use SOL_SOCKET)
      // returns -1 on error, 0 on success
      if (getsockopt(_fd, SOL_SOCKET, SO_ERROR, &error, &size) == -1)
	{
	  return NO;
	}
      
      if (error != 0)
	{
#warning handle right way in CWService tick if the port was incorrectly specified
	  return NO;
	}
    }
  // select() has returned 0 which means that the timeout has expired.
  else
    {
      return NO;
    }

  return YES;
}


//
//
//
- (BOOL) isSSL
{
  return (_ssl ? YES : NO);
}


//
// other methods
//
- (void) close
{
  //NSLog(@"TCPConnection: -close");

  if (_ssl)
    {
      SSL_shutdown(_ssl);
    }

  safe_close(_fd);
  _fd = -1;
}


//
//
//
- (ssize_t) read: (char *) buf
      length: (size_t) len
{
  if (ssl_handshaking)
    {
      return 0;
    }

  if (_ssl)
    {
      return SSL_read(_ssl, buf, (int)len);
    }

  return safe_recv(_fd, buf, len, 0);
}


//
//
//
- (ssize_t) write: (char *) buf
       length: (size_t) len
{
  if (ssl_handshaking)
    {
      return 0;
    }

  if (_ssl)
    {
      return SSL_write(_ssl, buf, (int)len);
    }

  return send(_fd, buf, len, 0);
}


//
// 0  -> success
// -1 ->
// -2 -> handshake error
//
- (int) startSSL
{
  int ret;
  
  // For now, we do not verify the certificates...
  _ctx = SSL_CTX_new(SSLv23_client_method());
  SSL_CTX_set_verify(_ctx, SSL_VERIFY_NONE, NULL);
  SSL_CTX_set_mode(_ctx, SSL_MODE_ENABLE_PARTIAL_WRITE);

  // We then connect the SSL socket
  _ssl = SSL_new(_ctx);
  SSL_set_fd(_ssl, _fd);
  ret = SSL_connect(_ssl);

  if (ret != 1)
    {
      int rc;

      rc = SSL_get_error(_ssl, ret);

      if ((rc != SSL_ERROR_WANT_READ) && (rc != SSL_ERROR_WANT_WRITE))
	{
	  // SSL handshake error...
	  //NSLog(@"SSL handshake error.");
	  return -2;
	}
      else
	{
	  NSDate *limit;

	  //NSLog(@"SSL handshaking... %d", rc);
	  ssl_handshaking = YES; 
	  limit = [[NSDate alloc] initWithTimeIntervalSinceNow: DEFAULT_TIMEOUT];

	  while ((rc == SSL_ERROR_WANT_READ || rc == SSL_ERROR_WANT_WRITE)
		 && [limit timeIntervalSinceNow] > 0.0)
	    {
	      [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
	      ret = SSL_connect(_ssl);
	      //NSLog(@"ret = %d", ret);
	      if (ret != 1)
		{
		  //int e = errno;
		  rc = SSL_get_error(_ssl, ret);
		  //NSLog(@"%s  errno = %s", ERR_error_string(rc, NULL), strerror(e));
		}
	      else
		{
		  rc = SSL_ERROR_NONE;
		}
	      
	      //NSLog(@"rc = %d", rc);
	    }

	  RELEASE(limit);

	  if (rc != SSL_ERROR_NONE)
	    {
	      //NSLog(@"ERROR DURING HANDSHAKING...");
	      //NSLog(@"unable to make SSL connection: %s", ERR_error_string(rc, NULL));
	      //ERR_print_errors_fp(stderr);
	      ssl_handshaking = NO;
	      SSL_free(_ssl);
	      _ssl = NULL;
	      return -2;
	    }
	  
	  // We are done with handshaking
	  ssl_handshaking = NO;
	}
    }

  // Everything went all right, let's tell our caller.
  return 0;
}

@end

//
//
//
@implementation CWTCPConnection (Private)

- (void) _DNSResolutionCompleted: (NSNotification *) theNotification
{
  struct sockaddr_in server;

  if (![[[theNotification userInfo] objectForKey: @"Name"] isEqualToString: _name])
    {
      return;
    }

  NSDebugLog(@"DNS resolution completed for name |%@|", [[theNotification userInfo] objectForKey: @"Name"]);
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  _dns_resolution_completed = YES;

  server.sin_family = AF_INET;
  server.sin_addr.s_addr = [[[theNotification userInfo] objectForKey: @"Address"] unsignedIntValue];
  server.sin_port = htons(_port);

  // We initiate our connection to the socket
  if (connect(_fd, (struct sockaddr *)&server, sizeof(server)) == -1)
    {
#ifdef __MINGW32__
      if (WSAGetLastError() == WSAEWOULDBLOCK)
#else
      if (errno == EINPROGRESS)
#endif
	{
	  return;
	} // if ( errno == EINPROGRESS ) ...
      else
	{
	  NSLog(@"Failed to connect asynchronously.");
	  safe_close(_fd);
	}
    } // if ( connect(...) )
}

//
//
//
- (void) _DNSResolutionFailed: (NSNotification *) theNotification
{
  NSDebugLog(@"DNS resolution failed!");
 
  _dns_resolution_completed = YES;
  safe_close(_fd);

  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
