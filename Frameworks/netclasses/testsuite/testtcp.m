/***************************************************************************
                                testtcp.m
                          -------------------
    begin                : Mon Jul 11 21:34:17 CDT 2005
    copyright            : (C) 2005 by Andrew Ruder
    email                : aeruder@ksu.edu
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#import "testsuite.h"

#import <netclasses/NetBase.h>
#import <netclasses/NetTCP.h>

#import <Foundation/Foundation.h>

int numConnections = 0;
id lastserver = nil;

@interface NumBytesServer : NSObject <NetObject>
	{
		id<NetTransport> transport;
	}
- (void)connectionLost;
- connectionEstablished: (id <NetTransport>)aTransport;
- dataReceived: (NSData *)data;
- (id <NetTransport>)transport;
@end

@implementation NumBytesServer
- (void)connectionLost
{
	NSLog(@"Server: lost connection");
	numConnections--;
	DESTROY(transport);
}
- connectionEstablished: (id <NetTransport>)aTransport;
{
	NSLog(@"Server: received connection");
	numConnections++;
	ASSIGN(transport, aTransport);
	lastserver = self;
	[[NetApplication sharedInstance] connectObject: self];
	return self;
}
- dataReceived: (NSData *)data
{
	NSLog(@"Server: got some data");
	[transport writeData: data];
	return self;
}
- (id <NetTransport>)transport
{
	return transport;
}
@end

@interface NumBytesClient : NSObject <NetObject>
	{
		id<NetTransport> transport;
		int numBytes;
	}
- (void)connectionLost;
- connectionEstablished: (id <NetTransport>)aTransport;
- dataReceived: (NSData *)data;
- (id <NetTransport>)transport;
- (int)numBytes;
@end

@implementation NumBytesClient
- (void)connectionLost
{
	[transport close];
	DESTROY(transport);
}
- connectionEstablished: (id <NetTransport>)aTransport;
{
	ASSIGN(transport, aTransport);
	[[NetApplication sharedInstance] connectObject: self];
	return self;
}
- dataReceived: (NSData *)data
{
	numBytes += [data length];
	return self;
}
- (id <NetTransport>)transport
{
	return transport;
}
- (int)numBytes
{
	return numBytes;
}
@end

#define RUNABIT() \
	[[NSRunLoop currentRunLoop] runUntilDate: \
	[NSDate dateWithTimeIntervalSinceNow: 5.0]]

int main(int argc, char **argv)
{
	CREATE_AUTORELEASE_POOL(apr);
	TCPSystem *tcp;
	TCPPort *port;
	NetApplication *net;
	uint16_t portnum;
	NumBytesClient *c1, *c2;
	NSHost *host = [NSHost hostWithAddress: @"127.0.0.1"];
	FILE *randfile;
	char random[140];
	NSData *randdata;

	net = [NetApplication sharedInstance];
	tcp = [TCPSystem sharedInstance];
	port = [[TCPPort alloc] initOnPort: 0];
	portnum = [port port];
	[port setNetObject: [NumBytesServer class]];
	c1 = [NumBytesClient new];
	c2 = [NumBytesClient new];

	testTrue(@"?Initialized port", port);
	NSLog(@"Initialized server on port %lu", (long unsigned)portnum); 
	NSLog(@"Making foreground connection...");
	testTrue(@"?Made connection", [tcp connectNetObject: c1 toHost: host
	  onPort: portnum withTimeout: 4]);
	RUNABIT();
	testTrue(@"?Server got Connection", numConnections == 1);
	NSLog(@"Making background connection...");
	testTrue(@"?Making connection", [tcp connectNetObjectInBackground: c2 toHost:
	  host onPort: portnum withTimeout: 4]);
	RUNABIT();
	testTrue(@"?Made connection", numConnections == 2);

	testTrue(@"?Open /dev/random", (randfile = fopen("/dev/random", "r")));
	testTrue(@"?Reading data", 
	  (fread(random, sizeof(random), 1, randfile) == 1));

	randdata = [NSData dataWithBytes: random length: sizeof(random)];
	testTrue(@"?random data", randdata);
	testTrue(@"?transport c1", [c1 transport]);
	testTrue(@"?transport c2", [c2 transport]);
	NSLog(@"Sending random data to server");
	[[c1 transport] writeData: randdata];
	[[c2 transport] writeData: randdata];
	RUNABIT();
	testTrue(@"?Got all data back c1", ([c1 numBytes] == sizeof(random)));
	testTrue(@"?Got all data back c2", ([c2 numBytes] == sizeof(random)));
	NSLog(@"Disconnecting client 1");
	[net disconnectObject: c1];
	RUNABIT();
	testTrue(@"?Server lost connection", numConnections == 1);
	NSLog(@"Disconnecting server 2");
	[net disconnectObject: lastserver];
	NSLog(@"Writing to server 2");
	[[c2 transport] writeData: randdata];
	RUNABIT();
	testTrue(@"?No more servers...", numConnections == 0);
	testFalse(@"?c1 no transport", ([c1 transport]));
	testFalse(@"?c2 no transport", ([c2 transport]));
	[net disconnectObject: port];
	[port close];
	RUNABIT();
	testFalse(@"?Can't make connection to port", [tcp connectNetObject: c1 toHost: host
	  onPort: portnum withTimeout: 4]);

	FINISH();
	
	RELEASE(apr);

	return 0;
}
