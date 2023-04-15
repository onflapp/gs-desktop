/***************************************************************************
                                NetTCP.m
                          -------------------
    begin                : Fri Nov  2 01:19:16 UTC 2001
    copyright            : (C) 2005 by Andrew Ruder
                         : (C) 2015-2016 The GAP Team
    email                : aeruder@ksu.edu
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Lesser General Public License as        *
 *   published by the Free Software Foundation; either version 2.1 of the  *
 *   License or (at your option) any later version.                        *
 *                                                                         *
 ***************************************************************************/
/**
 * <title>NetTCP reference</title>
 * <author name="Andrew Ruder">
 * 	<email address="aeruder@ksu.edu" />
 * 	<url url="http://www.aeruder.net" />
 * </author>
 * <version>Revision 1</version>
 * <date>November 8, 2003</date>
 * <copy>Andrew Ruder</copy>
 */

#include "config.h"

#import "NetTCP.h"
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSException.h>
#import <Foundation/NSHost.h>

#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <sys/time.h>

#ifndef HAVE_SOCKLEN_T 
typedef int socklen_t;
#endif

NSString *NetclassesErrorTimeout = @"Connection timed out";
NSString *NetclassesErrorBadAddress = @"Bad address";
NSString *NetclassesErrorAborted = @"Connection aborted";

static TCPSystem *default_system = nil;

@interface TCPSystem (InternalTCPSystem)
- (int)openPort: (uint16_t)portNumber;
- (int)openPort: (uint16_t)portNumber onHost: (NSHost *)aHost;

- (int)connectToHost: (NSHost *)aHost onPort: (uint16_t)portNumber
         withTimeout: (int)timeout inBackground: (BOOL)background;

- setErrorString: (NSString *)anError withErrno: (int)aErrno;
@end

@interface TCPConnecting (InternalTCPConnecting)
- initWithNetObject: (id <NetObject>)netObject withTimeout: (int)aTimeout;
- connectingFailed: (NSString *)error;
- connectingSucceeded;
- timeoutReceived: (NSTimer *)aTimer;
@end
	
@interface TCPConnectingTransport : NSObject < NetTransport >
	{
		BOOL connected;
		int desc;
		NSHost *remoteHost;
		NSHost *localHost;
		NSMutableData *writeBuffer;
		TCPConnecting *owner;	
	}
- (NSMutableData *)writeBuffer;

- (id)initWithDesc: (int)aDesc withRemoteHost: (NSHost *)theAddress
     withOwner: (TCPConnecting *)anObject;
	 
- (void)close;

- (NSData *)readData: (int)maxDataSize;
- (BOOL)isDoneWriting;
- (id <NetTransport>)writeData: (NSData *)data;

- (NSHost *)remoteHost;
- (NSHost *)localHost;
- (int)desc;
@end

@implementation TCPConnectingTransport
- (NSMutableData *)writeBuffer
{
	return writeBuffer;
}
- (id)initWithDesc: (int)aDesc withRemoteHost: (NSHost *)theAddress 
     withOwner: (TCPConnecting *)anObject
{
	struct sockaddr_in x;
	socklen_t address_length = sizeof(x);
	
	if (!(self = [super init])) return nil;
	
	desc = aDesc;

	writeBuffer = [NSMutableData new];
	remoteHost = RETAIN(theAddress);
		
	owner = anObject;
	
	if (getsockname(desc, (struct sockaddr *)&x, &address_length) != 0) 
	{
		[[TCPSystem sharedInstance]
		  setErrorString: [NSString stringWithFormat: @"%s",
		  strerror(errno)] withErrno: errno];
		[self release];
		return nil;
	}
	connected = YES;
	
	localHost = RETAIN([[TCPSystem sharedInstance] 
	  hostFromNetworkOrderInteger: x.sin_addr.s_addr]);
	
	return self;
}
- (void)dealloc
{
	[self close];
	
	RELEASE(writeBuffer);
	RELEASE(remoteHost);
	RELEASE(localHost);

	[super dealloc];
}
- (NSData *)readData: (int)maxDataSize
{
	return nil;
}
- (BOOL)isDoneWriting
{
	return YES;
}
- (id <NetTransport>)writeData: (NSData *)data
{
	char buffer[1];
	if (data)
	{
		[writeBuffer appendData: data];
		return self;
	}
	
	if (recv(desc, buffer, sizeof(buffer), MSG_PEEK) == -1)
	{
		if (errno != EAGAIN)
		{
			[owner connectingFailed: [NSString stringWithFormat: @"%s", 
			  strerror(errno)]];
			return self;
		}
	}
	
	[owner connectingSucceeded];
	return self;
}
- (NSHost *)remoteHost
{
	return remoteHost;
}
- (NSHost *)localHost
{
	return localHost;
}
- (int)desc
{
	return desc;
}
- (void)close
{
	if (!connected)
		return;
	close(desc);
	connected = NO;
}
@end

@implementation TCPConnecting (InternalTCPConnecting)
- initWithNetObject: (id <NetObject>)aNetObject withTimeout: (int)aTimeout
{
	if (!(self = [super init])) return nil;
	
	netObject = RETAIN(aNetObject);
	if (aTimeout > 0)
	{
		timeout = RETAIN([NSTimer scheduledTimerWithTimeInterval:
		    (NSTimeInterval)aTimeout
		  target: self selector: @selector(timeoutReceived:)
		  userInfo: nil repeats: NO]);
	}
		
	return self;
}
- connectingFailed: (NSString *)error
{
	if ([netObject conformsToProtocol: @protocol(TCPConnecting)])
	{
		[netObject connectingFailed: error];
	}
	[timeout invalidate];
	[transport close];
	[[NetApplication sharedInstance] disconnectObject: self];

	return self;
}
- connectingSucceeded
{
  TCPTransport *newTrans;
  NSMutableData *buffer;
  
  newTrans = [[TCPTransport alloc] initWithDesc:
                                     dup([transport desc])
                                 withRemoteHost: [transport remoteHost]];
  [newTrans autorelease];
  
  buffer = [(TCPConnectingTransport *)transport writeBuffer];
  [buffer retain];
  [timeout invalidate];
  
  [[NetApplication sharedInstance] disconnectObject: self];
  [netObject connectionEstablished: newTrans];
  
  [newTrans writeData: buffer];
  RELEASE(buffer);
  
  return self;
}

- timeoutReceived: (NSTimer *)aTimer
{	
	if (aTimer != timeout)
	{
		[aTimer invalidate];
	}
	[self connectingFailed: NetclassesErrorTimeout];
	
	return self;
}
@end

@implementation TCPConnecting
- (void)dealloc
{
	RELEASE(netObject);
	RELEASE(timeout);
	
	[super dealloc];
}
- (id <NetObject>)netObject
{
	return netObject;
}
- (void)abortConnection
{
	[self connectingFailed: NetclassesErrorAborted];
}
- (void)connectionLost
{
	DESTROY(transport);
}
- connectionEstablished: (id <NetTransport>)aTransport
{
	transport = RETAIN(aTransport);	
	[[NetApplication sharedInstance] connectObject: self];
	[[NetApplication sharedInstance] transportNeedsToWrite: transport];
	if ([netObject conformsToProtocol: @protocol(TCPConnecting)])
	{
		[netObject connectingStarted: self];
	}
	return self;
}
- (id <NetObject>)dataReceived: (NSData *)data
{
	return self;
}
- (id <NetTransport>)transport
{
	return transport;
}
@end

@implementation TCPSystem (InternalTCPSystem)
- (int)openPort: (uint16_t)portNumber
{
	return [self openPort: portNumber onHost: nil];
}
- (int)openPort: (uint16_t)portNumber onHost: (NSHost *)aHost
{
	struct sockaddr_in sin;
	int temp;
	int myDesc;
	
	memset(&sin, 0, sizeof(struct sockaddr_in));
	
	if (!aHost)
	{
		sin.sin_addr.s_addr = htonl(INADDR_ANY);
	}
	else
	{
		if (inet_aton([[aHost address] cString], 
		    (struct in_addr *)(&(sin.sin_addr))) == 0)
		{
			[self setErrorString: NetclassesErrorBadAddress withErrno: 0];
			return -1;
		}	      
	}
	
	sin.sin_port = htons(portNumber);
	sin.sin_family = AF_INET;
	
	if ((myDesc = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		[self setErrorString: [NSString stringWithFormat: @"%s", 
		  strerror(errno)] withErrno: errno];
		return -1;
	}
	temp = 1;
	if (setsockopt(myDesc, SOL_SOCKET, SO_REUSEADDR, 
	               &temp, sizeof(temp)) == -1)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat: @"%s",
		  strerror(errno)] withErrno: errno];
		return -1;
	}
	if (bind(myDesc, (struct sockaddr *) &sin, sizeof(struct sockaddr)) < 0)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat: @"%s",
		  strerror(errno)] withErrno: errno];
		return -1;
	}
	temp = 1;
	if (setsockopt(myDesc, SOL_SOCKET, SO_KEEPALIVE, 
	               &temp, sizeof(temp)) == -1)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat: @"%s",
		  strerror(errno)] withErrno: errno];
		return -1;
	}
	if (listen(myDesc, 5) == -1)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat: @"%s",
		  strerror(errno)] withErrno: errno];
		return -1;
	}

	return myDesc;
}
- (int)connectToHost: (NSHost *)host onPort: (uint16_t)portNumber 
       withTimeout: (int)timeout inBackground: (BOOL)bck
{
	int myDesc;
	struct sockaddr_in destAddr;

	if (!host)
	{
		[self setErrorString: NetclassesErrorBadAddress withErrno: 0];
		return -1;
	}
	
	if ((myDesc = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		[self setErrorString: [NSString stringWithFormat: @"%s",
		  strerror(errno)] withErrno: errno];
		return -1;
	}

	destAddr.sin_family = AF_INET;
	destAddr.sin_port = htons(portNumber);
	if (!(inet_aton([[host address] cString], 
	    (struct in_addr *)(&destAddr.sin_addr))))
	{
		[self setErrorString: [NSString stringWithFormat: @"%s",
		  strerror(errno)] withErrno: errno];
		close(myDesc);
		return -1;
	}
	memset(&(destAddr.sin_zero), 0, sizeof(destAddr.sin_zero));

	if (timeout > 0 || bck)
	{
		if (fcntl(myDesc, F_SETFL, O_NONBLOCK) == -1)
		{
			[self setErrorString: [NSString stringWithFormat: @"%s",
			  strerror(errno)] withErrno: errno];
			close(myDesc);
			return -1;
		}
	}
	if (connect(myDesc, (struct sockaddr *)&destAddr, sizeof(destAddr)) == -1)
	{
		if (errno == EINPROGRESS) // Need to work with timeout now.
		{
			fd_set fdset;
			struct timeval selectTime;
			int selectReturn;

			if (bck)
			{
				return myDesc;
			}
			
			FD_ZERO(&fdset);
			FD_SET(myDesc, &fdset);

			selectTime.tv_sec = timeout;
			selectTime.tv_usec = 0;

			selectReturn = select(myDesc + 1, 0, &fdset, 0, &selectTime);

			if (selectReturn == -1)
			{
				[self setErrorString: [NSString stringWithFormat: @"%s",
				  strerror(errno)] withErrno: errno];
				close(myDesc);
				return -1;
			}
			if (selectReturn > 0)
			{
				char buffer[1];
				if (recv(myDesc, buffer, sizeof(buffer), MSG_PEEK) == -1)
				{
					if (errno != EAGAIN)
					{
						[self setErrorString: [NSString stringWithFormat: @"%s",
						  strerror(errno)] withErrno: errno];
						close(myDesc);
						return -1;
					}
				}
			}
			else
			{
				[self setErrorString: NetclassesErrorTimeout
				  withErrno: 0];
				close(myDesc);
				return -1;
			}
		}
		else // connect failed with something other than EINPROGRESS
		{
			[self setErrorString: [NSString stringWithFormat: @"%s",
			  strerror(errno)] withErrno: errno];
			close(myDesc);
			return -1;
		}
	}
	return myDesc;
}
- setErrorString: (NSString *)anError withErrno: (int)aErrno
{
	errorNumber = aErrno;
	
	if (anError == errorString) return self;

	RELEASE(errorString);
	errorString = RETAIN(anError);

	return self;
}
@end		
	
@implementation TCPSystem
+ sharedInstance
{
	return (default_system) ? default_system : [[self alloc] init];
}
- init
{
	if (!(self = [super init])) return nil;
	
	if (default_system)
	{
		[self release];
		return nil;
	}
	default_system = RETAIN(self);
	
	return self;
}
- (NSString *)errorString
{
	return errorString;
}
- (int)errorNumber
{
	return errorNumber;
}
- (id <NetObject>)connectNetObject: (id <NetObject>)netObject toHost: (NSHost *)aHost
                onPort: (uint16_t)aPort withTimeout: (int)aTimeout
{
	int desc;
	id transport;

	desc = [self connectToHost: aHost onPort: aPort withTimeout: aTimeout 
	  inBackground: NO];
	if (desc < 0)
	{
		return nil;
	}
	transport = AUTORELEASE([[TCPTransport alloc] initWithDesc: desc 
	 withRemoteHost: aHost]);
	
	if (!(transport))
	{
		close(desc);
		return nil;
	}

	[netObject connectionEstablished: transport];
	
	return netObject;
}
- (TCPConnecting *)connectNetObjectInBackground: (id <NetObject>)netObject 
    toHost: (NSHost *)aHost onPort: (uint16_t)aPort withTimeout: (int)aTimeout
{
	int desc;
	id transport;
	id object;

	desc = [self connectToHost: aHost onPort: aPort
	  withTimeout: 0 inBackground: YES];
	  
	if (desc < 0)
	{
		return nil;
	}
	
	object = AUTORELEASE([[TCPConnecting alloc] initWithNetObject: netObject
	   withTimeout: aTimeout]);
	transport = AUTORELEASE([[TCPConnectingTransport alloc] initWithDesc: desc 
	  withRemoteHost: aHost withOwner: object]);
	
	if (!transport)
	{
		close(desc);
		return nil;
	}
	
	[object connectionEstablished: transport];
	
	return object;
}
- (BOOL)hostOrderInteger: (uint32_t *)aNumber fromHost: (NSHost *)aHost
{
	struct in_addr addr;

	if (!aHost) return NO;
	if (![aHost address]) return NO;

	if (inet_aton([[aHost address] cString], &addr) != 0)
	{
		if (aNumber)
		{
			*aNumber = ntohl(addr.s_addr);
			return YES;
		}
	}

	return NO;
}
- (BOOL)networkOrderInteger: (uint32_t *)aNumber fromHost: (NSHost *)aHost
{
	struct in_addr addr;

	if (!aHost) return NO;
	if (![aHost address]) return NO;
	
	if (inet_aton([[aHost address] cString], &addr) != 0)
	{
		if (aNumber)
		{
			*aNumber = addr.s_addr;
			return YES;
		}
	}
	
	return NO;
}
- (NSHost *)hostFromNetworkOrderInteger: (uint32_t)ip
{
	struct in_addr addr;
	char *temp;
	
	addr.s_addr = ip;

	temp = inet_ntoa(addr);
	if (temp)
	{
		return [NSHost hostWithAddress: [NSString stringWithCString: temp]];
	}

	return nil;
}
- (NSHost *)hostFromHostOrderInteger: (uint32_t)ip
{
	struct in_addr addr;
	char *temp;
	
	addr.s_addr = htonl(ip);

	temp = inet_ntoa(addr);
	if (temp)
	{
		return [NSHost hostWithAddress: [NSString stringWithCString: temp]];
	}

	return nil;
}	
@end

@implementation TCPPort
- initOnHost: (NSHost *)aHost onPort: (uint16_t)aPort
{
	struct sockaddr_in x;
	socklen_t address_length = sizeof(x);
	
	if (!(self = [super init])) return nil;
	
	desc = [[TCPSystem sharedInstance] openPort: aPort onHost: aHost];

	if (desc < 0)
	{
		[self release];
		return nil;
	}
	if (getsockname(desc, (struct sockaddr *)&x, &address_length) != 0)
	{
		[[TCPSystem sharedInstance] setErrorString: [NSString stringWithFormat: @"%s",
		  strerror(errno)] withErrno: errno];
		close(desc);
		[self release];
		return nil;
	}
	connected = YES;
	
	port = ntohs(x.sin_port);

	[[NetApplication sharedInstance] connectObject: self];
	return self;
}
- initOnPort: (uint16_t)aPort
{
	return [self initOnHost: nil onPort: aPort];
}
- setNetObject: (Class)aClass
{
	if (![aClass conformsToProtocol: @protocol(NetObject)])
	{
		[NSException raise: FatalNetException
		  format: @"%@ does not conform to < NetObject >",
		    NSStringFromClass(aClass)];
	}
	
	netObjectClass = aClass;
	return self;
}
- (int)desc
{
	return desc;
}
- (void)close
{
	if (!connected)
		return;
	close(desc);
	connected = NO;
}

- (void)connectionLost
{
}

- (id <NetPort>)setupNewConnection
{
	int newDesc;
	struct sockaddr_in sin;
	unsigned temp;
	TCPTransport *transport;
	NSHost *newAddress;
	
	temp = sizeof(struct sockaddr_in);
	
	if ((newDesc = accept(desc, (struct sockaddr *)&sin, 
	    &temp)) == -1)
	{
		[NSException raise: FatalNetException
		  format: @"%s", strerror(errno)];
	}
	
	newAddress = [[TCPSystem sharedInstance] 
	  hostFromNetworkOrderInteger: sin.sin_addr.s_addr];	

	transport = AUTORELEASE([[TCPTransport alloc] 
	  initWithDesc: newDesc
	  withRemoteHost: newAddress]);
	
	if (!transport)
	{
		close(newDesc);
		return self;
	}
	
	[AUTORELEASE([netObjectClass new]) connectionEstablished: transport];
	
	return self;
}
- (uint16_t)port
{
	return port;
}
- (void)dealloc
{
	[self close];
	[super dealloc];
}
@end

static NetApplication *net_app = nil; 

@implementation TCPTransport
+ (void)initialize
{
	net_app = RETAIN([NetApplication sharedInstance]);
}
- (id)initWithDesc: (int)aDesc withRemoteHost: (NSHost *)theAddress
{
	struct sockaddr_in x;
	socklen_t address_length = sizeof(x);

	if (!(self = [super init])) return nil;
	
	desc = aDesc;
	
	writeBuffer = RETAIN([NSMutableData dataWithCapacity: 2000]);
	remoteHost = RETAIN(theAddress);
	
	if (getsockname(desc, (struct sockaddr *)&x, &address_length) != 0) 
	{
		[[TCPSystem sharedInstance]
		  setErrorString: [NSString stringWithFormat: @"%s",
		  strerror(errno)] withErrno: errno];
		[self release];
		return nil;
	}
	
	localHost = RETAIN([[TCPSystem sharedInstance] 
	  hostFromNetworkOrderInteger: x.sin_addr.s_addr]);
	
	connected = YES;
	
	return self;
}
- (void)dealloc
{
	[self close];
	RELEASE(writeBuffer);
	RELEASE(localHost);
	RELEASE(remoteHost);

	[super dealloc];
}
#define READ_BLOCK_SIZE 65530 
- (NSData *)readData: (int)maxDataSize
{
	char *buffer;
	int readReturn;
	NSMutableData *data;
	int remaining;
	int bufsize;
	fd_set readSet;
	int toRead;
	int loops = 8;
	struct timeval zeroTime = { 0, 0 };
	
	if (!connected)
	{
		[NSException raise: FatalNetException
		  format: @"Not connected"];
	}
	
	if (maxDataSize <= 0)
	{
		remaining = -1;
		bufsize = READ_BLOCK_SIZE;
	}
	else
	{
		remaining = maxDataSize;
		bufsize = (READ_BLOCK_SIZE < remaining ? READ_BLOCK_SIZE : remaining);
	}
	
	buffer = malloc(bufsize);
	if (!buffer)
	{
		[NSException raise: NSMallocException 
		  format: @"%s", strerror(errno)];
	}
	data = [NSMutableData dataWithCapacity: bufsize];
	
	do
	{
		if (remaining == -1)
		{
			toRead = bufsize;
		}
		else
		{
			toRead = bufsize < remaining ? bufsize : remaining;
		}

		readReturn = read(desc, buffer, toRead); 
		if (readReturn == 0)
		{
			id except;
			free(buffer);
			except = [NSException exceptionWithName: NetException
			  reason: @"Socket closed" userInfo: 
			  [NSDictionary dictionaryWithObjectsAndKeys:
			    data, @"Data", nil]];
			
			[except raise];
		}

		if (readReturn == -1)
		{
			id except;
			free(buffer);
			except = [NSException exceptionWithName: NetException
			  reason: [NSString stringWithCString: strerror(errno)] 
			  userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			    data, @"Data", nil]];
			
			[except raise];
		}

		[data appendBytes: buffer length: readReturn];
		
		if (readReturn < bufsize)
		{
			break;
		}

		if (remaining != -1)
		{
			remaining -= readReturn;
			if (remaining == 0)
			{
				break;
			}
		}
		
		FD_ZERO(&readSet);
		FD_SET(desc, &readSet);
		select(desc + 1, &readSet, NULL, NULL, &zeroTime);
		--loops;
	} while (loops && FD_ISSET(desc, &readSet));
		
	free(buffer);
	
	return data;
}
#undef READ_BLOCK_SIZE
- (BOOL)isDoneWriting
{
	if (!connected)
	{
		[NSException raise: FatalNetException
		  format: @"Not connected"];
	}
	return ([writeBuffer length]) ? NO : YES;
}
- (id <NetTransport>)writeData: (NSData *)aData
{
	int writeReturn;
	char *bytes;
	int length;
	
	if (aData)
	{
		if ([aData length] == 0)
		{
			return self;
		}
		if ([writeBuffer length] == 0)
		{
			[net_app transportNeedsToWrite: self];
		}
		[writeBuffer appendData: aData];
		return self;
	}
	if (!connected)
	{
		[NSException raise: FatalNetException
		  format: @"Not connected"];
	}
	
	if ([writeBuffer length] == 0)
	{
		return self;
	}
	
	writeReturn = 
	  write(desc, [writeBuffer mutableBytes], [writeBuffer length]);

	if (writeReturn == -1)
	{
		[NSException raise: FatalNetException
		  format: @"%s", strerror(errno)];
	}
	if (writeReturn == 0)
	{
		return self;
	}
	
	bytes = (char *)[writeBuffer mutableBytes];
	length = [writeBuffer length] - writeReturn;
	
	memmove(bytes, bytes + writeReturn, length);
	[writeBuffer setLength: length];
	
	return self;
}
- (id)localHost
{
	return localHost;	
}
- (id)remoteHost
{
	return remoteHost;
}
- (int)desc
{
	return desc;
}
- (void)close
{
	if (!connected)
		return;
	connected = NO;
	close(desc);
}
@end	

