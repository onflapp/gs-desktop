/*
**  CWPOP3Folder.m
**
**  Copyright (c) 2001-2006 Ludovic Marcotte
**  Copyright (C) 2014-2020 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
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

#import <Pantomime/CWPOP3Folder.h>

#import <Pantomime/CWConnection.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/CWMessage.h>
#import <Pantomime/CWPOP3CacheManager.h>
#import <Pantomime/CWPOP3CacheObject.h>
#import <Pantomime/CWPOP3Message.h>
#import <Pantomime/CWPOP3Store.h>
#import <Pantomime/CWTCPConnection.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/NSString+Extensions.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>

#include <limits.h>
#include <stdio.h>
#include <string.h>

#if !defined(UINT_MAX)
#define UINT_MAX (unsigned int)~0
#endif

//
// Private methods
//
@interface CWPOP3Folder (Private)
- (void) _deleteOldMessages;
@end


//
//
//
@implementation CWPOP3Folder

- (id) initWithName: (NSString *) theName
{
  self = [super initWithName: theName];
  _leave_on_server = YES;
  _retain_period = 0;
  return self;
}


//
//
//
- (void) prefetchMessageAtIndex: (NSUInteger) theIndex
		  numberOfLines: (NSUInteger) theNumberOfLines
{
  [_store sendCommand: POP3_TOP  arguments: @"TOP %lu %lu", (long unsigned)theIndex, (long unsigned)theNumberOfLines];
}


//
//
//
- (void) prefetch
{
  [_store sendCommand: POP3_STAT  arguments: @"STAT"];
}


//
// This method does nothing.
//
- (void) close
{
  // We do nothing.
}


//
//
//
- (BOOL) leaveOnServer
{
  return _leave_on_server;
}


//
//
//
- (void) setLeaveOnServer: (BOOL) theBOOL
{
  _leave_on_server = theBOOL;
}


//
//
//
- (unsigned int) retainPeriod
{
  return _retain_period;
}


//
// The retain period is set in days.
//
- (void) setRetainPeriod: (unsigned int) theRetainPeriod
{
  _retain_period = theRetainPeriod;
}


//
//
//
- (PantomimeFolderMode) mode
{
  return PantomimeReadWriteMode;
}


//
//
//
- (void) expunge
{
  NSUInteger count;

  count = [self count];

  // We mark it as deleted if we need to
  if (!_leave_on_server)
    {
      NSUInteger i;

      for (i = 1; i <= count; i++)
	{
	  [_store sendCommand: POP3_DELE  arguments: @"DELE %u", (unsigned)i];
	}
    }
  else if (_retain_period > 0)
    {
      [self _deleteOldMessages];
    }

  [_store sendCommand: POP3_EXPUNGE_COMPLETED  arguments: @""];
}


//
// In POP3, we do nothing.
//
- (void) search: (NSString *) theString
	   mask: (PantomimeSearchMask) theMask
	options: (PantomimeSearchOption) theOptions
{
}

@end


//
// Private methods
//
@implementation CWPOP3Folder (Private)

- (void) _deleteOldMessages
{
  NSUInteger i, count;

  count = [self count];
  
  for (i = count; i > 0; i--)
    {
      NSDate *aDate;
      
      aDate = [(CWPOP3CacheManager *)_cacheManager dateForUID: [[allMessages objectAtIndex: i-1] UID]];
      
      if (aDate)
	{
          NSTimeInterval interval;
	  
          interval = -[aDate timeIntervalSinceNow];
          if (interval > 0)
            {
              NSUInteger days = lround(interval / (24*3600));
	  
              if (days >= _retain_period)
	        {
	          [_store sendCommand: POP3_DELE  arguments: @"DELE %d", i];
	        }
            }
	}
    }
}

@end
