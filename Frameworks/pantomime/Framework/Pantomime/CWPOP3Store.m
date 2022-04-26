/*
**  CWPOP3Store.m
**
**  Copyright (c) 2001-2006 Ludovic Marcotte
**  Copyright (C) 2017-2020 Riccardo Mottola
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

#import <Pantomime/CWPOP3Store.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWMD5.h>
#import <Pantomime/CWMIMEUtility.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/CWPOP3CacheManager.h>
#import <Pantomime/CWPOP3Folder.h>
#import <Pantomime/CWPOP3Message.h>
#import <Pantomime/CWStore.h>
#import <Pantomime/CWTCPConnection.h>
#import <Pantomime/CWURLName.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSPathUtilities.h>

#include <stdio.h>

//
// Some static variables used to enhance the performance.
//
static NSStringEncoding defaultCStringEncoding;
static NSData *CRLF;

//
//
//
@interface CWPOP3QueueObject : NSObject
{
  @public
    POP3Command command;
    NSString *arguments;
}
- (id) initWithCommand: (POP3Command) theCommand
	     arguments: (NSString *) theArguments;
@end

@implementation CWPOP3QueueObject

- (id) initWithCommand: (POP3Command) theCommand
	     arguments: (NSString *) theArguments
{
  self = [super init];
  if (self)
    {
      command = theCommand;
      ASSIGN(arguments, theArguments);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(arguments);
  [super dealloc];
}
@end



//
// Private methods
//
@interface CWPOP3Store (Private)

- (void) _parseAPOP;
- (void) _parseAUTHORIZATION;
- (void) _parseCAPA;
- (void) _parseLIST;
- (void) _parseNOOP;
- (void) _parsePASS;
- (void) _parseQUIT;
- (void) _parseRETR;
- (void) _parseSTAT;
- (void) _parseSTLS;
- (void) _parseTOP;
- (void) _parseUIDL;
- (void) _parseUSER;
- (void) _parseServerOutput;

@end


//
//
//
@implementation CWPOP3Store

+ (void) initialize
{
  defaultCStringEncoding = [NSString defaultCStringEncoding];
  CRLF = [[NSData alloc] initWithBytes: "\r\n"  length: 2];
}


//
//
//
- (id) initWithName: (NSString *) theName
	       port: (unsigned int) thePort
{
  if (thePort == 0) thePort = 110;

  self = [super initWithName: theName  port: thePort];
  if (self)
    {
      _lastCommand = POP3_AUTHORIZATION;
      _timestamp = nil;
  
      // We initialize out POP3Folder object.
      _folder = [[CWPOP3Folder alloc] initWithName: @"Inbox"];
      [_folder setStore: self];
  
      // We queue our first "command".
      [_queue addObject: AUTORELEASE([[CWPOP3QueueObject alloc] initWithCommand: _lastCommand  arguments: @""])];
    }
  
  return self;
}


//
//
//
- (void) dealloc
{
  //NSLog(@"POP3Store: -dealloc");
  RELEASE(_folder);
  RELEASE(_timestamp);

  [super dealloc];
}


//
//
//
- (id) initWithURL: (CWURLName *) theURL
{
  return [self initWithName: [theURL host]  port: 110];
}


//
//
//
- (NSEnumerator *) folderEnumerator
{
  return [[NSArray arrayWithObject: @"Inbox"] objectEnumerator];
}


//
//
//
- (NSEnumerator *) subscribedFolderEnumerator
{
  return [self folderEnumerator];
}


//
//
//
- (NSEnumerator *) openFoldersEnumerator
{
  return [[NSArray arrayWithObject: _folder] objectEnumerator];
}


//
//
//
- (void) removeFolderFromOpenFolders: (CWFolder *) theFolder
{
  // Do nothing
}


//
// This method authenticates the Store to the POP3 server.
// In case of an error, it returns NO.
//
- (void) authenticate: (NSString *) theUsername
	     password: (NSString *) thePassword
	    mechanism: (NSString *) theMechanism
{
  ASSIGN(_username, theUsername);
  ASSIGN(_password, thePassword);
  ASSIGN(_mechanism, theMechanism);
  
  // We verify if we must use APOP
  if (theMechanism && [theMechanism caseInsensitiveCompare: @"APOP"] == NSOrderedSame)
    {
      NSMutableData *aMutableData;
      CWMD5 *aMD5;
      
      aMutableData = [[NSMutableData alloc] init];
      [aMutableData appendCFormat:  @"%@%@", _timestamp, _password];
      aMD5 = [[CWMD5 alloc] initWithData: aMutableData];
      RELEASE(aMutableData);

      [aMD5 computeDigest];

      [self sendCommand: POP3_APOP  arguments: @"APOP %@ %@", _username, [aMD5 digestAsString]];
      RELEASE(aMD5);
    }
  else
    {
      [self sendCommand: POP3_USER  arguments: @"USER %@", _username];
    }
}


//
//
//
- (NSArray *) supportedMechanisms
{
  if (_timestamp)
    {
      return [NSArray arrayWithObject: @"APOP"];
    }
  
  return [NSArray array];
}


//
// The default folder in POP3 is always Inbox.
//
- (id) defaultFolder
{
  return _folder;
}


//
// This method will always return nil if theName is not
// equal to Inbox (case-insensitive) since you cannot
// access an other mailbox (other than Inbox) using the
// POP3 protocol.
//
- (id) folderForName: (NSString *) theName
{
  if ([theName caseInsensitiveCompare: @"Inbox"] == NSOrderedSame)
    {
      return [self defaultFolder];
    }
  
  return nil;
}


//
//
//
- (id) folderForURL: (NSString *) theURL
{
  return [self defaultFolder];
}


//
//
//
- (BOOL) folderForNameIsOpen: (NSString *) theName
{
  if ([theName caseInsensitiveCompare: @"Inbox"] == NSOrderedSame)
    {
      return YES;
    }

  return NO;
}


//
// No other folder is allowed in POP3 other than the Inbox.
// Also, this folder can only holds messages.
//
- (PantomimeFolderType) folderTypeForFolderName: (NSString *) theName
{
  return PantomimeHoldsMessages;
}


//
// POP3 has no concept of folder separator.
//
- (unichar) folderSeparator
{
  return 0;
}


//
//
//
- (void) close
{
  [self sendCommand: POP3_QUIT  arguments: @"QUIT"];
}


//
//
//
- (void) noop
{
  [self sendCommand: POP3_NOOP  arguments: @"NOOP"];
}


//
// In POP3, you are NOT allowed to create a folder.
//
- (void) createFolderWithName: (NSString *) theName 
			 type: (PantomimeFolderFormat) theType
		     contents: (NSData *) theContents
{
}


//
// In POP3, you are NOT allowed to delete a folder.
//
- (void) deleteFolderWithName: (NSString *) theName
{
}


//
// In POP3, you are NOT allowed to rename a folder.
//
- (void) renameFolderWithName: (NSString *) theName
                       toName: (NSString *) theNewName
{
}


//
//
//
- (NSString *) timestamp
{
  return _timestamp;
}


//
// From RFC1939:
//
//   Responses in the POP3 consist of a status indicator and a keyword
//   possibly followed by additional information.  All responses are
//   terminated by a CRLF pair.  Responses may be up to 512 characters
//   long, including the terminating CRLF.  There are currently two status
//   indicators: positive ("+OK") and negative ("-ERR").  Servers MUST
//   send the "+OK" and "-ERR" in upper case.
//
//   Responses to certain commands are multi-line.  In these cases, which
//   are clearly indicated below, after sending the first line of the
//   response and a CRLF, any additional lines are sent, each terminated
//   by a CRLF pair.  When all lines of the response have been sent, a
//   final line is sent, consisting of a termination octet (decimal code
//   046, ".") and a CRLF pair.  If any line of the multi-line response
//   begins with the termination octet, the line is "byte-stuffed" by
//   pre-pending the termination octet to that line of the response.
//   Hence a multi-line response is terminated with the five octets
//   "CRLF.CRLF".  When examining a multi-line response, the client checks
//   to see if the line begins with the termination octet.  If so and if
//   octets other than CRLF follow, the first octet of the line (the
//   termination octet) is stripped away.  If so and if CRLF immediately
//   follows the termination character, then the response from the POP
//   server is ended and the line containing ".CRLF" is not considered
//   part of the multi-line response.
//
- (void) updateRead
{
  id aData;
 
  char *buf;
  NSUInteger count;

  [super updateRead];

  while ((aData = split_lines(_rbuf)))
    {
      buf = (char *)[aData bytes];
      count = [aData length];
      [_responsesFromServer addObject: aData];

      if (count)
	{
	  switch (*buf)
	    {
	    case '.':
	      //
	      // We verify if we must strip the termination octet
	      //
	      if (count > 1)
		{
		  aData = [NSMutableData dataWithData: aData];
		  buf = [aData mutableBytes];
		  memmove(buf, buf+1, count-2);
		  [aData setLength: count-2];
		}
	      else
		{
		  // We are done receiving multi-line response and
		  // we are ready to parse the received bytes. Before
		  // parsing all the received bytes, we remove the
		  // last line added since it corresponds to our
		  // multi-line response terminator.
		  [_responsesFromServer removeLastObject];
		  [self _parseServerOutput];
		  return;
		}
	      break;

	    case '+':
	      //
	      // There's no real way in POP3 to know if we are currently
	      // reading a multi-line response. We assume we are NOT for
	      // some commands.
	      //
	      if (_lastCommand != POP3_CAPA &&
		  _lastCommand != POP3_LIST &&
		  _lastCommand != POP3_TOP &&
		  _lastCommand != POP3_RETR &&
		  _lastCommand != POP3_RETR_AND_INITIALIZE &&
		  _lastCommand != POP3_UIDL &&
		  (count > 2 && strncmp("+OK", buf, 3) == 0))
		{
		  [self _parseServerOutput];
		  return;
		}
	      break;

	    case '-':
	      if (_lastCommand != POP3_TOP &&
		  _lastCommand != POP3_RETR &&
		  _lastCommand != POP3_RETR_AND_INITIALIZE &&
		  (count > 3 && strncmp("-ERR", buf, 4) == 0))
		{
		  [self _parseServerOutput];
		  return;
		}
	      break;
	    }
	}
    }
}

//
// From RFC1939:
//
//   Commands in the POP3 consist of a case-insensitive keyword, possibly
//   followed by one or more arguments.  All commands are terminated by a
//   CRLF pair.  Keywords and arguments consist of printable ASCII
//   characters.  Keywords and arguments are each separated by a single
//   SPACE character.  Keywords are three or four characters long. Each
//   argument may be up to 40 characters long.
//
- (void) sendCommand: (POP3Command) theCommand  arguments: (NSString *) theFormat, ...
{
  CWPOP3QueueObject *aQueueObject;

  //NSLog(@"sendCommand invoked, cmd = %i", theCommand);

  if (theCommand == POP3_EMPTY_QUEUE)
    {
      if ([_queue count])
	{
	  // We dequeue the first inserted command from the queue.
	  aQueueObject = [_queue lastObject];
	}
      else
	{
	  // The queue is empty, we have nothing more to do...
	  return;
	}
    }
  else
    {
      NSString *aString;
      va_list args;
      
      va_start(args, theFormat);
      
      aString = [[NSString alloc] initWithFormat: theFormat  arguments: args];
      
      aQueueObject = [[CWPOP3QueueObject alloc] initWithCommand: theCommand  arguments: aString];
      RELEASE(aString);

      [_queue insertObject: aQueueObject  atIndex: 0];
      RELEASE(aQueueObject);

      //NSLog(@"queue size = %d:", [_queue count]);
      
      // If we had queued commands, we return since we'll eventually
      // dequeue them one by one. Otherwise, we run it immediately.
      if ([_queue count] > 1)
	{
	  //NSLog(@"QUEUED |%@|", aString);
	  return;
	}
    }
  
  //NSLog(@"Sending |%@|", aQueueObject->arguments);
  _lastCommand = aQueueObject->command;

  // We verify if we had queued an indicator to tell us that we were done
  // wrt expunging the POP3 folder.
  if (_lastCommand == POP3_EXPUNGE_COMPLETED)
    {
      [_queue removeObject: [_queue lastObject]];

      POST_NOTIFICATION(PantomimeFolderExpungeCompleted, self, [NSDictionary dictionaryWithObject: _folder  forKey: @"Folder"]); 
      PERFORM_SELECTOR_2(_delegate, @selector(folderExpungeCompleted:), PantomimeFolderExpungeCompleted, _folder, @"Folder");
      return;
    }

  // We send the command to the POP3 server.
  [self writeData: [aQueueObject->arguments dataUsingEncoding: defaultCStringEncoding]];
  [self writeData: CRLF];
}

//
//
//
- (void) startTLS
{
  [self sendCommand: POP3_STLS  arguments: @"STLS"];
}

@end


//
// Private methods
//
@implementation CWPOP3Store (Private)

- (void) _parseAPOP
{
  NSData *aData;
  
  aData = [_responsesFromServer lastObject];
  
  if ([aData hasCPrefix: "+OK"])
    {
      AUTHENTICATION_COMPLETED(_delegate, @"APOP");
    }
  else
    {
      AUTHENTICATION_FAILED(_delegate, @"APOP");
    }
}


//
//
//
- (void) _parseAUTHORIZATION
{
  NSData *aData;
  
  aData = [_responsesFromServer lastObject];
  
  if ([aData hasCPrefix: "+OK"])
    {
      NSRange range1, range2;
      
      range1 = [aData rangeOfCString: "<"];
      range2 = [aData rangeOfCString: ">"];
      
      if (range1.length && range2.length)
	{
	  ASSIGN(_timestamp, [[aData subdataWithRange: NSMakeRange(range1.location,range2.location-range1.location+1)] asciiString]);
	}
      
      [self sendCommand: POP3_CAPA  arguments: @"CAPA"];
    }
  else
    {
      // FIXME
      // connectionLost? or should we call [self close]?
    }
}


//
// See RFC2449 for details.
//
- (void) _parseCAPA
{
  NSData *aData;
  NSUInteger i, count;

  count = [_responsesFromServer count];

  for (i = 1; i < count; i++)
    {
      aData = [_responsesFromServer objectAtIndex: i];
      [_capabilities addObject: AUTORELEASE([[NSString alloc] initWithData: aData  encoding: defaultCStringEncoding])];
    }
  
  POST_NOTIFICATION(PantomimeServiceInitialized, self, nil);
  PERFORM_SELECTOR_1(_delegate, @selector(serviceInitialized:), PantomimeServiceInitialized);
}


//
// From RFC1939:
//
// If no argument was given and the POP3 server issues a
// positive response, then the response given is multi-line.
// After the initial +OK, for each message in the maildrop,
// the POP3 server responds with a line containing
// information for that message.  This line is also called a
// "scan listing" for that message.  If there are no
// messages in the maildrop, then the POP3 server responds
// with no scan listings--it issues a positive response
// followed by a line containing a termination octet and a
// CRLF pair.
//
- (void) _parseLIST
{
  CWPOP3Message *aMessage;
  NSUInteger i, idx, count;
  unsigned long size;

  count = [_responsesFromServer count];
  
  for (i = 1; i < count; i++)
    {
      sscanf([[_responsesFromServer objectAtIndex: i] cString], "%lu %lu", (unsigned long*)&idx, &size);
      
      aMessage = [_folder->allMessages objectAtIndex: (idx-1)];
      [aMessage setSize: size];
      [aMessage setMessageNumber: i];
    }

  [self sendCommand: POP3_UIDL  arguments: @"UIDL"];
}


//
//
//
- (void) _parseNOOP
{
  // Do what?
}


//
//
//
- (void) _parsePASS
{
  NSData *aData;
  
  aData = [_responsesFromServer lastObject];
  
  if ([aData hasCPrefix: "+OK"])
    {
      AUTHENTICATION_COMPLETED(_delegate, @"");
    }
  else
    {
      AUTHENTICATION_FAILED(_delegate, @"");
    }
}


//
//
//
- (void) _parseQUIT
{
  // We don't need to do anything special here.
  [super close];
}


//
//
//
- (void) _parseRETR
{
  NSData *aData;
  
  aData = [_responsesFromServer objectAtIndex: 0];

  if ([aData hasCPrefix: "+OK"])
    {
      NSMutableData *aMutableData;
      CWPOP3Message *aMessage;
      NSUInteger count, i;
      unsigned idx;

      // We get the idx of the message we are parsing...
      sscanf([((CWPOP3QueueObject *)[_queue lastObject])->arguments cString], "RETR %u", &idx);

      aMessage = (CWPOP3Message *)[_folder messageAtIndex: (idx-1)];
      aMutableData = [[NSMutableData alloc] initWithCapacity: [aMessage size]];
      count = [_responsesFromServer count];

      for (i = 1; i < count; i++)
	{
	  [aMutableData appendData: [_responsesFromServer objectAtIndex: i]];

	  // We do NOT append the last \n.
	  if (i < count-1)
	    {
	      [aMutableData appendBytes: "\n"  length: 1];
	    }
	}

      [aMessage setRawSource: aMutableData];

      if (_lastCommand == POP3_RETR_AND_INITIALIZE)
	{
	  NSRange aRange;
	  
	  aRange = [aMutableData rangeOfCString: "\n\n"];
	  
	  if (aRange.length == 0)
	    {
	      [aMessage setInitialized: NO];
	    }
	  else
	    {
	      [aMessage setHeadersFromData: [aMutableData subdataWithRange: NSMakeRange(0,aRange.location)]];
	      [CWMIMEUtility setContentFromRawSource:
			       [aMutableData subdataWithRange:
					       NSMakeRange(aRange.location + 2, [aMutableData length]-(aRange.location+2))]
			     inPart: aMessage];
	      [aMessage setInitialized: YES];
	    }
	}
      
      [aMessage setSize: [aMutableData length]];
      RELEASE(aMutableData);

      // Do that in parse top also?
      if ([_folder cacheManager])
	{
	  cache_record r;

	  r.date = (uint32_t)round([[aMessage receivedDate] timeIntervalSince1970]);
	  r.pop3_uid = [aMessage UID];
	  [(CWPOP3CacheManager *)[_folder cacheManager] writeRecord: &r];
	}

      POST_NOTIFICATION(PantomimeMessagePrefetchCompleted, self, [NSDictionary dictionaryWithObject: aMessage  forKey: @"Message"]);
      PERFORM_SELECTOR_2(_delegate, @selector(messagePrefetchCompleted:), PantomimeMessagePrefetchCompleted, aMessage, @"Message");
    }
}


//
//
//
- (void) _parseSTAT
{
  NSData *aData;
  
  aData = [_responsesFromServer lastObject];

  if ([aData hasCPrefix: "+OK"])
    {
      CWPOP3Message *aMessage;
      int count;
      long size;

      sscanf([aData cString], "+OK %i %li", &count, &size);
      //NSLog(@"count = %d  size = %li", count, size);

      while (count--)
	{
	  aMessage = [[CWPOP3Message alloc] init];
	  [aMessage setFolder: _folder];
	  [_folder->allMessages addObject: aMessage];
	  RELEASE(aMessage);
	}

      //NSLog(@"Folder count = %d", [_folder count]);

      [self sendCommand: POP3_LIST  arguments: @"LIST"];
    }
  else
    {
      // FIXME: Do what in case STAT failed?
    }
}

//
//
//
- (void) _parseSTLS
{
  NSData *aData;
  
  aData = [_responsesFromServer lastObject];

  if ([aData hasCPrefix: "+OK"])
    {
      [(CWTCPConnection *)_connection startSSL];

      POST_NOTIFICATION(PantomimeServiceInitialized, self, nil);
      PERFORM_SELECTOR_1(_delegate, @selector(serviceInitialized:), PantomimeServiceInitialized);
    }
  else
    {
      // FIXME: Handle the case where STLS failed
    }
}

//
// This method is very similar to the _parseRETR method.
// We don't touch the message's size (set in _parseLIST)
// since we must know how much we had to read,
//
- (void) _parseTOP
{
  NSData *aData;
  
  aData = [_responsesFromServer objectAtIndex: 0];

  if ([aData hasCPrefix: "+OK"])
    {
      NSMutableData *aMutableData;
      CWPOP3Message *aMessage;

      int count, i, idx, num;

      // We get the idx of the message we are parsing...
      sscanf([((CWPOP3QueueObject *)[_queue lastObject])->arguments cString], "TOP %d %d", &idx, &num);

      //NSLog(@"PARTIALLY DECODING MESSAGE no. %d - number of lines %d!", idx, num);
      
      aMessage = (CWPOP3Message *)[_folder messageAtIndex: (idx-1)];
      aMutableData = [[NSMutableData alloc] init];
      count = [_responsesFromServer count];

      for (i = 1; i < count; i++)
	{
	  [aMutableData appendData: [_responsesFromServer objectAtIndex: i]];
	  [aMutableData appendBytes: "\n"  length: 1];
	}

      [aMessage setRawSource: aMutableData];
      RELEASE(aMutableData);

      POST_NOTIFICATION(PantomimeMessagePrefetchCompleted, self, [NSDictionary dictionaryWithObject: aMessage  forKey: @"Message"]);
      PERFORM_SELECTOR_2(_delegate, @selector(messagePrefetchCompleted:), PantomimeMessagePrefetchCompleted, aMessage, @"Message");
    }
}


//
//
//
- (void) _parseUIDL
{
  NSUInteger i, idx, count;
  char buf[71];

  count = [_responsesFromServer count];
  
  for (i = 1; i < count; i++)
    {
       memset(buf, 0, 71);
       sscanf([[_responsesFromServer objectAtIndex: i] cString],"%lu %s", (unsigned long*)&idx, buf);
       [[_folder->allMessages objectAtIndex: (idx-1)] setUID: [NSString stringWithCString: buf]];
    }

  POST_NOTIFICATION(PantomimeFolderPrefetchCompleted, self, [NSDictionary dictionaryWithObject: _folder  forKey: @"Folder"]);
  PERFORM_SELECTOR_2(_delegate, @selector(folderPrefetchCompleted:), PantomimeFolderPrefetchCompleted, _folder, @"Folder");
}


//
// From RFC1939:
//
// To authenticate using the USER and PASS command
// combination, the client must first issue the USER
// command.  If the POP3 server responds with a positive
// status indicator ("+OK"), then the client may issue
// either the PASS command to complete the authentication,
// or the QUIT command to terminate the POP3 session.  If
// the POP3 server responds with a negative status indicator
// ("-ERR") to the USER command, then the client may either
// issue a new authentication command or may issue the QUIT
// command.
//
- (void) _parseUSER
{
  NSData *aData;
  
  aData = [_responsesFromServer lastObject];

  if ([aData hasCPrefix: "+OK"])
    {
      [self sendCommand: POP3_PASS  arguments: @"PASS %@", _password];
    }
  else
    {
      // We must terminate the POP3 session.
      [self close];
    }
}


//
//
//
- (void) _parseServerOutput
{
  if (![_responsesFromServer count])
    {
      return;
    }

  //NSLog(@"In _parseServerOutput...%d", _lastCommand);

  switch (_lastCommand)
    {
    case POP3_APOP:
      [self _parseAPOP];
      break;

    case POP3_AUTHORIZATION:
      [self _parseAUTHORIZATION];
      break;

    case POP3_CAPA:
      [self _parseCAPA];
      break;

    case POP3_LIST:
      [self _parseLIST];
      break;
      
    case POP3_NOOP:
      [self _parseNOOP];
      break;

    case POP3_PASS:
      [self _parsePASS];
      break;

    case POP3_QUIT:
      [self _parseQUIT];
      break;

    case POP3_RETR:
    case POP3_RETR_AND_INITIALIZE:
      [self _parseRETR];
      break;

    case POP3_STAT:
      [self _parseSTAT];
      break;

    case POP3_STLS:
      [self _parseSTLS];
      break;

    case POP3_TOP:
      [self _parseTOP];
      break;

    case POP3_UIDL:
      [self _parseUIDL];
      break;

    case POP3_USER:
      [self _parseUSER];
      break;

    default:
      //NSLog(@"UNKNOWN POP3 LAST COMMAND %d", _lastCommand);
      break;
      // FIXME
    }

  // We are done parsing this entry...
  [_responsesFromServer removeAllObjects];
  
  
  // We remove the last object of the queue, if needed.
  //NSLog(@"Removing oldest command from queue (%d)...", [_queue count]);
  if ([_queue count])
    {
      [_queue removeLastObject];
      [self sendCommand: POP3_EMPTY_QUEUE  arguments: @""];
    }
}

@end
