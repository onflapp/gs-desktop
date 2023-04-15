/***************************************************************************
                                main.m
                          -------------------
    begin                : Tue Feb 17 00:18:42 CST 2004
    copyright            : (C) 2003 by Andy Ruder
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

#import "SimpleClient.h"
#import <netclasses/NetTCP.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSData.h>

#include <unistd.h>
#include <fcntl.h>
#include <signal.h>

int main(int argc, char **argv, char **env)
{
	id client;
	int port;
	char buffer[200];
	ssize_t length;

	NSHost *aHost;
	CREATE_AUTORELEASE_POOL(arp);

	/* We don't want a SIGPIPE (when the server disconnects) to interfere
	 * with us.
	 */
	signal(SIGPIPE, SIG_IGN);
	
	if (argc < 3)
	{
		printf("Usage: SimpleClient <host> <port>\n");
		return 0;
	}
	
	aHost = [NSHost hostWithName: [NSString stringWithCString: argv[1]]];

	if (!aHost)
	{
		printf("Couldn't lookup host!\n");
		return 1;
	}

	port = strtol(argv[2], (char **)0, 0);
	
	if (port <= 0)
	{
		printf("Invalid port!\n");
		return 1;
	}
	
	client = [SimpleClient new];

	NSLog(@"Connecting to %@ on port %d", [aHost name], port);

	if (![[TCPSystem sharedInstance] connectNetObject: client 
	  toHost: aHost onPort: port withTimeout: 30])
	{
		NSLog(@"Couldn't connect: %@", 
		  [[TCPSystem sharedInstance] errorString]);
		return 1;
	}
	NSLog(@"Connected...");
		
	fcntl(0, F_SETFL, O_NONBLOCK);
	while (1)
	{
		length = read(0, buffer, sizeof(buffer));
		if (length > 0)
		{
			[[client transport] 
			  writeData: [NSData dataWithBytes: buffer length: length]];
		}
		if (![client isConnected])
		{
			break;
		}
		
		[[NSRunLoop currentRunLoop] runUntilDate: [NSDate 
		  dateWithTimeIntervalSinceNow: 1.0]];
	}
	
	RELEASE(arp);
	return 0;
}

