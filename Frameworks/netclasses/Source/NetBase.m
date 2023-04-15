/***************************************************************************
                                NetBase.m
                          -------------------
    begin                : Fri Nov  2 01:19:16 UTC 2001
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
 * <title>NetBase reference</title>
 * <author name="Andrew Ruder">
 * 	<email address="aeruder@ksu.edu" />
 * 	<url url="http://www.aeruder.net" />
 * </author>
 * <version>Revision 1</version>
 * <date>November 8, 2003</date>
 * <copy>Andrew Ruder</copy>
 */

#import "NetBase.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSAutoreleasePool.h>

#include <string.h>
#include <config.h>
#include <unistd.h> /* for intptr_t */

NSString *NetException = @"NetException";
NSString *FatalNetException = @"FatalNetException";

NetApplication *netApplication;

#ifndef GNUSTEP
#include <CoreFoundation/CoreFoundation.h>

static NSMapTable *desc_to_info = 0;

typedef struct {
	CFSocketRef socket;
	CFRunLoopSourceRef source;
	int modes;
	NSMapTable *watchers;
} net_socket_info;

static void handle_cf_events(CFSocketRef s, CFSocketCallBackType callbackType,
  CFDataRef address, const void *data, void *info);

static void remove_info_for_socket(int desc)
{
	net_socket_info *x;

	x = NSMapGet(desc_to_info, (void *)desc);

	if (!x) return;

	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), x->source,
	  kCFRunLoopDefaultMode);

	CFRelease(x->source);
	CFRelease(x->socket);
	NSFreeMapTable(x->watchers);
	free(x);

	NSMapRemove(desc_to_info, (void *)desc);

	return;
}

static BOOL is_info_for_socket(int desc)
{
	return NSMapGet(desc_to_info, (void *)desc) != 0;
}

static net_socket_info *info_for_socket(int desc)
{
	CFSocketRef sock;
	CFRunLoopSourceRef source;
	net_socket_info *x;

	x = NSMapGet(desc_to_info, (void *)desc);

	if (x) return x;

	sock = CFSocketCreateWithNative(
	  NULL, desc, kCFSocketReadCallBack | kCFSocketWriteCallBack, handle_cf_events, NULL );
	
	CFSocketDisableCallBacks( sock, kCFSocketWriteCallBack | kCFSocketReadCallBack);

	if (!sock) return NULL;

	source = CFSocketCreateRunLoopSource(
	  NULL, sock, 1);

	if (!source)
	{
		CFRelease(sock);
		return NULL;
	}

	x = malloc (sizeof(net_socket_info));

	x->socket = sock;
	x->source = source;
	x->modes = 0;
	x->watchers = NSCreateMapTable(NSIntMapKeyCallBacks, 
	 NSObjectMapValueCallBacks, 100);

	NSMapInsert(desc_to_info, (void *)desc, (void *)x);

	CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);

	return x;
}

static void handle_cf_events(CFSocketRef s, CFSocketCallBackType callbackType,
  CFDataRef address, const void *data, void *info)
{
	int desc;
	net_socket_info *x;

	desc = (int)CFSocketGetNative(s);

	if (!is_info_for_socket(desc))
	{
		return;
	}
	x = info_for_socket(desc); 

	if (!x) return;

	if (callbackType & kCFSocketWriteCallBack)
	{
		[(id)NSMapGet(x->watchers, (void *)(1 << ET_WDESC)) 
		  receivedEvent: (void *)desc
		  type: ET_WDESC extra: 0 forMode: nil];
	}
	if (callbackType & kCFSocketReadCallBack)
	{
		[(id)NSMapGet(x->watchers, (void *)(1 << ET_RDESC)) 
		  receivedEvent: (void *)desc
		  type: ET_RDESC extra: 0 forMode: nil];
	}
}

@interface NSRunLoop (RunLoopEventsAdditions)
- (void) addEvent: (void *)data type: (RunLoopEventType)type
  watcher: (id)watcher forMode: (NSString *)mode;
- (void) removeEvent: (void *)data type: (RunLoopEventType)type
   forMode: (NSString *)mode all: (BOOL)removeAll;
@end

@implementation NSRunLoop (RunLoopEventsAdditions)
+ (void) initialize
{
	desc_to_info = NSCreateMapTable(NSIntMapKeyCallBacks, 
	 NSIntMapValueCallBacks, 100);
}
- (void) addEvent: (void *)data type: (RunLoopEventType)type
  watcher: (id)watcher forMode: (NSString *)mode
{
	int desc = (int)data;
	int add_mode = (int)type;
	net_socket_info *x;


	x = info_for_socket(desc);

	if (x->modes & (1 << add_mode)) return;

	switch(add_mode)
	{
		case ET_RDESC:
			CFSocketEnableCallBacks( x->socket, kCFSocketReadCallBack );
			x->modes |= (1 << add_mode);
			NSMapInsert(x->watchers, (void *)(1 << add_mode), (void *)watcher);
			break;
		case ET_WDESC:
			CFSocketEnableCallBacks( x->socket, kCFSocketWriteCallBack );
			x->modes |= (1 << add_mode);
			NSMapInsert(x->watchers, (void *)(1 << add_mode), (void *)watcher);
			break;
		default:
			break;
	}
}

- (void) removeEvent: (void *)data type: (RunLoopEventType)type
   forMode: (NSString *)mode all: (BOOL)removeAll
{
	int desc = (int)data;
	int remove_mode = (int)type;
	net_socket_info *x;

	if (!is_info_for_socket(desc))
	{
		return;
	}

	x = info_for_socket(desc);

	switch(remove_mode)
	{
		case ET_RDESC:
			CFSocketDisableCallBacks( x->socket, kCFSocketReadCallBack );
			x->modes &= ~(1 << remove_mode);
			NSMapRemove(x->watchers, (void *)(1 << remove_mode));
			break;
		case ET_WDESC:
			CFSocketDisableCallBacks( x->socket, kCFSocketWriteCallBack );
			x->modes &= ~(1 << remove_mode);
			NSMapRemove(x->watchers, (void *)(1 << remove_mode));
			break;
		default:
			break;
	}

	if (x->modes == 0)
	{
		remove_info_for_socket(desc);
	}

}
@end
#endif

@implementation NetApplication
+ (int)netclassesMinorVersion
{
	int x;

	sscanf(PACKAGE_VERSION, "%*d.%d", &x);

	return x;
}
+ (int)netclassesMajorVersion
{
	int x;

	sscanf(PACKAGE_VERSION, "%d.%*d", &x);

	return x;
}
+ (NSString *)netclassesVersion
{
	return [NSString stringWithCString: PACKAGE_VERSION];
}
+ sharedInstance
{
	return (netApplication) ? (netApplication) : [[NetApplication alloc] init];
}
- init
{
	if (!(self = [super init])) return nil;
	if (netApplication)
	{
		[super dealloc];
		return nil;
	}
	netApplication = RETAIN(self);
	
	descTable = NSCreateMapTable(NSIntMapKeyCallBacks, 
	 NSNonRetainedObjectMapValueCallBacks, 100);
	
	portArray = [NSMutableArray new];
	netObjectArray = [NSMutableArray new];
	badDescs = [NSMutableArray new];
	return self;
}
- (void)dealloc  // How in the world...
{
	RELEASE(portArray);
	RELEASE(netObjectArray);
	RELEASE(badDescs);
	NSFreeMapTable(descTable);
	
	netApplication = nil;
	[super dealloc];
}
- (NSDate *)timedOutEvent: (void *)data
                     type: (RunLoopEventType)type
                  forMode: (NSString *)mode
{
	return nil;
}
- (void)receivedEvent: (void *)data
                 type: (RunLoopEventType)type
                extra: (void *)extra
              forMode: (NSString *)mode
{
	id object;

	object = (id)NSMapGet(descTable, data);
	if (!object)
	{
		[[NSRunLoop currentRunLoop] removeEvent: data
		 type: type forMode: NSDefaultRunLoopMode all: YES];
		return;
	}
	AUTORELEASE(RETAIN(object));
	
	NS_DURING
		switch(type)
		{
			default:
				break;
			case ET_RDESC:
				if ([object conformsToProtocol: @protocol(NetObject)])
				{
					[object dataReceived: [[object transport] readData: 0]];
				}
				else
				{
					[object setupNewConnection];
				}
				break;
			case ET_WDESC:
				[[object transport] writeData: nil];
				if ([[object transport] isDoneWriting])
				{
					[[NSRunLoop currentRunLoop] removeEvent: data
					 type: ET_WDESC forMode: NSDefaultRunLoopMode all: YES];
				}
				break;
			case ET_EDESC:
				[self disconnectObject: self];
				break;
		}
	NS_HANDLER
		if (([[localException name] isEqualToString:NetException]) ||
		    ([[localException name] isEqualToString:FatalNetException]))
		{
			if (type == ET_RDESC) 
			{
				id data;
				data = [[localException userInfo]
				  objectForKey: @"Data"];
				if (data && ([data length] > 0))
				{
					[object dataReceived: data];
				}
			}	
			[self disconnectObject: object];
		}
		else
		{
			[localException raise];
		}
	NS_ENDHANDLER																
}
- connectObject: anObject
{
	void *desc = 0;
	
	if ([anObject conformsToProtocol: @protocol(NetPort)])
	{ 
	  desc = (void *)(intptr_t)[anObject desc];
		
	  [portArray addObject: anObject];
	}
	else if ([anObject conformsToProtocol: @protocol(NetObject)])
	{
	  desc = (void *)(intptr_t)[[anObject transport] desc];
		
	  [netObjectArray addObject: anObject];
	}
	else
	{		
		[NSException raise: NetException 
		  format: @"[NetApplication addObject:] %@ does not follow "
		          @"< NetPort > or < NetObject >", 
		    NSStringFromClass([anObject class])];
	}
	NSMapInsert(descTable, desc, anObject);
	
	[[NSRunLoop currentRunLoop] addEvent: desc type: ET_EDESC
	 watcher: self forMode: NSDefaultRunLoopMode];
		
	[[NSRunLoop currentRunLoop] addEvent: desc type: ET_RDESC
	 watcher: self forMode: NSDefaultRunLoopMode];
	
	return self;
}

- disconnectObject: anObject
{
	id whichOne = nil;
	
	void *desc = 0;
	
	if ([portArray containsObject: anObject])
	{
		whichOne = portArray;
		
		desc = (void *)(intptr_t)[anObject desc];
	}
	else if ([netObjectArray containsObject: anObject])
	{
		whichOne = netObjectArray;
		
		desc = (void *)(intptr_t)[[anObject transport] desc];
		
		[[NSRunLoop currentRunLoop] removeEvent: desc
		 type: ET_WDESC forMode: NSDefaultRunLoopMode all: YES];
	}	
	else
	{		
		return self;
	}
	[[NSRunLoop currentRunLoop] removeEvent: desc
	 type: ET_RDESC forMode: NSDefaultRunLoopMode all: YES];
		
	[[NSRunLoop currentRunLoop] removeEvent: desc
	 type: ET_EDESC forMode: NSDefaultRunLoopMode all: YES];
	
	NSMapRemove(descTable, desc);

	[anObject retain];
	[whichOne removeObject: anObject];
	[anObject autorelease];
		
	[anObject connectionLost];
	
	return self;
}
- closeEverything
{
	CREATE_AUTORELEASE_POOL(apr);
	
	while ([netObjectArray count] != 0)
	{
		[self disconnectObject: [netObjectArray objectAtIndex: 0]];
	}
	
	while ([portArray count] != 0)
	{
		[self disconnectObject: [portArray objectAtIndex: 0]];
	}

	RELEASE(apr);
	return self;
}
- transportNeedsToWrite: (id <NetTransport>)aTransport
{
	int desc = [aTransport desc];

	if ((id)NSMapGet(descTable, (void *)(intptr_t)desc))
	{
		[[NSRunLoop currentRunLoop] addEvent: 
		 (void *)desc type: ET_WDESC watcher: self 
		 forMode: NSDefaultRunLoopMode];
	}
	return self;
}
- (NSArray *)netObjectArray
{
	return [NSArray arrayWithArray: netObjectArray];
}
- (NSArray *)portArray
{
	return [NSArray arrayWithArray: portArray];
}
@end

