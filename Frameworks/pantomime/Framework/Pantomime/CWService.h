/*
**  CWService.h
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

#ifndef _Pantomime_H_CWService
#define _Pantomime_H_CWService

#import <Pantomime/CWConnection.h>
#import <Pantomime/CWConstants.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSTimer.h>

#ifdef MACOSX
#import <Foundation/NSMapTable.h>
#include <CoreFoundation/CoreFoundation.h>
#endif

@class CWService;

/*!
  @function split_lines
  @discussion This function is used to split lines from <i>theMutableData</i> and
              return the first one found immediately (by removing it first
              from <i>theMutableData</i>). IMAP, POP3 and SMTP servers reponses are 
              always ended by CRLF.
  @param theMutableData The data from which to split lines from.
  @result A line as a NSData instance, nil if no line was splitted.
*/
static inline NSData *split_lines(NSMutableData *theMutableData)
{
  char *bytes, *end;
  NSUInteger i, count;

  end = bytes = (char *)[theMutableData mutableBytes];
  count = [theMutableData length];

  for (i = 0; i < count; i++)
    {
      if (*end == '\n' && *(end-1) == '\r')
	{
	  NSData *aData;
	  
	  aData = [NSData dataWithBytes: bytes  length: (i-1)];
	  memmove(bytes,end+1,count-i-1);
	  [theMutableData setLength: count-i-1];
	  return aData;
	}

      end++;
    }
  return nil;
}

/*!
  @const PantomimeAuthenticationCompleted
*/
extern NSString* PantomimeAuthenticationCompleted;

/*!
  @const PantomimeAuthenticationFailed
*/
extern NSString* PantomimeAuthenticationFailed;

/*!
  @const PantomimeConnectionEstablished
*/
extern NSString* PantomimeConnectionEstablished;

/*!
  @const PantomimeConnectionLost
*/
extern NSString* PantomimeConnectionLost;

/*!
  @const PantomimeConnectionTerminated
*/
extern NSString* PantomimeConnectionTerminated;

/*!
  @const PantomimeConnectionTimedOut
*/
extern NSString* PantomimeConnectionTimedOut;

/*!
  @const PantomimeRequestCancelled
*/
extern NSString* PantomimeRequestCancelled;

/*!
  @const PantomimeServiceInitialized
*/
extern NSString* PantomimeServiceInitialized;

/*!
  @const PantomimeServiceReconnected
*/
extern NSString* PantomimeServiceReconnected;

/*!
  @const PantomimeProtocolException
  @description This exception can be raised if a major
               protocol handling error occured in one
	       of the CWService subclasses. This would
	       mean that Pantomime has a bug.
*/
extern NSString* PantomimeProtocolException;

/*!
  @category NSObject (CWServiceClient)
  @discussion This informal protocol defines methods that can implemented in
              CWService's delegate (CWIMAPStore, CWPOP3Store or CWSMTP instance) 
	      to control the behavior of the class or to obtain status information.
	      You can release/autorelease a CWService instance in -connectionTimedOut:,
	      -connectionLost: or -connectionTerminated (or the respective
	      notification handlers). You may NOT do it elsewhere.
*/
@interface NSObject (CWServiceClient)

/*!
  @method authenticationCompleted:
  @discussion This method is automatically called on the delegate
              when the authentication has sucessfully completed
	      on the underlying Service's instance.
	      A PantomimeAuthenticationCompleted notification is also posted.
	      The authentication mechanism that was used can be obtained
	      from the notification's userInfo using the "Mechanism" key.
  @param theNotification The notification holding the information.
*/
- (void) authenticationCompleted: (NSNotification *) theNotification;

/*!
  @method authenticationFailed:
  @discussion This method is automatically called on the delegate
              when the authentication has failed on the underlying Service's instance.
	      A PantomimeAuthenticationCompleted notification is also posted.
	      The authentication mechanism that was used can be obtained
	      from the notification's userInfo using the "Mechanism" key.
  @param theNotification The notification holding the information.
*/
- (void) authenticationFailed: (NSNotification *) theNotification;

/*!
  @method connectionEstablished:
  @discussion Invoked once the connection has been established with the peer.
              A PantomimeConnectionEstablished notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) connectionEstablished: (NSNotification *) theNotification;

/*!
  @method connectionLost:
  @discussion Invoked when the connection to the peer has been 
              lost without the "user's" intervention.
              A PantomimeConnectionLost notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) connectionLost: (NSNotification *) theNotification;

/*!
  @method connectionTerminated:
  @discussion Invoked when the connection has been cleanly terminated
              with the peer.
	      A PantomimeConnectionTerminated notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) connectionTerminated: (NSNotification *) theNotification;

/*!
  @method connectionTimedOut:
  @discussion Invoked when connecting to a peer on a non-blocking
              fashion but the associated timeout has expired. It is also
	      invoked when we try to read bytes from the peer or when
	      trying send bytes to it. The method <i>isConnected</i> can
	      be invoked in order if we got this timeout when trying to
	      connect (the value will be set to "NO") or when we are
	      connected but can't read or write anymore.
	      A PantomimeConnectionTimedOut notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) connectionTimedOut: (NSNotification *) theNotification;

/*!
  @method service: receivedData:
  @discussion Invoked when bytes have been received by the underlying
              CWService's connection. No notification is posted.
  @param theService The CWService instance that generated network activity.
  @param theData The received bytes.
*/
- (void) service: (CWService *) theService  receivedData: (NSData *) theData;

/*!
  @method service: sentData:
  @discussion Invoked when bytes have been sent using the underlying
              CWService's connection. No notification is posted.
  @param theService The CWService instance that generated network activity.
  @param theData The sent bytes.
*/
- (void) service: (CWService *) theService  sentData: (NSData *) theData;

/*!
  @method requestCancelled:
  @discussion This method is automatically called after
              a request has been cancelled. The connection
	      was automatically closed PRIOR to calling this delegate method.
	      A PantomimeRequestCancelled notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) requestCancelled: (NSNotification *) theNotification;

/*!
  @method serviceInitialized:
  @discussion This method is automatically invoked on the delegate
              when the Service is fully initialized. This method
	      is invoked after -connectionEstablished: is called.
	      A PantomimeServiceInitialized notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) serviceInitialized: (NSNotification *) theNotification;

/*!
  @method serviceReconnected:
  @discussion When a service lost its connection, -connectionWasLost: is
              called. Usually, -reconnect is called to re-establish the
	      connection with the remote host. Once it has completed,
	      -serviceReconnected: is invoked on the delegate.
              A PantomimeServiceReconnected notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) serviceReconnected: (NSNotification *) theNotification;
@end


#ifdef MACOSX
typedef enum {ET_RDESC, ET_WDESC, ET_EDESC} RunLoopEventType;

/*!
  @class CWService
  @discussion This abstract class defines the basic behavior and implementation
              of all Pantomime internet services such as SMTP, POP3 and IMAP.
	      You should never instantiate this class directly. You rather
	      need to instantiate the CWSMTP, CWPOP3Store or CWIMAPStore classes,
	      which fully implement the abstract methods found in this class.
*/
@interface CWService : NSObject
#else
@interface CWService : NSObject <RunLoopEvents>
#endif
{
  @protected
    NSMutableArray *_supportedMechanisms;
    NSMutableArray *_responsesFromServer;
    NSMutableArray *_capabilities;
    NSMutableArray *_runLoopModes;
    NSMutableArray *_queue;
    NSMutableData *_wbuf;
    NSMutableData *_rbuf;
    NSString *_mechanism;
    NSString *_username;
    NSString *_password;
    NSString *_name;

#ifdef MACOSX
    CFRunLoopSourceRef _runLoopSource;
    CFSocketContext *_context;
    CFSocketRef _socket;
#endif

    unsigned int _connectionTimeout;
    unsigned int _readTimeout;
    unsigned int _writeTimeout;
    unsigned int _lastCommand;
    unsigned int _port;
    BOOL _connected;
    id _delegate;
    
    id<CWConnection> _connection;
    NSTimer * _timer;
    int _counter;
    
    struct {
      NSMutableArray *previous_queue;
      BOOL reconnecting;
      BOOL opening_mailbox;
    } _connection_state;
}

/*!
  @method initWithName: port:
  @discussion This is the designated initializer for the CWService class.
              Once called, it'll open a connection to the server specified
	      by <i>theName</i> using the specified port (<i>thePort</i>).
  @param theName The FQDN of the server.
  @param thePort The server port to which we will connect.
  @result An instance of a Service class, nil on error.
*/
- (id) initWithName: (NSString *) theName
               port: (unsigned int) thePort;

/*!
  @method setDelegate:
  @discussion This method is used to set the CWService's delegate.
              The delegate will not be retained. The CWService class
	      (and its subclasses) will invoke methods on the delegate
	      based on actions performed.
  @param theDelegate The delegate, which implements various callback methods.
*/
- (void) setDelegate: (id) theDelegate;

/*!
  @method delegate
  @discussion This method is used to get the delegate of the CWService's instance.
  @result The delegate, nil if none was previously set.
*/
- (id) delegate;

/*!
  @method name
  @discussion This method is used to obtain the server name.
  @result The server name.
*/
- (NSString *) name;

/*!
  @method setName:
  @discussion This method is used to set the server name to which
              we will eventually connect to.
  @param theName The name of the server.
*/
- (void) setName: (NSString *) theName;

/*!
  @method port
  @discussion This method is used to obtain the server port.
  @result The server port.
*/
- (unsigned int) port;

/*!
  @method setPort:
  @discussion This method is used to set the server port to which
              we will eventually connect to.
  @param theName The port of the server.
*/
- (void) setPort: (unsigned int) thePort;

/*!
  @method connection
  @discussion This method is used to retrieve the associated connection
              object for the service (usually a CWTCPConnection instance).
  @result The associated connectio object.
*/
- (id<CWConnection>) connection;

/*!
  @method username
  @discussion This method is used to get the username (if any) that will be
              used to authenticate to the service.
  @result The username.
*/
- (NSString *) username;

/*!
  @method setUsername:
  @discussion This method is used to set the username that will be used
              to authenticate to the service.
  @param theUsername The username for authentication.
*/
- (void) setUsername: (NSString *) theUsername;

/*!
  @method supportedMechanisms
  @discussion This method is used to return the supported SASL
              authentication mecanisms by the receiver.
  @result An array of NSString instances which indicates
          what SASL mechanisms are supported.
*/
- (NSArray *) supportedMechanisms;

/*!
  @method isConnected
  @discussion This method is used to verify if the receiver
              is connected to the server.
  @result YES if connected, NO otherwise.
*/
- (BOOL) isConnected;

/*!
  @method authenticate: password: mechanism:
  @discussion This method is used to authentifcate the receiver
              to the server. This method posts a PantomimeAuthenticationCompleted
	      (or calls the -authenticationCompleted: method on the delegate, if any)
	      if the authentication is sucessful. If not, it posts the
	      PantomimeAuthenticationFailed notification (or calls the
	      -authenticationFailed: method on the delegate, if any). This method
	      is fully asynchronous.
  @param theUsername The username to use, overwriting -username: if any.
  @param thePassword The password to use.
  @param theMechanism The authentication mechanism to use.
*/
- (void) authenticate: (NSString *) theUsername
             password: (NSString *) thePassword
            mechanism: (NSString *) theMechanism;

/*!
  @method cancelRequest
  @discussion This method will cancel any pending requests or communications
              with the server and close the connection. It'll post a
	      PantomimeRequestCancelled once it has fully cancelled everything.
	      This method is fully asynchronous.
*/
- (void) cancelRequest;

/*!
  @method close
  @discussion This method is used to close the connection to the server.
              If the receiver is not in a connected state, it does nothing.
	      If it is, it posts a PantomimeConnectionTerminated notification
	      once it has completed and invokes -connectionTerminated: on the
	      delegate, if any.
*/
- (void) close;

/*!
  @method connect
  @discussion This method is used to connect the receiver to the server.
              It will block until the connection was succefully established
	      (or until it fails).
  @result 0 on success, -1 on error.
*/
- (int) connect;

/*!
  @method connectInBackgroundAndNotify
  @discussion This method is used  connect the receiver to the server.
              The call to this method is non-blocking. This method will
	      post a PantomimeConnectionEstablished notification once
	      the connection has been establish (and call -connectionEstablished:
	      on the delegate, if any). Otherwise, it will post a PantomimeConnectionTimedOut
	      notification (and call -connectionTimedOut: on the delegate, if any).
*/
- (void) connectInBackgroundAndNotify;

/*!
  @method noop
  @discussion This method is used to generate some traffic on a server
              so the connection doesn't idle and gets terminated by
	      the server. Subclasses of CWService need to implement this method.
*/
- (void) noop;

/*!
  @method receivedEvent: type: extra: forMode:
  @discussion This method is automatically invoked when the receiver can
              either read or write bytes to its underlying CWConnection
	      instance. Never call this method directly.
  @param theData The file descriptor.
  @param theType The type of event that occured.
  @param theExtra Additional information.
  @param theMode The runloop modes.
*/
- (void) receivedEvent: (void *) theData
                  type: (RunLoopEventType) theType
                 extra: (void *) theExtra
               forMode: (NSString *) theMode;

/*!
  @method reconnect
  @discussion Pending.
  @result Pending.
*/       
- (int) reconnect;

/*!
  @method updateRead
  @discussion This method is invoked automatically when bytes are available
              to be read. You should never have to invoke this method directly.
*/
- (void) updateRead;

/*!
  @method updateWrite
  @discussion This method is invoked automatically when bytes are available
              to be written. You should never have to invoke this method directly.
*/
- (void) updateWrite;

/*!
  @method writeData:
  @discussion This method is used to buffer bytes to be written on the socket.
              You should never have to invoke this method directly.
  @param The bytes to buffer, as a NSData instance.
*/
- (void) writeData: (NSData *) theData;

/*!
  @method addRunLoopMode:
  @discussion This method is used to add an additional mode that the run-loop
              will use to listen for network events for reading and writing.
              Note that this method does nothing on OS X since only the
	      kCFRunLoopCommonModes mode is used.
  @param The additional mode. NSDefaultRunLoopMode is always present so there
         is no need to add it.
*/
- (void) addRunLoopMode: (NSString *) theMode;

/*!
  @method connectionTimeout
  @discussion This method is used to get the timeout used when
              connecting to the host.
  @result The connecton timeout.
*/
- (unsigned int) connectionTimeout;

/*!
  @method setConnectionTimeout:
  @discussion This method is used to set the timeout used when
              connecting to the host.
  @param theConnectionTimeout The timeout to use.
*/
- (void) setConnectionTimeout: (unsigned int) theConnectionTimeout;

/*!
  @method readTimeout
  @discussion This method is used to get the timeout used when
              reading bytes from the socket.
  @result The read timeout.
*/
- (unsigned int) readTimeout;

/*!
  @method setReadTimeout
  @discussion This method is used to set the timeout used when
              reading bytes from the socket.
  @param The timeout to use.
*/
- (void) setReadTimeout: (unsigned int) theReadTimeout;

/*!
  @method writeTimeout
  @discussion This method is used to get the timeout used when
              writing bytes from the socket.
  @result The write timeout.
*/
- (unsigned int) writeTimeout;

/*!
  @method setWriteTimeout
  @discussion This method is used to set the timeout used when
              writing bytes from the socket.
  @param The timeout to use.
*/
- (void) setWriteTimeout: (unsigned int) theWriteTimeout;

/*!
  @method startTLS
  @discussion This method is used to activate TLS over
              a non-secure connection. This method can
	      be called in the -serviceInitialized:
	      delegate method. The latter will be invoked
	      again once TLS has been activated successfully.
*/
- (void) startTLS;

/*!
  @method lastCommand
  @discussion This method is used to get the last command that
              has been sent by CWService subclasses to the
	      remote server. To know which commands can be
	      sent, see the documentation of the associated
	      subclasses.
  @result The last command sent, 0 otherwise.
*/
- (unsigned int) lastCommand;


/*!
  @method capabilities
  @discussion This method is used to obtain the capabilities of the
              associated service.
  @result The capabilities, as an array of NSString instances.
*/
- (NSArray *) capabilities;

@end

#endif // _Pantomime_H_CWService
