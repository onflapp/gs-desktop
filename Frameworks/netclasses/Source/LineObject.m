/***************************************************************************
                                LineObject.m
                          -------------------
    begin                : Thu May 30 02:19:30 UTC 2002
    copyright            : (C) 2005 by Andrew Ruder
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
 * <title>LineObject class reference</title>
 * <author name="Andrew Ruder">
 * 	<email address="aeruder@ksu.edu" />
 * 	<url url="http://www.aeruder.net" />
 * </author>
 * <version>Revision 1</version>
 * <date>November 8, 2003</date>
 * <copy>Andrew Ruder</copy>
 */

#import "LineObject.h"
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

#include <string.h>

static inline NSData *chomp_line(NSMutableData *data)
{
	char *memory = [data mutableBytes];
	char *memoryEnd = memory + [data length];
	char *lineEndWithControls;
	char *lineEnd;
	int tempLength;
	
	id lineData;
	
	lineEndWithControls = lineEnd = 
	  memchr(memory, '\n', memoryEnd - memory);
	
	if (!lineEnd)
	{
		return nil;
	}
	
	while ((lineEnd >= memory) && ((*lineEnd == '\n') || (*lineEnd == '\r')))
	{
		lineEnd--;
	}

	lineData = [NSData dataWithBytes: memory length: lineEnd - memory + 1];
	
	tempLength = memoryEnd - lineEndWithControls - 1;
	
	memmove(memory, lineEndWithControls + 1, 
	        tempLength);
	
	[data setLength: tempLength];
	
	return lineData;
}


@implementation LineObject
- init
{
	if (!(self = [super init])) return self;

	_readData = [NSMutableData new];

	return self;
}
- (void)dealloc
{
	RELEASE(_readData);
	[super dealloc];
}
- (void)connectionLost
{
	[_readData setLength: 0];
	DESTROY(transport);
}
- connectionEstablished: (id <NetTransport>)aTransport
{
	transport = RETAIN(aTransport);
	[[NetApplication sharedInstance] connectObject: self];

	return self;
}
- dataReceived: (NSData *)newData
{
	id newLine;
	
	[_readData appendData: newData];
	
	while (transport && (newLine = chomp_line(_readData))) [self lineReceived: newLine];
	
	return self;
}
- (id <NetTransport>)transport
{
	return transport;
}
- lineReceived: (NSData *)aLine
{
	return self;
}
@end	
