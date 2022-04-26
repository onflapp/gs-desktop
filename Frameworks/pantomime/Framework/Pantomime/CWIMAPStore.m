/*
**  CWIMAPStore.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2016-2020 Riccardo Mottola
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

#import <Pantomime/CWIMAPStore.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWFlags.h>
#import <Pantomime/CWFolderInformation.h>
#import <Pantomime/CWIMAPCacheManager.h>
#import <Pantomime/CWIMAPFolder.h>
#import <Pantomime/CWIMAPMessage.h>
#import <Pantomime/CWMD5.h>
#import <Pantomime/CWMIMEUtility.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/NSScanner+Extensions.h>
#import <Pantomime/NSString+Extensions.h>
#import <Pantomime/CWTCPConnection.h>
#import <Pantomime/CWURLName.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSValue.h>

#include <ctype.h>
#include <stdio.h>

//
// Some static variables used to enhance the performance.
//
static NSStringEncoding defaultCStringEncoding;
static NSData *CRLF;

//
// This C function is used to verify if a line (specified in
// "buf", with length "c") has a literal. If it does, the
// value of the literal is returned.
//
// "0" means no literal.
//
static inline int has_literal(char *buf, unsigned c)
{
  char *s;

  if (c == 0 || *buf != '*') return 0;

  s = buf+c-1;

  if (*s == '}')
    {
      int value, d;

      value = 0;
      d = 1;
      s--;
      
      while (isdigit((int)(unsigned char)*s))
	{
	  value += ((*s-48) * d);
	  d *= 10;
	  s--;
	}

      //NSLog(@"LITERAL = %d", value);

      return value;
    }

  return 0;
}

//
//
//
@interface CWIMAPQueueObject : NSObject
{
  @public
    NSMutableDictionary *info;
    IMAPCommand command;
    NSString *arguments;
    NSData *tag;
    int literal;
}
- (id) initWithCommand: (IMAPCommand) theCommand
	     arguments: (NSString *) theArguments
		   tag: (NSData *) theTag
		  info: (NSDictionary *) theInfo;
@end

@implementation CWIMAPQueueObject

- (id) initWithCommand: (IMAPCommand) theCommand
	     arguments: (NSString *) theArguments
		   tag: (NSData *) theTag
		  info: (NSDictionary *) theInfo
{
  self = [super init];
  if (self)
    {
      command = theCommand;
      literal = 0;

      ASSIGN(arguments, theArguments);
      ASSIGN(tag, theTag);

      if (theInfo)
	{
	  info = [[NSMutableDictionary alloc] initWithDictionary: theInfo];
	}
      else
	{
	  info = [[NSMutableDictionary alloc] init];
	}
    }
  return self;
}

- (void) dealloc
{
  RELEASE(arguments);
  RELEASE(info);
  RELEASE(tag);
  [super dealloc];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%d %@", command, arguments];
}
@end


//
// Private methods
//
@interface CWIMAPStore (Private)
- (NSString *) _folderNameFromString: (NSString *) theString;
- (void) _parseFlags: (NSString *) aString
             message: (CWIMAPMessage *) theMessage
	      record: (cache_record *) theRecord;
- (void) _renameFolder;
- (NSArray *) _uniqueIdentifiersFromData: (NSData *) theData;
- (void) _parseAUTHENTICATE_CRAM_MD5;
- (void) _parseAUTHENTICATE_LOGIN;
- (void) _parseBAD;
- (void) _parseBYE;
- (void) _parseCAPABILITY;
- (void) _parseEXISTS;
- (void) _parseEXPUNGE;
- (void) _parseFETCH: (unsigned) theMSN;
- (void) _parseLIST;
- (void) _parseLSUB;
- (void) _parseNO;
- (void) _parseNOOP;
- (void) _parseOK;
- (void) _parseRECENT;
- (void) _parseSEARCH;
- (void) _parseSEARCH_CACHE;
- (void) _parseSELECT;
- (void) _parseSTATUS;
- (void) _parseSTARTTLS;
- (void) _parseUIDVALIDITY: (const char *) theString;
- (void) _restoreQueue;
@end

//
//
//
@implementation CWIMAPStore

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
  if (thePort == 0) thePort = 143;

  self = [super initWithName: theName  port: thePort];
  if (self)
    {
      _folderSeparator = 0;
      _selectedFolder = nil;
      _tag = 1;
      
      _folders = [[NSMutableDictionary alloc] init];
      _openFolders = [[NSMutableDictionary alloc] init];
      _subscribedFolders = [[NSMutableArray alloc] init];
      _folderStatus = [[NSMutableDictionary alloc] init];
      
      _lastCommand = IMAP_AUTHORIZATION;
      _currentQueueObject = nil;
    }
  return self;
}


//
//
//
- (id) initWithURL: (CWURLName *) theURL
{
  return [self initWithName: [theURL host]  port: 143];
}


//
//
//
- (void) dealloc
{
  //NSLog(@"IMAPStore: -dealloc"); 
  RELEASE(_folders);
  RELEASE(_folderStatus);
  RELEASE(_openFolders);
  RELEASE(_subscribedFolders);
  [super dealloc];
}


//
// When this method is called, we are receiving bytes
// from the _lastCommand.
//
// Rationale:
//
// This command accumulates the responses (split into lines)
// from the server in _responsesFromServer.
//
// It will NOT add untagged reponses but rather process them right-away. 
//
// If it's receiving a FETCH response, it will NOT verify for
// tag line ('0123 OK', '0123 BAD', '0123 NO') for the duration
// of reading the literal length. For example, if we got {400},
// we will not consider a '0123 OK' response if we read less
// than 400 bytes. This prevent us from reading a '0123 OK' that
// could occur in a message.
//
- (void) updateRead
{
  id aData;
 
  NSUInteger i, count;
  char *buf;

  [super updateRead];

  //NSLog(@"_rbul len == %d |%@|", [_rbuf length], [_rbuf asciiString]);

  if (![_rbuf length]) return;

  while ((aData = split_lines(_rbuf)))
    {
      //NSLog(@"aLine = |%@|", [aData asciiString]);
      buf = (char *)[aData bytes];
      count = [aData length];

      // If we are reading a literal, do so.
      if (_currentQueueObject && _currentQueueObject->literal)
	{
	  _currentQueueObject->literal -= (count+2);
	  //NSLog(@"literal = %d, count = %d", _currentQueueObject->literal, count);

	  if (_currentQueueObject->literal < 0)
	    {
	      NSUInteger x;

              NSAssert(_currentQueueObject->literal <= 2, @"Negative literal too small");
	      x = (NSUInteger)(-2 - _currentQueueObject->literal);
	      [[_currentQueueObject->info objectForKey: @"NSData"] appendData: [aData subdataToIndex: x]];
	      [_responsesFromServer addObject: [aData subdataFromIndex: x]];
	      //NSLog(@"orig = |%@|, chooped = |%@|   |%@|", [aData asciiString], [[aData subdataToIndex: x] asciiString], [[aData subdataFromIndex: x] asciiString]);
	    }
	  else
	    {
	      [[_currentQueueObject->info objectForKey: @"NSData"] appendData: aData];
	    }  

	  // We are done reading a literal. Let's read again
	  // to see if we got a full response.
	  if (_currentQueueObject->literal <= 0)
	    {
	      //NSLog(@"DONE ACCUMULATING LITTERAL!\nread = |%@|", [[_currentQueueObject->info objectForKey: @"NSData"] asciiString]);
	      //
	      // Let's see, if we can, what does the next line contain. If we got
	      // something, we add this to the remaining _responsesFromServer
	      // and we are ready to parse that response (_responsesFromServer + bytes of literal).
	      //
	      // If it's nil, that's because we have nothing to read. In that case, just loop
	      // and call -updateRead in order to read the rest of the response.
	      //
	      // We must also be careful about what we read. Microsoft Exchange sometimes send us
	      // stuff like this:
	      //
	      // * 5 FETCH (BODY[TEXT] {1175}
	      // <!DOCTYPE HTML ...
	      // ...
	      // </HTML> UID 5)
	      // 0010 OK FETCH completed.
	      //
	      // The "</HTML> UID 5)" line will result in a _negative_ literal. Which we
	      // handle well here and just a couple of lines above this one.
	      //
	      if (_currentQueueObject->literal < 0)
		{
		  _currentQueueObject->literal = 0;
		}
	      else
		{
		  // We MUST wait until we are done reading our full
		  // FETCH response. _rbuf could end immediately at the
		  // end of our literal response and we need to call
		  // [super updateRead] to get more bytes from the socket
		  // in order to read the rest (")" or " UID 123)" for example).
		  while (!(aData = split_lines(_rbuf)))
		    {
		      //SLog(@"NOTHING TO READ! WAITING...");
		      [super updateRead];
		    }
		  [_responsesFromServer addObject: aData];
		}
	      
	      //
	      // Let's rollback in what are processing/read in order to
	      // reparse our initial response. It's if it's FETCH response,
	      // the literal will now be 0 so the parsing of this response
	      // will occur.
	      //
	      aData = [_responsesFromServer objectAtIndex: 0];
	      buf = (char *)[aData bytes];
	      count = [aData length];
	    }
	  else
	    {
	      //NSLog(@"Accumulating... %d remaining...", _currentQueueObject->literal);
	      //
	      // We are still accumulating bytes of the literal. Once we have appended
	      // our CRLF, we just continue the loop since there's no need to try to
	      // parse anything, as we don't have the complete response yet.
	      //
	      [[_currentQueueObject->info objectForKey: @"NSData"] appendData: CRLF];
	      continue;
	    }
	}
      else 
	{
	  //NSLog(@"aLine = |%@|", [aData asciiString]);
	  [_responsesFromServer addObject: aData];

	  if (_currentQueueObject && (_currentQueueObject->literal = has_literal(buf, count)))
	    {
	      //NSLog(@"literal = %d", _currentQueueObject->literal);
	      [_currentQueueObject->info setObject: [NSMutableData dataWithCapacity: _currentQueueObject->literal]
				  forKey: @"NSData"];
	    }
	}

      // Now search for the position of the first space in our response.
      i = 0;
      while (i < count && *buf != ' ')
	{
	  buf++; i++;
	}

      //NSLog(@"i = %d  count = %d", i, count);
      
      //
      // We got an untagged response or a command continuation request.
      //
      if (i == 1)
	{
	  unsigned d, msn, len;
          unsigned j;
	  BOOL b;

	  //
	  // We verify if we received a command continuation request.
	  // This response is used in the AUTHENTICATE command or
	  // in any argument to the command is a literal. In the current
	  // code, the only command which has a literal argument is
	  // the APPEND command. We must NOT use "break;" at the very
	  // end of this block since we could read a line in a mail
	  // that begins with a '+'.
	  //
	  if (*(buf-i) == '+')
	    {
	      if (_currentQueueObject && _lastCommand == IMAP_APPEND)
		{
		  [self writeData: [_currentQueueObject->info objectForKey: @"NSDataToAppend"]];
		  [self writeData: CRLF];
		  break;
		}
	      else if (_lastCommand == IMAP_AUTHENTICATE_CRAM_MD5)
		{
		  [self _parseAUTHENTICATE_CRAM_MD5];
		  break;
		}
	      else if (_lastCommand == IMAP_AUTHENTICATE_LOGIN)
		{
		  [self _parseAUTHENTICATE_LOGIN];
		  break;
		}
	      else if (_currentQueueObject && _lastCommand == IMAP_LOGIN)
		{
		  //NSLog(@"writing password |%s|", [[_currentQueueObject->info objectForKey: @"Password"] cString]);
		  [self writeData: [_currentQueueObject->info objectForKey: @"Password"]];
		  [self writeData: CRLF];
		  break;
		}
	    }

	  msn = 0; b = YES; d = 1;
	  j = i+1; buf++;

	  // Let's see if we can read a MSN
	  while (j < count && *buf != ' ')
	    {
	      if (!isdigit((int)(unsigned char)*buf)) b = NO;
	      buf++; j++;
	    }
	  
	  //NSLog(@"j = %d, b = %d", j, b);

	  //
	  // The token following our "*" is all-digit. Let's
	  // decode the MSN and get the kind of response.
	  //
	  // We will also read the untagged responses we get
	  // when SELECT'ing a mailbox ("* 4 EXISTS" for example).
	  //
	  // We parse those results but we ignore the "MSN" since
	  // it bears no relation to an actual MSN.
	  //
	  if (b)
	    {
	      unsigned k;
	      
	      k = j;

	      // We compute the MSN
	      while (k > i+1)
		{
		  buf--; k--;
		  //NSLog(@"msn c = %c", *buf);
		  msn += ((*buf-48) * d);
		  d *= 10;
		}

	      //NSLog(@"Done computing the msn = %d  k = %d", msn, k);

	      // We now get what kind of response we read (FETCH, etc?)
	      buf += (j-i);
	      k = j+1;

	      while (k < count && isalpha((int)(unsigned char)*buf))
		{
		  //NSLog(@"response after c = %c", *buf);
		  buf++; k++;
		}
	      
	      //NSLog(@"Done reading response: i = %d  j = %d  k = %d", i, j, k);

	      buf = buf-k+j+1;
	      len = k-j-1;
	    }
	  //
	  // It's NOT all-digit.
	  //
	  else
	    {
	      buf = buf-j+i+1;
	      len = j-i-1;
	    }
	      
	  //NSData *foo;
	  //foo = [NSData dataWithBytes: buf  length: len];
	  //NSLog(@"DONE!!! foo after * = |%@| b = %d, msn = %d", [foo asciiString], b, msn);
	  //NSLog(@"len = %d", len);
	  
	  //
	  // We got an untagged OK response. We handle only the one used in the IMAP authorization
	  // state and ignore the ones required during a SELECT command (like OK [UNSEEN <n>]).
	  //
	  if (len && strncasecmp("OK", buf, 2) == 0 && _lastCommand == IMAP_AUTHORIZATION)
	    {
	      [self _parseOK];
	    }
	  //
	  // We check if we got disconnected from the IMAP server.
	  // If it's the case, we invoke -reconnect.
	  // 
	  else if (len && strncasecmp("BYE", buf, 3) == 0)
	    {
	      [self _parseBYE];
	    }
	  //
	  //
	  //
	  else if (len && strncasecmp("LIST", buf, 4) == 0)
	    {
	      [self _parseLIST];
	    }
	  //
	  //
	  //
	  else if (len && strncasecmp("LSUB", buf, 4) == 0)
	    {
	      [self _parseLSUB];
	    }
	  //
	  // We got a FETCH response and we are done reading all
	  // bytes specified by our literal. We also handle
	  // untagged responses coming AFTER a tagged response,
	  // like that:
	  //
	  // 000c UID FETCH 3071053:3071053 BODY[TEXT]
	  // * 1 FETCH (UID 3071053 BODY[TEXT] {859}
	  // f00 bar zarb
	  // ..
	  // )
	  // 000c OK UID FETCH completed
	  // * 1 FETCH (FLAGS (\Seen))
	  //
	  // Responses like that must be carefully handled since
	  // _currentQueueObject would nil after getting the
	  // tagged response.
	  // 
	  else if (len && strncasecmp("FETCH", buf, 5) == 0 &&
		   (!_currentQueueObject || (_currentQueueObject && _currentQueueObject->literal == 0)))
	    {
	      [self _parseFETCH: msn];
	    }
	  //
	  //
	  //
	  else if (len && strncasecmp("EXISTS", buf, 6) == 0)
	    {
	      [self _parseEXISTS];
	      [_responsesFromServer removeLastObject];
	    }
	  //
	  //
	  //
	  else if (len && strncasecmp("RECENT", buf, 6) == 0)
	    {
	      [self _parseRECENT];
	      [_responsesFromServer removeLastObject];
	    }
	  //
	  //
	  //
	  else if (len && strncasecmp("SEARCH", buf, 6) == 0)
	    {
	      switch (_lastCommand)
		{
		case IMAP_UID_SEARCH:
		case IMAP_UID_SEARCH_ANSWERED:
		case IMAP_UID_SEARCH_FLAGGED:
		case IMAP_UID_SEARCH_UNSEEN:
		  [self _parseSEARCH_CACHE];
		  break;
		  
		default:
		  [self _parseSEARCH];
		}
	    }
	  //
	  //
	  //
	  else if (len && strncasecmp("STATUS", buf, 6) == 0)
	    {
	      [self _parseSTATUS];
	    }
	  //
	  //
	  //
	  else if (len && strncasecmp("EXPUNGE", buf, 7) == 0)
	    {
	      [self _parseEXPUNGE];
	    }
	  //
	  //
	  //
	  else if (len && strncasecmp("CAPABILITY", buf, 10) == 0)
	    {
	      [self _parseCAPABILITY];
	    }
          else
            {
              NSDebugLog(@"IMAP Unknown tagged response: %s", buf);
            }
	}
      //
      // We got a tagged response
      //
      else
	{
	  unsigned j;

	  //NSData *foo;
	  //foo = [NSData dataWithBytes: buf-i  length: i];
	  //NSLog(@"tag = |%@|", [foo asciiString]);

	  j = i+1;
	  buf++;
	  
	  // We read past our tag, in order to find
	  // the type of response (OK/NO/BAD).
	  while (j < count && *buf != ' ')
	    {
	      //NSLog(@"IN OK: %c", *buf);
	      buf++; j++;
	    }

	  //NSLog(@"OK/NO/BAD response = |%@|", [[NSData dataWithBytes: buf-j+i+1  length: j-i-1] asciiString]);
	  buf = buf-j+i+1;
	  
	  // From RFC3501:
	  //
	  // The server completion result response indicates the success or
	  // failure of the operation.  It is tagged with the same tag as the
	  // client command which began the operation.  Thus, if more than one
	  // command is in progress, the tag in a server completion response
	  // identifies the command to which the response applies.  There are
	  // three possible server completion responses: OK (indicating success),
	  // NO (indicating failure), or BAD (indicating a protocol error such as
	  // unrecognized command or command syntax error).
	  //
	  if (strncasecmp("OK", buf, 2) == 0)
	    {
	      [self _parseOK];
	    }
	  //
	  // RFC3501 says:
	  //
	  // The NO response indicates an operational error message from the
	  // server.  When tagged, it indicates unsuccessful completion of the
	  // associated command.  The untagged form indicates a warning; the
	  // command can still complete successfully.  The human-readable text
	  // describes the condition.
	  //
	  else if (strncasecmp("NO", buf, 2) == 0)
	    {
	      [self _parseNO];
	    }
	  else
	    {
	      [self _parseBAD];
	    }
	}
    } // while ((aData = split_lines...

  //NSLog(@"While loop broken!");
}


//
// This method authenticates the Store to the IMAP server.
// In case of an error, it returns NO.
//
// FIXME: We MUST NOT send a login command if LOGINDISABLED is
//        enforced by the server (6.2.3).
//
- (void) authenticate: (NSString*) theUsername
	     password: (NSString*) thePassword
	    mechanism: (NSString*) theMechanism
{
  ASSIGN(_username, theUsername);
  ASSIGN(_password, thePassword);
  ASSIGN(_mechanism, theMechanism);
 
  if (theMechanism && [theMechanism caseInsensitiveCompare: @"CRAM-MD5"] == NSOrderedSame)
    {
      [self sendCommand: IMAP_AUTHENTICATE_CRAM_MD5  info: nil  arguments: @"AUTHENTICATE CRAM-MD5"];
      return;
    }
  else if (theMechanism && [theMechanism caseInsensitiveCompare: @"LOGIN"] == NSOrderedSame)
    {
      [self sendCommand: IMAP_AUTHENTICATE_LOGIN  info: nil  arguments: @"AUTHENTICATE LOGIN"];
      return;
    }
  
  // We must verify if we must quote the password
  if ( nil != thePassword  &&
      ([thePassword rangeOfCharacterFromSet: [NSCharacterSet punctuationCharacterSet]].length ||
      [thePassword rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]].length))
    {
      thePassword = [NSString stringWithFormat: @"\"%@\"", thePassword];
    }
  else if (![thePassword is7bitSafe])
    {
      NSData *aData;
      
      //
      // We support non-ASCII password by using the 8-bit ISO Latin 1 encoding.
      // FIXME: Is there any standard on which encoding to use?
      //
      aData = [thePassword dataUsingEncoding: NSISOLatin1StringEncoding];
      
      [self sendCommand: IMAP_LOGIN
	    info: [NSDictionary dictionaryWithObject: aData  forKey: @"Password"]
	    arguments: @"LOGIN %@ {%d}", _username, [aData length]];
      return;
    }
  
  [self sendCommand: IMAP_LOGIN  info: nil  arguments: @"LOGIN %@ %@", _username, thePassword];
}


//
//
//
- (NSArray *) supportedMechanisms
{
  NSMutableArray *aMutableArray;
  NSString *aString;
  NSUInteger i, count;;

  aMutableArray = [NSMutableArray array];
  count = [_capabilities count];

  for (i = 0; i < count; i++)
    {
      aString = [_capabilities objectAtIndex: i];

      if ([aString hasCaseInsensitivePrefix: @"AUTH="])
	{
	  [aMutableArray addObject: [aString substringFromIndex: 5]];
	}
    }

  return aMutableArray;
}


//
// The default folder in IMAP is always Inbox. This method will prefetch
// the messages of an IMAP folder if they haven't been prefetched before.
//
- (id) defaultFolder
{
  return [self folderForName: @"INBOX"];
}


//
//
//
- (id) folderForName: (NSString *) theName
{
  return [self folderForName: theName
	       mode: PantomimeReadWriteMode
	       prefetch: YES];
}


//
//
//
- (CWIMAPFolder *) folderForName: (NSString *) theName
			  select: (BOOL) aBOOL
{
  if ([_openFolders objectForKey: theName])
    {
      return [_openFolders objectForKey: theName];
    }

  if (aBOOL)
    {
      return [self folderForName: theName];
    }
  else
    {
      CWIMAPFolder *aFolder;
      
      aFolder = [[CWIMAPFolder alloc] initWithName: theName];
      
      [aFolder setStore: self];
      [aFolder setSelected: NO];
      return AUTORELEASE(aFolder);
    }
}


//
//
//
#warning VERIFY FOR NoSelect
- (CWIMAPFolder *) folderForName: (NSString *) theName
			    mode: (PantomimeFolderMode) theMode
			prefetch: (BOOL) aBOOL
{  
  CWIMAPFolder *aFolder;
  
  aFolder = [_openFolders objectForKey: theName];

  // Careful here, we might return a non-selected mailbox.
  if (aFolder)
    {
      return aFolder;
    }

  aFolder = [[CWIMAPFolder alloc] initWithName: theName  mode: theMode];
  [aFolder setStore: self];
  [_openFolders setObject: aFolder  forKey: theName];
  RELEASE(aFolder);

  //NSLog(@"_connection_state.opening_mailbox = %d", _connection_state.opening_mailbox);

  // If we are already opening a mailbox, we must interrupt the process
  // and open the preferred one instead.
  if (_connection_state.opening_mailbox)
    {
      // Safety measure - in case close (so -removeFolderFromOpenFolders)
      // on the selected folder wasn't called.
      if (_selectedFolder)
	{
	  [_openFolders removeObjectForKey: [_selectedFolder name]];
	}

      [super cancelRequest];
      [self reconnect];

      _selectedFolder = aFolder;
      return _selectedFolder;
    }

  _connection_state.opening_mailbox = YES;

  if (theMode == PantomimeReadOnlyMode)
    {
      [self sendCommand: IMAP_EXAMINE  info: nil  arguments: @"EXAMINE \"%@\"", [theName modifiedUTF7String]];
    }
  else
    {
      [self sendCommand: IMAP_SELECT  info: nil  arguments: @"SELECT \"%@\"", [theName modifiedUTF7String]];
    }

  // This folder becomes the selected one. This will have to be improved in the future.
  // No need to retain "aFolder" here. The "_openFolders" dictionary already retains it.
  _selectedFolder = aFolder;

  if (aBOOL)
    {
      [_selectedFolder prefetch];
    }

  return _selectedFolder;
}


//
//
//
- (id) folderForURL: (NSString *) theURL
{
  CWURLName *theURLName;
  id aFolder;

  theURLName = [[CWURLName alloc] initWithString: theURL];

  aFolder = [self folderForName: [theURLName foldername]];

  RELEASE(theURLName);
  
  return aFolder;
}


//
// When this method is invoked for the first time, it sends a LIST
// command to the IMAP server and cache the results for subsequent
// queries. The IMAPStore notifies the delegate once it has parsed
// all server's responses.
//
- (NSEnumerator *) folderEnumerator
{
  if (![_folders count])
    {
      [self sendCommand: IMAP_LIST  info: nil  arguments: @"LIST \"\" \"*\""];
      return nil;
    }

  return [_folders keyEnumerator];
}


//
// This method works the same way as the -folderEnumerator method.
//
- (NSEnumerator *) subscribedFolderEnumerator
{
  if (![_subscribedFolders count])
    {
      [self sendCommand: IMAP_LSUB  info: nil  arguments: @"LSUB \"\" \"*\""];
      return nil;
    }

  return [_subscribedFolders objectEnumerator];
}


//
//
//
- (NSDictionary *) folderStatus: (NSArray *) theArray
{
  NSUInteger i;

  [_folderStatus removeAllObjects];

  // C: A042 STATUS blurdybloop (UIDNEXT MESSAGES)
  // S: * STATUS blurdybloop (MESSAGES 231 UIDNEXT 44292)
  // S: A042 OK STATUS completed
  //
  // We send: MESSAGES UNSEEN
  for (i = 0; i < [theArray count]; i++)
    {
      // RFC3501 says we SHOULD NOT call STATUS on the selected mailbox - so we won't do it.
      if (_selectedFolder && [[_selectedFolder name] isEqualToString: [theArray objectAtIndex: i]])
	{
	  continue;
	}

      [self sendCommand: IMAP_STATUS
	    info: [NSDictionary dictionaryWithObject: [theArray objectAtIndex: i]  forKey: @"Name"]
	    arguments: @"STATUS \"%@\" (MESSAGES UNSEEN)", [[theArray objectAtIndex: i] modifiedUTF7String]];
    }

  return _folderStatus;
}


//
// This method appends theCommand to the IMAP tag
// and sends it to the server.
//
// It then sets the last command (w/o the tag) that has been sent.
//
// If the server is already processing a query, it queues it in _queue.
//
- (void) sendCommand: (IMAPCommand) theCommand  info: (NSDictionary *) theInfo  arguments: (NSString *) theFormat, ...
{
  if (theCommand == IMAP_EMPTY_QUEUE)
    {
      if ([_queue count])
	{
	  // We dequeue the first inserted command from the queue.
	  _currentQueueObject = [_queue lastObject];
	}
      else
	{
	  // The queue is empty, we have nothing more to do...
	  _currentQueueObject = nil;
	  return;
	}
    }
  else
    {
      CWIMAPQueueObject *aQueueObject;
      NSString *aString;
      va_list args;
      NSUInteger i, count;

      //NSLog(@"sendCommand invoked, cmd = %i", theCommand);
      va_start(args, theFormat);
      
      aString = [[NSString alloc] initWithFormat: theFormat  arguments: args];
      
      //
      // We must check in the queue if we aren't trying to add a command that is already there.
      // This could happend if -rawSource is called in IMAPMessage multiple times before
      // PantomimeMessageFetchCompleted is sent.
      //
      // We skip this verification for the IMAP_APPEND command as a messages with the same size
      // could be quickly appended to the folder and we do NOT want to skip the second one.
      //
      count = [_queue count];

      for (i = 0; i < count; i++)
	{
	  aQueueObject = [_queue objectAtIndex: i];
	  if (aQueueObject->command == theCommand && theCommand != IMAP_APPEND && [aQueueObject->arguments isEqualToString: aString])
	    {
	      RELEASE(aString);
	      //NSLog(@"A COMMAND ALREADY EXIST!!!!");
	      return;
	    }   
	}

      aQueueObject = [[CWIMAPQueueObject alloc] initWithCommand: theCommand  arguments: aString  tag: [self nextTag]  info: theInfo];
      RELEASE(aString);
      
      [_queue insertObject: aQueueObject  atIndex: 0];
      RELEASE(aQueueObject);
      
      //NSLog(@"queue size = %d", [_queue count]);
      
      // If we had queued commands, we return since we'll eventually
      // dequeue them one by one. Otherwise, we run it immediately.
      if ([_queue count] > 1)
	{
	  //NSLog(@"QUEUED |%@|", aString);
	  return;
	}

      _currentQueueObject = aQueueObject;
    }
     
  //NSLog(@"Sending |%@|", _currentQueueObject->arguments);
  _lastCommand = _currentQueueObject->command;

  [self writeData: _currentQueueObject->tag];
  [self writeData: [NSData dataWithBytes: " "  length: 1]];
  [self writeData: [_currentQueueObject->arguments dataUsingEncoding: defaultCStringEncoding]];
  [self writeData: CRLF];

  POST_NOTIFICATION(@"PantomimeCommandSent", self, _currentQueueObject->info);
  PERFORM_SELECTOR_2(_delegate, @selector(commandSent:), @"PantomimeCommandSent", [NSNumber numberWithUnsignedInt: _lastCommand], @"Command");
}

//
// 
//
- (NSEnumerator *) openFoldersEnumerator
{
  return [_openFolders objectEnumerator];
}

//
//
//
- (void) removeFolderFromOpenFolders: (CWFolder *) theFolder
{
  if (_selectedFolder == (CWIMAPFolder *)theFolder)
    {
      _selectedFolder = nil;
    }

  [_openFolders removeObjectForKey: [theFolder name]];
}

//
// 
//
- (BOOL) folderForNameIsOpen: (NSString *) theName
{
  NSEnumerator *anEnumerator;
  CWIMAPFolder *aFolder;
  
  anEnumerator = [self openFoldersEnumerator];
 
  while ((aFolder = [anEnumerator nextObject]))
    {
      if ([[aFolder name] compare: theName
			  options: NSCaseInsensitiveSearch] == NSOrderedSame)
 	{
 	  return YES;
 	}
    }
  
  return NO;
}


//
// This method verifies in the cache if theName is present.
// If so, it returns the associated value.
//
// If it's not present, it sends a LIST command to the server
// and the delegate will eventually be notified when the LIST
// command completed. It also returns 0 if it's not present.
// 
- (PantomimeFolderType) folderTypeForFolderName: (NSString *) theName
{
  id o;

  o = [_folders objectForKey: theName];
  
  if (o)
    {
      return [o intValue];
    }

  [self sendCommand: IMAP_LIST  info: nil  arguments: @"LIST \"\" \"%@\"", [theName modifiedUTF7String]];

  return 0;
}


//
//
//
- (unichar) folderSeparator
{
  return _folderSeparator;
}


//
//
//
- (NSData *) nextTag
{
  _tag++;
  return [self lastTag];
}


//
//
//
- (NSData *) lastTag
{
  char str[5];
  sprintf(str, "%04x", _tag);
  return [NSData dataWithBytes: str  length: 4];
}


//
//
//
- (void) subscribeToFolderWithName: (NSString *) theName
{
  [self sendCommand: IMAP_SUBSCRIBE
	info: [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]
	arguments: @"SUBSCRIBE \"%@\"", [theName modifiedUTF7String]];
}


//
//
//
- (void) unsubscribeToFolderWithName: (NSString *) theName
{
  [self sendCommand: IMAP_UNSUBSCRIBE
	info: [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]
	arguments: @"UNSUBSCRIBE \"%@\"", [theName modifiedUTF7String]];
}


//
//
//
- (void) close
{
  [self sendCommand: IMAP_LOGOUT  info: nil  arguments: @"LOGOUT"];
}


//
// Create the mailbox and subscribe to it. The full path to the mailbox must
// be provided.
//
// The delegate will be notified when the folder has been created (or not).
//
- (void) createFolderWithName: (NSString *) theName 
			 type: (PantomimeFolderFormat) theType
		     contents: (NSData *) theContents
{
  [self sendCommand: IMAP_CREATE
	info: [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]
	arguments: @"CREATE \"%@\"", [theName modifiedUTF7String]];
}


//
// Delete the mailbox. The full path to the mailbox must be provided.
//
// The delegate will be notified when the folder has been deleted (or not).
//
- (void) deleteFolderWithName: (NSString *) theName
{
  [self sendCommand: IMAP_DELETE
	info: [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]
	arguments: @"DELETE \"%@\"", [theName modifiedUTF7String]];
}


//
// This method is used to rename a folder.
//
// theName and theNewName MUST be the full path of those mailboxes.
// If they begin with the folder separator (ie., '/'), the character is
// automatically stripped.
//
// This method supports renaming SELECT'ed mailboxes.
//
// The delegate will be notified when the folder has been renamed (or not).
//
- (void) renameFolderWithName: (NSString *) theName
                       toName: (NSString *) theNewName
{
  NSDictionary *info;

  theName = [theName stringByDeletingFirstPathSeparator: _folderSeparator];
  theNewName = [theNewName stringByDeletingFirstPathSeparator: _folderSeparator]; 
  info = [NSDictionary dictionaryWithObjectsAndKeys: theName, @"Name", theNewName, @"NewName", nil];

  if ([[theName stringByTrimmingWhiteSpaces] length] == 0 ||
      [[theNewName stringByTrimmingWhiteSpaces] length] == 0)
    {
      POST_NOTIFICATION(PantomimeFolderRenameFailed, self, info);
      PERFORM_SELECTOR_3(_delegate, @selector(folderRenameFailed:), PantomimeFolderRenameFailed, info);
    }

  [self sendCommand: IMAP_RENAME
	info: info
	arguments: @"RENAME \"%@\" \"%@\"", [theName modifiedUTF7String], [theNewName modifiedUTF7String]];
}


//
// This method NOOPs the IMAP store.
//
- (void) noop
{
  [self sendCommand: IMAP_NOOP  info: nil  arguments: @"NOOP"];
}


//
//
//
- (int) reconnect
{
  //NSLog(@"CWIMAPStore: -reconnect");
  
  [_connection_state.previous_queue addObjectsFromArray: _queue];
  _connection_state.reconnecting = YES;
  
  // We flush our read/write buffers.
  [_rbuf setLength: 0];
  [_wbuf setLength: 0];

  //
  // We first empty our queue and set again our _lastCommand ivar to
  // the IMAP_AUTHORIZATION command
  //
  //NSLog(@"queue count = %d", [_queue count]);
  //NSLog(@"%@", [_queue description]);
  [_queue removeAllObjects];
  _lastCommand = IMAP_AUTHORIZATION;
  _currentQueueObject = nil;
  _counter = 0;

  [super close];
  [super connectInBackgroundAndNotify];

  return 0;
}


//
// 
//
- (void) startTLS
{
  [self sendCommand: IMAP_STARTTLS  info: nil  arguments: @"STARTTLS"];
}

@end


//
// Private methods
//
@implementation CWIMAPStore (Private)

//
// This method is used to parse the name of a mailbox.
//
// If the string was encoded using mUTF-7, it'll also
// decode it.
//
- (NSString *) _folderNameFromString: (NSString *) theString
{
  NSString *aString, *decodedString;
  NSRange aRange;

  aRange = [theString rangeOfString: @"\""];

  if (aRange.length)
    {
      NSUInteger mark;

      mark = aRange.location + 1;
      
      aRange = [theString rangeOfString: @"\""
			  options: 0
			  range: NSMakeRange(mark, [theString length] - mark)];
      
      aString = [theString substringWithRange: NSMakeRange(mark, aRange.location - mark)];

      // Check if we got "NIL" or a real separator.
      if ([aString length] == 1)
	{
	  _folderSeparator = [aString characterAtIndex: 0];
	}
      else
	{
	  _folderSeparator = 0;
	}
      
      mark = aRange.location + 2;
      aString = [theString substringFromIndex: mark];
    }
  else
    {
      aRange = [theString rangeOfString: @"NIL"  options: NSCaseInsensitiveSearch];

      if (aRange.length)
	{
	  aString = [theString substringFromIndex: aRange.location + aRange.length + 1];
	}
      else
	{
	  return theString;
	}
    }
    
  aString = [aString stringFromQuotedString];
  decodedString = [aString stringFromModifiedUTF7];
  
  return (decodedString != nil ? decodedString : aString);
}


//
// This method parses the flags received in theString and builds
// a corresponding Flags object for them.
//
- (void) _parseFlags: (NSString *) theString
	     message: (CWIMAPMessage *) theMessage
	      record: (cache_record *) theRecord
{
  CWFlags *theFlags;
  NSRange aRange;
  
  theFlags = [[CWFlags alloc] init];

  // We check if the message has the Seen flag
  aRange = [theString rangeOfString: @"\\Seen" 
		      options: NSCaseInsensitiveSearch];
  
  if (aRange.length > 0)
    {
      [theFlags add: PantomimeSeen];
    }

  // We check if the message has the Recent flag
  aRange = [theString rangeOfString: @"\\Recent" 
		      options: NSCaseInsensitiveSearch];
  
  if (aRange.length > 0)
    {
      [theFlags add: PantomimeRecent];
    }
  
  // We check if the message has the Deleted flag
  aRange = [theString rangeOfString: @"\\Deleted"
		      options: NSCaseInsensitiveSearch];
  
  if (aRange.length > 0)
    {
      [theFlags add: PantomimeDeleted];
    }
  
  // We check if the message has the Answered flag
  aRange = [theString rangeOfString: @"\\Answered"
		      options: NSCaseInsensitiveSearch];
  
  if (aRange.length > 0)
    {
      [theFlags add: PantomimeAnswered];
    }
  
  // We check if the message has the Flagged flag
  aRange = [theString rangeOfString: @"\\Flagged"
		      options: NSCaseInsensitiveSearch];
  
  if (aRange.length > 0)
    {
      [theFlags add: PantomimeFlagged];
    }
  
  // We check if the message has the Draft flag
  aRange = [theString rangeOfString: @"\\Draft"
		      options: NSCaseInsensitiveSearch];
  
  if (aRange.length > 0)
    {
      [theFlags add: PantomimeDraft];
    }

  [[theMessage flags] replaceWithFlags: theFlags];
  theRecord->flags = theFlags->flags;
  RELEASE(theFlags);
  
  //
  // If our previous command is NOT the FETCH command, we must inform our
  // delegate that messages flags have changed. The delegate SHOULD refresh
  // its view and does NOT have to issue any command to update the state
  // of the messages (since it has been done).
  //
  if (_lastCommand != IMAP_UID_FETCH_BODY_TEXT && _lastCommand != IMAP_UID_FETCH_HEADER_FIELDS &&
      _lastCommand != IMAP_UID_FETCH_HEADER_FIELDS_NOT && _lastCommand != IMAP_UID_FETCH_RFC822)
    {
      POST_NOTIFICATION(PantomimeMessageChanged, self, [NSDictionary dictionaryWithObject: theMessage  forKey: @"Message"]);
      PERFORM_SELECTOR_1(_delegate, @selector(messageChanged:), PantomimeMessageChanged);
    }
}


//
//
//
- (void) _renameFolder
{
  CWFolderInformation *aFolderInformation;
  NSString *aName, *aNewName;
  CWIMAPFolder *aFolder;

  aName = [_currentQueueObject->info objectForKey: @"Name"];
  aNewName = [_currentQueueObject->info objectForKey: @"NewName"];
  
  // If the folder was open, we change its name and recache its entry.
  aFolder = [_openFolders objectForKey: aName];
	
  if (aFolder)
    {
      RETAIN(aFolder);
      [aFolder setName: aNewName];
      [_openFolders removeObjectForKey: aName];
      [_openFolders setObject: aFolder  forKey: aNewName];
      RELEASE(aFolder);
    }
  
  // We then do the same thing for our list of folders / suscribed folders
  aFolderInformation = RETAIN([_folders objectForKey: aName]);
  [_folders removeObjectForKey: aName];

  if (aFolderInformation)
    {
      [_folders setObject: aFolderInformation  forKey: aNewName];
      RELEASE(aFolderInformation);
    }

  if ([_subscribedFolders containsObject: aName])
    {
      [_subscribedFolders removeObject: aName];
      [_subscribedFolders addObject: aNewName];
    }
}


//
// This method parses a SEARCH response in order to decode
// all UIDs in the result.
//
// Examples of theData:
//
// "* SEARCH 1 4 59 81"
// "* SEARCH"
//
- (NSArray *) _uniqueIdentifiersFromData: (NSData *) theData
{
  NSMutableArray *aMutableArray;
  NSScanner *aScanner;
  unsigned int value;

  aMutableArray = [NSMutableArray array];

  theData = [theData subdataFromIndex: 8];

  // If we have no results, let's return right away.
  if (![theData length])
    {
      return aMutableArray;
    }

  // We scan all our UIDs.
  aScanner = [[NSScanner alloc] initWithString: [theData asciiString]];
  
  while (![aScanner isAtEnd])
    {
      [aScanner scanUnsignedInt: &value];
      [aMutableArray addObject: [NSNumber numberWithUnsignedInt: value]];
    }

  RELEASE(aScanner);

  return aMutableArray;
}


//
//
//
- (void) _parseAUTHENTICATE_CRAM_MD5
{
  NSData *aData;
  
  aData = [_responsesFromServer lastObject];

  //
  // We first verify if we got our challenge response from the IMAP server.
  // If so, we use it and send back a response to proceed with the authentication.
  //
  if ([aData hasCPrefix: "+"])
    {
      NSString *aString;
      CWMD5 *aMD5;

      // We trim the "+ " and we keep the challenge phrase
      aData = [aData subdataFromIndex: 2];
      
      //NSLog(@"Challenge phrase = |%@|", [aData asciiString]);
      aMD5 = [[CWMD5 alloc] initWithData: [aData decodeBase64]];
      [aMD5 computeDigest];
      
      aString = [NSString stringWithFormat: @"%@ %@", _username, [aMD5 hmacAsStringUsingPassword: _password]];
      aString = [[NSString alloc] initWithData: [[aString dataUsingEncoding: NSASCIIStringEncoding] encodeBase64WithLineLength: 0]
				  encoding: NSASCIIStringEncoding];

      [self writeData: [aString dataUsingEncoding: defaultCStringEncoding]];
      [self writeData: CRLF];

      RELEASE(aMD5);
      RELEASE(aString);
    }
}


//
// LOGIN is a very lame authentication method but we support it anyway. We basically
// wait for a challenge, send the username (in base64), wait for an other challenge
// and finally send the password (in base64). The challenges aren't even used.
//
- (void) _parseAUTHENTICATE_LOGIN
{
  NSData *aData;
  
  aData = [_responsesFromServer lastObject];
  
  //
  // We first verify if we got our challenge response from the IMAP server.
  // If so, we use it and send back a response to proceed with the authentication.
  // Based on what we sent before, we can either send the username or the password.
  //
  if ([aData hasCPrefix: "+"])
    {
      NSData *aResponse;
      
      // Have we read the initial challenge? If not, we must send the username!
      if (_currentQueueObject && ![_currentQueueObject->info
					objectForKey: @"Challenge"])
	{
	  aResponse =  [[_username dataUsingEncoding: NSASCIIStringEncoding]
						encodeBase64WithLineLength: 0];
	  [_currentQueueObject->info setObject: aData  forKey: @"Challenge"];
	}
      else
	{
	  aResponse = [[_password dataUsingEncoding: NSASCIIStringEncoding]
						encodeBase64WithLineLength: 0];
	}

      [self writeData: aResponse];
      [self writeData: CRLF];
    }
}


//
//
//
- (void) _parseBAD
{
  NSData *aData;
  
  aData = [_responsesFromServer lastObject];

  switch (_lastCommand)
    {
    case IMAP_LOGIN:
      // This can happen if we got an empty username or password.
      AUTHENTICATION_FAILED(_delegate, _mechanism);
      break;

    default:
      // We got a BAD response that we could not handle. Raise an exception for now
      // and remove the command that caused this from the queue.
      [_queue removeLastObject];
      [_responsesFromServer removeAllObjects];
      [NSException raise: PantomimeProtocolException
		   format: @"Unable to handle IMAP response (%@).", [aData asciiString]];
    }

  if (![aData hasCPrefix: "*"])
    {
      [_queue removeLastObject];
      [self sendCommand: IMAP_EMPTY_QUEUE  info: nil  arguments: @""];
    }

  [_responsesFromServer removeAllObjects];
}


//
//
//
- (void) _parseBYE
{
  //
  // We check if we sent the IMAP_LOGOUT command.
  //
  // If we got an untagged BYE response, it means
  // that the server disconnected us. We will
  // handle that in CWService: -updateRead.
  //
  if (_lastCommand == IMAP_LOGOUT)
    {
      return;
    }
}


//
// This method parses an * CAPABILITY IMAP4 IMAP4rev1 ACL AUTH=LOGIN NAMESPACE ..
// untagged response (6.1.1)
//
// FIXME: check for OK/BAD
//
- (void) _parseCAPABILITY
{
  NSString *aString;
  NSData *aData;

  aData = [_responsesFromServer objectAtIndex: 0];
  aString = [[NSString alloc] initWithData: aData  encoding: defaultCStringEncoding];

  [_capabilities addObjectsFromArray: [[aString substringFromIndex: 13] componentsSeparatedByString: @" "]];
  RELEASE(aString);

  if (_connection_state.reconnecting)
    {
      [self authenticate: _username  password: _password  mechanism: _mechanism];
    }
  else
    {
      POST_NOTIFICATION(PantomimeServiceInitialized, self, nil);
      PERFORM_SELECTOR_1(_delegate, @selector(serviceInitialized:),  PantomimeServiceInitialized);
    }
}


//
// This method parses an * 23 EXISTS untagged response. (7.3.1)
//
// If we were NOT issueing a SELECT command, it fetches the
// new messages (if any) and informs the folder's delegate that
// new messages have arrived.
//
- (void) _parseEXISTS
{
  NSData *aData;
  unsigned n;
  
  aData = [_responsesFromServer lastObject];

  sscanf([aData cString], "* %u EXISTS", &n);
  
  //NSLog(@"_parseExists: %d", n);

  if (_currentQueueObject && _currentQueueObject->command != IMAP_SELECT &&
      _selectedFolder && 
      n > [_selectedFolder->allMessages count])
    {
      NSUInteger uid;
      
      uid = 0;
      
      // We prefetch the new messages from the last UID+1
      if ([_selectedFolder->allMessages lastObject])
	{
	  uid = [[_selectedFolder->allMessages lastObject] UID];
	} 

      [self sendCommand: IMAP_UID_FETCH_HEADER_FIELDS  info: nil  arguments: @"UID FETCH %u:* (FLAGS RFC822.SIZE BODY.PEEK[HEADER.FIELDS (From To Cc Subject Date Message-ID References In-Reply-To)])", (uid+1)];
    }
}


//
// Example: * 44 EXPUNGE
//
- (void) _parseEXPUNGE
{
  CWIMAPMessage *aMessage;
  NSData *aData;
  NSUInteger i;
  unsigned msn;

  // It looks like some servers send untagged expunge reponses
  // _after_ the selected folder has been closed.
  if (!_selectedFolder)
    {
      return;
    }

  aData = [_responsesFromServer lastObject];

  sscanf([aData cString], "* %u EXPUNGE", &msn);

  //
  // Messages CAN be expunged before we really had time to FETCH them.
  // We simply proceed by skipping over MSN that are bigger than we
  // we have so far. It should be safe since the view hasn't even
  // had the chance to display them.
  //
  if (msn > [_selectedFolder->allMessages count]) return;

  aMessage = [_selectedFolder->allMessages objectAtIndex: (msn-1)];
  RETAIN(aMessage);
  
  // We do NOT use  [_selectedFolder removeMessage: aMessage] since it'll
  // thread the messages everytime we invoke it. We rather thread messages
  // if:
  // * We got an untagged EXPUNGE response but the last command was NOT
  //   an EXPUNGE one (see below, near the end of the method)
  // * We sent an EXPUNGE command - we'll do the threading of the
  //   messages in _parseOK:
  //
  [_selectedFolder->allMessages removeObject: aMessage];
  [_selectedFolder updateCache];
  
  // We remove its entry in our cache
  if ([_selectedFolder cacheManager])
    {
      [(CWIMAPCacheManager *)[_selectedFolder cacheManager] removeMessageWithUID: [aMessage UID]];
    }
  
  // We update all MSNs starting from the message that has been expunged.
  for (i = (msn-1); i < [_selectedFolder->allMessages count]; i++)
    {
      [[_selectedFolder->allMessages objectAtIndex: i] setMessageNumber: (i+1)];
    }
  
  //
  // If our previous command is NOT the EXPUNGE command, we must inform our
  // delegate that messages have been expunged. The delegate SHOULD refresh
  // its view and does NOT have to issue any command to update the state
  // of the messages (since it has been done).
  //
  if (_lastCommand != IMAP_EXPUNGE)
    {
      if ([_selectedFolder allContainers])
	{
	  [_selectedFolder thread];
	}

      if ([_selectedFolder cacheManager])
	{
	  [[_selectedFolder cacheManager] expunge];
	}

      POST_NOTIFICATION(PantomimeMessageExpunged, self, [NSDictionary dictionaryWithObject: aMessage  forKey: @"Message"]);
      PERFORM_SELECTOR_1(_delegate, @selector(messageExpunged:), PantomimeMessageExpunged);
    }

  RELEASE(aMessage);

  //NSLog(@"Expunged %d", msn);
}


//
//
// Examples of FETCH responses:
//
// * 50 FETCH (UID 50 RFC822 {6718}
// Return-Path: <...
// )
//
//
// * 418 FETCH (FLAGS (\Seen) UID 418 RFC822.SIZE 3565452 BODY[HEADER.FIELDS (From To Cc Subject Date Message-ID 
// References In-Reply-To MIME-Version)] {666}
// Subject: abc
// ...
// )
//
//
// * 50 FETCH (UID 50 BODY[HEADER.FIELDS.NOT (From To Cc Subject Date Message-ID References In-Reply-To MIME-Version)] {1412}
// Return-Path: <...
// )
//
// * 50 FETCH (BODY[TEXT] {5009}
// Hi, ...
// )
//
//
// "Twisted" response from Microsoft Exchange 2000:
//
// * 549 FETCH (FLAGS (\Recent) RFC822.SIZE 970 BODY[HEADER.FIELDS (From To Cc Subject Date Message-ID References In-Reply-To MIME-Version)] {196}
// From: <aaaaaa@bbbbbbbbbbbbbbb.com>
// To: aaaaaa@bbbbbbbbbbbbbbb.com
// Subject: Test mail
// Date: Tue, 16 Dec 2003 15:52:23 GMT
// Message-Id: <200312161552.PAA07523@aaaaaaa.bbb.ccccccccccccccc.com>
// 
//  UID 29905)
//
//
// Yet an other "twisted" response, likely coming from UW IMAP Server (2001.315rh)
//
// * 741 FETCH (UID 23628 BODY[TEXT] {818}
// f00bar baz
// ...
// )
// * 741 FETCH (FLAGS (\Seen) UID 23628)
// 000b OK UID FETCH completed
//
//
// Other examples:
//
// * 1 FETCH (FLAGS (\Seen) UID 97 RFC822.SIZE 19123 BODY[HEADER.FIELDS (From To Cc Subject Date
// Message-ID References In-Reply-To MIME-Version)] {216}
//
// This method can be called more than on times for a message. For example, Exchange sends
// answers like this one:
//
// * 9 FETCH (BODY[HEADER.FIELDS.NOT (From To Cc Subject Date Message-ID References In-Reply-To MIME-Version)] {408}
// Received: by nt1.inverse.qc.ca 
// .id <01C34ADC.D13E2A20@nt1.inverse.qc.ca>; Tue, 15 Jul 2003 09:24:36 -0500
// content-class: urn:content-classes:message
// Content-Type: multipart/mixed;
// .boundary="----_=_NextPart_001_01C34ADC.D13E2A20"
// X-MS-Has-Attach: yes
// X-MS-TNEF-Correlator: 
// Thread-Topic: test5
// X-MimeOLE: Produced By Microsoft Exchange V6.0.6249.0
// Thread-Index: AcNK3NDIIAS/1aRKSYC4x2N4Zj3GGg==
//
// UID 9)
//
// And we MUST parse the UID correctly.
//
- (void) _parseFETCH: (unsigned) theMSN
{
  NSMutableString *aMutableString;
  NSCharacterSet *aCharacterSet;
  CWIMAPMessage *aMessage;
  NSScanner *aScanner;

  NSMutableArray *aMutableArray;
  NSString *aWord, *aString;
  NSRange aRange;

  BOOL done, seen_fetch, must_flush_record;
  NSUInteger i, j, count, len;
  cache_record r;
  
  //
  // The folder might have been closed so we must not try to
  // update it for no good reason.
  //
  if (!_selectedFolder) return;
  
  count = [_responsesFromServer count]-1;
   
  //NSLog(@"RESPONSES FROM SERVER: %d", count);
  
  aMutableString = [[NSMutableString alloc] init];
  aMutableArray = [[NSMutableArray alloc] init];

  //
  // Note:
  //
  // We must be careful here to NOT consider all responses from the server. For example,
  // UW IMAP might send us:
  // 1 UID SEARCH ANSWERED
  // * SEARCH
  // * 1 FETCH (FLAGS (\Recent \Seen) UID 1)
  // 1 OK UID SEARCH completed
  //
  // In such response, we must NOT consider the "* SEARCH" response.
  //
  must_flush_record = seen_fetch = NO;

  for (i = 0; i <= count; i++)
    {
      aString = [[_responsesFromServer objectAtIndex: i] asciiString];
      //NSLog(@"%i: %@", i, aString);
      if (!seen_fetch && [aString hasCaseInsensitivePrefix: [NSString stringWithFormat: @"* %u FETCH", theMSN]])
	{
	  seen_fetch = YES;
	}

      if (seen_fetch)
	{
	  [aMutableArray addObject: [_responsesFromServer objectAtIndex: i]];
	  [aMutableString appendString: aString];
	  if (i < count-1)
	    {
	      [aMutableString appendString: @" "];
	    }
	}
    }
  
  //NSLog(@"GOT TO PARSE: |%@|", aMutableString);

  aCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  len = [aMutableString length];
  aMessage = nil;
  i = 0;
  
  aScanner = [[NSScanner alloc] initWithString: aMutableString];
  [aScanner setScanLocation: i];
  
  done = ![aScanner scanUpToCharactersFromSet: aCharacterSet  intoString: NULL];

  //
  // We tokenize our string into words
  //
  while (!done)
    {
      j = [aScanner scanLocation];
      aWord = [[aMutableString substringWithRange: NSMakeRange(i,j-i)] stringByTrimmingWhiteSpaces];
      
      //NSLog(@"WORD |%@|", aWord);
      
      if ([aWord characterAtIndex: 0] == '(')
	{
	  aWord = [aWord substringFromIndex: 1];
	}

      //
      // We read the MSN
      //
      if ([aWord characterAtIndex: 0] == '*')
	{
	  unsigned msn;

	  [aScanner scanUnsignedInt: &msn];
	  //NSLog(@"msn = %d", msn);

	  //
	  // If the MSN is > then the folder's count, that means it's
	  // a new message.
	  //
	  // We can safely assume this since what we have in _selectedFolder->allMessages
	  // is really the messages in our IMAP folder. That is true since we
	  // synchronized our cache when opening the folder, in IMAPFolder: -prefetch.
	  //
	  if (msn > [_selectedFolder->allMessages count])
	    {
	      //NSLog(@"============ NEW MESSAGE ======================");
	      aMessage = [[CWIMAPMessage alloc] init];
	      
	      // We set some initial properties to our message;
	      [aMessage setInitialized: NO];
	      [aMessage setFolder: _selectedFolder];
	      [aMessage setMessageNumber: msn];
	      [_selectedFolder appendMessage: aMessage];
	      
	      // We add the new message to our cache.
	      if ([_selectedFolder cacheManager])
		{
		  if (must_flush_record)
		    {
		      [(CWIMAPCacheManager *)[_selectedFolder cacheManager] writeRecord: &r  message: aMessage];
		    }
		  
		  CLEAR_CACHE_RECORD(r);
		  must_flush_record = YES;

		  //[[_selectedFolder cacheManager] addObject: aMessage];
		}
	      
	      RELEASE(aMessage);
	    }
	  else
	    {
	      aMessage = [_selectedFolder->allMessages objectAtIndex: (msn-1)];
	      [aMessage setMessageNumber: msn];
	      [aMessage setFolder: _selectedFolder];
	    }
	}
      if (!aMessage)
	{
	  RELEASE(aMutableString);
	  RELEASE(aMutableArray);
	  RELEASE(aScanner);
	  return;
	}
      //
      // We read our UID
      //
      if ([aWord caseInsensitiveCompare: @"UID"] == NSOrderedSame)
	{
	  unsigned int uid;

	  [aScanner scanUnsignedInt: &uid];
	  //NSLog(@"uid %d j = %d, scanLoc = %d", uid, j, [aScanner scanLocation]);
	  
	  if ([aMessage UID] == 0)
	    {
	      [aMessage setUID: uid];
	      r.imap_uid = uid;
	    }

	  j = [aScanner scanLocation];
	}
      //
      // We read our flags. We usually get something like FLAGS (\Seen)
      //
      else if ([aWord caseInsensitiveCompare: @"FLAGS"] == NSOrderedSame)
	{
	  // We get the substring inside our ( )
	  aRange = [aMutableString rangeOfString: @")"  options: 0  range: NSMakeRange(j,len-j)]; 
	  //NSLog(@"Flags = |%@|", [aMutableString substringWithRange: NSMakeRange(j+2, aRange.location-j-2)]);
	  [self _parseFlags: [aMutableString substringWithRange: NSMakeRange(j+2, aRange.location-j-2)]
		message: aMessage
		record: &r];

	  j = aRange.location + 1;
	  [aScanner setScanLocation: j];
	}
      //
      // We read the RFC822 message size
      //
      else if ([aWord caseInsensitiveCompare: @"RFC822.SIZE"] == NSOrderedSame)
	{
	  unsigned size;

	  [aScanner scanUnsignedInt: &size];
	  //NSLog(@"size = %u", size);
	  [aMessage setSize: size];
	  r.size = size;

	  j = [aScanner scanLocation];
	}
      //
      // Note:
      //
      // Novell's IMAP server doesn't distinguish a NOT BODY.PEEK from a standard one (ie., no NOT). So we can have:
      //
      // 000b UID FETCH 3071053:3071053 BODY.PEEK[HEADER.FIELDS.NOT (From To Cc Subject Date Message-ID References In-Reply-To MIME-Version)]
      // * 1 FETCH (UID 3071053 BODY[HEADER.FIELDS ("From" "To" "Cc" "Subject" "Date" "Message-ID" "References" "In-Reply-To" "MIME-Version")] {1030}
      //
      else if ([aWord caseInsensitiveCompare: @"BODY[HEADER.FIELDS.NOT"] == NSOrderedSame ||
	       _lastCommand == IMAP_UID_FETCH_HEADER_FIELDS_NOT)
	{
	  [[_currentQueueObject->info objectForKey: @"NSData"] replaceCRLFWithLF];
	  [aMessage addHeadersFromData:  [_currentQueueObject->info objectForKey: @"NSData"] record: NULL];
	  break;
	}
      //
      // We must not break immediately after parsing this information. It's very important
      // since servers like Exchange might send us responses like:
      //
      // * 1 FETCH (FLAGS (\Seen) RFC822.SIZE 4491 BODY[HEADER.FIELDS (From To Cc Subject Date Message-ID References In-Reply-To Content-Type)] {337} UID 614348)
      //
      // If we break right away, we'll skip the size and more importantly, the UID.
      //
      else if ([aWord caseInsensitiveCompare: @"BODY[HEADER.FIELDS"] == NSOrderedSame)
	{
	  [[_currentQueueObject->info objectForKey: @"NSData"] replaceCRLFWithLF];
	  [aMessage setHeadersFromData: [_currentQueueObject->info objectForKey: @"NSData"]  record: &r];
	}
      //
      //
      //
      else if ([aWord caseInsensitiveCompare: @"BODY[TEXT]"] == NSOrderedSame)
	{
	  [[_currentQueueObject->info objectForKey: @"NSData"] replaceCRLFWithLF];
	  if (![aMessage content])
	    {
	      NSData *aData;
	      
	      //
	      // We do an initial check for the message body. If we haven't read a literal,
	      // [_currentQueueObject->info objectForKey: @"NSData"] returns nil. This can
	      // happen with messages having a totally emtpy body. For those messages,
	      // we simply set a default content, being an empty NSData instance.
	      //
	      aData = [_currentQueueObject->info objectForKey: @"NSData"];
	      
	      if (!aData) aData = [NSData data];
	      
	      [CWMIMEUtility setContentFromRawSource: aData  inPart: aMessage];
	      [aMessage setInitialized: YES];

	      [_currentQueueObject->info setObject: aMessage  forKey: @"Message"];

	      POST_NOTIFICATION(PantomimeMessagePrefetchCompleted, self, [NSDictionary dictionaryWithObject: aMessage  forKey: @"Message"]);
	      PERFORM_SELECTOR_2(_delegate, @selector(messagePrefetchCompleted:), PantomimeMessagePrefetchCompleted, aMessage, @"Message");
	    }
	  break;
	}
      //
      //
      //
      else if ([aWord caseInsensitiveCompare: @"RFC822"] == NSOrderedSame)
	{
	  [[_currentQueueObject->info objectForKey: @"NSData"] replaceCRLFWithLF];
	  [aMessage setRawSource: [_currentQueueObject->info objectForKey: @"NSData"]];
	  POST_NOTIFICATION(PantomimeMessageFetchCompleted, self, [NSDictionary dictionaryWithObject: aMessage  forKey: @"Message"]);
	  PERFORM_SELECTOR_2(_delegate, @selector(messageFetchCompleted:), PantomimeMessageFetchCompleted, aMessage, @"Message");
	  break;
	}

      i = j;
      done = ![aScanner scanUpToCharactersFromSet: aCharacterSet  intoString: NULL];

      if (done && must_flush_record)
	{
	  [(CWIMAPCacheManager *)[_selectedFolder cacheManager] writeRecord: &r  message: aMessage];
	}
    }
 

  RELEASE(aScanner);
  RELEASE(aMutableString);

  //
  // It is important that we remove the responses we have processed. This is particularly
  // useful if we are caching an IMAP mailbox. We could receive thousands of untagged
  // FETCH responses and we don't want to go over them again and again everytime
  // this method is invoked.
  //
  [_responsesFromServer removeObjectsInArray: aMutableArray];
  RELEASE(aMutableArray);
}


//
// This command parses the result of a LIST command. See 7.2.2 for the complete
// description of the LIST response.
//
// Rationale:
//
// In IMAP, all mailboxes can hold messages and folders. Thus, the HOLDS_MESSAGES
// flag is ALWAYS set for a mailbox that has been parsed.
//
// We also support RFC3348 \HasChildren and \HasNoChildren flags. In fact, we
// directly map \HasChildren to HOLDS_FOLDERS.
//
// We support the following standard flags (from RFC3501):
//
//      \Noinferiors
//         It is not possible for any child levels of hierarchy to exist
//         under this name; no child levels exist now and none can be
//         created in the future.
//
//      \Noselect
//         It is not possible to use this name as a selectable mailbox.
//
//      \Marked
//         The mailbox has been marked "interesting" by the server; the
//         mailbox probably contains messages that have been added since
//         the last time the mailbox was selected.
//
//      \Unmarked
//         The mailbox does not contain any additional messages since the
//         last time the mailbox was selected.
//
- (void) _parseLIST
{
  NSString *aFolderName, *aString, *theString;
  NSRange r1, r2;
  int flags;
  NSUInteger len;

  theString = [[_responsesFromServer lastObject] asciiString];

  //
  // We verify if we got the number of bytes to read instead of the real mailbox name.
  // That happens if we couldn't get the ASCII string of what we read.
  //
  // Some servers seem to send that when the mailbox name is 8-bit. Those 8-bit mailbox
  // names were undefined in earlier versions of the IMAP protocol (now deprecated).
  // See section 5.1. (Mailbox Naming) of RFC3051.
  //
  // The RFC says we SHOULD interpret that as UTF-8.
  //
  // If we got a 8-bit string, we rollback to get the previous answer in order
  // to also decode the mailbox attribute.
  //
  if (!theString)
    {
      aFolderName = AUTORELEASE([[NSString alloc] initWithData: [_responsesFromServer lastObject]  encoding: NSUTF8StringEncoding]);
      
      // We get the "previous" line which contains our mailbox attributes
      theString = [[_responsesFromServer objectAtIndex: [_responsesFromServer count]-2] asciiString];
    }
  else
    {
      // We get the folder name and the mailbox name attributes
      aFolderName = [self _folderNameFromString: theString];
    }

  //
  // If the folder name starts/ends with {}, that means it was "wrongly" encoded using
  // 8-bit characters which are not allowed. We just return since we'll re-enter in
  // _parseLIST whenever the real mailbox name will be read.
  //
  len = [aFolderName length];
  if (len > 0 && [aFolderName characterAtIndex: 0] == '{' && [aFolderName characterAtIndex: len-1] == '}')
    {
      return;
    }

  // We try to get our name attributes.
  r1 = [theString rangeOfString: @"("];

  if (r1.location == NSNotFound)
    {
      return;
    }
 
  r2 = [theString rangeOfString: @")"  options: 0  range: NSMakeRange(r1.location+1, [theString length]-r1.location-1)];

  if (r2.location == NSNotFound)
    {
      return;
    }

  aString = [theString substringWithRange: NSMakeRange(r1.location+1, r2.location-r1.location-1)];

  // We get all the supported flags, starting with the flags of RFC3348
  flags = PantomimeHoldsMessages;

  if ([aString length])
    {
      if ([aString rangeOfString: @"\\HasChildren" options: NSCaseInsensitiveSearch].length)
	{
	  flags = flags|PantomimeHoldsFolders;
	}
      
      if ([aString rangeOfString: @"\\NoInferiors" options: NSCaseInsensitiveSearch].length)
	{
	  flags = flags|PantomimeNoInferiors;
	}

      if ([aString rangeOfString: @"\\NoSelect" options: NSCaseInsensitiveSearch].length)
	{
	  flags = flags|PantomimeNoSelect;
	}

      if ([aString rangeOfString: @"\\Marked" options: NSCaseInsensitiveSearch].length)
	{
	  flags = flags|PantomimeMarked;
	}
      
      if ([aString rangeOfString: @"\\Unmarked" options: NSCaseInsensitiveSearch].length)
	{
	  flags = flags|PantomimeUnmarked;
	}
    }

  [_folders setObject: [NSNumber numberWithInt: flags]  forKey: aFolderName];
}


//
//
//
- (void) _parseLSUB
{
  NSString *aString, *aFolderName;
  NSUInteger len;

  aString = [[NSString alloc] initWithData: [_responsesFromServer lastObject]  encoding: defaultCStringEncoding];
  
  if (!aString)
    {
      aFolderName = AUTORELEASE([[NSString alloc] initWithData: [_responsesFromServer lastObject]  encoding: NSUTF8StringEncoding]);
    }
  else
    {
      aFolderName = [self _folderNameFromString: [aString retain]];
      RELEASE(aString);
    }
  
  
  // Check the rationale in _parseLIST.
  len = [aFolderName length];
  if (len > 0 && [aFolderName characterAtIndex: 0] == '{' && [aFolderName characterAtIndex: len-1] == '}')
    {
      RELEASE(aString);
      return;
    }

  [_subscribedFolders addObject: aFolderName];
  RELEASE(aString);
}


//
//
//
- (void) _parseNO
{
  NSData *aData;

  aData = [_responsesFromServer lastObject];
  
  //NSLog(@"IN _parseNO: |%@| %d", [aData asciiString], _lastCommand);
  
  switch (_lastCommand)
    {
    case IMAP_APPEND:
      POST_NOTIFICATION(PantomimeFolderAppendFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_3(_delegate, @selector(folderAppendFailed:), PantomimeFolderAppendFailed, _currentQueueObject->info);
      break;

    case IMAP_AUTHENTICATE_CRAM_MD5:
    case IMAP_AUTHENTICATE_LOGIN:
    case IMAP_LOGIN:
      AUTHENTICATION_FAILED(_delegate, _mechanism);
      break;

    case IMAP_CREATE:
      POST_NOTIFICATION(PantomimeFolderCreateFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_1(_delegate, @selector(folderCreateFailed:), PantomimeFolderCreateFailed);
      break;

    case IMAP_DELETE:
      POST_NOTIFICATION(PantomimeFolderDeleteFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_1(_delegate, @selector(folderDeleteFailed:), PantomimeFolderDeleteFailed);
      break;

    case IMAP_EXPUNGE:
      POST_NOTIFICATION(PantomimeFolderExpungeFailed, self, _currentQueueObject->info);      
      PERFORM_SELECTOR_2(_delegate, @selector(folderExpungeFailed:), PantomimeFolderExpungeFailed, _selectedFolder, @"Folder");
      break;

    case IMAP_RENAME:
      POST_NOTIFICATION(PantomimeFolderRenameFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_1(_delegate, @selector(folderRenameFailed:), PantomimeFolderRenameFailed);
      break;

    case IMAP_SELECT:
      _connection_state.opening_mailbox = NO;
      POST_NOTIFICATION(PantomimeFolderOpenFailed, self, [NSDictionary dictionaryWithObject: _selectedFolder  forKey: @"Folder"]);
      PERFORM_SELECTOR_2(_delegate, @selector(folderOpenFailed:), PantomimeFolderOpenFailed, _selectedFolder, @"Folder");
      [_openFolders removeObjectForKey: [_selectedFolder name]];
      _selectedFolder = nil;
      break;

    case IMAP_SUBSCRIBE:
      POST_NOTIFICATION(PantomimeFolderSubscribeFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_2(_delegate, @selector(folderSubscribeFailed:), PantomimeFolderSubscribeFailed, [_currentQueueObject->info objectForKey: @"Name"], @"Name");
      break;
      
    case IMAP_UID_COPY:
      POST_NOTIFICATION(PantomimeMessagesCopyFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_3(_delegate, @selector(messagesCopyFailed:), PantomimeMessagesCopyFailed, _currentQueueObject->info);  
      break;

    case IMAP_UID_SEARCH_ALL:
      POST_NOTIFICATION(PantomimeFolderSearchFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_1(_delegate, @selector(folderSearchFailed:), PantomimeFolderSearchFailed);
      break;

    case IMAP_STATUS:
      POST_NOTIFICATION(PantomimeFolderStatusFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_2(_delegate, @selector(folderStatusFailed:), PantomimeFolderStatusFailed, [_currentQueueObject->info objectForKey: @"Name"], @"Name");
      break;

    case IMAP_UID_STORE:
      POST_NOTIFICATION(PantomimeMessageStoreFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_3(_delegate, @selector(messageStoreFailed:), PantomimeMessageStoreFailed, _currentQueueObject->info);
      break;
	
    case IMAP_UNSUBSCRIBE:
      POST_NOTIFICATION(PantomimeFolderUnsubscribeFailed, self, _currentQueueObject->info);
      PERFORM_SELECTOR_2(_delegate, @selector(folderUnsubscribeFailed:), PantomimeFolderUnsubscribeFailed, [_currentQueueObject->info objectForKey: @"Name"], @"Name");
      break;

    default:
      break;
    }

  //
  // If the NO response is tagged response, we remove the current
  // queued object from the queue since it reached completion.
  //
  if (![aData hasCPrefix: "*"])//|| _lastCommand == IMAP_AUTHORIZATION)
    {
      //NSLog(@"REMOVING QUEUE OBJECT");
      
      [_currentQueueObject->info setObject: [NSNumber numberWithUnsignedInt: _lastCommand]  forKey: @"Command"];
      POST_NOTIFICATION(@"PantomimeCommandCompleted", self, _currentQueueObject->info);
      PERFORM_SELECTOR_3(_delegate, @selector(commandCompleted:), @"PantomimeCommandCompleted", _currentQueueObject->info);
      
      [_queue removeLastObject];
      [self sendCommand: IMAP_EMPTY_QUEUE  info: nil  arguments: @""];
    }

  [_responsesFromServer removeAllObjects];
}


//
// After sending a NOOP to the IMAP server, we might read untagged
// responses like * 5 RECENT that will eventually be processed.
//
- (void) _parseNOOP
{
  //NSLog(@"Parsing noop responses...");
  // FIXME
}


//
//
//
- (void) _parseOK
{
  NSData *aData;

  aData = [_responsesFromServer lastObject];
  
  //NSLog(@"IN _parseOK: |%@|", [aData asciiString]);

  switch (_lastCommand)
    {
    case IMAP_APPEND:
      //
      // No need to do add the newly append messages to our internal messages holder as
      // we will get an untagged * EXISTS response that will trigger the new FETCH
      // RFC3501 says:
      //
      // If the mailbox is currently selected, the normal new message
      // actions SHOULD occur.  Specifically, the server SHOULD notify the
      // client immediately via an untagged EXISTS response.  If the server
      // does not do so, the client MAY issue a NOOP command (or failing
      // that, a CHECK command) after one or more APPEND commands.
      //
      POST_NOTIFICATION(PantomimeFolderAppendCompleted, self, _currentQueueObject->info);
      PERFORM_SELECTOR_3(_delegate, @selector(folderAppendCompleted:), PantomimeFolderAppendCompleted, _currentQueueObject->info);
      break;

    case IMAP_AUTHENTICATE_CRAM_MD5:
    case IMAP_AUTHENTICATE_LOGIN:
    case IMAP_LOGIN:
      if (_connection_state.reconnecting)
	{
	  if (_selectedFolder)
	    {
	        if ([_selectedFolder mode] == PantomimeReadOnlyMode)
		  {
		    [self sendCommand: IMAP_EXAMINE  info: nil  arguments: @"EXAMINE \"%@\"", [[_selectedFolder name] modifiedUTF7String]];
		  }
		else
		  {
		    [self sendCommand: IMAP_SELECT  info: nil  arguments: @"SELECT \"%@\"", [[_selectedFolder name] modifiedUTF7String]];
		  }
		
		if (_connection_state.opening_mailbox) [_selectedFolder prefetch];
	    }
	  else
	    {
	      [self _restoreQueue];
	    }
	}
      else
	{
	  AUTHENTICATION_COMPLETED(_delegate, _mechanism);
	}
      break;
   
    case IMAP_AUTHORIZATION:
      if ([aData hasCPrefix: "* OK"])
	{
	  [self sendCommand: IMAP_CAPABILITY  info: nil  arguments: @"CAPABILITY"];
	}
      else
	{
	  // FIXME
	  // connectionLost? or should we call [self close]?
	}
      break;
      
    case IMAP_CLOSE:
      POST_NOTIFICATION(PantomimeFolderCloseCompleted, self, _currentQueueObject->info);
      PERFORM_SELECTOR_3(_delegate, @selector(folderCloseCompleted:), PantomimeFolderCloseCompleted, _currentQueueObject->info);
      break;

    case IMAP_CREATE:
      [_folders setObject: [NSNumber numberWithInt: 0]  forKey: [_currentQueueObject->info objectForKey: @"Name"]];
      POST_NOTIFICATION(PantomimeFolderCreateCompleted, self, _currentQueueObject->info);
      PERFORM_SELECTOR_1(_delegate, @selector(folderCreateCompleted:), PantomimeFolderCreateCompleted);
      break;

    case IMAP_DELETE:
      [_folders removeObjectForKey: [_currentQueueObject->info objectForKey: @"Name"]];
      POST_NOTIFICATION(PantomimeFolderDeleteCompleted, self, _currentQueueObject->info);
      PERFORM_SELECTOR_1(_delegate, @selector(folderDeleteCompleted:), PantomimeFolderDeleteCompleted);
      break;

    case IMAP_EXPUNGE:
      //
      // No need to synchronize our IMAP cache here since, at worst, the
      // expunged messages will get removed once we reopen the mailbox.
      //
      if ([_selectedFolder allContainers])
	{
	  [_selectedFolder thread];
	}

      if ([_selectedFolder cacheManager])
	{
	  [[_selectedFolder cacheManager] expunge];
	}
      POST_NOTIFICATION(PantomimeFolderExpungeCompleted, self, _currentQueueObject->info);      
      PERFORM_SELECTOR_2(_delegate, @selector(folderExpungeCompleted:), PantomimeFolderExpungeCompleted, _selectedFolder, @"Folder");
      break;

    case IMAP_LIST:
      POST_NOTIFICATION(PantomimeFolderListCompleted, self, [NSDictionary dictionaryWithObject: [_folders keyEnumerator] forKey: @"NSEnumerator"]);
      PERFORM_SELECTOR_2(_delegate, @selector(folderListCompleted:), PantomimeFolderListCompleted, [_folders keyEnumerator], @"NSEnumerator");
      break;

    case IMAP_LOGOUT:
      // FIXME: What should we do here?
      [super close];
      break;

    case IMAP_LSUB:
      POST_NOTIFICATION(PantomimeFolderListSubscribedCompleted, self, [NSDictionary dictionaryWithObject: [_subscribedFolders objectEnumerator] forKey: @"NSEnumerator"]);
      PERFORM_SELECTOR_2(_delegate, @selector(folderListSubscribedCompleted:), PantomimeFolderListSubscribedCompleted, [_subscribedFolders objectEnumerator], @"NSEnumerator");
      break;

    case IMAP_RENAME:
      [self _renameFolder];
      POST_NOTIFICATION(PantomimeFolderRenameCompleted, self, _currentQueueObject->info);
      PERFORM_SELECTOR_1(_delegate, @selector(folderRenameCompleted:), PantomimeFolderRenameCompleted);
      break;

    case IMAP_SELECT:
      [self _parseSELECT];
      break;

    case IMAP_STARTTLS:
      [self _parseSTARTTLS];
      break;

    case IMAP_SUBSCRIBE:
      // We must add the folder to our list of subscribed folders.
      [_subscribedFolders addObject: [_currentQueueObject->info objectForKey: @"Name"]];
      POST_NOTIFICATION(PantomimeFolderSubscribeCompleted, self, _currentQueueObject->info);
      PERFORM_SELECTOR_2(_delegate, @selector(folderSubscribeCompleted:), PantomimeFolderSubscribeCompleted, [_currentQueueObject->info objectForKey: @"Name"], @"Name");
      break;

    case IMAP_UID_COPY:
      POST_NOTIFICATION(PantomimeMessagesCopyCompleted, self, _currentQueueObject->info);
      PERFORM_SELECTOR_3(_delegate, @selector(messagesCopyCompleted:), PantomimeMessagesCopyCompleted, _currentQueueObject->info);
      break;

    case IMAP_UID_FETCH_HEADER_FIELDS:
      {
	_connection_state.opening_mailbox = NO;

	if ([_selectedFolder cacheManager])
	  {
	    [[_selectedFolder cacheManager] synchronize];
	  }
	
	//NSLog(@"DONE PREFETCHING FOLDER");
	POST_NOTIFICATION(PantomimeFolderPrefetchCompleted, self, [NSDictionary dictionaryWithObject: _selectedFolder  forKey: @"Folder"]);
	PERFORM_SELECTOR_2(_delegate, @selector(folderPrefetchCompleted:), PantomimeFolderPrefetchCompleted, _selectedFolder, @"Folder");
      }
      break;

    case IMAP_UID_SEARCH_ALL:
      //
      // Before assuming we got a result and initialized everything in _parseSEARCH,
      // we do a basic check. This is to prevent a rather weird behavior from
      // UW IMAP Server, like this:
      //
      // . UID SEARCH ALL FROM "collaboration-world"
      // * OK [PARSE] Unexpected characters at end of address: <>, Aix.p4@itii-paca.net...
      // * SEARCH
      // 000d OK UID SEARCH completed^
      //
      if ([_currentQueueObject->info objectForKey: @"Results"])
	{
	  NSDictionary *userInfo;

	  userInfo = [NSDictionary dictionaryWithObjectsAndKeys: _selectedFolder, @"Folder", [_currentQueueObject->info objectForKey: @"Results"], @"Results", nil];
	  POST_NOTIFICATION(PantomimeFolderSearchCompleted, self, userInfo);
	  PERFORM_SELECTOR_3(_delegate, @selector(folderSearchCompleted:), PantomimeFolderSearchCompleted, userInfo);
	}
      break;

    case IMAP_UID_STORE:
      {
	// Once the STORE has completed, we update the messages.
	NSArray *theMessages;
	CWFlags *theFlags;
	NSUInteger i, count;
	
	theMessages = [_currentQueueObject->info objectForKey: @"Messages"];
	theFlags = [_currentQueueObject->info objectForKey: @"Flags"];
	count = [theMessages count];

	for (i = 0; i < count; i++)
	  {
	    [[[theMessages objectAtIndex: i] flags] replaceWithFlags: theFlags];
	  }

	POST_NOTIFICATION(PantomimeMessageStoreCompleted, self, _currentQueueObject->info);
	PERFORM_SELECTOR_3(_delegate, @selector(messageStoreCompleted:), PantomimeMessageStoreCompleted, _currentQueueObject->info);
      }
      break;
      
    case IMAP_UNSUBSCRIBE:
      // We must remove the folder from our list of subscribed folders.
      [_subscribedFolders removeObject: [_currentQueueObject->info objectForKey: @"Name"]];
      POST_NOTIFICATION(PantomimeFolderUnsubscribeCompleted, self, _currentQueueObject->info);
      PERFORM_SELECTOR_2(_delegate, @selector(folderUnsubscribeCompleted:), PantomimeFolderUnsubscribeCompleted, [_currentQueueObject->info objectForKey: @"Name"], @"Name");
      break;

    default:
      break;
    }

  //
  // If the OK response is tagged response, we remove the current
  // queued object from the queue since it reached completion.
  //
  if (![aData hasCPrefix: "*"])// || _lastCommand == IMAP_AUTHORIZATION)
    {
      //NSLog(@"REMOVING QUEUE OBJECT");      
      [_currentQueueObject->info setObject: [NSNumber numberWithUnsignedInt: _lastCommand]  forKey: @"Command"];
      POST_NOTIFICATION(@"PantomimeCommandCompleted", self, _currentQueueObject->info);
      PERFORM_SELECTOR_3(_delegate, @selector(commandCompleted:), @"PantomimeCommandCompleted", _currentQueueObject->info);
      
      [_queue removeLastObject];
      [self sendCommand: IMAP_EMPTY_QUEUE  info: nil  arguments: @""];
    }

  [_responsesFromServer removeAllObjects];
}


//
// This method receives a * 5 RECENT parameter and parses it.
//
- (void) _parseRECENT
{
  // Do nothing for now. This breaks 7.3.2 since the response
  // is not recorded.
}


//
//
//
- (void) _parseSEARCH
{
  NSMutableArray *aMutableArray;
  CWIMAPMessage *aMessage;
  NSArray *allResults;
  NSUInteger i, count;
  
  allResults = [self _uniqueIdentifiersFromData: [_responsesFromServer lastObject]];
  count = [allResults count];
  
  aMutableArray = [NSMutableArray array];
  
     
  for (i = 0; i < count; i++)
    {
      aMessage = [(CWIMAPCacheManager *)[_selectedFolder cacheManager] messageWithUID:
		[(NSNumber *)[allResults objectAtIndex: i] unsignedIntValue]];
      
      if (aMessage)
	{
	  [aMutableArray addObject: aMessage];
	}
      else
	{
	  //NSLog(@"Message with UID = %u not found in cache.",
	  //	[[allResults objectAtIndex: i] unsignedIntValue]);
	}
    }

  // We store the results in our command queue (ie., in the current queue object).
  // aMutableArray may be empty if no result was found
  if (_currentQueueObject)
    [_currentQueueObject->info setObject: aMutableArray  forKey: @"Results"];
}


//
// This methods updates all FLAGS and MSNs for messages in the cache.
//
// It also purges the messages that have been deleted on the IMAP server
// but that are still present in the folder cache.
// 
// Nota bene: We can safely assume our cacheManager exists since this method
//            wouldn't otherwise have been invoked.
//
//
- (void) _parseSEARCH_CACHE
{
  CWIMAPMessage *aMessage;
  NSArray *allResults;
  NSUInteger i, count;
  BOOL b;

  allResults = [self _uniqueIdentifiersFromData: [_responsesFromServer objectAtIndex: 0]];
  count = [allResults count];
  
  switch (_lastCommand)
    {
    case IMAP_UID_SEARCH:
      //
      // We can now read our SEARCH results from our IMAP store. The result contains
      // all MSN->UID mappings. New messages weren't added to the search result as
      // we couldn't find them in IMAPStore: -_parseSearch:.
      //
      for (i = 0; i < count; i++)
	{
	  aMessage = [(CWIMAPCacheManager *)[_selectedFolder cacheManager] messageWithUID: [(NSNumber *)[allResults objectAtIndex: i] unsignedIntValue]];
	  
	  if (aMessage)
	    {
	      [aMessage setFolder: _selectedFolder];
	      [aMessage setMessageNumber: (i+1)];
	    }
	}
      
      //
      // We purge our cache from all deleted messages and we keep the
      // good ones to our folder.
      //
      //for (i = ([theCache count]-1); i >= 0; i--)
      //NSLog(@"Folder count (to remove UID) = %d", [_selectedFolder->allMessages count]);
      b = NO;

      for (i = ([_selectedFolder->allMessages count]); i > 0; i--)
	{   
	  aMessage = [_selectedFolder->allMessages objectAtIndex: i-1];
	  //aMessage = [theCache objectAtIndex: i];
      
	  if ([aMessage folder] == nil)
	    {
	      [(CWIMAPCacheManager *)[_selectedFolder cacheManager] removeMessageWithUID: [aMessage UID]];
	      //NSLog(@"Removed message |%@| UID = %d", [aMessage subject], [aMessage UID]);
	      [_selectedFolder->allMessages removeObject: aMessage];
	      b = YES;
	    }
	  
	}
      
      // We check to see if we must expunge deleted messages from our cache.
      // It's important to do this here. Otherwise, calling -synchronize on
      // our cache manager could lead to offset problems as the number of
      // records in our cache would be greater than the amount of entries
      // in our _selectedFolder->allMessages ivar.
      if (b && [_selectedFolder cacheManager])
	{
	  [[_selectedFolder cacheManager] expunge];
	}

      [_selectedFolder updateCache];
      [self sendCommand: IMAP_UID_SEARCH_ANSWERED  info: nil  arguments: @"UID SEARCH ANSWERED"];
      break;

    case IMAP_UID_SEARCH_ANSWERED:
      //
      // We now update our \Answered flag, for all messages.
      //     
      for (i = 0; i < count; i++)
	{
	  [[[(CWIMAPCacheManager *)[_selectedFolder cacheManager] messageWithUID: [[allResults objectAtIndex: i] unsignedIntValue]] flags] add: PantomimeAnswered];
	}
      [self sendCommand: IMAP_UID_SEARCH_FLAGGED  info: nil  arguments: @"UID SEARCH FLAGGED"];
      break;

    case IMAP_UID_SEARCH_FLAGGED:
      //
      // We now update our \Flagged flag, for all messages.
      //     
      for (i = 0; i < count; i++)
	{
	  [[[(CWIMAPCacheManager *)[_selectedFolder cacheManager] messageWithUID: [[allResults objectAtIndex: i] unsignedIntValue]] flags] add: PantomimeFlagged];
	}
      [self sendCommand: IMAP_UID_SEARCH_UNSEEN  info: nil  arguments: @"UID SEARCH UNSEEN"];
      break;

    case IMAP_UID_SEARCH_UNSEEN:
      //
      // We now update our \Seen flag, for all messages.
      //
      for (i = 0; i < count; i++)
	{
	  //NSLog(@"removing for UID %d", [[allResults objectAtIndex: i] unsignedIntValue]);
	  [[[(CWIMAPCacheManager *)[_selectedFolder cacheManager] messageWithUID: [[allResults objectAtIndex: i] unsignedIntValue]] flags] remove: PantomimeSeen];
	}
      
      //
      // We obtain the last UID of our cache.
      // Messages will be fetched starting from that UID + 1.
      //
      //NSLog(@"LAST UID IN CACHE: %u", [[_selectedFolder->allMessages lastObject] UID]);
      [self sendCommand: IMAP_UID_FETCH_HEADER_FIELDS  info: nil  arguments: @"UID FETCH %u:* (UID FLAGS RFC822.SIZE BODY.PEEK[HEADER.FIELDS (From To Cc Subject Date Message-ID References In-Reply-To)])", ([[_selectedFolder->allMessages lastObject] UID]+1)];
      break;

    default:
      //NSLog(@"Unknown command for updating the cache file. Ignored.");
      break;
    }
}


//
//
//
- (void) _parseSELECT
{
  NSData *aData;
  NSUInteger i, count;

  // The last object in _responsesFromServer is a tagged OK response.
  // We need to parse it here.
  count = [_responsesFromServer count];

  for (i = 0; i < count; i++)
    {
      aData = [[_responsesFromServer objectAtIndex: i] dataByTrimmingWhiteSpaces];
     
      //NSLog(@"|%@|", [aData asciiString]);
      // * OK [UIDVALIDITY 1052146864] 
      if ([aData hasCPrefix: "* OK [UIDVALIDITY"] && [aData hasCSuffix: "]"])
	{
	  [self _parseUIDVALIDITY: [aData cString]];
	}
      
      // 3c4d OK [READ-ONLY] Completed
      if ([aData rangeOfCString: "OK [READ-ONLY]"].length)
	{
	  [_selectedFolder setMode: PantomimeReadOnlyMode];
	}

      // 1a2b OK [READ-WRITE] Completed
      if ([aData rangeOfCString: "OK [READ-WRITE]"].length)
	{
	  [_selectedFolder setMode: PantomimeReadWriteMode];
	}
    }

  if (_connection_state.reconnecting)
    {
      [self _restoreQueue];
    }
  else
    {
      [_selectedFolder setSelected: YES];
      POST_NOTIFICATION(PantomimeFolderOpenCompleted, self, [NSDictionary dictionaryWithObject: _selectedFolder  forKey: @"Folder"]);
      PERFORM_SELECTOR_2(_delegate, @selector(folderOpenCompleted:), PantomimeFolderOpenCompleted, _selectedFolder, @"Folder");
    }
}


//
//
//
- (void) _parseSTARTTLS
{
  [(CWTCPConnection *)_connection startSSL];
  POST_NOTIFICATION(PantomimeServiceInitialized, self, nil);
  PERFORM_SELECTOR_1(_delegate, @selector(serviceInitialized:),  PantomimeServiceInitialized);
}

//
//
// This method receives a * STATUS blurdybloop (MESSAGES 231 UIDNEXT 44292)
// parameter and parses it. It then put the decoded values in the
// folderStatus dictionary.
//
//
- (void) _parseSTATUS
{
  CWFolderInformation *aFolderInformation;
  NSString *aFolderName;
  NSDictionary *info;
  NSData *aData;

  NSRange aRange;
  unsigned messages, unseen;

  aData = [_responsesFromServer lastObject];
  
  aRange = [aData rangeOfCString: "("  options: NSBackwardsSearch];
  aFolderName = [[[aData subdataToIndex: (aRange.location-1)] subdataFromIndex: 9] asciiString];
  
  sscanf([[aData subdataFromIndex: aRange.location] cString], "(MESSAGES %u UNSEEN %u)", &messages, &unseen);
  
  aFolderInformation = [[CWFolderInformation alloc] init];
  [aFolderInformation setNbOfMessages: messages];
  [aFolderInformation setNbOfUnreadMessages: unseen];
  
  // Before putting the folder in our dictionary, we unquote it.
  aFolderName = [aFolderName stringFromQuotedString];
  [_folderStatus setObject: aFolderInformation  forKey: aFolderName];
  
  info = [NSDictionary dictionaryWithObjectsAndKeys: aFolderInformation, @"FolderInformation", aFolderName, @"FolderName", nil];  
  POST_NOTIFICATION(PantomimeFolderStatusCompleted, self, info);

  if (_delegate && [_delegate respondsToSelector: @selector(folderStatusCompleted:)]) 
    {
      [_delegate performSelector: @selector(folderStatusCompleted:)
		 withObject: [NSNotification notificationWithName: PantomimeFolderStatusCompleted
					     object: self
					     userInfo: info]];
    }
  
  RELEASE(aFolderInformation);
}


//
// Example: * OK [UIDVALIDITY 948394385]
//
- (void) _parseUIDVALIDITY: (const char *) theString
{
  unsigned int n;
  sscanf(theString, "* OK [UIDVALIDITY %u]", &n);
  [_selectedFolder setUIDValidity: n];
}


//
//
//
- (void) _restoreQueue
{
  // We restore our list of pending commands
  [_queue addObjectsFromArray: _connection_state.previous_queue];
  
  // We clean the state
  [_connection_state.previous_queue removeAllObjects];
  _connection_state.reconnecting = NO;

  POST_NOTIFICATION(PantomimeServiceReconnected, self, nil);
  PERFORM_SELECTOR_1(_delegate, @selector(serviceReconnected:), PantomimeServiceReconnected);
}

@end
