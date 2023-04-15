/***************************************************************************
                             SimpleClient.h
                          -------------------
    begin                : Tue Feb 17 00:04:54 CST 2004
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

@class SimpleClient;

#ifndef SIMPLE_CLIENT_H
#define SIMPLE_CLIENT_H

#import <netclasses/NetBase.h>
#import <Foundation/NSObject.h>

@class NSData;

@interface SimpleClient : NSObject < NetObject >
	{
		id <NetTransport>transport;
		BOOL isConnected;
	}
- (BOOL)isConnected;
- (void)connectionLost;
- connectionEstablished: (id <NetTransport>)aTransport;
- dataReceived: (NSData *)data;
- (id <NetTransport>)transport;
@end

#endif
