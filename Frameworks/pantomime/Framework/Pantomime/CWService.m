/*
**  CWService.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2018      Riccardo Mottola
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

#import <Pantomime/CWService.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWTCPConnection.h>
#import <Pantomime/NSData+Extensions.h>

#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSPathUtilities.h>

#include <stdlib.h>
#include <string.h>

//
// It's important that the read buffer be bigger than the PMTU. Since almost all networks
// permit 1500-byte packets and few permit more, the PMTU will generally be around 1500.
// 2k is fine, 4k accomodates FDDI (and HIPPI?) networks too.
//
#define NET_BUF_SIZE 4096 

//
// We set the size increment of blocks we will write. Under Mac OS X, we use 1024 bytes
// in order to avoid a strange bug in SSL_write. This prevents us from no longer beeing
// notified after a couple of writes that we can actually write data!
//
#define WRITE_BLOCK_SIZE 1024


//
// Default timeout used when waiting for something to complete.
//
#define DEFAULT_TIMEOUT 60

//
// Service's private interface.
//
@interface CWService (Private)

- (int) _addWatchers;
- (void) _removeWatchers;
- (void) _connectionTick: (id) sender;
- (void) _queueTick: (id) sender;

@end


//
// OS X's implementation of the GNUstep RunLoop Extensions
//
#ifdef MACOSX
static NSMapTable *fd_to_cfsocket;

void socket_callback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void* data, void* info)
{
  if (type&kCFSocketWriteCallBack)
    {
      [(CWService *)info receivedEvent: (void*)CFSocketGetNative(s)
	  	  type: ET_WDESC
		  extra: 0
		  forMode: nil];
    }
  if (type&kCFSocketReadCallBack)
    {
      [(CWService *)info receivedEvent: (void*)CFSocketGetNative(s)
		  type: ET_RDESC
		  extra: 0
		  forMode: nil];
    }
}

@interface NSRunLoop (PantomimeRunLoopExtensions)
- (void) addEvent: (void *) data
             type: (RunLoopEventType) type
          watcher: (id) watcher
          forMode: (NSString *) mode;
- (void) removeEvent: (void *) data
                type: (RunLoopEventType) type
	     forMode: (NSString *) mode
		 all: (BOOL) removeAll; 
@end

@implementation NSRunLoop (PantomimeRunLoopExtensions)

- (void) addEvent: (void *) data
             type: (RunLoopEventType) type
          watcher: (id) watcher
          forMode: (NSString *) mode
{
  CFSocketRef socket;
  
  socket = (CFSocketRef)NSMapGet(fd_to_cfsocket, data);
  
  // We prevent dealing with callbacks when the socket is NOT
  // in a connected state. This can happen, under OS X, if
  // we call -addEvent: type: watcher: forMode: but the
  // connection hasn't yet been established. If it hasn't been
  // established, -_addWatchers: was not called so the fd is
  // NOT in our map table.
  if (!socket)
    {
      return;
    }

  switch (type)
    {
    case ET_RDESC:
      CFSocketEnableCallBacks(socket, kCFSocketReadCallBack);
      break;
    case ET_WDESC:
      CFSocketEnableCallBacks(socket, kCFSocketWriteCallBack);
      break;
    default:
      break;
    }
}

- (void) removeEvent: (void *) data
                type: (RunLoopEventType) type
	     forMode: (NSString *) mode
		 all: (BOOL) removeAll
{
  CFSocketRef socket;
  
  socket = (CFSocketRef)NSMapGet(fd_to_cfsocket, data);
  
  // See the description in -addEvent: type: watcher: forMode:.
  if (!socket)
    {
      return;
    }

  switch (type)
    {
    case ET_RDESC:
      CFSocketDisableCallBacks(socket, kCFSocketReadCallBack);
      break;
    case ET_WDESC:
      CFSocketDisableCallBacks(socket, kCFSocketWriteCallBack);
      break;
    default:
      break;
    }
}

@end
#endif // MACOSX


//
//
//
@implementation CWService

#ifdef MACOSX
+ (void) initialize
{
  fd_to_cfsocket = NSCreateMapTable(NSIntMapKeyCallBacks, NSIntMapValueCallBacks, 16);  
}
#endif


//
//
//
- (id) init
{
  self = [super init];
  if (self)
    {
      _supportedMechanisms = [[NSMutableArray alloc] init];
      _responsesFromServer = [[NSMutableArray alloc] init];
      _capabilities = [[NSMutableArray alloc] init];
      _queue = [[NSMutableArray alloc] init];
      _username = nil;
      _password = nil;


      _rbuf = [[NSMutableData alloc] init];
      _wbuf = [[NSMutableData alloc] init];

      _runLoopModes = [[NSMutableArray alloc] initWithObjects: NSDefaultRunLoopMode, nil];
      _connectionTimeout = _readTimeout = _writeTimeout = DEFAULT_TIMEOUT;
      _counter = _lastCommand = 0;
      _connection = nil;
      
      _connection_state.previous_queue = [[NSMutableArray alloc] init];
      _connection_state.reconnecting = _connection_state.opening_mailbox = NO;
    }
  
  return self;
}


//
//
//
- (id) initWithName: (NSString *) theName
               port: (unsigned int) thePort
{
  self = [self init];
  if (self)
    {
      [self setName: theName];
      [self setPort: thePort];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  //NSLog(@"Service: -dealloc");
  [self setDelegate: nil];

  RELEASE(_supportedMechanisms);
  RELEASE(_responsesFromServer);
  RELEASE(_capabilities);

  RELEASE(_queue);

  RELEASE(_rbuf);
  RELEASE(_wbuf);

  TEST_RELEASE(_mechanism);
  TEST_RELEASE(_username);
  TEST_RELEASE(_password);
  RELEASE(_name);
  
  TEST_RELEASE((id<NSObject>)_connection);
  RELEASE(_runLoopModes);

  RELEASE(_connection_state.previous_queue);

  [super dealloc];
}


//
// access / mutation methods
//
- (void) setDelegate: (id) theDelegate
{
  _delegate = theDelegate;
}

- (id) delegate
{
  return _delegate;
}


//
//
//
- (NSString *) name
{
  return _name;
}

- (void) setName: (NSString *) theName
{
  ASSIGN(_name, theName);
}


//
//
//
- (unsigned int) port
{
  return _port;
}

- (void) setPort: (unsigned int) thePort
{
  _port = thePort;
}


//
//
//
- (id<CWConnection>) connection
{
  return _connection;
}


//
//
//
- (NSArray *) supportedMechanisms
{
  return [NSArray arrayWithArray: _supportedMechanisms];
}


//
//
//
- (NSString *) username
{
  return _username;
}

- (void) setUsername: (NSString *) theUsername
{
  ASSIGN(_username, theUsername);
}


//
//
//
- (BOOL) isConnected
{
  return _connected;
}


//
// Other methods
//
- (void) authenticate: (NSString *) theUsername
             password: (NSString *) thePassword
            mechanism: (NSString *) theMechanism
{
  [self subclassResponsibility: _cmd];
}


//
//
//
- (void) cancelRequest
{
  // If we were in the process of establishing
  // a connection, let's stop our internal timer.
  [_timer invalidate];
  DESTROY(_timer);

  [self _removeWatchers];
  [_connection close];
  DESTROY(_connection);
  [_queue removeAllObjects];

  POST_NOTIFICATION(PantomimeRequestCancelled, self, nil);
  PERFORM_SELECTOR_1(_delegate, @selector(requestCancelled:), PantomimeRequestCancelled);
}


//
//
//
- (void) close
{
  //
  // If we are reconnecting, no matter what, we close and release our current connection immediately.
  // We do that since we'll create a new on in -connect/-connectInBackgroundAndNotify. No need
  // to return immediately since _connected will be set to NO in _removeWatchers.
  //
  if (_connection_state.reconnecting)
    {
      [self _removeWatchers];
      [_connection close];
      DESTROY(_connection);
    }

  if (_connected)
    {
      [self _removeWatchers];
      [_connection close];

      POST_NOTIFICATION(PantomimeConnectionTerminated, self, nil);
      PERFORM_SELECTOR_1(_delegate, @selector(connectionTerminated:), PantomimeConnectionTerminated);
    }
}

// 
// If the connection or binding succeeds, zero  is  returned.
// On  error, -1 is returned, and errno is set appropriately
//
- (int) connect
{
  _connection = [[CWTCPConnection alloc] initWithName: _name
					 port: _port
					 background: NO];
  if (!_connection)
    {
      return -1;
    }
  return [self _addWatchers];
}


//
//
//
- (void) connectInBackgroundAndNotify
{
  NSUInteger i;

  _connection = [[CWTCPConnection alloc] initWithName: _name
					 port: _port
					 background: YES];

  if (!_connection)
    {
      POST_NOTIFICATION(PantomimeConnectionTimedOut, self, nil);
      PERFORM_SELECTOR_1(_delegate, @selector(connectionTimedOut:),  PantomimeConnectionTimedOut);
      return;
    }

  _timer = [NSTimer timerWithTimeInterval: 0.1
		    target: self
		    selector: @selector(_connectionTick:)
		    userInfo: nil
		    repeats: YES];
  RETAIN(_timer);

  for (i = 0; i < [_runLoopModes count]; i++)
    {
      [[NSRunLoop currentRunLoop] addTimer: _timer  forMode: [_runLoopModes objectAtIndex: i]];
    }

  [_timer fire];
}


//
//
//
- (void) noop
{
  [self subclassResponsibility: _cmd];
}


//
//
//
- (void) updateRead
{
  char buf[NET_BUF_SIZE];
  ssize_t count;
  
  while ((count = [_connection read: buf  length: NET_BUF_SIZE]) > 0)
    {
      NSData *aData;

      aData = [[NSData alloc] initWithBytes: buf  length: (NSUInteger)count];

      if (_delegate && [_delegate respondsToSelector: @selector(service:receivedData:)])
	{
	  [_delegate performSelector: @selector(service:receivedData:)
		     withObject: self
		     withObject: aData];  
	}

      [_rbuf appendData: aData];
      RELEASE(aData);
    }

  if (count == 0)
    {
      //
      // We check to see if we got disconnected.
      //
      // The data that causes select to return is the EOF because the other side
      // has closed the connection. This causes read to return zero. 
      //
      if (!((CWTCPConnection *)_connection)->ssl_handshaking && _connected)
	{
	  [self _removeWatchers];
	  [_connection close];
	  POST_NOTIFICATION(PantomimeConnectionLost, self, nil);
	  PERFORM_SELECTOR_1(_delegate, @selector(connectionLost:),  PantomimeConnectionLost);
	}
    }
  else
    {
      // We reset our connection timeout counter. This could happen when we are performing operations
      // that return a large amount of data. The queue might be non-empty but network I/O could be
      // going on at the same time. This could also be problematic for lenghty IMAP search or
      // mailbox preload.
      _counter = 0;
    }
}
 
 
//
//
//
- (void) updateWrite
{
  if ([_wbuf length] > 0)
    {
      char *bytes;
      NSUInteger len;
      NSInteger count;
      NSUInteger i;

      bytes = (char *)[_wbuf mutableBytes];
      len = [_wbuf length];

#ifdef MACOSX
      count = [_connection write: bytes  length: len > WRITE_BLOCK_SIZE ? WRITE_BLOCK_SIZE : len];
#else
      count = [_connection write: bytes  length: len];
#endif
      // If nothing was written or if an error occured, we return.
      if (count <= 0)
	{
	  return;
	}
      // Otherwise, we inform our delegate that we wrote some data...
      else if (_delegate && [_delegate respondsToSelector: @selector(service:sentData:)])
	{
	  [_delegate performSelector: @selector(service:sentData:)
		     withObject: self
		     withObject: [_wbuf subdataToIndex: (NSUInteger)count]];
	}
      
      //NSLog(@"count = %d, len = %d", count, len);

      // If we have been able to write everything...
      if (count == len)
	{
	  [_wbuf setLength: 0];
#ifndef __MINGW32__
	  // If we are done writing, let's remove the watcher on our fd.
	  for (i = 0; i < [_runLoopModes count]; i++)
	    {
	      [[NSRunLoop currentRunLoop] removeEvent: (void *)[_connection fd]
					  type: ET_WDESC
					  forMode: [_runLoopModes objectAtIndex: i]
					  all: YES];
	    }
#endif
	}
      else
	{
	  memmove(bytes, bytes+count, len-count);
	  [_wbuf setLength: len-count];
      
	  // We enable the write callback under OS X.
	  // See the rationale in -writeData:
#ifdef MACOSX
	  for (i = 0; i < [_runLoopModes count]; i++)
	    {
	      [[NSRunLoop currentRunLoop] addEvent: (void *)[_connection fd]
					  type: ET_WDESC
					  watcher: self
					  forMode: [_runLoopModes objectAtIndex: i]];
	    }
#endif
	}
    }
}


//
//
//
- (void) writeData: (NSData *) theData
{
  if (theData && [theData length])
    {
      NSUInteger i;

      [_wbuf appendData: theData];

      //
      // Let's not try to enable the write callback if we are not connected
      // There's no reason to try to enable the write callback if we
      // are not connected.
      //
      if (!_connected)
	{
	  return;
	}
      
      //
      // We re-enable the write callback.
      //
      // Rationale from OS X's CoreFoundation:
      //
      // By default kCFSocketReadCallBack, kCFSocketAcceptCallBack, and kCFSocketDataCallBack callbacks are
      // automatically reenabled, whereas kCFSocketWriteCallBack callbacks are not; kCFSocketConnectCallBack
      // callbacks can only occur once, so they cannot be reenabled. Be careful about automatically reenabling
      // read and write callbacks, because this implies that the callbacks will be sent repeatedly if the socket
      // remains readable or writable respectively. Be sure to set these flags only for callback types that your
      // CFSocket actually possesses; the result of setting them for other callback types is undefined.
      //
#ifndef __MINGW32__
      for (i = 0; i < [_runLoopModes count]; i++)
	{
	  [[NSRunLoop currentRunLoop] addEvent: (void *)[_connection fd]
				      type: ET_WDESC
				      watcher: self
				      forMode: [_runLoopModes objectAtIndex: i]];
	}
#endif
    }
}


//
// RunLoopEvents protocol's implementations.
//
- (void) receivedEvent: (void *) theData
                  type: (RunLoopEventType) theType
                 extra: (void *) theExtra
               forMode: (NSString *) theMode
{
  AUTORELEASE(RETAIN(self));    // Don't be deallocated while handling event
  switch (theType)
    {
#ifdef __MINGW32__
    case ET_HANDLE:
    case ET_TRIGGER:
      [self updateRead];
      [self updateWrite];
      break;
#else
    case ET_RDESC:
      [self updateRead];
      break;

    case ET_WDESC:
      [self updateWrite];
      break;

    case ET_EDESC:
      //NSLog(@"GOT ET_EDESC! %d  current fd = %d", theData, [_connection fd]);
      break;
#endif

    default:
      break;
    }
}


//
//
//
- (int) reconnect
{
  [self subclassResponsibility: _cmd];
  return 0;
}


//
//
//
- (NSDate *) timedOutEvent: (void *) theData
		      type: (RunLoopEventType) theType
		   forMode: (NSString *) theMode
{
  //NSLog(@"timed out event!");
  return nil;
}


//
//
//
- (void) addRunLoopMode: (NSString *) theMode
{
#ifndef MACOSX
  if (theMode && ![_runLoopModes containsObject: theMode])
    {
      [_runLoopModes addObject: theMode];
    }
#endif
}


//
//
//
- (unsigned int) connectionTimeout
{
  return _connectionTimeout;
}

- (void) setConnectionTimeout: (unsigned int) theConnectionTimeout
{
  _connectionTimeout = (theConnectionTimeout > 0 ? theConnectionTimeout : DEFAULT_TIMEOUT);
}

- (unsigned int) readTimeout
{
  return _readTimeout;
}

- (void) setReadTimeout: (unsigned int) theReadTimeout
{
  _readTimeout = (theReadTimeout > 0 ? theReadTimeout: DEFAULT_TIMEOUT);
}

- (unsigned int) writeTimeout
{
  return _writeTimeout;
}

- (void) setWriteTimeout: (unsigned int) theWriteTimeout
{
  _writeTimeout = (theWriteTimeout > 0 ? theWriteTimeout : DEFAULT_TIMEOUT);
}

- (void) startTLS
{
  [self subclassResponsibility: _cmd];
}

- (unsigned int) lastCommand
{
  return _lastCommand;
}

- (NSArray *) capabilities
{
  return _capabilities;
}

@end

//
//
//
@implementation CWService (Private)


//
// This methods adds watchers on a file descriptor.
// It returns 0 if it has completed successfully.
//
- (int) _addWatchers
{
  NSUInteger i;

  //
  // Under Mac OS X, we must also create a CFSocket and a runloop source in order
  // to enabled callbacks write read/write availability.
  //
#ifdef MACOSX 
  _context = (CFSocketContext *)malloc(sizeof(CFSocketContext));
  memset(_context, 0, sizeof(CFSocketContext));
  _context->info = self;
  
  _socket = CFSocketCreateWithNative(NULL, [_connection fd], kCFSocketReadCallBack|kCFSocketWriteCallBack, socket_callback, _context);
  CFSocketDisableCallBacks(_socket, kCFSocketReadCallBack|kCFSocketWriteCallBack);
  
  if (!_socket)
    {
      //NSLog(@"Failed to create CFSocket from native.");
      return -1;
    }
  
  _runLoopSource = CFSocketCreateRunLoopSource(NULL, _socket, 1);
  
  if (!_runLoopSource)
    {
      //NSLog(@"Failed to create the runloop source.");
      return -1;
    }
  
  CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
  NSMapInsert(fd_to_cfsocket, (void *)[_connection fd], (void *)_socket);
#endif

  // We get ready to monitor for read/write timeouts
  _timer = [NSTimer timerWithTimeInterval: 1
		    target: self
		    selector: @selector(_queueTick:)
		    userInfo: nil
		    repeats: YES];
  RETAIN(_timer);
  _counter = 0;

  //NSLog(@"Adding watchers on %d", [_connection fd]);

  for (i = 0; i < [_runLoopModes count]; i++)
    {
      [[NSRunLoop currentRunLoop] addEvent: (void *)[_connection fd]
#ifdef __MINGW32__
				  type: ET_HANDLE
#else
                                  type: ET_RDESC
#endif
				  watcher: self
				  forMode: [_runLoopModes objectAtIndex: i]];
      
      [[NSRunLoop currentRunLoop] addEvent: (void *)[_connection fd]
#ifdef __MINGW32__
				  type: ET_TRIGGER
#else
                                  type: ET_EDESC
#endif
				  watcher: self
				  forMode: [_runLoopModes objectAtIndex: i]];

      [[NSRunLoop currentRunLoop] addTimer: _timer  forMode: [_runLoopModes objectAtIndex: i]];
    }
  
  _connected = YES;
  POST_NOTIFICATION(PantomimeConnectionEstablished, self, nil);
  PERFORM_SELECTOR_1(_delegate, @selector(connectionEstablished:),  PantomimeConnectionEstablished);

  [_timer fire];
  return 0;
}


//
//
//
- (void) _removeWatchers
{
  NSUInteger i;
  
  //
  // If we are not connected, no need to remove the watchers on our file descriptor.
  // This could also generate a crash under OS X as the _runLoopSource, _socket etc.
  // ivars aren't initialized.
  //
  if (!_connected)
    {
      return;
    }

  [_timer invalidate];
  DESTROY(_timer);
  _connected = NO;

  //NSLog(@"Removing all watchers on %d...", [_connection fd]);
  
  for (i = 0; i < [_runLoopModes count]; i++)
    {
#ifdef __MINGW32__
      [[NSRunLoop currentRunLoop] removeEvent: (void *)[_connection fd]
                                  type: ET_HANDLE
                                  forMode: [_runLoopModes objectAtIndex: i]
                                  all: YES];
    
      [[NSRunLoop currentRunLoop] removeEvent: (void *)[_connection fd]
                                  type: ET_TRIGGER
                                  forMode: [_runLoopModes objectAtIndex: i]
                                  all: YES];
#else
      [[NSRunLoop currentRunLoop] removeEvent: (void *)[_connection fd]
				  type: ET_RDESC
				  forMode: [_runLoopModes objectAtIndex: i]
				  all: YES];
      
      [[NSRunLoop currentRunLoop] removeEvent: (void *)[_connection fd]
				  type: ET_WDESC
				  forMode: [_runLoopModes objectAtIndex: i]
				  all: YES];
      
      [[NSRunLoop currentRunLoop] removeEvent: (void *)[_connection fd]
				  type: ET_EDESC
				  forMode: [_runLoopModes objectAtIndex: i]
				  all: YES];
#endif
    }
    
#ifdef MACOSX
  if (CFRunLoopSourceIsValid(_runLoopSource))
    {
      CFRunLoopSourceInvalidate(_runLoopSource);
      CFRelease(_runLoopSource);
    }

  if (CFSocketIsValid(_socket))
    {
      CFSocketInvalidate(_socket);
    }

  NSMapRemove(fd_to_cfsocket, (void *)[_connection fd]);
  CFRelease(_socket);
  free(_context);
#endif
}

//
//
//
- (void) _connectionTick: (id) sender
{
  if ((_counter/10) == _connectionTimeout)
    {
      [_timer invalidate];
      DESTROY(_timer);

      POST_NOTIFICATION(PantomimeConnectionTimedOut, self, nil);
      PERFORM_SELECTOR_1(_delegate, @selector(connectionTimedOut:), PantomimeConnectionTimedOut);
      return;
    }

  if ([_connection isConnected])
    {
      [_timer invalidate];
      DESTROY(_timer);
      [self _addWatchers];
      return;
    }

   _counter++;
}

//
//
//
- (void) _queueTick: (id) sender
{
  if ([_queue count])
    {
      if (_counter == _readTimeout)
	{
	  NSLog(@"Waited %d secs, read/write timeout", _readTimeout);
	  [_timer invalidate];
	  DESTROY(_timer);
	  POST_NOTIFICATION(PantomimeConnectionTimedOut, self, nil);
	  PERFORM_SELECTOR_1(_delegate, @selector(connectionTimedOut:), PantomimeConnectionTimedOut);
	}

      _counter++;
    }
  else
    {
      _counter = 0;
    }
}

@end
