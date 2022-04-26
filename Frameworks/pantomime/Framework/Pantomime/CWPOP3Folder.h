/*
**  CWPOP3Folder.h
**
**  Copyright (c) 2001-2006 Ludovic Marcotte
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
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

#ifndef _Pantomime_H_CWPOP3Folder
#define _Pantomime_H_CWPOP3Folder

#import <Pantomime/CWFolder.h>

#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>

/*!
  @class CWPOP3Folder
  @discussion This class, which extends the Folder class, is used to
              implement POP3-specific features.
*/
@interface CWPOP3Folder : CWFolder
{ 
  BOOL _leave_on_server;
  unsigned int _retain_period;
}

/*!
  @method prefetchMessageAtIndex: numberOfLines:
  @discussion This method is used to fetch a certain amount of lines of
              the message, at the specified index. On completion, this method posts
	      the PantomimeMessagePrefetchCompleted (and calls -messagePrefetchCompleted:
	      on the delegate, if any). This method is fully asynchronous. Since
	      this method can be used to partially fetch the message, it is the
	      responsability of the caller to verify if the message's data
	      is fully loaded. One can verify the lenght of the message's data
	      and compare it to the message's size.
  @param theIndex The index of the message, which is 1-based in POP3.
  @param theNumberOfLines The number of lines to fetch. Specifying 0
                          will only fetch the headers.
*/
- (void) prefetchMessageAtIndex: (NSUInteger) theIndex
                  numberOfLines: (NSUInteger) theNumberOfLines;

/*!
  @method prefetch
  @discussion This method is used to cache a certain amount of information from
              the POP3 server, for all messages. It caches the number of messages,
	      their size and UID. On completion, it posts a PantomimeFolderPrefetchCompleted
	      notification (and calls -folderPrefetchCompleted: on the delegate, if any).
	      This method is also fully asynchronous.
*/
- (void) prefetch;

/*!
  @method leaveOnServer
  @discussion This method is used to verify if the receiver leaves the messages
              on server after retrieve them.
  @result The value.
*/
- (BOOL) leaveOnServer;

/*!
  @method setLeaveOnServer:
  @discussion This method is used to set the flag to leave or not the messages on the POP3
              server after fetching them.
  @param theBOOL YES if we want to leave them on the server after a fetch. If NO, the
                 messages will be automatically deleted after being fetched.
*/
- (void) setLeaveOnServer: (BOOL) theBOOL;

/*!
  @method retainPeriod
  @discussion This method is used to obtain the retain period for the messages,
              if left on the server.
  @result The retain period. A value of 0 means that the messages will always
          be retained.
*/
- (unsigned int) retainPeriod;

/*!
  @method setRetainPeriod:
  @discussion This method is used to set the retain period (in days) before
              the messages are deleted from the server. In order for this
	      to work, the receiver must have a cache (instance of CWPOP3CacheManager).
  @param theRetainPeriod The retain period to use, in number of days.
*/
- (void) setRetainPeriod: (unsigned int) theRetainPeriod;

@end

#endif // _Pantomime_H_CWPOP3Folder
