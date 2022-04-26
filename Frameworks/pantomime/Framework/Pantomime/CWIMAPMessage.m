/*
**  CWIMAPMessage.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
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

#import <Pantomime/CWIMAPMessage.h>
#import <Pantomime/CWParser.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/CWFlags.h>
#import <Pantomime/CWIMAPFolder.h>
#import <Pantomime/CWIMAPStore.h>

#import <Foundation/NSDebug.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>

#if defined(__APPLE__) && (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
@interface NSNumber (TigerExtensions)
+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)value;
- (NSUInteger)unsignedIntegerValue;
@end

@implementation NSNumber (TigerExtensions)
+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)value
{
  return [NSNumber numberWithUnsignedInt:(unsigned int)value];
}
- (NSUInteger)unsignedIntegerValue
{
  return (NSUInteger)[self unsignedIntValue];
}
@end
#endif


//
//
//
@implementation CWIMAPMessage 

- (id) init
{
  self = [super init];
  if (self)
    {
      _headers_were_prefetched = NO;
      _UID = 0;
    }
  return self;
}

- (id) initWithCacheRecord: (cache_record) cr
{
  self = [super init];
  if (self)
    {
      _headers_were_prefetched = NO;
      
      [self flags]->flags = cr.flags;  // FASTER and _RIGHT_ since we can't call -setFlags: on CWIMAPMessage
      [self setReceivedDate: [NSCalendarDate dateWithTimeIntervalSince1970: (NSTimeInterval)cr.date]];
      _UID = cr.imap_uid;
      _size = (unsigned long) cr.size;
      
      [CWParser parseFrom: cr.from  inMessage: self  quick: YES];
      [CWParser parseInReplyTo: cr.in_reply_to  inMessage: self  quick: YES];
      [CWParser parseMessageID: cr.message_id  inMessage: self  quick: YES];
      [CWParser parseReferences: cr.references  inMessage: self  quick: YES];
      [CWParser parseSubject: cr.subject inMessage: self  quick: YES];
      [CWParser parseDestination: cr.to
                         forType: PantomimeToRecipient
                       inMessage: self
                           quick: YES];
      [CWParser parseDestination: cr.cc
                         forType: PantomimeCcRecipient
                       inMessage: self
                           quick: YES];
    }
  return self;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *) theCoder
{
  // Must also encode Message's superclass
  [super encodeWithCoder: theCoder];
  [theCoder encodeObject: [NSNumber numberWithUnsignedInteger: _UID]];
}


//
//
//
- (id) initWithCoder: (NSCoder *) theCoder
{
  // Must also decode Message's superclass
  self = [super initWithCoder: theCoder];
  if (self)
    {
      _UID = [[theCoder decodeObject] unsignedIntegerValue];
    }
  return self;
}


//
//
//
- (NSUInteger) UID
{
  return _UID;
}

- (void) setUID: (NSUInteger) theUID
{
  _UID = theUID;
}


//
// This method is called to initialize the message if it wasn't.
// If we set it to NO and we HAD a content, we release the content.
//
- (void) setInitialized: (BOOL) theBOOL
{
  [super setInitialized: theBOOL];
  
  if (!theBOOL)
    {
      DESTROY(_content);
      return;
    }
  else if (![(CWIMAPFolder *)[self folder] selected])
    {
      [super setInitialized: NO];
      [NSException raise: PantomimeProtocolException
		   format: @"Unable to fetch message content from unselected mailbox."];
      return;
    }

  if (!_content)
    {
      id aStore;

      aStore = [(CWIMAPFolder *)[self folder] store];

      if (!_headers_were_prefetched)
	{
	  [aStore sendCommand: IMAP_UID_FETCH_HEADER_FIELDS_NOT  info: nil  arguments: @"UID FETCH %u:%u BODY.PEEK[HEADER.FIELDS.NOT (From To Cc Subject Date Message-ID References In-Reply-To)]", _UID, _UID];
	}

      // If we are no longer connected to the IMAP server, we don't send the 2nd command.
      // This will prevent us from calling the delegate method twice (the one that handles
      // the disconnection from the IMAP server).
      if ([aStore isConnected])
	{
	  [aStore sendCommand: IMAP_UID_FETCH_BODY_TEXT  info: nil  arguments: @"UID FETCH %u:%u BODY[TEXT]", _UID, _UID];
	}

      // Since we are loading asynchronously our message, it's not yet initialized. It'll be set as an initialized one
      // in CWIMAPStore once the body is fully loaded.
      [super setInitialized: NO];
    }
  
  _headers_were_prefetched = YES;
}


//
//
//
- (NSData *) rawSource
{
  if (![(CWIMAPFolder *)[self folder] selected])
    {
      [NSException raise: PantomimeProtocolException
		   format: @"Unable to fetch message data from unselected mailbox."];
      return _rawSource;
    }

  if (!_rawSource)
    {
      [(CWIMAPStore *)[[self folder] store] sendCommand: IMAP_UID_FETCH_RFC822  info: nil  arguments: @"UID FETCH %u:%u RFC822", _UID, _UID];
    }
  
  return _rawSource;
}


//
//
//
- (void) setFlags: (CWFlags *) theFlags
{
  [[self folder] setFlags: theFlags
		 messages: [NSArray arrayWithObject: self]];
}

@end
