/*
**  CWIMAPFolder.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2020      Riccardo Mottola
**
**  Authors: Ludovic Marcotte <ludovic@Sophos.ca>
**           Riccardo Mottola
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

#import <Pantomime/CWIMAPFolder.h>

#import <Pantomime/CWConnection.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/CWFlags.h>
#import <Pantomime/CWIMAPCacheManager.h>
#import <Pantomime/CWIMAPStore.h>
#import <Pantomime/CWIMAPMessage.h>
#import <Pantomime/CWTCPConnection.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/NSString+Extensions.h>

//
// Private methods
//
@interface CWIMAPFolder (Private)
- (NSString *) _flagsAsStringFromFlags: (CWFlags *) theFlags;
- (NSData *) _removeInvalidHeadersFromMessage: (NSData *) theMessage;
@end


//
//
//
@implementation CWIMAPFolder

- (id) initWithName: (NSString *) theName
{
  self = [super initWithName: theName];
  if (self)
    {
      [self setSelected: NO];
    }
  return self;
}


//
//
//
- (id) initWithName: (NSString *) theName
               mode: (PantomimeFolderMode) theMode
{
  self = [self initWithName: theName];
  if (self)
    {
      _mode = theMode;
    }
  return self;
}


//
//
//
- (void) appendMessageFromRawSource: (NSData *) theData
                              flags: (CWFlags *) theFlags
{
  [self appendMessageFromRawSource: theData
	flags: theFlags
	internalDate: nil];
}

//
//
//
- (void) appendMessageFromRawSource: (NSData *) theData
                              flags: (CWFlags *) theFlags
		       internalDate: (NSCalendarDate *) theDate
{
  NSDictionary *aDictionary;
  NSString *flagsAsString;
  NSData *aData;
 
  if (theFlags)
    {
      flagsAsString = [self _flagsAsStringFromFlags: theFlags];
    }
  else
    {
      flagsAsString = @"";
    }
  
  // We remove any invalid headers from our message
  aData = [self _removeInvalidHeadersFromMessage: theData];
  
  if (theFlags)
    {
      aDictionary = [NSDictionary dictionaryWithObjectsAndKeys: aData, @"NSDataToAppend", theData, @"NSData", self, @"Folder", theFlags, @"Flags", nil];
    }
  else
    {
      aDictionary = [NSDictionary dictionaryWithObjectsAndKeys: aData, @"NSDataToAppend", theData, @"NSData", self, @"Folder", nil];
    }

  
  if (theDate)
    {
      [_store sendCommand: IMAP_APPEND
	      info: aDictionary
	      arguments: @"APPEND \"%@\" (%@) \"%@\" {%d}",                    // IMAP command
	      [_name modifiedUTF7String],                                      // folder name
	      flagsAsString,                                                   // flags
	      [theDate descriptionWithCalendarFormat:@"%d-%b-%Y %H:%M:%S %z"], // internal date
	      [aData length]];                                                 // length of the data to write
    }
  else
    {
      [_store sendCommand: IMAP_APPEND
	      info: aDictionary
	      arguments: @"APPEND \"%@\" (%@) {%d}",  // IMAP command
	      [_name modifiedUTF7String],             // folder name
	      flagsAsString,                          // flags
	      [aData length]];                        // length of the data to write
    }
}

//
//
//
- (void) copyMessages: (NSArray *) theMessages
	     toFolder: (NSString *) theFolder
{
  NSMutableString *aMutableString;
  NSUInteger i, count;

  // We create our message's UID set
  aMutableString = [[NSMutableString alloc] init];
  count = [theMessages count];

  for (i = 0; i < count; i++)
    {
      if (i == count-1)
	{
	  [aMutableString appendFormat: @"%lu", 
		(unsigned long)[[theMessages objectAtIndex: i] UID]];
	}
      else
	{
	  [aMutableString appendFormat: @"%lu,",
		(unsigned long)[[theMessages objectAtIndex: i] UID]];
	}
    }
 
  // We send our IMAP command
  [_store sendCommand: IMAP_UID_COPY
	  info: [NSDictionary dictionaryWithObjectsAndKeys: theMessages, @"Messages", theFolder, @"Name", self, @"Folder", nil]
	  arguments: @"UID COPY %@ \"%@\"",
	  aMutableString,
	  [theFolder modifiedUTF7String]];
 
  RELEASE(aMutableString);
}


//
//
//
- (void) prefetch
{
  // We first update the messages in our cache, if we need to.
  if (_cacheManager && [self count])
    {
      [_store sendCommand: IMAP_UID_SEARCH  info: nil  arguments: @"UID SEARCH 1:*"];
    }
  else
    {
      //
      // We must send this command since our IMAP cache might be empty (or have been removed).
      // In that case, we much fetch again all messages, starting at UID 1.
      //
      [_store sendCommand: IMAP_UID_FETCH_HEADER_FIELDS  info: nil  arguments: @"UID FETCH %u:* (UID FLAGS RFC822.SIZE BODY.PEEK[HEADER.FIELDS (From To Cc Subject Date Message-ID References In-Reply-To)])", 1];
    }
}


//
// This method simply close the selected mailbox (ie. folder)
//
- (void) close
{
  IMAPCommand theCommand;

  if (![self selected])
    {
      [_store removeFolderFromOpenFolders: self];
      return;
    }

  // If we are opening a mailbox but -close was called before we
  // finished opening it, we close the connection immediately.
  theCommand = [[self store] lastCommand];

  if (theCommand == IMAP_SELECT || theCommand == IMAP_UID_SEARCH || theCommand == IMAP_UID_SEARCH_ANSWERED ||
      theCommand == IMAP_UID_SEARCH_FLAGGED || theCommand == IMAP_UID_SEARCH_UNSEEN)
    {
      [_store removeFolderFromOpenFolders: self];
      [[self store] cancelRequest];
      [[self store] reconnect];
      return;
    }

  if (_cacheManager)
    {
      [_cacheManager synchronize];
    }

  // We set the _folder ivar to nil for all messages. This is required in case
  // an IMAPMessage instance was retained and we invoke -setFlags: on it, which
  // will try to access the _folder ivar in order to communicate with the IMAP server.
  [allMessages makeObjectsPerformSelector: @selector(setFolder:)  withObject: nil];

  // We close the selected IMAP folder to _expunge_ messages marked as \Deleted
  // if and only we are NOT showing DELETED messages. We also don't send the command
  // if we are NOT connected since a MUA using Pantomime needs to call -close
  // on IMAPFolder to clean-up the "open" folder.
  if ([_store isConnected] && ![self showDeleted])
    {
      [_store sendCommand: IMAP_CLOSE
	      info: [NSDictionary dictionaryWithObject: self  forKey: @"Folder"]
	      arguments: @"CLOSE"];
    }
  else
    {
      PERFORM_SELECTOR_2([_store delegate], @selector(folderCloseCompleted:), PantomimeFolderCloseCompleted, self, @"Folder");
      POST_NOTIFICATION(PantomimeFolderCloseCompleted, _store, [NSDictionary dictionaryWithObject: self  forKey: @"Folder"]);
    }

  [_store removeFolderFromOpenFolders: self];
}


//
// This method returns all messages that have the flag PantomimeDeleted.
//
- (void) expunge
{
  //
  // We send our EXPUNGE command. The responses will be processed in IMAPStore and
  // the MSN will be updated in IMAPStore: -_parseExpunge.
  //
  [_store sendCommand: IMAP_EXPUNGE  info: nil  arguments: @"EXPUNGE"];
}


//
//
//
- (unsigned int) UIDValidity
{
  return _uid_validity;
}


//
//
//
- (void) setUIDValidity: (unsigned int) theUIDValidity
{
  _uid_validity = theUIDValidity;
 
   if (_cacheManager)
    {
      if ([(CWIMAPCacheManager *)_cacheManager UIDValidity] == 0 || [(CWIMAPCacheManager *)_cacheManager UIDValidity] != _uid_validity)
	{
	  [_cacheManager invalidate];
	  [(CWIMAPCacheManager *)_cacheManager setUIDValidity: _uid_validity];
	}
    }
}


//
//
//
- (BOOL) selected
{
  return _selected;
}


//
//
//
- (void) setSelected: (BOOL) theBOOL
{
  _selected = theBOOL;
}

//
//
//
- (void) setFlags: (CWFlags *) theFlags
         messages: (NSArray *) theMessages
{
  NSMutableString *aMutableString, *aSequenceSet;
  CWIMAPMessage *aMessage;

  if ([theMessages count] == 1)
    {
      aMessage = [theMessages lastObject];
      // We set the flags right away, just in case someone asks for them
      // just after invoking this method. Nevertheless, they WILL be set
      // in IMAPStore: -_parseOK:.
      // We do the same below, when the count > 1
      [[aMessage flags] replaceWithFlags: theFlags];
      aSequenceSet = [NSMutableString stringWithFormat: @"%lu:%lu", 
				(unsigned long)[aMessage UID], (unsigned long)[aMessage UID]];
    }
  else
    {
      NSUInteger i, count;

      aSequenceSet = AUTORELEASE([[NSMutableString alloc] init]);
      count = [theMessages count];

      for (i = 0; i < count; i++)
	{
	  aMessage = [theMessages objectAtIndex: i];
	  [[aMessage flags] replaceWithFlags: theFlags];

	  if (aMessage == [theMessages lastObject])
	    {
	      [aSequenceSet appendFormat: @"%lu", (unsigned long)[aMessage UID]];
	    }
	  else
	    {
	      [aSequenceSet appendFormat: @"%lu,", (unsigned long)[aMessage UID]];
	    }
	}
    }
  
  aMutableString = [[NSMutableString alloc] init];
  
  //
  // If we're removing all flags, we rather send a STORE -FLAGS (<current flags>) 
  // than a STORE FLAGS (<new flags>) since some broken servers might not 
  // support it (like Cyrus v1.5.19 and v1.6.24).
  //
  if (theFlags->flags == 0)
    {
      [aMutableString appendFormat: @"UID STORE %@ -FLAGS.SILENT (", aSequenceSet];
      [aMutableString appendString: [self _flagsAsStringFromFlags: theFlags]];
      [aMutableString appendString: @")"];
    }
  else
    {
      [aMutableString appendFormat: @"UID STORE %@ FLAGS.SILENT (", aSequenceSet];
      [aMutableString appendString: [self _flagsAsStringFromFlags: theFlags]];
      [aMutableString appendString: @")"];
    }
  
  [_store sendCommand: IMAP_UID_STORE
	  info: [NSDictionary dictionaryWithObjectsAndKeys: theMessages, @"Messages", theFlags, @"Flags", nil]
	  arguments: aMutableString];
  RELEASE(aMutableString);
}



//
// Using IMAP, we ignore most parameters.
//
- (void) search: (NSString *) theString
	   mask: (PantomimeSearchMask) theMask
	options: (PantomimeSearchOption) theOptions
{
  NSString *aString;  
   
  switch (theMask)
    {
    case PantomimeFrom:
      aString = [NSString stringWithFormat: @"UID SEARCH ALL FROM \"%@\"", theString];
      break;
     
    case PantomimeTo:
      aString = [NSString stringWithFormat: @"UID SEARCH ALL TO \"%@\"", theString];
      break;

    case PantomimeContent:
      aString = [NSString stringWithFormat: @"UID SEARCH ALL BODY \"%@\"", theString];
      break;
      
    case PantomimeSubject:
    default:
      aString = [NSString stringWithFormat: @"UID SEARCH ALL SUBJECT \"%@\"", theString];
    }

  // We send our SEARCH command. Store->searchResponse will have the result.
  [_store sendCommand: IMAP_UID_SEARCH_ALL  info: [NSDictionary dictionaryWithObject: self  forKey: @"Folder"]  arguments: aString];
}

@end


//
// Private methods
// 
@implementation CWIMAPFolder (Private)

- (NSString *) _flagsAsStringFromFlags: (CWFlags *) theFlags
{
  NSMutableString *aMutableString;

  aMutableString = [[NSMutableString alloc] init];
  AUTORELEASE(aMutableString);

  if ([theFlags contain: PantomimeAnswered])
    {
      [aMutableString appendString: @"\\Answered "];
    }

  if ([theFlags contain: PantomimeDraft] )
    {
      [aMutableString appendString: @"\\Draft "];
    }

  if ([theFlags contain: PantomimeFlagged])
    {
      [aMutableString appendString: @"\\Flagged "];
    }

  if ([theFlags contain: PantomimeSeen])
    {
      [aMutableString appendString: @"\\Seen "];
    }
  
  if ([theFlags contain: PantomimeDeleted])
    {
      [aMutableString appendString: @"\\Deleted "];
    }

  return [aMutableString stringByTrimmingWhiteSpaces];
}


//
//
//
- (NSData *) _removeInvalidHeadersFromMessage: (NSData *) theMessage
{
  NSMutableData *aMutableData;
  NSArray *allLines;
  NSUInteger i, count;

  // We allocate our mutable data object
  aMutableData = [[NSMutableData alloc] initWithCapacity: [theMessage length]];
  
  // We now replace all \n by \r\n
  allLines = [theMessage componentsSeparatedByCString: "\n"];
  count = [allLines count];

  for (i = 0; i < count; i++)
    {
      NSData *aLine;

      // We get a line...
      aLine = [allLines objectAtIndex: i];

      // We skip dumb headers
      if ([aLine hasCPrefix: "From "])
	{
	  continue;
	}

      [aMutableData appendData: aLine];
      [aMutableData appendCString: "\r\n"];
    }

  return AUTORELEASE(aMutableData);
}

@end

