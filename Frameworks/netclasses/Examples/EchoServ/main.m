/***************************************************************************
                                main.m
                          -------------------
    begin                : Sun Apr 28 21:18:23 UTC 2002
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

#import "EchoServ.h"
#import <netclasses/NetTCP.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRunLoop.h>

int main(int argc, char **argv, char **env)
{
	TCPPort *x;
	CREATE_AUTORELEASE_POOL(arp);

	x = AUTORELEASE([[[TCPPort alloc] initOnPort: 0] 
	                setNetObject: [EchoServ class]]);
	NSLog(@"Ready to go on TCP port %d", [x port]);

	if (!x)
	{
		NSLog(@"%@", [[TCPSystem sharedInstance] errorString]);
		return 0;
	}
	
	[[NSRunLoop currentRunLoop] run];
		
	RELEASE(arp);
	return 0;
}

