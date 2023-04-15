/***************************************************************************
                                NetTCP.h
                          -------------------
    begin                : Fri Nov  2 01:19:16 UTC 2001
    copyright            : (C) 2005 by Andrew Ruder
                         : (C) 2015-2016 The GAP Team
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

@class TCPSystem, TCPConnecting, TCPPort, TCPTransport;

#ifndef NET_TCP_H
#define NET_TCP_H

#import "NetBase.h"
#import <Foundation/NSObject.h>

#include <netinet/in.h>
#include <stdint.h>

@class NSString, NSNumber, NSString, NSData, NSMutableData, TCPConnecting;
@class TCPTransport, TCPSystem, NSHost;

/**
 * If an error occurs and error number is zero, this could be the error string.
 * This error occurs when some operation times out.
 */
extern NSString *NetclassesErrorTimeout;
/**
 * Could be the current error string if the error number is zero and some
 * error has occurred.  Indicates
 * that a NSHost returned an address that was invalid.
 */
extern NSString *NetclassesErrorBadAddress;
/**
 * The error message used when a connection is aborted.
 */
extern NSString *NetclassesErrorAborted;
 
/**
 * A class can implement this protocol, and when it is connected in the 
 * background using -connectNetObjectInBackground:toHost:onPort:withTimeout:
 * it will receive the messages in this protocol which notify the object of
 * certain events while being connected in the background.
 */
@protocol TCPConnecting
/** 
 * Tells the class implementing this protocol that the error in 
 * <var>aError</var> has occurred and the connection will not 
 * be established
 */
- connectingFailed: (NSString *)aError;
/**
 * Tells the class implementing this protocol that the connection
 * has begun and will be using the connection place holder 
 * <var>aConnection</var>
 */
- connectingStarted: (TCPConnecting *)aConnection;
@end

/** 
 * Used for certain operations in the TCP/IP system.  There is only one
 * instance of this class at a time, used +sharedInstance to get this
 * instance.
 */
@interface TCPSystem : NSObject
	{
		NSString *errorString;
		int errorNumber;
	}
/**
 * Returns the one instance of TCPSystem currently in existence.
 */
+ sharedInstance;

/** 
 * Returns the error string of the last error that occurred.
 */
- (NSString *)errorString;
/**
 * Returns the errno of the last error that occurred.  If it is some other
 * non-system error, this will be zero, but the error string shall be set
 * accordingly.
 */
- (int)errorNumber;

/** 
 * Will connect the object <var>netObject</var> to host <var>aHost</var>
 * on port <var>aPort</var>.  If this connection doesn't happen in 
 * <var>aTimeout</var> seconds or some other error occurs, it will return
 * nil and the error string and error number shall be set accordingly.
 * Otherwise this will return <var>netObject</var>
 */
- (id <NetObject>)connectNetObject: (id <NetObject>)netObject toHost: (NSHost *)aHost 
                onPort: (uint16_t)aPort withTimeout: (int)aTimeout;

/**
 * Connects <var>netObject</var> to host <var>aHost</var> on the port 
 * <var>aPort</var>.  Returns a place holder object that finishes the
 * connection in the background.  The placeholder will fail if the connection
 * does not occur in <var>aTimeout</var> seconds.  Returns nil if an error 
 * occurs and sets the error string and error number accordingly.
 */
- (TCPConnecting *)connectNetObjectInBackground: (id <NetObject>)netObject
    toHost: (NSHost *)aHost onPort: (uint16_t)aPort withTimeout: (int)aTimeout;

/**
 * Returns a host order 32-bit integer from a host
 * Returns YES on success and NO on failure, the result is stored in the
 * 32-bit integer pointed to by <var>aNumber</var>
 */
- (BOOL)hostOrderInteger: (uint32_t *)aNumber fromHost: (NSHost *)aHost;
/**
 * Returns a network order 32-bit integer from a host
 * Returns YES on success and NO on failure, the result is stored in the
 * 32-bit integer pointed to by <var>aNumber</var>
 */
- (BOOL)networkOrderInteger: (uint32_t *)aNumber fromHost: (NSHost *)aHost;

/**
 * Returns a host from a network order 32-bit integer ip address.
 */
- (NSHost *)hostFromHostOrderInteger: (uint32_t)ip;
/**
 * Returns a host from a host order 32-bit integer ip address.
 */
- (NSHost *)hostFromNetworkOrderInteger: (uint32_t)ip;
@end

/**
 * If an object was attempted to have been connected in the background, this 
 * is a placeholder for that ongoing connection.  
 * -connectNetObjectInBackground:toHost:onPort:withTimeout: will return an 
 * instance of this object.  This placeholder object can be used to cancel
 * an ongoing connection with the -abortConnection method.
 */
@interface TCPConnecting : NSObject < NetObject >
	{
		id <NetTransport>transport;
		id netObject;
		NSTimer *timeout;
	}
/**
 * Returns the object that will be connected by this placeholder object.
 */
- (id <NetObject>)netObject;
/**
 * Aborts the ongoing connection.  If the net object conforms to the 
 * [(TCPConnecting)] protocol, it will receive a 
 * [(TCPConnecting)-connectingFailed:] message with a argument of
 * <code>NetclassesErrorAborted</code>
 */
- (void)abortConnection;

/**
 * Cleans up the connection placeholder.  This will release the transport.
 */
- (void)connectionLost;
/**
 * Sets up the connection placeolder.  If the net object conforms to 
 * [(TCPConnecting)], it will receive a 
 * [(TCPConnecting)-connectingStarted:] with the instance of TCPConnecting
 * as an argument.
 */
- connectionEstablished: (id <NetTransport>)aTransport;
/**
 * This shouldn't happen while a class is connecting, but included to 
 * conform to the [(NetObject)] protocol.
 */
- (id <NetObject>)dataReceived: (NSData *)data;
/**
 * Returns the transport used by this object.  Will not be the same transport
 * given to the net object when the connection is made.
 */
- (id <NetTransport>)transport;
@end

/**
 * TCPPort is a class that is used to bind a descriptor to a certain
 * TCP/IP port and listen for connections.  When a connection is received,
 * it will create a class set with -setNetObject: and set it up with the new
 * connection.  When the TCPPort is dealloc'd it will close the descriptor
 * if it had not been closed already.
 */
@interface TCPPort : NSObject < NetPort >
    {
		int desc;
		Class netObjectClass;
		uint16_t port;
		BOOL connected;
	}
/**
 * Calls -initOnHost:onPort: with a nil argument for the host.
 */
- initOnPort: (uint16_t)aPort;
/** 
 * Initializes a port on <var>aHost</var> and binds it to port <var>aPort</var>.
 * If <var>aHost</var> is nil, it will set it up on all addresses on the local
 * machine.  Using zero for <var>aPort</var> will use a random currently 
 * available port number.  Use -port to find out where it is actually
 * bound to.
 */
- initOnHost: (NSHost *)aHost onPort: (uint16_t)aPort;

/**
 * Returns the port that this TCPPort is currently bound to.
 */
- (uint16_t)port;
/**
 * Sets the class that will be initialized if a connection occurs on this
 * port.  If <var>aClass</var> does not implement the [(NetObject)]
 * protocol, will throw a FatalNetException.
 */
- setNetObject: (Class)aClass;
/**
 * Returns the low-level file descriptor for the port.
 */
- (int)desc;
/**
 * Closes the descriptor.
 */
- (void)close;
/**
 * Called when the connection is closed.
 */
- (void)connectionLost;

/**
 * Called when a new connection occurs.  Will initialize a new object
 * of the class set with -setNetObject: with the new connection.
 */
- (id <NetPort>)setupNewConnection;
@end

/**
 * Handles the actual TCP/IP transfer of data.  When an instance of this
 * object is deallocated, the descriptor will be closed if not already
 * closed.
 */
@interface TCPTransport : NSObject < NetTransport >
    {
		int desc;
		BOOL connected;
		NSMutableData *writeBuffer;
		NSHost *remoteHost;
		NSHost *localHost;
	}
/** 
 * Initializes the transport with the file descriptor <var>aDesc</var>.
 * <var>theAddress</var> is the host that the flie descriptor is connected
 * to.
 */
- (id)initWithDesc: (int)aDesc withRemoteHost: (NSHost *)theAddress;
/**
 * Handles the actual reading of data from the connection.
 * Throws an exception if an error occurs while reading data.
 * The @"Data" key in the userInfo for these exceptions should
 * be any NSData that could not be returned.
 *
 * If <var>maxDataSize</var> is &lt;= 0, all possible data will be
 * read.
 */
- (NSData *)readData: (int)maxDataSize;
/**
 * Returns YES if there is no more data to write in the buffer and NO if 
 * there is.
 */
- (BOOL)isDoneWriting;
/**
 * If <var>aData</var> is nil, this will physically transport the data
 * to the connected end.  Otherwise this will put the data in the buffer of 
 * data that needs to be written to the connection when next possible.
 */
- (id <NetTransport>)writeData: (NSData *)aData;
/**
 * Returns a NSHost of the local side of a connection.
 */
- (id)localHost;
/** 
 * Returns a NSHost of the remote side of a connection.
 */
- (id)remoteHost;
/**
 * Returns the low level file descriptor that is used internally.
 */
- (int)desc;
/**
 * Closes the transport and makes sure there is no more incoming or outgoing
 * data on the connection.
 */
- (void)close;
@end

#endif
