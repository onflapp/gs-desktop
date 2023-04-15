/***************************************************************************
                              SimpleClient.m
                          -------------------
	begin                : Tue Feb 17 00:06:15 CST 2004
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
#import <Foundation/NSData.h>
#import <Foundation/NSString.h> 
#import <Foundation/NSHost.h>
#import <Foundation/NSCharacterSet.h>

@implementation SimpleClient
- (BOOL)isConnected
{
	return isConnected;
}
- (void)connectionLost
{
	[transport close];
	DESTROY(transport);
	isConnected = NO;
}
- connectionEstablished: (id <NetTransport>)aTransport
{
	transport = RETAIN(aTransport);

	[[NetApplication sharedInstance] connectObject: self];
	isConnected = YES;

	return self;
}
- dataReceived: (NSData *)data
{
	NSString *aString = [NSString stringWithCString: [data bytes] 
	  length: [data length]];

	aString = [aString stringByTrimmingCharactersInSet: [NSCharacterSet
	  whitespaceAndNewlineCharacterSet]];

	NSLog(@"Received data: %@", aString);

	return self;
}
- (id <NetTransport>)transport
{
	return transport;
}
@end													   
