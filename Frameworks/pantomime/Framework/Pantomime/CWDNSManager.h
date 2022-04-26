/*
**  CWDNSManager.h
**
**  Copyright (c) 2004-2007 Ludovic Marcotte
**  Copyright (C) 2013 The GNUstep team
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef _Pantomime_H_CWDNSManager
#define _Pantomime_H_CWDNSManager

#include <Pantomime/CWConnection.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSTimer.h>

#ifdef MACOSX
#import <Foundation/NSMapTable.h>
#include <CoreFoundation/CoreFoundation.h>
#endif

#if defined(__APPLE__) && (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
#ifndef NSUInteger
#define NSUInteger unsigned int
#endif
#ifndef NSInteger
#define NSInteger int
#endif
#endif

/*!
  @const PantomimeDNSResolutionCompleted
  @discussion This notification is automatically posted when 
              the DNS resolution has completed successfully.
*/
extern NSString* PantomimeDNSResolutionCompleted;

/*!
  @const PantomimeDNSResolutionFailed
  @discussion This notification is automatically posted when
              the DNS resolution has failed.
*/
extern NSString* PantomimeDNSResolutionFailed;

#ifdef MACOSX
typedef enum {ET_RDESC, ET_WDESC, ET_EDESC} RunLoopEventType;
/*!
  @class CWDNSManager
  @discussion This class is used in Pantomime to perform DNS resolution.
              Currently, it does not do asynchronous lookups but implements
	      a simple cache to speedup repetitive requets.
*/
@interface CWDNSManager : NSObject
#else
@interface CWDNSManager : NSObject <RunLoopEvents>
#endif
{
  @private
    NSMutableArray *_servers, *_queue;
    NSMutableDictionary *_cache;
    NSTimer *_timer;

#ifdef MACOSX
    CFRunLoopSourceRef _runLoopSource;
    CFSocketContext *_context;
    CFSocketRef _cf_socket;
#endif

    unsigned short _packet_id;
    BOOL _is_asynchronous;
    NSInteger _socket;
}

/*!
  @method addressesForName:background:
  @discussion This method is used to obtain an array of IP
              addresses from a fully qualified domain name.
  @param theName The fully qualified domain name.
  @param theBOOL If YES, the call is non-blocking and returns nil.
                 Otherwise, the call is block and returns an
		 array of addresses, if any.
  @result The array of addresses encoded as NSData instances.
*/
- (NSArray *) addressesForName: (NSString *) theName
                    background: (BOOL) theBOOL;
/*!
  @method singleInstance
  @discussion This method is used to obtain the shared
              CWDNSManager instance for DNS resolution.
  @result The shared instance.
*/
+ (id) singleInstance;

#ifdef MACOSX
- (void) receivedEvent: (void *) theData
                  type: (RunLoopEventType) theType
                 extra: (void *) theExtra
               forMode: (NSString *) theMode;
#endif

@end

#endif // _Pantomime_H_CWDNSManager
