/***************************************************************************
                                IRCObject.m
                          -------------------
    begin                : Thu May 30 22:06:25 UTC 2002
    copyright            : (C) 2005 by Andrew Ruder
                         : (C) 2013-2015 The GNUstep Application Project
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
 * <title>IRCObject reference</title>
 * <author name="Andrew Ruder">
 * 	<email address="aeruder@ksu.edu" />
 * 	<url url="http://www.aeruder.net" />
 * </author>
 * <version>Revision 1</version>
 * <date>November 8, 2003</date>
 * <copy>Andrew Ruder</copy>
 * <p>
 * Much of the information presented in this document is based off
 * of information presented in RFC 1459 (Oikarinen and Reed 1999).
 * This document is NOT aimed at reproducing the information in the RFC, 
 * and the RFC should still always be consulted for various server-related
 * replies to messages and proper format of the arguments.  In short, if you
 * are doing a serious project dealing with IRC, even with the use of 
 * netclasses, RFC 1459 is indispensable.
 * </p>
 */

#import "NetBase.h"
#import "NetTCP.h"
#import "IRCObject.h"

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSPathUtilities.h>

#include <string.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

NSString *IRCException = @"IRCException";

static NSMapTable *command_to_function = 0;
static NSMapTable *ctcp_to_function = 0;

static NSData *IRC_new_line = nil;

@implementation NSString (IRCAddition)
- (NSString *)uppercaseIRCString
{
	NSMutableString *aString = [NSString stringWithString: [self uppercaseString]];
	NSRange aRange = {0, [aString length]};

	[aString replaceOccurrencesOfString: @"{" withString: @"[" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"}" withString: @"]" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"|" withString: @"\\" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"^" withString: @"~" options: 0
	  range: aRange];
	
	return [aString uppercaseString];
}
- (NSString *)uppercaseStrictRFC1459IRCString
{
	NSMutableString *aString = [NSString stringWithString: [self uppercaseString]];
	NSRange aRange = {0, [aString length]};

	[aString replaceOccurrencesOfString: @"{" withString: @"[" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"}" withString: @"]" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"|" withString: @"\\" options: 0
	  range: aRange];
	
	return [aString uppercaseString];
}
- (NSString *)lowercaseIRCString
{
	NSMutableString *aString = [NSMutableString 
	  stringWithString: [self lowercaseString]];
	NSRange aRange = {0, [aString length]};

	[aString replaceOccurrencesOfString: @"[" withString: @"{" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"]" withString: @"}" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"\\" withString: @"|" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"~" withString: @"^" options: 0
	  range: aRange];
	
	return [aString lowercaseString];
}
- (NSString *)lowercaseStrictRFC1459IRCString
{
	NSMutableString *aString = [NSMutableString 
	  stringWithString: [self lowercaseString]];
	NSRange aRange = {0, [aString length]};

	[aString replaceOccurrencesOfString: @"[" withString: @"{" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"]" withString: @"}" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"\\" withString: @"|" options: 0
	  range: aRange];
	
	return [aString lowercaseString];
}
@end

@interface IRCObject (InternalIRCObject)
- setErrorString: (NSString *)anError;
@end
	
#define NEXT_SPACE(__y, __z, __string)\
{\
	__z = [(__string) rangeOfCharacterFromSet:\
	[NSCharacterSet whitespaceCharacterSet] options: 0\
	range: NSMakeRange((__y), [(__string) length] - (__y))].location;\
	if (__z == NSNotFound) __z = [(__string) length];\
}
	
#define NEXT_NON_SPACE(__y, __z, __string)\
{\
	NSUInteger __len = [(__string) length];\
	id set = [NSCharacterSet whitespaceCharacterSet];\
	__z = (__y);\
	while (__z < __len && \
	  [set characterIsMember: [(__string) characterAtIndex: __z]]) __z++;\
}

static inline NSString *get_IRC_prefix(NSString *line, NSString **prefix)
{
	NSUInteger beg;
	NSUInteger end;
	NSUInteger len = [line length];
	
	if (len == 0)
	{
		*prefix = nil;
		return @"";
	}
	NEXT_NON_SPACE(0, beg, line);
	
	if (beg == len)
	{
		*prefix = nil;
		return @"";
	}
	
	NEXT_SPACE(beg, end, line);
		
	if ([line characterAtIndex: beg] != ':')
	{
		*prefix = nil;
		return line;
	}
	else
	{
		beg++;
		if (beg == end)
		{
			*prefix = @"";
			if (beg == len)
			{
				return @"";
			}
			else
			{
				return [line substringFromIndex: beg];
			}
		}
	}
	
	*prefix = [line substringWithRange: NSMakeRange(beg, end - beg)];
	
	if (end != len)
	{
		return [line substringFromIndex: end];
	}
	
	return @"";
}
	
static inline NSString *get_next_IRC_word(NSString *line, NSString **prefix)
{
	NSUInteger beg;
	NSUInteger end;
	NSUInteger len = [line length];
	
	if (len == 0)
	{
		*prefix = nil;
		return @"";
	}
	NEXT_NON_SPACE(0, beg, line);
	
	if (beg == len)
	{
		*prefix = nil;
		return @"";
	}
	if ([line characterAtIndex: beg] == ':')
	{
		beg++;
		if (beg == len)
		{
			*prefix = @"";
		}
		else
		{
			*prefix = [line substringFromIndex: beg];
		}
		
		return @"";
	}
	
   NEXT_SPACE(beg, end, line);
	
	*prefix = [line substringWithRange: NSMakeRange(beg, end - beg)];
	
	if (end != len)
	{
		return [line substringFromIndex: end];
	}
	
	return @"";
}

#undef NEXT_NON_SPACE
#undef NEXT_SPACE

static inline BOOL is_numeric_command(NSString *aString)
{
	static NSCharacterSet *set = nil;
	unichar test[3];
	
	if (!set)
	{
		set = RETAIN([NSCharacterSet 
		  characterSetWithCharactersInString: @"0123456789"]);
	}
	
	if ([aString length] != 3)
	{
		return NO;
	}
	
	[aString getCharacters: test];
	if ([set characterIsMember: test[0]] && [set characterIsMember: test[1]] &&
	    [set characterIsMember: test[2]])
	{
		return YES;
	}
	
	return NO;
}	

static inline NSString *string_to_string(NSString *aString, NSString *delim)
{
	NSRange a = [aString rangeOfString: delim];
	
	if (a.location == NSNotFound) return [NSString stringWithString: aString];
	
	return [aString substringToIndex: a.location];
}

static inline NSString *string_from_string(NSString *aString, NSString *delim)
{
	NSRange a = [aString rangeOfString: delim];
	
	if (a.location == NSNotFound) return nil;
	
	a.location += a.length;
	
	if (a.location == [aString length])
	{
		return @"";
	}
	
	return [aString substringFromIndex: a.location];
}

inline NSString *ExtractIRCNick(NSString *prefix)
{	
	if (!prefix) return @"";
	return string_to_string(prefix, @"!");
}

inline NSString *ExtractIRCHost(NSString *prefix)
{
	if (!prefix) return @"";
	return string_from_string(prefix, @"!");
}

inline NSArray *SeparateIRCNickAndHost(NSString *prefix)
{
	if (!prefix) return [NSArray arrayWithObject: @""];
	return [NSArray arrayWithObjects: string_to_string(prefix, @"!"),
	  string_from_string(prefix, @"!"), nil];
}

static void rec_isupport(IRCObject *client, NSArray *paramList)
{
	NSEnumerator *iter;
	id object;

	iter = [paramList objectEnumerator];
	while ((object = [iter nextObject]))
	{
		object = [object lowercaseString];
		if ([object hasPrefix: @"casemapping="])
		{
			object = [object substringFromIndex: 12];
			if ([object isEqualToString: @"rfc1459"])
			{
				[client setLowercasingSelector: @selector(lowercaseIRCString)];
			} 
			else if ([object isEqualToString: @"strict-rfc1459"])
			{
				[client setLowercasingSelector: 
				  @selector(lowercaseStrictRFC1459IRCString)];
			} 
			else if ([object isEqualToString: @"ascii"])
			{
				[client setLowercasingSelector:
				  @selector(lowercaseString)];
			}
			else
			{
				NSLog(@"Did not understand casemapping=%@", object);
			}
			break;
		}
	}
}
	
static void rec_numeric(IRCObject *client, NSString *command,
                        NSString *prefix, NSArray *paramList)
{
	if ([command isEqualToString: RPL_ISUPPORT])
	{
		rec_isupport(client, paramList);
	}

	[client numericCommandReceived: command withParams: paramList
	  from: prefix];
}
static void rec_caction(IRCObject *client, NSString *prefix,
                        NSString *command, NSString *rest, NSString *to)
{
	if ([rest length] == 0)
	{
		return;
	}
	[client actionReceived: rest to: to from: prefix];
}

static void rec_ccustom(IRCObject *client, NSString *prefix, 
                        NSString *command, NSString *rest, NSString *to,
                        NSString *ctcp)
{
	if ([command isEqualToString: @"NOTICE"])
	{
		[client CTCPReplyReceived: ctcp withArgument: rest
		  to: to from: prefix];
	}
	else
	{
		[client CTCPRequestReceived: ctcp withArgument: rest
		  to: to from: prefix];
	}
}

static void rec_nick(IRCObject *client, NSString *command,
                     NSString *prefix, NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}
		
	if ([paramList count] < 1)
	{
		return;
	}
	
	if ([client caseInsensitiveCompare: [client nick] to: 
         ExtractIRCNick(prefix)] == NSOrderedSame)
	{
		[client setNick: [paramList objectAtIndex: 0]];
	}
	[client nickChangedTo: [paramList objectAtIndex: 0] from: prefix];
}

static void rec_join(IRCObject *client, NSString *command, 
                     NSString *prefix, NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}

	if ([paramList count] == 0)
	{
		return;
	}

	[client channelJoined: [paramList objectAtIndex: 0] from: prefix];
}

static void rec_part(IRCObject *client, NSString *command,
                     NSString *prefix, NSArray *paramList)
{
	NSUInteger x;
	
	if (!prefix)
	{	
		return;
	}

	x = [paramList count];
	if (x == 0)
	{
		return;
	}

	[client channelParted: [paramList objectAtIndex: 0] withMessage:
	  (x == 2) ? [paramList objectAtIndex: 1] : 0 from: prefix];
}

static void rec_quit(IRCObject *client, NSString *command,
                     NSString *prefix, NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}

	if ([paramList count] == 0)
	{
		return;
	}

	[client quitIRCWithMessage: [paramList objectAtIndex: 0] from: prefix];
}

static void rec_topic(IRCObject *client, NSString *command,
                      NSString *prefix, NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}

	if ([paramList count] < 2)
	{
		return;
	}

	[client topicChangedTo: [paramList objectAtIndex: 1] 
	  in: [paramList objectAtIndex: 0] from: prefix];
}
static void rec_privmsg(IRCObject *client, NSString *command,
                        NSString *prefix, NSArray *paramList)
{
	NSString *message;
	
	if ([paramList count] < 2)
	{
		return;
	}

	message = [paramList objectAtIndex: 1];
	if ([message hasPrefix: @"\001"])
	{
		void (*func)(IRCObject *, NSString *, NSString *, NSString *, 
		              NSString *);
		id ctcp = string_to_string(message, @" ");
		id rest;
		
		if ([ctcp isEqualToString: message])
		{
			if ([ctcp hasSuffix: @"\001"])
			{
				ctcp = [ctcp substringToIndex: [ctcp length] - 1];
			}
			rest = nil;
		}
		else
		{
			NSRange aRange;
			aRange.location = [ctcp length] + 1;
			aRange.length = [message length] - aRange.location;
			
			if ([message hasSuffix: @"\001"])
			{
				aRange.length--;
			}
			
			if (aRange.length > 0)
			{
				rest = [message substringWithRange: aRange];
			}
			else
			{
				rest = nil;
			}
		}	
		func = NSMapGet(ctcp_to_function, ctcp);
		
		if (func)
		{
			func(client, prefix, command, rest, [paramList objectAtIndex: 0]);
		}
		else
		{
			ctcp = [ctcp substringFromIndex: 1];
			rec_ccustom(client, prefix, command, rest,
			  [paramList objectAtIndex: 0], ctcp);
		}
		return;
	}
	
	if ([command isEqualToString: @"PRIVMSG"])
	{
		[client messageReceived: message
		   to: [paramList objectAtIndex: 0] from: prefix];
	}
	else
	{
		[client noticeReceived: message
		   to: [paramList objectAtIndex: 0] from: prefix];
	}
}
static void rec_mode(IRCObject *client, NSString *command, NSString *prefix, 
                     NSArray *paramList)
{
	NSArray *newParams;
	NSUInteger x;
	
	if (!prefix)
	{
		return;
	}
	
	x = [paramList count];
	if (x < 2)
	{	
		return;
	}

	if (x == 2)
	{
		newParams = AUTORELEASE([NSArray new]);
	}
	else
	{
		NSRange aRange;
		aRange.location = 2;
		aRange.length = x - 2;
		
		newParams = [paramList subarrayWithRange: aRange];
	}
	
	[client modeChanged: [paramList objectAtIndex: 1] 
	  on: [paramList objectAtIndex: 0] withParams: newParams from: prefix];
}
static void rec_invite(IRCObject *client, NSString *command, NSString *prefix, 
                     NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}
	if ([paramList count] < 2)
	{
		return;
	}

	[client invitedTo: [paramList objectAtIndex: 1] from: prefix];
}
static void rec_kick(IRCObject *client, NSString *command, NSString *prefix,
                       NSArray *paramList)
{
	id object;
	
	if (!prefix)
	{
		return;
	}
	if ([paramList count] < 2)
	{
		return;
	}
	
	object = ([paramList count] > 2) ? [paramList objectAtIndex: 2] : nil;
	
	[client userKicked: [paramList objectAtIndex: 1]
	   outOf: [paramList objectAtIndex: 0] for: object from: prefix];
}
static void rec_ping(IRCObject *client, NSString *command, NSString *prefix,
                       NSArray *paramList)
{
	NSString *arg;
	
	arg = [paramList componentsJoinedByString: @" "];
	
	[client pingReceivedWithArgument: arg from: prefix];
}
static void rec_pong(IRCObject *client, NSString *command, NSString *prefix,
                     NSArray *paramList)
{
	NSString *arg;
	
	arg = [paramList componentsJoinedByString: @" "];
	
	[client pongReceivedWithArgument: arg from: prefix];
}
static void rec_wallops(IRCObject *client, NSString *command, NSString *prefix,
                          NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}
	if ([paramList count] < 1)
	{
		return;
	}
	
	[client wallopsReceived: [paramList objectAtIndex: 0] from: prefix];
}
static void rec_error(IRCObject *client, NSString *command, NSString *prefix,
                        NSArray *paramList)
{
	if ([paramList count] < 1)
	{
		return;
	}

	[client errorReceived: [paramList objectAtIndex: 0]];
}


@implementation IRCObject (InternalIRCObject)
- setErrorString: (NSString *)anError
{
	RELEASE(errorString);
	errorString = RETAIN(anError);
	return self;
}
@end

@implementation IRCObject
+ (void)initialize
{
	IRC_new_line = [[NSData alloc] initWithBytes: "\r\n" length: 2];

	command_to_function = NSCreateMapTable(NSObjectMapKeyCallBacks,
	   NSIntMapValueCallBacks, 13);
	
	NSMapInsert(command_to_function, @"NICK", rec_nick);
	NSMapInsert(command_to_function, @"JOIN", rec_join);
	NSMapInsert(command_to_function, @"PART", rec_part);
	NSMapInsert(command_to_function, @"QUIT", rec_quit);
	NSMapInsert(command_to_function, @"TOPIC", rec_topic);
	NSMapInsert(command_to_function, @"PRIVMSG", rec_privmsg);
	NSMapInsert(command_to_function, @"NOTICE", rec_privmsg);
	NSMapInsert(command_to_function, @"MODE", rec_mode);
	NSMapInsert(command_to_function, @"KICK", rec_kick);
	NSMapInsert(command_to_function, @"INVITE", rec_invite);
	NSMapInsert(command_to_function, @"PING", rec_ping);
	NSMapInsert(command_to_function, @"PONG", rec_pong);
	NSMapInsert(command_to_function, @"WALLOPS", rec_wallops);
	NSMapInsert(command_to_function, @"ERROR", rec_error);

	ctcp_to_function = NSCreateMapTable(NSObjectMapKeyCallBacks,
	   NSIntMapValueCallBacks, 1);
	
	NSMapInsert(ctcp_to_function, @"\001ACTION", rec_caction);
}
- initWithNickname: (NSString *)aNickname withUserName: (NSString *)aUser
   withRealName: (NSString *)aRealName
   withPassword: (NSString *)aPassword
{
	if (!(self = [super init])) return nil;
	
	lowercasingSelector = @selector(lowercaseIRCString);
	defaultEncoding = [NSString defaultCStringEncoding];
	
	if (![self setNick: aNickname])
	{
		[self release];
		return nil;
	}

	if (![self setUserName: aUser])
	{
		[self release];
		return nil;
	}

	if (![self setRealName: aRealName])
	{
		[self release];
		return nil;
	}

	if (![self setPassword: aPassword])
	{
		[self release];
		return nil;
	}

	targetToEncoding = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSIntMapValueCallBacks, 10);

	if (!targetToEncoding)
	{
		[self release];
		return nil;
	}

	targetToOriginalTarget = [NSMutableDictionary new];

	if (!targetToOriginalTarget)
	{
		[self release];
		return nil;
	}

	return self;
}
- (void)dealloc
{
	NSFreeMapTable(targetToEncoding);
	DESTROY(targetToOriginalTarget);
	DESTROY(nick);
	DESTROY(userName);
	DESTROY(realName);
	DESTROY(password);
	DESTROY(errorString);
	
	[super dealloc];
}
- (void)connectionLost
{
	connected = NO;
	[super connectionLost];
}
- (id)setLowercasingSelector: (SEL)aSelector
{
	NSEnumerator *iter;
	NSString *object;
	NSString *normal;
	NSStringEncoding aEncoding;
	NSMutableDictionary *new;

	if (aSelector == NULL)
	{
		aSelector = @selector(lowercaseIRCString);
	}

	new = [NSMutableDictionary new];
	iter = [targetToOriginalTarget keyEnumerator];
	while ((object = [iter nextObject]))
	{
		aEncoding = (NSStringEncoding)NSMapGet(targetToEncoding, object);
		NSMapRemove(targetToEncoding, object);
		normal = [targetToOriginalTarget objectForKey: object];
		object = [normal performSelector: aSelector];
		[new setObject: normal forKey: object];
		NSMapInsert(targetToEncoding, object, (void *)aEncoding);
	}
	RELEASE(targetToOriginalTarget);
	targetToOriginalTarget = new;

	lowercasingSelector = aSelector;
	return self;
}
- (SEL)lowercasingSelector
{
	return lowercasingSelector;
}
- (NSComparisonResult)caseInsensitiveCompare: (NSString *)aString1
   to: (NSString *)aString2
{
	return ([(NSString *)[aString1 performSelector: lowercasingSelector] compare: 
	     [aString2 performSelector: lowercasingSelector]]);
}
- (id)setNick: (NSString *)aNickname
{
	if (aNickname == nick) return self;
	
	aNickname = string_to_string(aNickname, @" ");
	if ([aNickname length] == 0)
	{
		[self setErrorString: @"No usable nickname provided"];
		return nil;
	}

	RELEASE(nick);
	nick = RETAIN(aNickname);

	return self;
}
- (NSString *)nick
{
	return nick;
}
- (id)setUserName: (NSString *)aUser
{
	if ([aUser length] == 0)
	{
		aUser = NSUserName();

		if ([aUser length] == 0)
		{
			aUser = @"netclasses";
		}
	}
	if ([(aUser = string_to_string(aUser, @" ")) length] == 0)
	{
		aUser = @"netclasses";
	}

	RELEASE(userName);
	userName = RETAIN(aUser);
	
	return self;
}
- (NSString *)userName
{
	return userName;
}
- (id)setRealName: (NSString *)aRealName
{
	if ([aRealName length] == 0)
	{
		aRealName = @"John Doe";
	}

	RELEASE(realName);
	realName = RETAIN(aRealName);

	return self;
}
- (NSString *)realName
{
	return realName;
}
- (id)setPassword: (NSString *)aPass
{
	if ([aPass length])
	{
		if ([(aPass = string_to_string(aPass, @" ")) length] == 0) 
		{
			[self setErrorString: @"Unusable password"];
			return nil;
		}
	}
	else
	{
		aPass = nil;
	}
	
	DESTROY(password);
	password = RETAIN(aPass);
	
	return self;
}
- (NSString *)password
{
	return password;
}
- (NSString *)errorString
{
	return errorString;
}
- (id)connectionEstablished: (id <NetTransport>)aTransport
{
	[super connectionEstablished: aTransport];
	
	[self setLowercasingSelector: @selector(lowercaseIRCString)];
	if (password)
	{
		[self writeString: [NSString stringWithFormat: 
		  @"PASS %@", password]];
	}

	[self changeNick: nick];

	[self writeString: @"USER %@ %@ %@ :%@", userName, @"localhost", 
	  @"netclasses", realName];
	return self;
}
- (BOOL)connected
{
	return connected;
}
- (id)setEncoding: (NSStringEncoding)aEncoding
{
	defaultEncoding = aEncoding;
	return self;
}
- (id)setEncoding: (NSStringEncoding)aEncoding forTarget: (NSString *)aTarget
{
	NSString *lower = [aTarget performSelector: lowercasingSelector];

	if (!lower) return self;

	NSMapInsert(targetToEncoding, lower, (void *)aEncoding);
	[targetToOriginalTarget setObject: aTarget forKey: lower];

	return self;
}
- (NSStringEncoding)encoding
{
	return defaultEncoding;
}
- (NSStringEncoding)encodingForTarget: (NSString *)aTarget
{
	NSString *lower = [aTarget performSelector: lowercasingSelector];

	if (!lower) return defaultEncoding;

	return (NSStringEncoding)NSMapGet(targetToEncoding, lower);
}
- (void)removeEncodingForTarget: (NSString *)aTarget
{
	NSString *lower = [aTarget performSelector: lowercasingSelector];

	if (!lower) return;

	NSMapRemove(targetToEncoding, lower);
	[targetToOriginalTarget removeObjectForKey: lower];
}
- (NSArray *)targetsWithEncodings
{
	return NSAllMapTableKeys(targetToEncoding);
}
- (id)changeNick: (NSString *)aNick
{
	if ([aNick length] > 0)
	{
		if ([(aNick = string_to_string(aNick, @" ")) length] == 0)
		{
			[NSException raise: IRCException
			 format: @"[IRCObject changeNick: '%@'] Unusable nickname given",
			  aNick];
		}
		if (!connected)
		{
			[self setNick: aNick];
		}

		[self writeString: @"NICK %@", aNick];
	}
	return self;
}
- (id)quitWithMessage: (NSString *)aMessage
{
	if ([aMessage length] > 0)
	{
		[self writeString: @"QUIT :%@", aMessage];
	}
	else
	{
		[self writeString: @"QUIT"];
	}
	return self;
}
- (id)partChannel: (NSString *)aChannel withMessage: (NSString *)aMessage
{
	if ([aChannel length] == 0)
	{
		return self;
	}
	
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject partChannel: '%@' ...] Unusable channel given",
		  aChannel];
	}
	
	if ([aMessage length] > 0)
	{
		[self writeString: @"PART %@ :%@", aChannel, aMessage];
	}
	else
	{
		[self writeString: @"PART %@", aChannel];
	}
	
	return self;
}
- (id)joinChannel: (NSString *)aChannel withPassword: (NSString *)aPassword
{
	if ([aChannel length] == 0)
	{
		return self;
	}

	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject joinChannel: '%@' ...] Unusable channel",
		  aChannel];
	}

	if ([aPassword length] == 0)
	{
		[self writeString: @"JOIN %@", aChannel];
		return self;
	}

	if ([(aPassword = string_to_string(aPassword, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject joinChannel: withPassword: '%@'] Unusable password",
		  aPassword];
	}

	[self writeString: @"JOIN %@ %@", aChannel, aPassword];

	return self;
}
- (id)sendCTCPReply: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		  @"[IRCObject sendCTCPReply: '%@'withArgument: '%@' to: '%@'] Unusable receiver",
		    aCTCP, args, aPerson];
	}
	if (!aCTCP)
	{
		aCTCP = @"";
	}
	if ([args length])
	{
		[self writeString: @"NOTICE %@ :\001%@ %@\001", aPerson, aCTCP, args];
	}
	else
	{
		[self writeString: @"NOTICE %@ :\001%@\001", aPerson, aCTCP];
	}
		
	return self;
}
- (id)sendCTCPRequest: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		  @"[IRCObject sendCTCPRequest: '%@'withArgument: '%@' to: '%@'] Unusable receiver",
		    aCTCP, args, aPerson];
	}
	if (!aCTCP)
	{
		aCTCP = @"";
	}
	if ([args length])
	{
		[self writeString: @"PRIVMSG %@ :\001%@ %@\001", aPerson, aCTCP, args];
	}
	else
	{
		[self writeString: @"PRIVMSG %@ :\001%@\001", aPerson, aCTCP];
	}
		
	return self;
}
- (id)sendMessage: (NSString *)aMessage to: (NSString *)aReceiver
{
	if ([aMessage length] == 0)
	{
		return self;
	}
	if ([aReceiver length] == 0)
	{
		return self;
	}
	if ([(aReceiver = string_to_string(aReceiver, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject sendMessage: '%@' to: '%@'] Unusable receiver",
		  aMessage, aReceiver];
	}
	
	[self writeString: @"PRIVMSG %@ :%@", aReceiver, aMessage];
	
	return self;
}
- (id)sendNotice: (NSString *)aNotice to: (NSString *)aReceiver
{
	if ([aNotice length] == 0)
	{
		return self;
	}
	if ([aReceiver length] == 0)
	{
		return self;
	}
	if ([(aReceiver = string_to_string(aReceiver, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject sendNotice: '%@' to: '%@'] Unusable receiver",
		  aNotice, aReceiver];
	}
	
	[self writeString: @"NOTICE %@ :%@", aReceiver, aNotice];
	
	return self;
}
- (id)sendAction: (NSString *)anAction to: (NSString *)aReceiver
{
	if ([anAction length] == 0)
	{
		return self;
	}
	if ([aReceiver length] == 0)
	{
		return self;
	}
	if ([(aReceiver = string_to_string(aReceiver, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject sendAction: '%@' to: '%@'] Unusable receiver",
		   anAction, aReceiver];
	}

	[self writeString: @"PRIVMSG %@ :\001ACTION %@\001", aReceiver, anAction];
	
	return self;
}
- (id)becomeOperatorWithName: (NSString *)aName withPassword: (NSString *)aPassword
{
	if (([aName length] == 0) || ([aPassword length] == 0))
	{
		return self;
	}
	if ([(aPassword = string_to_string(aPassword, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject becomeOperatorWithName: %@ withPassword: %@] Unusable password",
		  aName, aPassword];
	}
	if ([(aName = string_to_string(aName, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject becomeOperatorWithName: %@ withPassword: %@] Unusable name",
		  aName, aPassword];
	}
	
	[self writeString: @"OPER %@ %@", aName, aPassword];
	
	return self;
}
- (id)requestNamesOnChannel: (NSString *)aChannel
{
	if ([aChannel length] == 0)
	{
		[self writeString: @"NAMES"];
		return self;
	}
	
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: 
		  @"[IRCObject requestNamesOnChannel: %@] Unusable channel",
		   aChannel];
	}
			
	[self writeString: @"NAMES %@", aChannel];

	return self;
}
- (id)requestMOTDOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"MOTD"];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format: 
		  @"[IRCObject requestMOTDOnServer:'%@'] Unusable server",
		  aServer];
	}

	[self writeString: @"MOTD %@", aServer];
	return self;
}
- (id)requestSizeInformationFromServer: (NSString *)aServer 
    andForwardTo: (NSString *)anotherServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"LUSERS"];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestSizeInformationFromServer: '%@' andForwardTo: '%@'] Unusable first server", 
		  aServer, anotherServer];
	}
	if ([anotherServer length] == 0)
	{
		[self writeString: @"LUSERS %@", aServer];
		return self;
	}
	if ([(anotherServer = string_to_string(anotherServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestSizeInformationFromServer: '%@' andForwardTo: '%@'] Unusable second server",
		 aServer, anotherServer];
	}

	[self writeString: @"LUSERS %@ %@", aServer, anotherServer];
	return self;
}	
- (id)requestVersionOfServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"VERSION"];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestVersionOfServer: '%@'] Unusable server",
		  aServer];
	}

	[self writeString: @"VERSION %@", aServer];
	return self;
}
- (id)requestServerStats: (NSString *)aServer for: (NSString *)query
{
	if ([query length] == 0)
	{
		[self writeString: @"STATS"];
		return self;
	}
	if ([(query = string_to_string(query, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerStats: '%@' for: '%@'] Unusable query",
		  aServer, query];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"STATS %@", query];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerStats: '%@' for: '%@'] Unusable server",
		  aServer, query];
	}
	
	[self writeString: @"STATS %@ %@", query, aServer];
	return self;
}
- (id)requestServerLink: (NSString *)aLink from: (NSString *)aServer
{
	if ([aLink length] == 0)
	{
		[self writeString: @"LINKS"];
		return self;
	}
	if ([(aLink = string_to_string(aLink, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerLink: '%@' from: '%@'] Unusable link",
		  aLink, aServer];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"LINKS %@", aLink];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerLink: '%@' from: '%@'] Unusable server", 
		  aLink, aServer];
	}

	[self writeString: @"LINKS %@ %@", aServer, aLink];
	return self;
}
- (id)requestTimeOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"TIME"];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestTimeOnServer: '%@'] Unusable server",
		  aServer];
	}

	[self writeString: @"TIME %@", aServer];
	return self;
}
- (id)requestServerToConnect: (NSString *)aServer to: (NSString *)connectServer
                  onPort: (NSString *)aPort
{
	if ([connectServer length] == 0)
	{
		return self;
	}
	if ([(connectServer = string_to_string(connectServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerToConnect: '%@' to: '%@' onPort: '%@'] Unusable second server",
		  aServer, connectServer, aPort];
	}
	if ([aPort length] == 0)
	{
		return self;
	}
	if ([(aPort = string_to_string(aPort, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerToConnect: '%@' to: '%@' onPort: '%@'] Unusable port",
		  aServer, connectServer, aPort];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"CONNECT %@ %@", connectServer, aPort];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format: 
		 @"[IRCObject requestServerToConnect: '%@' to: '%@' onPort: '%@'] Unusable first server",
		  aServer, connectServer, aPort];
	}
	
	[self writeString: @"CONNECT %@ %@ %@", connectServer, aPort, aServer];
	return self;
}
- (id)requestTraceOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"TRACE"];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format: 
		 @"[IRCObject requestTraceOnServer: '%@'] Unusable server",
		  aServer];
	}
	
	[self writeString: @"TRACE %@", aServer];
	return self;
}
- (id)requestAdministratorOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"ADMIN"];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestAdministratorOnServer: '%@'] Unusable server", 
		  aServer];
	}

	[self writeString: @"ADMIN %@", aServer];
	return self;
}
- (id)requestInfoOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"INFO"];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestInfoOnServer: '%@'] Unusable server",
		  aServer];
	}

	[self writeString: @"INFO %@", aServer];
	return self;
}
- (id)requestServerRehash
{
	[self writeString: @"REHASH"];
	return self;
}
- (id)requestServerShutdown
{
	[self writeString: @"DIE"];
	return self;
}
- (id)requestServerRestart
{
	[self writeString: @"RESTART"];
	return self;
}
- (id)requestUserInfoOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"USERS"];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestUserInfoOnServer: '%@'] Unusable server",
		  aServer];
	}

	[self writeString: @"USERS %@", aServer];
	return self;
}
- (id)areUsersOn: (NSString *)userList
{
	if ([userList length] == 0)
	{
		return self;
	}
	
	[self writeString: @"ISON %@", userList];
	return self;
}
- (id)sendWallops: (NSString *)aMessage
{
	if ([aMessage length] == 0)
	{
		return self;
	}

	[self writeString: @"WALLOPS :%@", aMessage];
	return self;
}
- (id)listWho: (NSString *)aMask onlyOperators: (BOOL)operators
{
	if ([aMask length] == 0)
	{
		[self writeString: @"WHO"];
		return self;
	}
	if ([(aMask = string_to_string(aMask, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject listWho: '%@' onlyOperators: %d] Unusable mask",
		 aMask, operators];
	}
	
	if (operators)
	{
		[self writeString: @"WHO %@ o", aMask];
	}
	else
	{
		[self writeString: @"WHO %@", aMask];
	}
	
	return self;
}
- (id)whois: (NSString *)aPerson onServer: (NSString *)aServer
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whois: '%@' onServer: '%@'] Unusable person",
		 aPerson, aServer];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"WHOIS %@", aPerson];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whois: '%@' onServer: '%@'] Unusable server",
		  aPerson, aServer];
	}

	[self writeString: @"WHOIS %@ %@", aServer, aPerson];
	return self;
}
- (id)whowas: (NSString *)aPerson onServer: (NSString *)aServer
      withNumberEntries: (NSString *)aNumber
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whowas: '%@' onServer: '%@' withNumberEntries: '%@'] Unusable person",
		  aPerson, aServer, aNumber];
	}
	if ([aNumber length] == 0)
	{
		[self writeString: @"WHOWAS %@", aPerson];
		return self;
	}
	if ([(aNumber = string_to_string(aNumber, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whowas: '%@' onServer: '%@' withNumberEntries: '%@'] Unusable number of entries", 
		  aPerson, aServer, aNumber];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"WHOWAS %@ %@", aPerson, aNumber];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whowas: '%@' onServer: '%@' withNumberEntries: '%@'] Unusable server",
		  aPerson, aServer, aNumber];
	}

	[self writeString: @"WHOWAS %@ %@ %@", aPerson, aNumber, aServer];
	return self;
}
- (id)kill: (NSString *)aPerson withComment: (NSString *)aComment
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject kill: '%@' withComment: '%@'] Unusable person",
		 aPerson, aComment];
	}
	if ([aComment length] == 0)
	{
		return self;
	}

	[self writeString: @"KILL %@ :%@", aPerson, aComment];
	return self;
}
- (id)setTopicForChannel: (NSString *)aChannel to: (NSString *)aTopic
{
	if ([aChannel length] == 0)
	{
		return self;
	}
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject setTopicForChannel: %@ to: %@] Unusable channel",
		   aChannel, aTopic];
	}

	if ([aTopic length] == 0)
	{
		[self writeString: @"TOPIC %@", aChannel];
	}
	else
	{
		[self writeString: @"TOPIC %@ :%@", aChannel, aTopic];
	}

	return self;
}
- (id)setMode: (NSString *)aMode on: (NSString *)anObject 
                     withParams: (NSArray *)aList
{
	NSMutableString *aString;
	NSEnumerator *iter;
	id object;
	
	if ([anObject length] == 0)
	{
		return self;
	}
	if ([(anObject = string_to_string(anObject, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		  @"[IRCObject setMode:'%@' on:'%@' withParams:'%@'] Unusable object", 
		    aMode, anObject, aList];
	}
	if ([aMode length] == 0)
	{
		[self writeString: @"MODE %@", anObject];
		return self;
	}
	if ([(aMode = string_to_string(aMode, @" ")) length] == 0)
	{		
		[NSException raise: IRCException format:
		  @"[IRCObject setMode:'%@' on:'%@' withParams:'%@'] Unusable mode", 
		    aMode, anObject, aList];
	}
	if (!aList)
	{
		[self writeString: @"MODE %@ %@", anObject, aMode];
		return self;
	}
	
	aString = [NSMutableString stringWithFormat: @"MODE %@ %@", 
	            anObject, aMode];
				
	iter = [aList objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[aString appendString: @" "];
		[aString appendString: object];
	}
	
	[self writeString: @"%@", aString];

	return self;
}
- (id)listChannel: (NSString *)aChannel onServer: (NSString *)aServer
{
	if ([aChannel length] == 0)
	{
		[self writeString: @"LIST"];
		return self;
	}
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject listChannel:'%@' onServer:'%@'] Unusable channel",
		  aChannel, aServer];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"LIST %@", aChannel];
		return self;
	}
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject listChannel:'%@' onServer:'%@'] Unusable server",
		  aChannel, aServer];
	}
	
	[self writeString: @"LIST %@ %@", aChannel, aServer];
	return self;
}
- (id)invite: (NSString *)aPerson to: (NSString *)aChannel
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([aChannel length] == 0)
	{
		return self;
	}
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject invite:'%@' to:'%@'] Unusable person",
		  aPerson, aChannel];
	}
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject invite:'%@' to:'%@'] Unusable channel",
		  aPerson, aChannel];
	}
	
	[self writeString: @"INVITE %@ %@", aPerson, aChannel];
	return self;
}
- (id)kick: (NSString *)aPerson offOf: (NSString *)aChannel for: (NSString *)aReason
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([aChannel length] == 0)
	{
		return self;
	}
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject kick:'%@' offOf:'%@' for:'%@'] Unusable person",
		  aPerson, aChannel, aReason];
	}
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject kick:'%@' offOf:'%@' for:'%@'] Unusable channel",
		  aPerson, aChannel, aReason];
	}
	if ([aReason length] == 0)
	{
		[self writeString: @"KICK %@ %@", aChannel, aPerson];
		return self;
	}

	[self writeString: @"KICK %@ %@ :%@", aChannel, aPerson, aReason];
	return self;
}
- (id)setAwayWithMessage: (NSString *)aMessage
{
	if ([aMessage length] == 0)
	{
		[self writeString: @"AWAY"];
		return self;
	}

	[self writeString: @"AWAY :%@", aMessage];
	return self;
}
- (id)sendPingWithArgument: (NSString *)aString
{
	if (!aString)
	{
		aString = @"";
	}

	[self writeString: @"PING :%@", aString];
	
	return self;
}
- (id)sendPongWithArgument: (NSString *)aString
{
	if (!aString)
	{
		aString = @"";
	}

	[self writeString: @"PONG :%@", aString];
	
	return self;
}
@end

@implementation IRCObject (Callbacks)
- (id)registeredWithServer
{
	return self;
}
- (id)couldNotRegister: (NSString *)aReason
{
	return self;
}	
- (id)CTCPRequestReceived: (NSString *)aCTCP
   withArgument: (NSString *)anArgument to: (NSString *)aReceiver
   from: (NSString *)aPerson
{
	return self;
}
- (id)CTCPReplyReceived: (NSString *)aCTCP
   withArgument: (NSString *)anArgument to: (NSString *)aReceiver
   from: (NSString *)aPerson
{
	return self;
}
- (id)errorReceived: (NSString *)anError
{
	return self;
}
- (id)wallopsReceived: (NSString *)aMessage from: (NSString *)aSender
{
	return self;
}
- (id)userKicked: (NSString *)aPerson outOf: (NSString *)aChannel 
         for: (NSString *)aReason from: (NSString *)aKicker
{
	return self;
}
- (id)invitedTo: (NSString *)aChannel from: (NSString *)anInviter
{
	return self;
}
- (id)modeChanged: (NSString *)aMode on: (NSString *)anObject 
    withParams: (NSArray *)paramList from: (NSString *)aPerson
{
	return self;
}
- (id)numericCommandReceived: (NSString *)aCommand withParams: (NSArray *)paramList 
    from: (NSString *)aSender
{
	return self;
}
- (id)nickChangedTo: (NSString *)newName from: (NSString *)aPerson
{
	return self;
}
- (id)channelJoined: (NSString *)aChannel from: (NSString *)aJoiner
{
	return self;
}
- (id)channelParted: (NSString *)aChannel withMessage: (NSString *)aMessage
             from: (NSString *)aParter
{
	return self;
}
- (id)quitIRCWithMessage: (NSString *)aMessage from: (NSString *)aQuitter
{
	return self;
}
- (id)topicChangedTo: (NSString *)aTopic in: (NSString *)aChannel
              from: (NSString *)aPerson
{
	return self;
}
- (id)messageReceived: (NSString *)aMessage to: (NSString *)aReceiver
               from: (NSString *)aSender
{
	return self;
}
- (id)noticeReceived: (NSString *)aNotice to: (NSString *)aReceiver
              from: (NSString *)aSender
{
	return self;
}
- (id)actionReceived: (NSString *)anAction to: (NSString *)aReceiver
              from: (NSString *)aSender
{
	return self;
}
- (id)pingReceivedWithArgument: (NSString *)anArgument from: (NSString *)aSender
{
	return self;
}
- (id)pongReceivedWithArgument: (NSString *)anArgument from: (NSString *)aSender
{
	return self;
}
- (id)newNickNeededWhileRegistering
{
	[self changeNick: [NSString stringWithFormat: @"%@_", nick]];
	
	return self;
}
@end

@implementation IRCObject (LowLevel)
- (id)lineReceived: (NSData *)aLine
{
	NSString *prefix = nil;
	NSString *command = nil;
	NSMutableArray *paramList = nil;
	id object;
	void (*function)(IRCObject *, NSString *, NSString *, NSArray *);
	NSString *line, *orig;
	
	orig = line = AUTORELEASE([[NSString alloc] initWithData: aLine
	  encoding: defaultEncoding]);

	if ([line length] == 0)
	{
		return self;
	}
	
	paramList = AUTORELEASE([NSMutableArray new]);
	
	line = get_IRC_prefix(line, &prefix); 
	
	if ([line length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject lineReceived: '%@'] Line ended prematurely.",
		 orig];
	}

	line = get_next_IRC_word(line, &command);
	if (command == nil)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject lineReceived: '%@'] Line ended prematurely.",
		 orig];
	}

	while (1)
	{
		line = get_next_IRC_word(line, &object);
		if (!object)
		{
			break;
		}
		[paramList addObject: object];
	}
	
	if (is_numeric_command(command))
	{		
		if ([paramList count] >= 2)
		{
			NSRange aRange;

			[self setNick: [paramList objectAtIndex: 0]];

			aRange.location = 1;
			aRange.length = [paramList count] - 1;

			rec_numeric(self, command, prefix, 
			            [paramList subarrayWithRange: aRange]);
		}	
	}
	else
	{
		function = NSMapGet(command_to_function, command);
		if (function != 0)
		{
			function(self, command, prefix, paramList);
		}
		else
		{
			NSLog(@"Could not handle :%@ %@ %@", prefix, command, paramList);
		}
	}

	if (!connected)
	{
		if ([command isEqualToString: ERR_NEEDMOREPARAMS] ||
			[command isEqualToString: ERR_ALREADYREGISTRED] ||
			[command isEqualToString: ERR_NONICKNAMEGIVEN])
		{
			[[NetApplication sharedInstance] disconnectObject: self];
			[self couldNotRegister: [NSString stringWithFormat:
			 @"%@ %@ %@", prefix, command, paramList]];
			return nil;
		}
		else if ([command isEqualToString: ERR_NICKNAMEINUSE] ||
		         [command isEqualToString: ERR_NICKCOLLISION] ||
				 [command isEqualToString: ERR_ERRONEUSNICKNAME])
		{
			[self newNickNeededWhileRegistering];
		}
		else if ([command isEqualToString: RPL_WELCOME])
		{
			connected = YES;
			[self registeredWithServer];
		}
	}
	
	return self;
}
- (id)writeString: (NSString *)format, ...
{
	NSString *temp;
	va_list ap;

	va_start(ap, format);
	temp = AUTORELEASE([[NSString alloc] initWithFormat: format 
	  arguments: ap]);

	[(id <NetTransport>)transport writeData: [temp dataUsingEncoding: defaultEncoding]];
	
	if (![temp hasSuffix: @"\r\n"])
	{
		[(id <NetTransport>)transport writeData: IRC_new_line];
	}
	return self;
}
@end

NSString *RPL_WELCOME = @"001";
NSString *RPL_YOURHOST = @"002";
NSString *RPL_CREATED = @"003";
NSString *RPL_MYINFO = @"004";
NSString *RPL_BOUNCE = @"005";
NSString *RPL_ISUPPORT = @"005";
NSString *RPL_USERHOST = @"302";
NSString *RPL_ISON = @"303";
NSString *RPL_AWAY = @"301";
NSString *RPL_UNAWAY = @"305";
NSString *RPL_NOWAWAY = @"306";
NSString *RPL_WHOISUSER = @"311";
NSString *RPL_WHOISSERVER = @"312";
NSString *RPL_WHOISOPERATOR = @"313";
NSString *RPL_WHOISIDLE = @"317";
NSString *RPL_ENDOFWHOIS = @"318";
NSString *RPL_WHOISCHANNELS = @"319";
NSString *RPL_WHOWASUSER = @"314";
NSString *RPL_ENDOFWHOWAS = @"369";
NSString *RPL_LISTSTART = @"321";
NSString *RPL_LIST = @"322";
NSString *RPL_LISTEND = @"323";
NSString *RPL_UNIQOPIS = @"325";
NSString *RPL_CHANNELMODEIS = @"324";
NSString *RPL_NOTOPIC = @"331";
NSString *RPL_TOPIC = @"332";
NSString *RPL_INVITING = @"341";
NSString *RPL_SUMMONING = @"342";
NSString *RPL_INVITELIST = @"346";
NSString *RPL_ENDOFINVITELIST = @"347";
NSString *RPL_EXCEPTLIST = @"348";
NSString *RPL_ENDOFEXCEPTLIST = @"349";
NSString *RPL_VERSION = @"351";
NSString *RPL_WHOREPLY = @"352";
NSString *RPL_ENDOFWHO = @"315";
NSString *RPL_NAMREPLY = @"353";
NSString *RPL_ENDOFNAMES = @"366";
NSString *RPL_LINKS = @"364";
NSString *RPL_ENDOFLINKS = @"365";
NSString *RPL_BANLIST = @"367";
NSString *RPL_ENDOFBANLIST = @"368";
NSString *RPL_INFO = @"371";
NSString *RPL_ENDOFINFO = @"374";
NSString *RPL_MOTDSTART = @"375";
NSString *RPL_MOTD = @"372";
NSString *RPL_ENDOFMOTD = @"376";
NSString *RPL_YOUREOPER = @"381";
NSString *RPL_REHASHING = @"382";
NSString *RPL_YOURESERVICE = @"383";
NSString *RPL_TIME = @"391";
NSString *RPL_USERSSTART = @"392";
NSString *RPL_USERS = @"393";
NSString *RPL_ENDOFUSERS = @"394";
NSString *RPL_NOUSERS = @"395";
NSString *RPL_TRACELINK = @"200";
NSString *RPL_TRACECONNECTING = @"201";
NSString *RPL_TRACEHANDSHAKE = @"202";
NSString *RPL_TRACEUNKNOWN = @"203";
NSString *RPL_TRACEOPERATOR = @"204";
NSString *RPL_TRACEUSER = @"205";
NSString *RPL_TRACESERVER = @"206";
NSString *RPL_TRACESERVICE = @"207";
NSString *RPL_TRACENEWTYPE = @"208";
NSString *RPL_TRACECLASS = @"209";
NSString *RPL_TRACERECONNECT = @"210";
NSString *RPL_TRACELOG = @"261";
NSString *RPL_TRACEEND = @"262";
NSString *RPL_STATSLINKINFO = @"211";
NSString *RPL_STATSCOMMANDS = @"212";
NSString *RPL_ENDOFSTATS = @"219";
NSString *RPL_STATSUPTIME = @"242";
NSString *RPL_STATSOLINE = @"243";
NSString *RPL_UMODEIS = @"221";
NSString *RPL_SERVLIST = @"234";
NSString *RPL_SERVLISTEND = @"235";
NSString *RPL_LUSERCLIENT = @"251";
NSString *RPL_LUSEROP = @"252";
NSString *RPL_LUSERUNKNOWN = @"253";
NSString *RPL_LUSERCHANNELS = @"254";
NSString *RPL_LUSERME = @"255";
NSString *RPL_ADMINME = @"256";
NSString *RPL_ADMINLOC1 = @"257";
NSString *RPL_ADMINLOC2 = @"258";
NSString *RPL_ADMINEMAIL = @"259";
NSString *RPL_TRYAGAIN = @"263";
NSString *ERR_NOSUCHNICK = @"401";
NSString *ERR_NOSUCHSERVER = @"402";
NSString *ERR_NOSUCHCHANNEL = @"403";
NSString *ERR_CANNOTSENDTOCHAN = @"404";
NSString *ERR_TOOMANYCHANNELS = @"405";
NSString *ERR_WASNOSUCHNICK = @"406";
NSString *ERR_TOOMANYTARGETS = @"407";
NSString *ERR_NOSUCHSERVICE = @"408";
NSString *ERR_NOORIGIN = @"409";
NSString *ERR_NORECIPIENT = @"411";
NSString *ERR_NOTEXTTOSEND = @"412";
NSString *ERR_NOTOPLEVEL = @"413";
NSString *ERR_WILDTOPLEVEL = @"414";
NSString *ERR_BADMASK = @"415";
NSString *ERR_UNKNOWNCOMMAND = @"421";
NSString *ERR_NOMOTD = @"422";
NSString *ERR_NOADMININFO = @"423";
NSString *ERR_FILEERROR = @"424";
NSString *ERR_NONICKNAMEGIVEN = @"431";
NSString *ERR_ERRONEUSNICKNAME = @"432";
NSString *ERR_NICKNAMEINUSE = @"433";
NSString *ERR_NICKCOLLISION = @"436";
NSString *ERR_UNAVAILRESOURCE = @"437";
NSString *ERR_USERNOTINCHANNEL = @"441";
NSString *ERR_NOTONCHANNEL = @"442";
NSString *ERR_USERONCHANNEL = @"443";
NSString *ERR_NOLOGIN = @"444";
NSString *ERR_SUMMONDISABLED = @"445";
NSString *ERR_USERSDISABLED = @"446";
NSString *ERR_NOTREGISTERED = @"451";
NSString *ERR_NEEDMOREPARAMS = @"461";
NSString *ERR_ALREADYREGISTRED = @"462";
NSString *ERR_NOPERMFORHOST = @"463";
NSString *ERR_PASSWDMISMATCH = @"464";
NSString *ERR_YOUREBANNEDCREEP = @"465";
NSString *ERR_YOUWILLBEBANNED = @"466";
NSString *ERR_KEYSET = @"467";
NSString *ERR_CHANNELISFULL = @"471";
NSString *ERR_UNKNOWNMODE = @"472";
NSString *ERR_INVITEONLYCHAN = @"473";
NSString *ERR_BANNEDFROMCHAN = @"474";
NSString *ERR_BADCHANNELKEY = @"475";
NSString *ERR_BADCHANMASK = @"476";
NSString *ERR_NOCHANMODES = @"477";
NSString *ERR_BANLISTFULL = @"478";
NSString *ERR_NOPRIVILEGES = @"481";
NSString *ERR_CHANOPRIVSNEEDED = @"482";
NSString *ERR_CANTKILLSERVER = @"483";
NSString *ERR_RESTRICTED = @"484";
NSString *ERR_UNIQOPPRIVSNEEDED = @"485";
NSString *ERR_NOOPERHOST = @"491";
NSString *ERR_UMODEUNKNOWNFLAG = @"501";
NSString *ERR_USERSDONTMATCH = @"502";
NSString *RPL_SERVICEINFO = @"231";
NSString *RPL_ENDOFSERVICES = @"232";
NSString *RPL_SERVICE = @"233";
NSString *RPL_NONE = @"300";
NSString *RPL_WHOISCHANOP = @"316";
NSString *RPL_KILLDONE = @"361";
NSString *RPL_CLOSING = @"262";
NSString *RPL_CLOSEEND = @"363";
NSString *RPL_INFOSTART = @"373";
NSString *RPL_MYPORTIS = @"384";
NSString *RPL_STATSCLINE = @"213";
NSString *RPL_STATSNLINE = @"214";
NSString *RPL_STATSILINE = @"215";
NSString *RPL_STATSKLINE = @"216";
NSString *RPL_STATSQLINE = @"217";
NSString *RPL_STATSYLINE = @"218";
NSString *RPL_STATSVLINE = @"240";
NSString *RPL_STATSLLINE = @"241";
NSString *RPL_STATSHLINE = @"244";
NSString *RPL_STATSSLINE = @"245";
NSString *RPL_STATSPING = @"246";
NSString *RPL_STATSBLINE = @"247";
NSString *RPL_STATSDLINE = @"250";
NSString *ERR_NOSERVICEHOST = @"492";
