/***************************************************************************
                                EchoServ.m
                          -------------------
    begin                : Sun Apr 28 21:18:20 UTC 2002
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
#import <Foundation/NSData.h>
#import <Foundation/NSString.h> 
#import <Foundation/NSHost.h>

@implementation EchoServ
- (void)connectionLost
{
	[transport close];
	DESTROY(transport);
}
- connectionEstablished: aTransport
{
    NSString *greetingString = 
	 [NSString stringWithFormat: @"Welcome to EchoServ v0.0.001 on %@, %@\r\n",  
	 [(NSHost *)[aTransport localHost] name], 
	 [(NSHost *)[aTransport remoteHost] name]];
	NSData *greetingData = [greetingString dataUsingEncoding: 
	  [NSString defaultCStringEncoding] 
	  allowLossyConversion: YES];
	
	transport = RETAIN(aTransport);

	[[NetApplication sharedInstance] connectObject: self];

	[transport writeData: greetingData];
	return self;
}
- dataReceived: (NSData *)data
{
	[transport writeData: data];
	return self;
}
- transport
{
	return transport;
}
@end													   
