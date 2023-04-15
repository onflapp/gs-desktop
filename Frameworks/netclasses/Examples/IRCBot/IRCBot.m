/*************************************************************************** IRCBot.m
                          -------------------
    begin                : Wed Jun  5 03:28:59 UTC 2002
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

#import "IRCBot.h"
#import <Foundation/NSTimer.h>
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Foundation/NSValue.h>

#include <string.h>
#include <stdio.h>
#include <unistd.h>

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
	
	while (((*lineEnd == '\n') || (*lineEnd == '\r'))
	       && (lineEnd >= memory))
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

@implementation IRCBot
- connectionEstablished: (id <NetTransport>)aTransport
{
	return [super connectionEstablished: aTransport];
}
- (void)connectionLost
{
	[super connectionLost];
}
- registeredWithServer
{
	[self joinChannel: 
	  @"#gnustep,#netclasses" 
	  withPassword: nil];
	return self;
}
- CTCPRequestReceived: (NSString *)aCTCP withArgument: (NSString *)argument
    to: (NSString *)aReceiver from: (NSString *)aPerson
{
	if ([aCTCP compare: @"PING"] == NSOrderedSame)
	{
		[self sendCTCPReply: @"PING" withArgument: argument
		  to: ExtractIRCNick(aPerson)];
	}
	if ([aCTCP compare: @"VERSION"] == NSOrderedSame)
	{
		NSString *version, *reply;

		version = [NetApplication netclassesVersion];
		reply = [NSString stringWithFormat: @"netclasses:%@:GNUstep", version];
		
		[self sendCTCPReply: @"VERSION" withArgument: reply 
		  to: ExtractIRCNick(aPerson)];
	}

	return self;
}		
- pingReceivedWithArgument: (NSString *)anArgument from: (NSString *)aSender
{
	[self sendPongWithArgument: anArgument];

	return self;
}
- messageReceived: (NSString *)aMessage to: (NSString *)to
               from: (NSString *)whom
{
	NSString *sendTo = ExtractIRCNick(whom);
	
	if ([nick caseInsensitiveCompare: to] != NSOrderedSame)
	{
		return self;  // Only accepts private messages
	}
		
	if ([aMessage caseInsensitiveCompare: @"quit"] == NSOrderedSame)
	{
		[self sendMessage: @"Quitting..." to: sendTo];
		[self quitWithMessage: 
		  [NSString stringWithFormat: @"Quit requested by %@", sendTo]];
		return self;
	}
	else if ([aMessage caseInsensitiveCompare: @"fortune"] == NSOrderedSame)
	{
		if (sendTo == to)
		{
			return self;
		}
		int read;
		FILE *fortune;
		NSMutableData *input = [NSMutableData dataWithLength: 4000];
		id line;
		
		fortune = popen("fortune", "r");
		
		do
		{
			read = fread([input mutableBytes], sizeof(char), 4000, fortune);
			while ((line = chomp_line(input))) 
			{
				[self sendMessage: [NSString stringWithCString: [line bytes]
				  length: [line length]] to: sendTo];
			}
		}
		while(read == 4000);

		[self sendMessage: [NSString stringWithCString: [line bytes]
		  length: [line length]] to: sendTo];
		
		pclose(fortune);
		return self;
	}
	
	return self;
}
@end
