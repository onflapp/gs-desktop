/***************************************************************************
                                NetBase.h
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

@class NetApplication;

#ifndef NET_BASE_H
#define NET_BASE_H

#import <Foundation/NSObject.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSMapTable.h>

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#ifndef GNUSTEP
#define CREATE_AUTORELEASE_POOL(X) \
NSAutoreleasePool *(X) = [NSAutoreleasePool new]

#define AUTORELEASE(object)      [object autorelease]
#define RELEASE(object)          [object release]
#define RETAIN(object)           [object retain]
#define DESTROY(object)          ({ \
  if (object) \
    { \
      id __o = object; \
        object = nil; \
          [__o release]; \
    } \
})

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4) && !defined(NSUInteger)
#define NSUInteger unsigned
#define NSInteger int
#endif

#endif

@class NSData, NSNumber, NSMutableDictionary, NSDictionary, NSArray;
@class NSMutableArray, NSString;

/**
 * A protocol used for the actual transport class of a connection.  A
 * transport is a low-level object which actually handles the physical
 * means of transporting data to the other side of the connection through
 * methods such as -readData: and -writeData:.
 */
@protocol NetTransport <NSObject>
/**
 * Returns an object representing the local side of a connection.  The actual
 * object depends on the implementation of this protocol.
 */
- (id)localHost;
/**
 * Returns an object representing the remote side of a connection.  The actual
 * object depends on the implementation of this protocol.
 */
- (id)remoteHost;
/**
 * This should serve two purposes.  When <var>data</var> is not nil,
 * the transport should store the data, and then call 
 * [NetApplication-transportNeedsToWrite:] to notify [NetApplication]
 * that the transport needs to write.
 *
 * When <var>data</var> is nil, the transport should assume that it is
 * actually safe to write the data and should do so at this time.  
 * [NetApplication] will call -writeData: with a nil argument when it is 
 * safe to write
 */
- (id <NetTransport>)writeData: (NSData *)data;
/**
 * Return YES if no more data is waiting to be written, and NO otherwise.
 * Used by [NetApplication] to determine when it can stop checking 
 * the transport for writing availability.
 */
- (BOOL)isDoneWriting;
/**
 * Called by [NetApplication] when it is safe to write.  Should return
 * data read from the connection with a maximum size of 
 * <var>maxReadSize</var>.  If <var>maxReadSize</var> should be zero, all
 * data available on the connection should be returned.
 */
- (NSData *)readData: (int)maxReadSize;
/**
 * Returns a file descriptor representing the connection.
 */
- (int)desc;
/**
 * Should close the file descriptor.
 */
- (void)close;
@end

/**
 * Represents a class that acts as a port.  Each port allows a object type
 * to be attached to it, and it will instantiate an object of that type
 * upon receiving a new connection.
 */
@protocol NetPort <NSObject>
/**
 * Sets the class of the object that should be attached to the port.  This
 * class should implement the [(NetObject)] protocol.
 */
- setNetObject: (Class)aClass;

/**
 * Called when the object has [NetApplication-disconnectObject:] called on it.
 */
- (void)connectionLost;

/**
 * Called when a new connection has been detected by [NetApplication].
 * The port should should use this new connection to instantiate a object
 * of the class set by -setNetObject:.
 */
- (id <NetPort>)setupNewConnection;

/**
 * Returns the low-level file descriptor.
 */
- (int)desc;
/**
 * Should close the file descriptor.
 */
- (void)close;
@end

/**
 * This protocol should be implemented by an object used in a connection.
 * When a connection is received by a [(NetPort)], the object attached to
 * the port is created and given the transport.
 */
@protocol NetObject <NSObject>
/**
 * Called when [NetApplication-disconnectObject:] is called with this
 * object as a argument.  This object will no longer receive data or other
 * messages after it is disconnected.
 */
- (void)connectionLost;
/**
 * Called when a connection has been established, and gives the object
 * the transport used to actually transport the data.  <var>aTransport</var>
 * will implement [(NetTransport)].
 */
- connectionEstablished: (id <NetTransport>)aTransport;
/**
 * <var>data</var> is data read in from the connection.
 */
- dataReceived: (NSData *)data;
/**
 * Should return the transport given to the object by -connectionEstablished:
 */
- (id <NetTransport>)transport;
@end

/**
 * Thrown when a recoverable exception occurs on a connection or otherwise.
 */
extern NSString *NetException;
/**
 * Should be thrown when a non-recoverable exception occurs on a connection.
 * The connection should be closed immediately.
 */
extern NSString *FatalNetException;

#ifndef GNUSTEP
/**
 * Used for OS X compatibility.  This type is an extension to GNUstep.  On
 * OS X, a compatibility layer is created to recreate the GNUstep extensions
 * using OS X extensions.
 */
typedef enum { ET_RDESC, ET_WDESC, ET_RPORT, ET_EDESC } RunLoopEventType;
/** 
 * Used for OS X compatibility.  OS X does not have the RunLoopEvents
 * protocol.  This is a GNUstep-specific extension.  This must be
 * recreated on OS X to compile netclasses.
 */
@protocol RunLoopEvents
/**
 * OS X compatibility function.  This is a callback called by the run loop
 * when an event has timed out.
 */
- (NSDate *)timedOutEvent: (void *)data 
                     type: (RunLoopEventType)type
                  forMode: (NSString *)mode;
/**
 * OS X compatibility function.  This is a callback called by the run loop
 * when an event has been received.
 */
- (void)receivedEvent: (void *)data
                  type: (RunLoopEventType)type
                 extra: (void *)extra
               forMode: (NSString *)mode;
@end
#endif

@interface NetApplication : NSObject < RunLoopEvents >
	{
		NSMutableArray *portArray;
		NSMutableArray *netObjectArray;
		NSMutableArray *badDescs;
		NSMapTable *descTable;
	}
/**
 * Return the minor version number of the netclasses framework.  If the 
 * version is 1.03, this will return 3.
 */
+ (int)netclassesMinorVersion;
/**
 * Return the major version number of the netclasses framework.  If the 
 * version is 1.03, this will return 1.
 */
+ (int)netclassesMajorVersion;
/**
 * Return the version string for the netclasses framework.  If the version
 * is 1.03, this will return @"1.03".
 */ 
+ (NSString *)netclassesVersion;
/**
 * There can be only one instance of NetApplication.  This method will 
 * return that one instance.
 */
+ sharedInstance;
/**
 * Should not be called.  Used internally by [NetApplication] to receive
 * timed out events notifications from the runloop.
 */
- (NSDate *)timedOutEvent: (void *)data 
                     type: (RunLoopEventType)type
                  forMode: (NSString *)mode;
/**
 * Should not be called.  Used internally by [NetApplication] to receive
 * events from the runloop.
 */
- (void)receivedEvent: (void *)data
                  type: (RunLoopEventType)type
                 extra: (void *)extra
               forMode: (NSString *)mode;
													 
/** 
 * This is called to notify NetApplication that 
 * <var>aTransport</var> has data that needs to be written out.
 * Only after this method is called will <var>aTransport</var>
 * begin to receive [(NetTransport)-writeData:] messages with a 
 * nil argument when it can write.
 */
- transportNeedsToWrite: (id <NetTransport>)aTransport;

/** 
 * Inserts <var>anObject</var> into the runloop (and retains it).  
 * <var>anObject</var> should implement either the [(NetPort)] or 
 * [(NetObject)] protocols. Throws a <code>NetException</code> if the 
 * class follows neither protocol.  After connecting <var>anObject</var>,
 * it will begin to receive the methods designated by its respective
 * protocol.  <var>anObject</var> should only be connected with this
 * after its transport is set.
 */
- connectObject: anObject;
/**
 * <p>
 * Removes <var>anObject</var> from the runloop and releases it.
 * <var>anObject</var> will no longer receive messages outlined by
 * its protocol.  Does <em>not</em> close the descriptor of 
 * <var>anObject</var>.  <var>anObject</var> will receive
 * a [(NetObject)-connectionLost] message or a [(NetPort)-connectionLost]
 * message.
 * </p>
 * <p>
 * If any object should lose its connection, this will
 * automatically be called with that object as its argument.
 * </p>
 */
- disconnectObject: anObject;
/** 
 * Calls -disconnectObject: on every object currently in the runloop.
 */
- closeEverything;
/**
 * Return an array of all net objects currently being handled by netclasses
 */
- (NSArray *)netObjectArray;
/**
 * Return an array of all port objects currently being handled by netclasses
 */
- (NSArray *)portArray;
@end

#endif
