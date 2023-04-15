/***************************************************************************
                                LineObject.h
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

@class LineObject;

#ifndef LINE_OBJECT_H
#define LINE_OBJECT_H

#import "NetBase.h"
#import <Foundation/NSObject.h>

@class NSMutableData, NSData;

/**
 * LineObject is used for line-buffered connections (end in \r\n or just \n).
 * To use, simply override lineReceived: in a subclass of LineObject.  By
 * default, LineObject does absolutely nothing with lineReceived except throw
 * the line away.  Use line object if you simply want line-buffered input.
 * This can be used on IRC, telnet, etc.
 */
@interface LineObject : NSObject < NetObject >
	{
		id <NetTransport>transport;
		NSMutableData *_readData;
	}
/**
 * Cleans up the instance variables and releases the transport.
 * If/when the transport is dealloc'd, the connection will be closed.
 */
- (void)connectionLost;
/**
 * Initializes data and retains <var>aTransport</var>
 * <var>aTransport</var> should conform to the [(NetTransport)]
 * protocol.
 */
- connectionEstablished: (id <NetTransport>)aTransport;
/**
 * Adds the data to a buffer.  Then calls -lineReceived: for all
 * full lines currently in the buffer.  Don't override this, override
 * -lineReceived:.
 */
- dataReceived: (NSData *)newData;
/**
 * Returns the transport
 */
- (id <NetTransport>)transport;

/**
 * <override-subclass />
 * <var>aLine</var> contains a full line of text (without the ending newline)
 */
- lineReceived: (NSData *)aLine;
@end

#endif
