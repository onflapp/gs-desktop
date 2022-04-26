/*
**  CWMessage.m
** 
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2016-2020 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola
**          Sebastian Reitenbach
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

#import <Pantomime/CWMessage.h>

#import <Pantomime/CWFlags.h>
#import <Pantomime/CWFolder.h>
#import <Pantomime/CWInternetAddress.h>
#import <Pantomime/CWMIMEMultipart.h>
#import <Pantomime/CWMIMEUtility.h>
#import <Pantomime/CWRegEx.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/NSString+Extensions.h>
#import <Pantomime/CWParser.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSUserDefaults.h>

#import <Pantomime/CWIMAPCacheManager.h>

#include <stdlib.h>
#include <string.h>
#include <time.h>

#define CHECK_RANGE(r,len) (r.location < len && (r.length < len-r.location))
#define LF "\n"

static int currentMessageVersion = 2;

static CWRegEx *atLeastOneSpaceRegex = nil;
static CWRegEx *suffixSubjTrailerRegex = nil;
static CWRegEx *prefixSubjLeaderRegex = nil;
static CWRegEx *prefixSubjBlobRegex = nil;
static CWRegEx *prefixSubjFwdHdrAndSuffixSubjFwdTrlRegex = nil;

//
// Private methods
//
@interface CWMessage (Private)

- (NSString *) _computeBaseSubject;
- (void) _extractText: (NSMutableData *) theMutableData
		 part: (id) thePart
		quote: (BOOL *) theBOOL;
- (NSData *) _formatRecipientsWithType: (PantomimeRecipientType) theType;

@end


//
//
//
@implementation CWMessage

//
// We setup regexes used in _computeBaseSubject
//
+ (void) initialize
{
  if (atLeastOneSpaceRegex == nil)
    {
      NSString *blobChar = @"[^][]";
      NSString *subjTrailer = @"(\\(fwd\\))| ";
      NSString *subjFwdHdr = @"\\[fwd:";
      NSString *subjFwdTrl = @"\\]";
      NSString *subjBlob = [NSString stringWithFormat:@"\\[(%@)*\\] *", blobChar];
      NSString *subjReFwd = [NSString stringWithFormat:@"((re)|(fwd?)) *(%@)?:", subjBlob];
      NSString *subjLeader = [NSString stringWithFormat:@"((%@)*%@)| ", subjBlob, subjReFwd];
 
      atLeastOneSpaceRegex = [[CWRegEx alloc] initWithPattern: @"[[:space:]]+"
					      flags: REG_EXTENDED|REG_ICASE];
      suffixSubjTrailerRegex = [[CWRegEx alloc] initWithPattern: [NSString stringWithFormat:@"(%@)*$", subjTrailer]
						flags: REG_EXTENDED|REG_ICASE];
      prefixSubjLeaderRegex = [[CWRegEx alloc] initWithPattern: [NSString stringWithFormat:@"^(%@)", subjLeader]
					       flags: REG_EXTENDED|REG_ICASE];
      prefixSubjBlobRegex = [[CWRegEx alloc] initWithPattern: [NSString stringWithFormat:@"^(%@)", subjBlob]
					     flags: REG_EXTENDED|REG_ICASE];
      prefixSubjFwdHdrAndSuffixSubjFwdTrlRegex = [[CWRegEx alloc] initWithPattern: [NSString stringWithFormat:@"^(%@)(.*)(%@)$", subjFwdHdr, subjFwdTrl]
								  flags: REG_EXTENDED|REG_ICASE];

      [CWMessage setVersion: currentMessageVersion];
    }
}


//
//
//
- (id) init
{
  self = [super init];
  if (self)
    {
      _recipients = [[NSMutableArray alloc] init];
      _flags = [[CWFlags alloc] init];
      _initialized = NO;
      _references = nil;
      _folder = nil;

      // By default, we want the subclass's rawSource method to be called so we set our
      // rawSource ivar to nil. If it's not nil (ONLY set in initWithData) it'll be returned,
      // for performances improvements.
      _rawSource = nil;

      // We initialize our dictionary holding all extra properties a message might have
      _properties = [[NSMutableDictionary alloc] init];
    }
  return self;
}


//
//
//
- (id) initWithData: (NSData *) theData
{
  self = [super initWithData: theData];

  // Part: -initWithData could fail. We return nil if it does.
  if (self)
    {
      //
      // We can tell now that this message is fully initialized
      // NOTE: We must NOT call [self setInitialized: YES] since
      //       it will call the method from the subclass and may do
      //       extremely weird things.
      _initialized = YES;

      // We set our rawSource ivar for performance reasons
      [self setRawSource: theData];
    }
  return self;
}



//
//
//
- (id) initWithHeadersFromData: (NSData *) theHeaders
{
  self = [self init];
  {
    [self setHeadersFromData: theHeaders];
  }
  return self;
}


//
//
//
- (id) initWithHeaders: (NSDictionary *) theHeaders
{
  self = [self init];
  if (self)
    {
      [self setHeaders: theHeaders];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_recipients);
  RELEASE(_properties);
  RELEASE(_references);
  RELEASE(_rawSource);
  RELEASE(_flags);
  
  [super dealloc];
}


//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *) theCoder
{
  // Must also encode Part's superclass
  [super encodeWithCoder: theCoder];

  [theCoder encodeObject: [self receivedDate]];                       // Date
  [theCoder encodeObject: [self from]];                               // From
  [theCoder encodeObject: _recipients];                               // To and Cc (Bcc, at worst)
  [theCoder encodeObject: [self subject]];                            // Subject
  [theCoder encodeObject: [self messageID]];                          // Message-ID
  [theCoder encodeObject: [self MIMEVersion]];                        // MIME-Version
  [theCoder encodeObject: _references];                               // References
  [theCoder encodeObject: [self inReplyTo]];                          // In-Reply-To
  
  [theCoder encodeObject: [NSNumber numberWithUnsignedInt: _message_number]]; // Message number
  [theCoder encodeObject: _flags];                                            // Message flags
}


//
//
//
- (id) initWithCoder: (NSCoder *) theCoder
{
  // Must also decode Part's superclass
  self = [super initWithCoder: theCoder];
  if (self)
    {
      _properties = [[NSMutableDictionary alloc] init];
      _recipients = [[NSMutableArray alloc] init];
  
      [self setReceivedDate: [theCoder decodeObject]];              // Date
      [self setFrom: [theCoder decodeObject]];                      // From
      [self setRecipients: [theCoder decodeObject]];                // To and Cc (Bcc, at worst)
      [self setSubject: [theCoder decodeObject]];                   // Subject
      [self setMessageID: [theCoder decodeObject]];                 // Message-ID
      [self setMIMEVersion: [theCoder decodeObject]];               // MIME-Version
      [self setReferences: [theCoder decodeObject]];                // References
      
      [self setInReplyTo: [theCoder decodeObject]];                 // In-Reply-To
      [self setMessageNumber: [[theCoder decodeObject] unsignedIntValue]];  // Message number
  
      // We decode our flags. We must not simply call [self setFlags: [theCoder decodeObject]]
      // since IMAPMessage is re-implementing flags and that would cause problems when
      // unarchiving IMAP caches.
      _flags = [[CWFlags alloc] init];
      [_flags replaceWithFlags: [theCoder decodeObject]];
  
      // It's very important to set the "initialized" ivar to NO since we didn't serialize the content.
      // or our message.
      _initialized = NO;
  
      // We initialize the rest of our ivars
      _rawSource = nil;
      _folder = nil;
    }
  return self;
}


//
// NSCopying protocol (FIXME)
//
- (id) copyWithZone: (NSZone *) zone
{
  return RETAIN(self);
}


//
//
//
- (CWInternetAddress *) from
{
  return [_headers objectForKey: @"From"];
}


//
//
//
- (void) setFrom: (CWInternetAddress *) theInternetAddress
{
  if (theInternetAddress)
    {
      [_headers setObject: theInternetAddress  forKey: @"From"];
    }
}


//
//
//
- (unsigned int) messageNumber
{
  return _message_number;
}


//
//
//
- (void) setMessageNumber: (unsigned int) theMessageNumber
{
  _message_number = theMessageNumber;
}


//
//
//
- (NSString *) messageID
{
  NSString *aString;

  aString = [_headers objectForKey: @"Message-ID"];
  
  if (!aString)
    {
      aString = [[CWMIMEUtility globallyUniqueID] asciiString];
      [self setMessageID: aString];
    }

  return aString;
}


//
//
//
- (void) setMessageID: (NSString *) theMessageID
{
  if (theMessageID)
    {
      [_headers setObject: theMessageID  forKey: @"Message-ID"];
    }
}


//
//
//
- (NSString *) inReplyTo
{
  return [_headers objectForKey: @"In-Reply-To"];
}


//
//
//
- (void) setInReplyTo: (NSString *) theInReplyTo
{
  if (theInReplyTo)
    {
      [_headers setObject: theInReplyTo  forKey: @"In-Reply-To"];
    }
}


//
//
//
- (NSCalendarDate *) receivedDate
{
  return [_headers objectForKey: @"Date"];
}


//
//
//
- (void) setReceivedDate: (NSCalendarDate*) theDate
{
  if (theDate)
    {
      [_headers setObject: theDate  forKey: @"Date"];
    }
}


//
//
//
- (void) addRecipient: (CWInternetAddress *) theAddress
{
  if (theAddress)
    {
      [_recipients addObject: theAddress];
    }
}


//
//
//
- (void) removeRecipient: (CWInternetAddress *) theAddress
{
  if (theAddress)
    {
      [_recipients removeObject: theAddress];
    }
}


//
//
//
- (NSArray *) recipients
{
  return _recipients;
}


//
//
//
- (void) setRecipients: (NSArray *) theRecipients
{
  [_recipients removeAllObjects];

  if (theRecipients)
    {
      [_recipients addObjectsFromArray: theRecipients];
    }
}


//
//
//
- (NSUInteger) recipientsCount
{
  return [_recipients count];
}


//
//
//
- (void) removeAllRecipients
{
  [_recipients removeAllObjects];
}


//
//
//
- (NSArray *) replyTo
{
  return [_headers objectForKey: @"Reply-To"];
}


//
//
//
- (void) setReplyTo: (NSArray *) theAddressList
{
  if (theAddressList && [theAddressList count])
    {
      [_headers setObject: theAddressList  forKey: @"Reply-To"];
    }
  else
    {
      [_headers removeObjectForKey: @"Reply-To"];
    }
}


//
//
//
- (NSString *) subject
{
    return [_headers objectForKey: @"Subject"];
}


//
//
//
- (void) setSubject: (NSString *) theSubject
{
  if (theSubject)
    {
      [_headers setObject: theSubject  forKey: @"Subject"];
      
      // We invalidate our previous base subject.
      [self setBaseSubject: nil];
    }
}


//
//
//
- (NSString *) baseSubject
{
  NSString *baseSubject;
  
  baseSubject = [self propertyForKey: @"baseSubject"];
  
  if (!baseSubject)
    {
      baseSubject = [self _computeBaseSubject];
      [self setBaseSubject: baseSubject];
    }
  
  return baseSubject;
}


//
//
//
- (void) setBaseSubject: (NSString *) theBaseSubject
{
  [self setProperty: theBaseSubject  forKey: @"baseSubject"];
}


//
//
//
- (BOOL) isInitialized
{
  return _initialized;
}


//
//
//
- (void) setInitialized: (BOOL) theBOOL
{
  _initialized = theBOOL;
}


//
//
//
- (NSString *) organization
{
  return [_headers objectForKey: @"Organization"];
}


//
//
//
- (void) setOrganization: (NSString *) theOrganization
{
  [_headers setObject: theOrganization  forKey: @"Organization"];
}


//
//
//
- (id) propertyForKey: (id) theKey
{
  return [_properties objectForKey: theKey];
}


//
//
//
- (void) setProperty: (id) theProperty
	      forKey: (id) theKey
{
  if (theProperty)
    {
      [_properties setObject: theProperty  forKey: theKey];
    }
  else
    {
      [_properties removeObjectForKey: theKey];
    }
}


//
//
//
- (NSArray *) allReferences
{
  return _references;
}


//
//
//
- (void) setReferences: (NSArray *) theReferences
{
  ASSIGN(_references, theReferences);
}


//
//
//
- (CWFlags *) flags
{
  return _flags;
}


//
//
//
- (void) setFlags: (CWFlags *) theFlags
{
  ASSIGN(_flags, theFlags);
}


//
//
//
- (NSString *) MIMEVersion
{
  return [_headers objectForKey: @"MIME-Version"];
}


//
//
//
- (void) setMIMEVersion: (NSString *) theMIMEVersion
{
  if (theMIMEVersion)
    {
      [_headers setObject: theMIMEVersion  forKey: @"MIME-Version"];
    }
}


//
// 
//
- (CWMessage *) reply: (PantomimeReplyMode) theMode
{
  CWInternetAddress *anInternetAddress;
  NSMutableData *aMutableData; 
  CWMessage *theMessage;
  BOOL needsToQuote;
  
  theMessage = [[CWMessage alloc] init];
  [theMessage setContentType: @"text/plain"];
  [theMessage setCharset: @"utf-8"];

  // We set the subject of our message 
  if (![self subject])
    {
      [theMessage setSubject: _(@"Re: your mail")];
    }
  else if ([[[self subject] stringByTrimmingWhiteSpaces] hasREPrefix])
    {
      [theMessage setSubject: [self subject]];
    }
  else 
    {
      [theMessage setSubject: [NSString stringWithFormat: _(@"Re: %@"), [[self subject] stringByTrimmingWhiteSpaces]]];
    }

  // If Reply-To is defined, we use it. Otherwise, we use From:
  if ([self replyTo] == nil)
    {
      anInternetAddress = [self from];
      [anInternetAddress setType: PantomimeToRecipient];
      [theMessage addRecipient: anInternetAddress];
    }
  else 
    {
      NSUInteger i;

      for (i = 0; i < [[self replyTo] count]; i++)
	{
	  anInternetAddress = [[self replyTo] objectAtIndex: i];
	  [anInternetAddress setType: PantomimeToRecipient];
	  [theMessage addRecipient: anInternetAddress];
	}
    }



  // We add our In-Reply-To header
  if ([self messageID])
    {
      [theMessage setInReplyTo: [self messageID]];
    }
  
  // If we reply to all, we add the other recipients
  if ((theMode&PantomimeReplyAllMode) == PantomimeReplyAllMode)
    {
      NSEnumerator *anEnumerator;

      anEnumerator = [_recipients objectEnumerator];
      
      while ((anInternetAddress = [anEnumerator nextObject]))
	{
	  [anInternetAddress setType: PantomimeCcRecipient];
	  [theMessage addRecipient: anInternetAddress];
	}
    }

  // If it's a "simple" reply, we don't compute a content.
  if ((theMode&PantomimeSimpleReplyMode) == PantomimeSimpleReplyMode)
    {
      [theMessage setContent: [NSData data]];
      return AUTORELEASE(theMessage);
    }
  

  // We finally work on the content of the message
  aMutableData = [[NSMutableData alloc] init];
  needsToQuote = NO;

  [self _extractText: aMutableData  part: self  quote: &needsToQuote];
  
  //
  // It was impossible for use to find a text/plain part. Let's
  // inform our user that we can't do anything with this message.
  //
  if (![aMutableData length])
    {
      [aMutableData appendData: [@"\t[NON-Text Body part not included]" dataUsingEncoding: NSUTF8StringEncoding]];
      needsToQuote = NO;
    }
  else
    {
      // We remove the signature
      // RFC 3676 specifies sig-dashes as followed by space and new line
      NSRange aRange;
      
      aRange = [aMutableData rangeOfCString: "\n-- \n"  options: NSBackwardsSearch];
      
      if (aRange.location != NSNotFound)
	{
	  [aMutableData replaceBytesInRange: NSMakeRange(aRange.location, [aMutableData length]-aRange.location)
			withBytes: NULL
			length: 0];
	}
    }

  
  // We now have our content as string, let's 'quote' it
  if (needsToQuote)
    {
      NSData *aData;
      
      aData = [aMutableData unwrapWithLimit: 78];
      [aMutableData setData: [aData quoteWithLevel: 1  wrappingLimit: 80]]; 
    }

  [aMutableData insertCString: [[NSString stringWithFormat: @"%@ wrote:\n\n", [[self from] stringValue]] UTF8String]
		atIndex: 0];
  
  
  // We verify if we have a Date value. We might receive messages w/o this field
  // (Yes, I know, it's borken but it's happening).
  if ([self receivedDate])
    {
      [aMutableData insertCString: [[NSString stringWithFormat: @"On %@ ", [[self receivedDate] description]] UTF8String]
		    atIndex: 0];
    }

  [theMessage setContent: aMutableData];
  RELEASE(aMutableData);
  
  return AUTORELEASE(theMessage);
}


//
//
//
- (CWMessage *) forward: (PantomimeForwardMode) theMode;
{
  CWMessage *theMessage;
 
  theMessage = [[CWMessage alloc] init];
  
  // We set the subject of our message
  if ([self subject])
    {
      [theMessage setSubject: [NSString stringWithFormat: @"%@ (fwd)", [self subject]]];
    }
  else
    {
      [theMessage setSubject: @"Forwarded mail..."];
    }

  if (theMode == PantomimeAttachmentForwardMode)
    {
      CWMIMEMultipart *aMimeMultipart;
      CWPart *aPart;      
      
      aMimeMultipart = [[CWMIMEMultipart alloc] init];

      aPart = [[CWPart alloc] init];
      [aMimeMultipart addPart: aPart];
      RELEASE(aPart);

      aPart = [[CWPart alloc] init];
      [aPart setContentType: @"message/rfc822"];
      [aPart setContentDisposition: PantomimeAttachmentDisposition];
      [aPart setSize: [self size]];
      [aPart setContent: self];
      [aMimeMultipart addPart: aPart];
      RELEASE(aPart);

      [theMessage setContentType: @"multipart/mixed"];
      [theMessage setContent: aMimeMultipart];
      RELEASE(aMimeMultipart);
    }
  else
    {
      NSMutableData *aMutableData;
      
      // We create our generic forward message header
      aMutableData = AUTORELEASE([[NSMutableData alloc] init]);
      [aMutableData appendCString: "---------- Forwarded message ----------"];
  
      // We verify if we have a Date value. We might receive messages w/o this field
      // (Yes, I know, it's borken but it's happening).
      if ([self receivedDate])
	{
	  [aMutableData appendCString: "\nDate: "];
	  [aMutableData appendData: [[[self receivedDate] description] dataUsingEncoding: NSASCIIStringEncoding]];
	}
      
      [aMutableData appendCString: "\nFrom: "];
      [aMutableData appendData: [[[self from] stringValue] dataUsingEncoding: [NSString encodingForPart: self]]];
  
      if ([self subject])
	{
	  [aMutableData appendCString: "\nSubject: "];
	}
  
      [aMutableData appendData: [[NSString stringWithFormat: @"%@\n\n", [self subject]]
				  dataUsingEncoding: [NSString encodingForPart: self]]];
  
      //
      // If our Content-Type is text/plain, we represent it as a it is, otherwise,
      // we currently create a new body part representing the forwarded message.
      // We assume that no type means raw text
      //
      if ([self isMIMEType: @"text"  subType: @"*"] || [self contentType] == nil)
	{
	  // We set the content of our message
	  [aMutableData appendData: [CWMIMEUtility plainTextContentFromPart: self]];

	  // We set the Content-Transfer-Encoding and the Charset to the previous one
	  [theMessage setContentTransferEncoding: [self contentTransferEncoding]];
	  [theMessage setCharset: [self charset]];
      

	  [theMessage setContentType: @"text/plain"];
	  [theMessage setContent: aMutableData];
	  [theMessage setSize: [aMutableData length]];
	}
      //
      // If our Content-Type is a message/rfc822 or any other type like
      // application/*, audio/*, image/* or video/*
      // 
      else if ([self isMIMEType: @"application"  subType: @"*"] ||
	       [self isMIMEType: @"audio"  subType: @"*"] ||
	       [self isMIMEType: @"image"  subType: @"*"] || 
	       [self isMIMEType: @"message"  subType: @"*"] ||
	       [self isMIMEType: @"video"  subType: @"*"])
	{
	  CWMIMEMultipart *aMimeMultipart;
	  CWPart *aPart;
      
	  aMimeMultipart = [[CWMIMEMultipart alloc] init];
      
	  // We add our text/plain part.
	  aPart = [[CWPart alloc] init];
	  [aPart setContentType: @"text/plain"];
	  [aPart setContent: aMutableData];
	  [aPart setContentDisposition: PantomimeInlineDisposition];
	  [aPart setSize: [aMutableData length]];
	  [aMimeMultipart addPart: aPart];
	  RELEASE(aPart);
      
	  // We add our content as an attachment
	  aPart = [[CWPart alloc] init];  
	  [aPart setContentType: [self contentType]];
	  [aPart setContent: [self content]];
	  [aPart setContentTransferEncoding: [self contentTransferEncoding]];
	  [aPart setContentDisposition: PantomimeAttachmentDisposition];
	  [aPart setCharset: [self charset]];
	  [aPart setFilename: [self filename]];
	  [aPart setSize: [self size]];
	  [aMimeMultipart addPart: aPart];
	  RELEASE(aPart);

	  [theMessage setContentType: @"multipart/mixed"];
	  [theMessage setContent: aMimeMultipart];
	  RELEASE(aMimeMultipart);
	}
      //
      // We have a multipart object. We must treat multipart/alternative
      // parts differently since we don't want to include multipart parts in the forward.
      //
      else if ([self isMIMEType: @"multipart"  subType: @"*"])
	{
	  //
	  // If we have multipart/alternative part, we only keep one part from it.
	  //
	  if ([self isMIMEType: @"multipart"  subType: @"alternative"])
	    {
	      CWMIMEMultipart *aMimeMultipart;
	      CWPart *aPart;
	      NSUInteger i;
	  
	      aMimeMultipart = (CWMIMEMultipart *)[self content];
	      aPart = nil;

	      // We search for our text/plain part
	      for (i = 0; i < [aMimeMultipart count]; i++)
		{
		  aPart = [aMimeMultipart partAtIndex: i];

		  if ([aPart isMIMEType: @"text"  subType: @"plain"])
		    {
		      break;
		    }
		  else
		    {
		      aPart = nil;
		    }
		}

	      // We found one
	      if (aPart)
		{
		  // We set the content of our message
		  [aMutableData appendData: (NSData *)[aPart content]];
	      
		  // We set the Content-Transfer-Encoding and the Charset to our text part
		  [theMessage setContentTransferEncoding: [aPart contentTransferEncoding]];
		  [theMessage setCharset: [aPart charset]];
	      
		  [theMessage setContentType: @"text/plain"];
		  [theMessage setContent: aMutableData];
		  [theMessage setSize: [aMutableData length]];
		}
	      // We haven't found one! Inform the user that it happened.
	      else
		{
		  [aMutableData appendCString: "No text/plain part from this multipart/alternative part has been found"];
		  [aMutableData appendCString: "\nNo parts have been included as attachments with this mail during the forward operation."];
		  [aMutableData appendCString: "\n\nPlease report this as a bug."];

		  [theMessage setContent: aMutableData];
		  [theMessage setSize: [aMutableData length]];
		}
	    }
	  //
	  // We surely have a multipart/mixed or multipart/related.
	  // We search for a text/plain part inside our multipart object.
	  // We 'keep' the other parts in a separate new multipart object too
	  // that will become our new content.
	  //
	  else
	    {
	      CWMIMEMultipart *aMimeMultipart, *newMimeMultipart;
	      CWPart *aPart;
	      BOOL hasFoundTextPlain = NO;
	      NSUInteger i;
	  
	      // We get our current mutipart object
	      aMimeMultipart = (CWMIMEMultipart *)[self content];

	      // We create our new multipart object for holding all our parts.
	      newMimeMultipart = [[CWMIMEMultipart alloc] init];
	  
	      for (i = 0; i < [aMimeMultipart count]; i++)
		{
		  aPart = [aMimeMultipart partAtIndex: i];
	      
		  if ([aPart isMIMEType: @"text"  subType: @"plain"] && !hasFoundTextPlain)
		    {
		      CWPart *newPart;
		  
		      newPart = [[CWPart alloc] init];
		  
		      // We set the content of our new part
		      [aMutableData appendData: (NSData *)[aPart content]];
		      [newPart setContentType: @"text/plain"];
		      [newPart setContent: aMutableData];
		      [newPart setSize: [aMutableData length]];
		  
		      // We set the Content-Transfer-Encoding and the Charset to the previous one
		      [newPart setContentTransferEncoding: [aPart contentTransferEncoding]];
		      [newPart setCharset: [aPart charset]];
		  
		      // We finally add our new part to our MIME multipart object
		      [newMimeMultipart addPart: newPart];
		      RELEASE(newPart);
		  
		      hasFoundTextPlain = YES;
		    }
		  // We set the Content-Disposition to "attachment"
		  // all the time.
		  else
		    {
		      [aPart setContentDisposition: PantomimeAttachmentDisposition];
		      [newMimeMultipart addPart: aPart];
		    }
		}
	      
	      [theMessage setContentType: @"multipart/mixed"];
	      [theMessage setContent: newMimeMultipart];
	      RELEASE(newMimeMultipart);
	    }
	}
      //
      // We got an unknown part. Let's inform the user about this situation.
      //
      else
	{
	  // We set the content of our message
	  [aMutableData appendCString: "The original message contained an unknown part that was not included in this forwarded message."];
	  [aMutableData appendCString: "\n\nPlease report this as a bug."];
      
	  [theMessage setContentType: @"text/plain"];
	  [theMessage setContent: aMutableData];
	  [theMessage setSize: [aMutableData length]];
	}
    }
  
  return AUTORELEASE(theMessage);
}


//
//
//
- (NSData *) dataValue
{
  NSMutableData *aMutableData;
  NSDictionary *aLocale;

  NSEnumerator *allHeaderKeyEnumerator;
  NSString *aKey;

  NSCalendarDate *aCalendarDate;
  NSData *aData;


  // We get our locale in English
#ifndef MACOSX
  aLocale = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle bundleForLibrary: @"gnustep-base"]
							  pathForResource: @"English"
							  ofType: nil
							  inDirectory: @"Languages"]];
#else
  aLocale = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle bundleForClass: [NSObject class]]
							  pathForResource: @"English"
							  ofType: nil
							  inDirectory: @"Languages"] ];
#endif
  
  // We initialize our mutable data object holding the raw data of the
  // new message.
  aMutableData = [[NSMutableData alloc] init];
  
#ifndef MACOSX
  if ([[NSUserDefaults standardUserDefaults] objectForKey: @"Local Time Zone"])
    {
      aCalendarDate = [[NSDate date] dateWithCalendarFormat: @"%a, %d %b %Y %H:%M:%S %z"
				     timeZone: [NSTimeZone systemTimeZone]];
    }
  else
    {
      tzset();
      aCalendarDate = [[NSDate date] dateWithCalendarFormat: @"%a, %d %b %Y %H:%M:%S %z"
				     timeZone: [NSTimeZone timeZoneWithAbbreviation: 
							     [NSString stringWithCString: tzname[1]]]];
    }
#else
  aCalendarDate = [[NSDate date] dateWithCalendarFormat: @"%a, %d %b %Y %H:%M:%S %z"
				 timeZone: [NSTimeZone systemTimeZone]];
#endif
  [aMutableData appendCFormat: @"Date: %@%s", [aCalendarDate descriptionWithLocale: aLocale], LF];
  
  // We set the subject, if we have one!
  if ([[[self subject] stringByTrimmingWhiteSpaces] length] > 0)
    {
      [aMutableData appendCString: "Subject: "];
      [aMutableData appendData: [CWMIMEUtility encodeWordUsingQuotedPrintable: [self subject]
					       prefixLength: 8]];
      [aMutableData appendCString: LF];
    }
  
  // We set our Message-ID
  [aMutableData appendCFormat: @"Message-ID: <%@>%s", [self messageID], LF];

  // We set our MIME-Version header
  [aMutableData appendCFormat: @"MIME-Version: 1.0 (Generated by Pantomime %@)%s", PANTOMIME_VERSION, LF];

  // We encode our From: field
  [aMutableData appendCFormat: @"From: "];
  [aMutableData appendData: [[self from] dataValue]];
  [aMutableData appendCFormat: @"%s", LF];
  
  // We encode our To field
  aData = [self _formatRecipientsWithType: PantomimeToRecipient];
  
  if (aData)
    {
      [aMutableData appendCString: "To: "];
      [aMutableData appendData: aData];
      [aMutableData appendCString: LF];
    }
  
  // We encode our Cc field
  aData = [self _formatRecipientsWithType: PantomimeCcRecipient];
  
  if (aData)
    {
      [aMutableData appendCString: "Cc: "];
      [aMutableData appendData: aData];
      [aMutableData appendCString: LF];
    }

  // We encode our Bcc field
  aData = [self _formatRecipientsWithType: PantomimeBccRecipient];
  
  if (aData)
    {
      [aMutableData appendCString: "Bcc: "];
      [aMutableData appendData: aData];
      [aMutableData appendCString: LF];
    }
  
  // We set the Reply-To address in case we need to
  if ([self replyTo])
    {
      NSUInteger i, count;

      [aMutableData appendCFormat: @"Reply-To: "];

      count = [[self replyTo] count];
      for (i = 0; i < count; i++)
	{
	  [aMutableData appendData: [[[self replyTo] objectAtIndex: i] dataValue]];

	  if (i < count-1) [aMutableData appendCString: ", "];
	}

      [aMutableData appendCString: LF];
    }
  
  // We set the Organization header value if we need to
  if ([self organization])
    {
      [aMutableData appendCString: "Organization: "];
      [aMutableData appendData: [CWMIMEUtility encodeWordUsingQuotedPrintable: [self organization]
					       prefixLength: 13]];
      [aMutableData appendCString: LF];
    }
  
  // We set the In-Reply-To header if we need to
  if ([self headerValueForName: @"In-Reply-To"])
    {
      [aMutableData appendCFormat: @"In-Reply-To: %@%s", [self inReplyTo], LF];
    }
  

  // We now set all X-* headers
  allHeaderKeyEnumerator = [_headers keyEnumerator];
  
  while ((aKey = [allHeaderKeyEnumerator nextObject])) 
    {
      if ([aKey hasPrefix: @"X-"] || ([aKey caseInsensitiveCompare: @"User-Agent"] == NSOrderedSame))
	{
	  [aMutableData appendCFormat: @"%@: %@%s", aKey, [self headerValueForName: aKey], LF];
	}
    }
  
  //
  // We add our message header/body separator
  //
  [aMutableData appendData: [super dataValue]];

  return AUTORELEASE(aMutableData);
}

//
//
//
- (void) addHeader: (NSString *) theName
	 withValue: (NSString *) theValue
{
  if (theName && theValue)
    {
      NSString *aString;
      
      if ((aString = [_headers objectForKey: theName]))
	{
	  aString = [NSString stringWithFormat: @"%@ %@", aString, theValue];
	}
      else
	{
	  aString = theValue;
	}
      
      [_headers setObject: aString  forKey: theName];
    }
}

//
//
//
- (CWFolder *) folder
{
  return _folder;
}

- (void) setFolder: (CWFolder *) theFolder
{
  _folder = theFolder;
}

//
// This method is used to optain tha raw source of a message.
// It's returned as a NSData object. The returned data should
// be the message like it's achived in a mbox format and it could
// easily be decoded with Message: -initWithData.
// 
// All subclasses of Message MUST implement this method.
//
- (NSData *) rawSource
{
  if (!_rawSource)
    {
      [self subclassResponsibility: _cmd];
      return nil;
    }
  
  return _rawSource;
}


//
//
//
- (void) setRawSource: (NSData *) theRawSource
{
  ASSIGN(_rawSource, theRawSource);
}


//
//
//
- (NSCalendarDate *) resentDate
{
  return [_headers objectForKey: @"Resent-Date"];
}


//
//
//
- (void) setResentDate: (NSCalendarDate *) theResentDate
{
  [_headers setObject: theResentDate  forKey: @"Resent-Date"];
}


//
//
//
- (CWInternetAddress *) resentFrom
{
  return [_headers objectForKey: @"Resent-From"];
}


//
//
//
- (void) setResentFrom: (CWInternetAddress *) theInternetAddress
{
  [_headers setObject: theInternetAddress  forKey: @"Resent-From"];
}


//
//
//
- (NSString *) resentMessageID
{
  return [_headers objectForKey: @"Resent-Message-ID"];
}


//
//
//
- (void) setResentMessageID: (NSString *) theResentMessageID
{
  [_headers setObject: theResentMessageID  forKey: @"Resent-Message-ID"];
}


//
//
//
- (NSString *) resentSubject
{
  return [_headers objectForKey: @"Resent-Subject"];
}


//
//
//
- (void) setResentSubject: (NSString *) theResentSubject
{
  [_headers setObject: theResentSubject  forKey: @"Resent-Subject"];
}


//
//
//
- (void) addHeadersFromData: (NSData *) theHeaders  record: (cache_record *) theRecord
{
  NSArray *allLines;
  NSData *aData;
  NSUInteger i, count;

  [super setHeadersFromData: theHeaders];

  // We MUST be sure to unfold all headers properly before
  // decoding the headers
  theHeaders = [theHeaders unfoldLines];

  allLines = [theHeaders componentsSeparatedByCString: "\n"];
  count = [allLines count];

  for (i = 0; i < count; i++)
    {
      NSData *aLine = [allLines objectAtIndex: i];

      // We stop if we found the header separator. (\n\n) since someone could
      // have called this method with the entire rawsource of a message.
      if ([aLine length] == 0)
	{
	  break;
	}

      if ([aLine hasCaseInsensitiveCPrefix: "Bcc"])
	{
	  [CWParser parseDestination: aLine
		    forType: PantomimeBccRecipient
		    inMessage: self
		    quick: NO];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Cc"])
	{
	  aData = [CWParser parseDestination: aLine
			    forType: PantomimeCcRecipient
			    inMessage: self
			    quick: NO];
	  if (theRecord) theRecord->cc = aData;
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Date"])
	{
	  [CWParser parseDate: aLine  inMessage: self];
	  if (theRecord && [self receivedDate]) theRecord->date = [[self receivedDate] timeIntervalSince1970]; 
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "From"] &&
	       ![aLine hasCaseInsensitiveCPrefix: "From "])
	{
	  aData = [CWParser parseFrom: aLine  inMessage: self  quick: NO];
	  if (theRecord) theRecord->from = aData;
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "In-Reply-To"])
	{
	  aData = [CWParser parseInReplyTo: aLine  inMessage: self  quick: NO];
	  if (theRecord) theRecord->in_reply_to = aData;
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Message-ID"])
	{
	  aData = [CWParser parseMessageID: aLine  inMessage: self  quick: NO];
	  if (theRecord) theRecord->message_id = aData;
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "MIME-Version"])
	{
	  [CWParser parseMIMEVersion: aLine  inMessage: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Organization"])
	{
	  [CWParser parseOrganization: aLine  inMessage: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "References"])
	{
	  aData = [CWParser parseReferences: aLine  inMessage: self  quick: NO];
	  if (theRecord) theRecord->references = aData;
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Reply-To"])
	{
	  [CWParser parseReplyTo: aLine  inMessage: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Resent-From"])
	{
	  [CWParser parseResentFrom: aLine  inMessage: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Resent-Bcc"])
	{
	  [CWParser parseDestination: aLine
		    forType: PantomimeResentBccRecipient
		    inMessage: self
		    quick: NO];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Resent-Cc"])
	{
	  [CWParser parseDestination: aLine
		    forType: PantomimeResentCcRecipient
		    inMessage: self
		    quick: NO];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Resent-To"])
	{
	  [CWParser parseDestination: aLine
		    forType: PantomimeResentToRecipient
		    inMessage: self
		    quick: NO];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Status"])
	{
	  [CWParser parseStatus: aLine  inMessage: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "To"])
	{
	  aData = [CWParser parseDestination: aLine
			    forType: PantomimeToRecipient
			    inMessage: self
			    quick: NO];
	  if (theRecord) theRecord->to = aData;
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "X-Status"])
	{
	  [CWParser parseXStatus: aLine  inMessage: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Subject"])
	{
	  aData = [CWParser parseSubject: aLine  inMessage: self  quick: NO];
	  if (theRecord) theRecord->subject = aData;
	}
      else
	{
	  // We MUST NOT parse the headers that we already parsed in
	  // Part as "unknown".
	  if (![aLine hasCaseInsensitiveCPrefix: "Content-Description"] &&
	      ![aLine hasCaseInsensitiveCPrefix: "Content-Disposition"] &&
	      ![aLine hasCaseInsensitiveCPrefix: "Content-ID"] &&
	      ![aLine hasCaseInsensitiveCPrefix: "Content-Length"] &&
	      ![aLine hasCaseInsensitiveCPrefix: "Content-Transfer-Encoding"] &&
	      ![aLine hasCaseInsensitiveCPrefix: "Content-Type"])
	    {
	      [CWParser parseUnknownHeader: aLine  inMessage: self];
	    }
	}
    }
}

//
//
//
- (void) setHeadersFromData: (NSData *) theHeaders
{
  [self setHeadersFromData: theHeaders  record: NULL];
}

//
//
//
- (void) setHeadersFromData: (NSData *) theHeaders  record: (cache_record *) theRecord
{  
  if (!theHeaders || [theHeaders length] == 0)
    {
      return;
    }

  [_recipients removeAllObjects];
  [_headers removeAllObjects];
  [self addHeadersFromData: theHeaders  record: theRecord];
}

@end


//
// Message's sorting category
//
@implementation CWMessage (Comparing)

- (NSComparisonResult) compareAccordingToNumber: (CWMessage *) aMessage
{
  unsigned int num;
  num = [aMessage messageNumber];
  if (_message_number < num)
    {
      return NSOrderedAscending;
    }
  else if (_message_number > num)
    {
      return NSOrderedDescending;
    }
  else
    {
      return NSOrderedSame;
    }
}

- (NSComparisonResult) reverseCompareAccordingToNumber: (CWMessage *) aMessage
{
  unsigned int num;
  num = [aMessage messageNumber];
  if (num < _message_number)
    {
      return NSOrderedAscending;
    }
  else if (num > _message_number)
    {
      return NSOrderedDescending;
    }
  else
    {
      return NSOrderedSame;
    }
}

- (NSComparisonResult) compareAccordingToDate: (CWMessage *) aMessage
{
  NSDate *date1 = [self receivedDate];
  NSDate *date2 = [aMessage receivedDate];
  NSTimeInterval timeInterval;

  if (date1 == nil || date2 == nil)
    {
      return [self compareAccordingToNumber: aMessage]; 
    }

  timeInterval = [date1 timeIntervalSinceDate: date2];

  if (timeInterval < 0)
    {
      return NSOrderedAscending;
    }
  else if (timeInterval > 0)
    {
      return NSOrderedDescending;
    }
  else
    {
      return [self compareAccordingToNumber: aMessage];      
    }
}

- (NSComparisonResult) reverseCompareAccordingToDate: (CWMessage *) aMessage
{
  NSDate *date2 = [self receivedDate];
  NSDate *date1 = [aMessage receivedDate];
  NSTimeInterval timeInterval;

  if (date1 == nil || date2 == nil)
    {
      return [self reverseCompareAccordingToNumber: aMessage]; 
    }

  timeInterval = [date1 timeIntervalSinceDate: date2];

  if (timeInterval < 0)
    {
      return NSOrderedAscending;
    }
  else if (timeInterval > 0)
    {
      return NSOrderedDescending;
    }
  else
    {
      return [self reverseCompareAccordingToNumber: aMessage];      
    }
}

- (NSComparisonResult) compareAccordingToSender: (CWMessage *) aMessage
{
  CWInternetAddress *from1, *from2;
  NSString *fromString1, *fromString2;
  NSString *tempString;
  NSComparisonResult result;

  from1 = [self from];
  from2 = [aMessage from];

  tempString = [from1 personal];
  if (tempString == nil || [tempString length] == 0)
    {
      fromString1 = [from1 address];
      if (fromString1 == nil)
	fromString1 = @"";
    }
  else
    {
      fromString1 = tempString;
    }


  tempString = [from2 personal];
  if (tempString == nil || [tempString length] == 0)
    {
      fromString2 = [from2 address];
      if (fromString2 == nil)
	fromString2 = @"";
    }
  else
    {
      fromString2 = tempString;
    }

  result = [fromString1 caseInsensitiveCompare: fromString2];
  if (result == NSOrderedSame)
    {
	  return [self compareAccordingToNumber: aMessage];
    }
  else
    {
      return result;
    }
}

- (NSComparisonResult) reverseCompareAccordingToSender: (CWMessage *) aMessage
{
  CWInternetAddress *from1, *from2;
  NSString *fromString1, *fromString2;
  NSString *tempString;
  NSComparisonResult result;

  from2 = [self from];
  from1 = [aMessage from];

  tempString = [from1 personal];
  if (tempString == nil || [tempString length] == 0)
    {
      fromString1 = [from1 address];
      if (fromString1 == nil)
	fromString1 = @"";
    }
  else
    {
      fromString1 = tempString;
    }


  tempString = [from2 personal];
  if (tempString == nil || [tempString length] == 0)
    {
      fromString2 = [from2 address];
      if (fromString2 == nil)
	fromString2 = @"";
    }
  else
    {
      fromString2 = tempString;
    }


  result = [fromString1 caseInsensitiveCompare: fromString2];
  
  if (result == NSOrderedSame)
    {
      return [self reverseCompareAccordingToNumber: aMessage];
    }
  else
    {
      return result;
    }
}

- (NSComparisonResult) compareAccordingToSubject: (CWMessage *) aMessage
{
  NSString *subject1 = [self baseSubject];
  NSString *subject2 = [aMessage baseSubject];
  NSComparisonResult result;
  
  if (subject1 == nil)
    subject1 = @"";
  if (subject2 == nil)
    subject2 = @"";

  result = [subject1 caseInsensitiveCompare: subject2];

  if (result == NSOrderedSame)
    {
      return [self compareAccordingToNumber: aMessage];      
    }
  else
    {
      return result;
    }
}

- (NSComparisonResult) reverseCompareAccordingToSubject: (CWMessage *) aMessage
{
  NSString *subject2 = [self baseSubject];
  NSString *subject1 = [aMessage baseSubject];
  NSComparisonResult result;
  
  if (subject1 == nil)
    subject1 = @"";
  if (subject2 == nil)
    subject2 = @"";

  result = [subject1 caseInsensitiveCompare: subject2];

  if (result == NSOrderedSame)
    {
      return [self compareAccordingToNumber: aMessage];      
    }
  else
    {
      return result;
    }
}

- (NSComparisonResult) compareAccordingToSize: (CWMessage *) aMessage
{
  unsigned long size1 = [self size];
  unsigned long size2 = [aMessage size];

  if (size1 < size2)
    {
      return NSOrderedAscending;
    }
  else if (size1 > size2)
    {
      return NSOrderedDescending;
    }
  else
    {
      return [self compareAccordingToNumber: aMessage];
    }
}

- (NSComparisonResult) reverseCompareAccordingToSize: (CWMessage *) aMessage
{
  unsigned long size1 = [aMessage size];
  unsigned long  size2 = [self size];

  if (size1 < size2)
    {
      return NSOrderedAscending;
    }
  else if (size1 > size2)
    {
      return NSOrderedDescending;
    }
  else
    {
      return [self reverseCompareAccordingToNumber: aMessage];      
    }
}

@end


//
// Private methods
//
@implementation CWMessage (Private)

//
// Intended to be compatible for use with the draft specification for
// sorting by subject contained in
// INTERNET MESSAGE ACCESS PROTOCOL - SORT and THREAD EXTENSIONS
// draft document, May 2003
//
// At the time of this writing, it can be found at
// http://www.ietf.org/internet-drafts/draft-ietf-imapext-sort-13.txt
//
- (NSString *) _computeBaseSubject
{
  NSMutableString *baseSubject;
  NSArray *theMatches;
  NSString *aSubject;
  NSRange aRange;

  BOOL b1, b2;
  NSUInteger i;
  
  aSubject = [self subject];
  
  if (!aSubject)
    {
      return nil;
    }
  
  baseSubject = [NSMutableString stringWithString: aSubject];
  
  //
  // (1) Convert any RFC 2047 encoded-words in the subject to
  // UTF-8 as described in "internationalization
  // considerations."  Convert all tabs and continuations to
  // space.  Convert all multiple spaces to a single space.
  // 
  theMatches = [atLeastOneSpaceRegex matchString: baseSubject];

  for (i = [theMatches count]; i > 0; i--)
    {
      aRange = [[theMatches objectAtIndex:i-1] rangeValue];
      
      if (CHECK_RANGE(aRange, [baseSubject length]))
	{
	  [baseSubject replaceCharactersInRange: aRange  withString:@" "];
	}
    }
  do
    {
      b1 = NO;
    
      //
      // (2) Remove all trailing text of the subject that matches
      // the subj-trailer ABNF, repeat until no more matches are
      // possible.
      //
      theMatches = [suffixSubjTrailerRegex matchString: baseSubject];

      if ([theMatches count] > 0)
        {
	  aRange = [[theMatches objectAtIndex:0] rangeValue];
	  
	  if (CHECK_RANGE(aRange,[baseSubject length]))
	    {
	      [baseSubject deleteCharactersInRange: [[theMatches objectAtIndex:0] rangeValue]];
	    }
	}
      do
        {
	  b2 = NO;
	  //
	  // (3) Remove all prefix text of the subject that matches the
	  // subj-leader ABNF.
          //
	  theMatches = [prefixSubjLeaderRegex matchString: baseSubject];
	  
	  if ([theMatches count] > 0)
            {
	      aRange = [[theMatches objectAtIndex:0] rangeValue];
	      
	      if (CHECK_RANGE(aRange, [baseSubject length]))
                {
		  [baseSubject deleteCharactersInRange: [[theMatches objectAtIndex:0] rangeValue]];
		  b2 = YES;
                }
            }
	  //
          // (4) If there is prefix text of the subject that matches the
          // subj-blob ABNF, and removing that prefix leaves a non-empty
          // subj-base, then remove the prefix text.
          //
	  theMatches = [prefixSubjBlobRegex matchString: baseSubject];

	  if ([theMatches count] > 0)
	    {
	      aRange = [[theMatches objectAtIndex:0] rangeValue];
	      if (CHECK_RANGE(aRange, [baseSubject length]))
                {
		  [baseSubject deleteCharactersInRange:[[theMatches objectAtIndex:0] rangeValue]];
		  b2 = YES;
                }
            }
            //
            // (5) Repeat (3) and (4) until no matches remain.
            //
        } while (b2);
      //
      // (6) If the resulting text begins with the subj-fwd-hdr ABNF
      // and ends with the subj-fwd-trl ABNF, remove the
      // subj-fwd-hdr and subj-fwd-trl and repeat from step (2).
      //
      theMatches = [prefixSubjFwdHdrAndSuffixSubjFwdTrlRegex matchString:baseSubject];

      if ([theMatches count] > 0)
        {
	  [baseSubject deleteCharactersInRange:NSMakeRange(0,5)];
	  [baseSubject deleteCharactersInRange:NSMakeRange([baseSubject length] - 1,1)];
	  b1 = YES;
        }
    } while (b1);
  //
  // (7) The resulting text is the "base subject" used in the SORT.
  //
  return baseSubject;
}


//
//
//
- (void) _extractText: (NSMutableData *) theMutableData
		 part: (id) thePart
		quote: (BOOL *) theBOOL
{
  //
  // We now get the right text part of the message.
  // We assume that no type means raw text (assuming also not mutlipart)
  // 
  //
  if ([thePart isMIMEType: @"text"  subType: @"*"] || [thePart contentType] == nil)
    {
      NSData *d;

      d = [[NSString stringWithData: [CWMIMEUtility plainTextContentFromPart: thePart]  charset: [[thePart charset] dataUsingEncoding: NSASCIIStringEncoding]]
	    dataUsingEncoding: NSUTF8StringEncoding];
      [theMutableData appendData: d];
       *theBOOL = YES;
    }
  //
  // If our message only contains the following part types, we cannot
  // represent those in a reply.
  // 
  else if ([thePart isMIMEType: @"application"  subType: @"*"] ||
	   [thePart isMIMEType: @"audio"  subType: @"*"] ||
	   [thePart isMIMEType: @"image"  subType: @"*"] || 
	   [thePart isMIMEType: @"message"  subType: @"*"] ||
	   [thePart isMIMEType: @"video"  subType: @"*"])
    {
      [theMutableData appendData: [@"\t[NON-Text Body part not included]" dataUsingEncoding: NSUTF8StringEncoding]];
    }
  //
  // We have a multipart type. It can be:
  //
  // multipart/appledouble, multipart/alternative, multipart/related,
  // multipart/mixed or even multipart/report.
  //
  // We must search for a text part to use in our reply.
  //
  else if ([thePart isMIMEType: @"multipart"  subType: @"*"])
    {
      CWMIMEMultipart *aMimeMultipart;
      CWPart *aPart;
      NSUInteger i;

      aMimeMultipart = (CWMIMEMultipart *)[thePart content];
     
      for (i = 0; i < [aMimeMultipart count]; i++)
	{
	  aPart = [aMimeMultipart partAtIndex: i];
	  
	  //
	  // We do a full verification on the Content-Type since we might
	  // have a text/x-{something} like text/x-vcard.
	  //
	  if ([aPart isMIMEType: @"text"  subType: @"plain"] ||
	      [aPart isMIMEType: @"text"  subType: @"enriched"] ||
	      [aPart isMIMEType: @"text"  subType: @"html"])
	    {
	      [theMutableData appendData: [[NSString stringWithData: [CWMIMEUtility plainTextContentFromPart: aPart]
						     charset: [[aPart charset] dataUsingEncoding: NSASCIIStringEncoding]]
					    dataUsingEncoding: NSUTF8StringEncoding]];
	      
	      // If our original Content-Type is multipart/alternative, no need to
	      // consider to the other text/* parts. Otherwise, we just append 
	      // all text/* parts.
	      if ([thePart isMIMEType: @"multipart"  subType: @"alternative"])
		{
		  break;
		}
	    }
	  //
	  // If we got any other kind of multipart parts, we loop inside of it in order to
	  // extract all text parts.
	  //
	  else if ([aPart isMIMEType: @"multipart"  subType: @"*"])
	    {
	      [self _extractText: theMutableData  part: aPart  quote: theBOOL];
	    }
	} // for ( ... )

      *theBOOL = YES;
    } // else if ([thePart isMIMEType: @"multipart"  subType: @"*"])
}


//
//
//
- (NSData *) _formatRecipientsWithType: (PantomimeRecipientType) theType
{
  NSMutableData *aMutableData;
  NSUInteger i;

  aMutableData = [[NSMutableData alloc] init];

  for (i = 0; i < [_recipients count]; i++)
    {
      CWInternetAddress *anInternetAddress;

      anInternetAddress = [_recipients objectAtIndex: i];

      if ([anInternetAddress type] == theType)
	{
	  [aMutableData appendData: [anInternetAddress dataValue]];
	  [aMutableData appendCString: ", "];
	}
    }
  
  if ([aMutableData length] > 0)
    {
      [aMutableData setLength: [aMutableData length]-2];
      return AUTORELEASE(aMutableData);
    }
  
  RELEASE(aMutableData);     
  return nil;
}

@end


