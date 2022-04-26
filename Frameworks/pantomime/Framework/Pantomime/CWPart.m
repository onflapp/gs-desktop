/*
**  CWPart.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2017-2018 Riccardo Mottola
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

#import <Pantomime/CWPart.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWMessage.h>
#import <Pantomime/CWMIMEMultipart.h>
#import <Pantomime/CWMIMEUtility.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/NSString+Extensions.h>
#import <Pantomime/CWParser.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>

#include <string.h>

#define LF "\n"

static int currentPartVersion = 2;

//
//
//
@implementation CWPart

+ (void) initialize
{
  [CWPart setVersion: currentPartVersion];
}

- (id) init
{
  self = [super init];
  if (self)
    {
      // We initialize our dictionary that will hold all our headers with a capacity of 25.
      // This is an empirical number that is used to speedup the addition of headers w/o 
      // reallocating our array everytime we add a new element.
      _headers = [[NSMutableDictionary alloc] initWithCapacity: 25];
      _parameters = [[NSMutableDictionary alloc] init];
      _line_length = 0;
      _size = 0;
      _content = nil;
    }
  
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_defaultCharset);
  RELEASE(_parameters);
  RELEASE(_headers);
  RELEASE(_content);

  [super dealloc];
}


//
//
//
- (id) initWithData: (NSData *) theData
{
  NSRange aRange;

  aRange = [theData rangeOfCString: "\n\n"];
  
  if (aRange.length == 0)
    {
      AUTORELEASE(self);
      return nil;
    }

  // We initialize our message with the headers and the content
  self = [self init];
  if (self)
    {
      // We verify if we have an empty body part content like:
      // X-UID: 5dc5aa4b82240000
      //
      // This is a MIME Message
      //
      // ------=_NextPart_000_007F_01BDF6C7.FABAC1B0
      //
      //
      // ------=_NextPart_000_007F_01BDF6C7.FABAC1B0
      // Content-Type: text/html; name="7english.co.kr.htm"
      if ([theData length] == 2)
	{
	  [self setContent: [NSData data]];
	}
      else
	{
	  [self setHeadersFromData:
		  [theData subdataWithRange: NSMakeRange(0,aRange.location)]];
	  [CWMIMEUtility setContentFromRawSource:
		       [theData subdataWithRange:
				  NSMakeRange(aRange.location + 2,
					      [theData length]-(aRange.location+2))]
					  inPart: self];
	}
    }
  return self;
}


//
//
//
- (id) initWithData: (NSData *) theData
            charset: (NSString *) theCharset
{
  self = [self initWithData: theData];
  if (self)
    {
      [self setDefaultCharset: theCharset];
    }
  return self;
}


//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *) theCoder
{
  [theCoder encodeObject: [self contentType]];
  [theCoder encodeObject: [self contentID]];
  [theCoder encodeObject: [self contentDescription]];
  [theCoder encodeObject: [NSNumber numberWithUnsignedInt: (unsigned)[self contentDisposition]]];
  [theCoder encodeObject: [self filename]];
 
  [theCoder encodeObject: [NSNumber numberWithUnsignedInt: (unsigned)[self contentTransferEncoding]]];
  [theCoder encodeObject: [NSNumber numberWithUnsignedInt: (unsigned)[self format]]];
  [theCoder encodeObject: [NSNumber numberWithUnsignedLong: _size]];

  [theCoder encodeObject: [self boundary]];
  [theCoder encodeObject: [self charset]];
  [theCoder encodeObject: _defaultCharset];
}


- (id) initWithCoder: (NSCoder *) theCoder
{
  self = [super init];
  if (self)
    {
      _headers = [[NSMutableDictionary alloc] initWithCapacity: 25];
      _parameters = [[NSMutableDictionary alloc] init];

      [self setContentType: [theCoder decodeObject]];
      [self setContentID: [theCoder decodeObject]];
      [self setContentDescription: [theCoder decodeObject]];
      [self setContentDisposition: (PantomimeContentDisposition)[[theCoder decodeObject] unsignedIntValue]];
      [self setFilename: [theCoder decodeObject]];

      [self setContentTransferEncoding: (PantomimeEncoding)[[theCoder decodeObject] unsignedIntValue]];
      [self setFormat: (PantomimeMessageFormat)[[theCoder decodeObject] unsignedIntValue]];
      [self setSize: [[theCoder decodeObject] unsignedLongValue]];

      [self setBoundary: [theCoder decodeObject]];
      [self setCharset: [theCoder decodeObject]];
      [self setDefaultCharset: [theCoder decodeObject]];
  
      _content = nil;
  }
  return self;
}


//
// access / mutation methods
//
- (NSObject *) content
{
  return _content;
}


//
//
//
- (void) setContent: (NSObject *) theContent
{
  if (theContent && !([theContent isKindOfClass: [NSData class]] ||
		      [theContent isKindOfClass: [CWMessage class]] ||
		      [theContent isKindOfClass: [CWMIMEMultipart class]]))
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"Invalid argument to CWPart: -setContent:  The content MUST be either a NSData, CWMessage or CWMIMEMessage instance."];
    }

  ASSIGN(_content, theContent);
}

//
//
//
- (NSString *) contentType
{
  return [_headers objectForKey: @"Content-Type"];
}

- (void) setContentType: (NSString*) theContentType
{
  if (theContentType)
    {
      [_headers setObject: theContentType  forKey: @"Content-Type"];
    }
}

//
//
//
- (NSString *) contentID
{
  return [_headers objectForKey: @"Content-Id"];
}        

- (void) setContentID: (NSString *) theContentID
{ 
  if (theContentID)
    {
      [_headers setObject: theContentID  forKey: @"Content-Id"];
    }  
}

//
//
//
- (NSString *) contentDescription
{
  return [_headers objectForKey: @"Content-Description"];
}

- (void) setContentDescription: (NSString *) theContentDescription
{
  if (theContentDescription)
    {
      [_headers setObject: theContentDescription  forKey: @"Content-Description"];
    }  
}


//
//
//
- (PantomimeContentDisposition) contentDisposition
{
  id o;

  o = [_headers objectForKey: @"Content-Disposition"];

  return (o ? (PantomimeContentDisposition)[o intValue] : PantomimeInlineDisposition);
}

- (void) setContentDisposition: (PantomimeContentDisposition) theContentDisposition
{
  [_headers setObject: [NSNumber numberWithUnsignedInt: (unsigned)theContentDisposition]  forKey: @"Content-Disposition"];
}


//
//
//
- (PantomimeEncoding) contentTransferEncoding
{
  id o;
  
  o = [_headers objectForKey: @"Content-Transfer-Encoding"];

  if (o)
    {
      return [o unsignedIntValue];
    }
 
  // Default value for the Content-Transfer-Encoding.
  // See RFC2045 - 6.1. Content-Transfer-Encoding Syntax.
  return PantomimeEncodingNone;
}

- (void) setContentTransferEncoding: (PantomimeEncoding) theEncoding
{
  [_headers setObject: [NSNumber numberWithUnsignedInt: (unsigned)theEncoding]  forKey: @"Content-Transfer-Encoding"];
}


//
//
//
- (NSString *) filename
{
  return [_parameters objectForKey: @"filename"];
  //return _filename;
}

- (void) setFilename: (NSString *) theFilename
{
  if (theFilename && ([theFilename length] > 0))
    {
      //ASSIGN(_filename, theFilename);
      [_parameters setObject: theFilename  forKey: @"filename"];
    }
  else
    {
      //ASSIGN(_filename, @"unknown");
      [_parameters setObject: @"unknown"  forKey: @"filename"];
    }
}


//
//
//
- (PantomimeMessageFormat) format
{
  id o;

  o = [_parameters objectForKey: @"format"];

  if (o)
    {
      return [o unsignedIntValue];
    }

  return PantomimeFormatUnknown;
}

- (void) setFormat: (PantomimeMessageFormat) theFormat
{
  [_parameters setObject: [NSNumber numberWithUnsignedInt: theFormat]  forKey: @"format"];
}


//
//
//
- (NSUInteger) lineLength
{
  return _line_length;
}

- (void) setLineLength: (NSUInteger) theLineLength
{
  _line_length = theLineLength;
}


//
// This method is used to verify if the part is of the following primaryType / subType
//
- (BOOL) isMIMEType: (NSString *) thePrimaryType
	    subType: (NSString *) theSubType 
{
  NSString *aString;

  if (![self contentType]) 
    {
      NSDebugLog(@"CWPart isMimeType: %@ subType: %@ - contentType is nil", thePrimaryType, theSubType);
      return NO;
    }

  if ([theSubType compare: @"*"] == NSOrderedSame)
    {
      if ([[self contentType] hasCaseInsensitivePrefix: thePrimaryType])
	{
	  return YES;
	}
    }
  else
    {
      aString = [NSString stringWithFormat: @"%@/%@", thePrimaryType, theSubType];
     
      if ([aString caseInsensitiveCompare: [self contentType]] == NSOrderedSame)
	{
	  return YES;
	}
    }
  
  return NO;
}


//
//
//
- (unsigned long) size
{
  return _size;
}

- (void) setSize: (unsigned long) theSize
{
  _size = theSize;
}


//
//
//
- (NSData *) dataValue
{
  NSMutableData *aMutableData;
  NSMutableArray *allKeys;
  NSData *aDataToSend;
  NSArray *allLines;
  NSString *aFilename; 
  NSUInteger i, count;

  aMutableData = [[NSMutableData alloc] init];
  
  // We start off by exactring the filename of the part.
  if ([[self filename] is7bitSafe])
    {
      aFilename = [self filename];
    }
  else
    {
      aFilename = [[NSString alloc] initWithData: [CWMIMEUtility encodeWordUsingQuotedPrintable: [self filename]
								 prefixLength: 0]
				    encoding: NSASCIIStringEncoding];
      AUTORELEASE(aFilename);
    }

  // We encode our Content-Transfer-Encoding header.
  if ([self contentTransferEncoding] != PantomimeEncodingNone)
    {
      [aMutableData appendCFormat: @"Content-Transfer-Encoding: %@%s",
		    [NSString stringValueOfTransferEncoding: [self contentTransferEncoding]],
		    LF];
    }

  // We encode our Content-ID header.
  if ([self contentID])
    {
      [aMutableData appendCFormat: @"Content-ID: %@%s", [self contentID], LF];
    }
  
  // We encode our Content-Description header.
  if ([self contentDescription])
    {
      [aMutableData appendCString: "Content-Description: "];
      [aMutableData appendData: [CWMIMEUtility encodeWordUsingQuotedPrintable: [self contentDescription]
					       prefixLength: 21]];
      [aMutableData appendCString: LF];
    }

  // We now encode the Content-Type header with its parameters.
  [aMutableData appendCFormat: @"Content-Type: %@", [self contentType]];

  if ([self charset])
    {
      [aMutableData appendCFormat: @"; charset=\"%@\"", [self charset]];
    }

  if ([self format] == PantomimeFormatFlowed &&
      ([self contentTransferEncoding] == PantomimeEncodingNone || [self contentTransferEncoding] == PantomimeEncoding8bit))
    {
      [aMutableData appendCString: "; format=\"flowed\""];
    }

  if (aFilename && [aFilename length])
    {
      [aMutableData appendCFormat: @"; name=\"%@\"", aFilename];
    }

  // Before checking for all other parameters, we check for the boundary one
  // If we got a CWMIMEMultipart instance as the content but no boundary
  // was set, we create a boundary and we set it.
  if ([self boundary] || [_content isKindOfClass: [CWMIMEMultipart class]])
    {
      if (![self boundary])
	{
	  [self setBoundary: [CWMIMEUtility globallyUniqueBoundary]];
	}

      [aMutableData appendCFormat: @";%s\tboundary=\"",LF];
      [aMutableData appendData: [self boundary]];
      [aMutableData appendCString: "\""];
    }
  
  // We now check for any other additional parameters. If we have some,
  // we add them one per line. We first REMOVE what we have added! We'll
  // likely and protocol= here.
  allKeys = [NSMutableArray arrayWithArray: [_parameters allKeys]];
  [allKeys removeObject: @"boundary"];
  [allKeys removeObject: @"charset"];
  [allKeys removeObject: @"filename"];
  [allKeys removeObject: @"format"];
  
  for (i = 0; i < [allKeys count]; i++)
    {
      [aMutableData appendCFormat: @";%s", LF];
      [aMutableData appendCFormat: @"\t%@=\"%@\"", [allKeys objectAtIndex: i], [_parameters objectForKey: [allKeys objectAtIndex: i]]];
    }

  [aMutableData appendCString: LF];

  // We encode our Content-Disposition header. We ignore other parameters
  // (other than the filename one) since they are pretty much worthless.
  // See RFC2183 for details.
  if ([self contentDisposition] == PantomimeAttachmentDisposition)
    {
      [aMutableData appendCString: "Content-Disposition: attachment"];

      if (aFilename && [aFilename length])
	{
	  [aMutableData appendCFormat: @"; filename=\"%@\"", aFilename];
	}
      
      [aMutableData appendCString: LF];
    }

  if ([_content isKindOfClass: [CWMessage class]])
    {
      aDataToSend = [(CWMessage *)_content rawSource];
    }
  else if ([_content isKindOfClass: [CWMIMEMultipart class]])
    {
      CWMIMEMultipart *aMimeMultipart;
      NSMutableData *md;
      CWPart *aPart;
      
      md = [[NSMutableData alloc] init];
      aMimeMultipart = (CWMIMEMultipart *)_content;
      count = [aMimeMultipart count];
      
      for (i = 0; i < count; i++)
	{
	  aPart = [aMimeMultipart partAtIndex: i];
	  
	  if (i > 0)
	    {
	      [md appendBytes: LF  length: strlen(LF)];
	    }
	  
	  [md appendBytes: "--"  length: 2];
	  [md appendData: [self boundary]];
	  [md appendBytes: LF  length: strlen(LF)];
	  [md appendData: [aPart dataValue]];
	}
      
      [md appendBytes: "--"  length: 2];
      [md appendData: [self boundary]];
      [md appendBytes: "--"  length: 2];
      [md appendBytes: LF  length: strlen(LF)];
	  
      aDataToSend = AUTORELEASE(md);
    }
  else
    {
      aDataToSend = (NSData *)_content;
    }

  // We separe our part's headers from the content
  [aMutableData appendCFormat: @"%s", LF];

  // We now encode our content the way it was specified
  if ([self contentTransferEncoding] == PantomimeEncodingQuotedPrintable)
    {
      aDataToSend = [aDataToSend encodeQuotedPrintableWithLineLength: 72  inHeader: NO];
    }
  else if ([self contentTransferEncoding] == PantomimeEncodingBase64)
    {
      aDataToSend = [aDataToSend encodeBase64WithLineLength: 72];
    }
  else if (([self contentTransferEncoding] == PantomimeEncodingNone || [self contentTransferEncoding] == PantomimeEncoding8bit) &&
	   [self format] == PantomimeFormatFlowed)
    {
      NSUInteger limit;
      
      limit = _line_length;
      
      if (limit < 2 || limit > 998)
	{
	  limit = 72;
	}
      
      aDataToSend = [aDataToSend wrapWithLimit: limit];
    }

  allLines = [aDataToSend componentsSeparatedByCString: "\n"];
  count = [allLines count];

  for (i = 0; i < count; i++)
    {
      if (i == count-1 && [[allLines objectAtIndex: i] length] == 0)
	{
	  break;
	}
      
      [aMutableData appendData: [allLines objectAtIndex: i]];
      [aMutableData appendBytes: LF  length: 1];
    }
  
  return AUTORELEASE(aMutableData);
}


//
//
//
- (NSData *) boundary
{
  return [_parameters objectForKey: @"boundary"];
}

- (void) setBoundary: (NSData *) theBoundary
{
  if (theBoundary)
    {
      [_parameters setObject: theBoundary  forKey: @"boundary"];
    }
}


//
//
//
- (NSData *) protocol
{
  return [_parameters objectForKey: @"protocol"];
  //return _protocol;
}

- (void) setProtocol: (NSData *) theProtocol
{
  //ASSIGN(_protocol, theProtocol);
  if (theProtocol)
    {
      [_parameters setObject: theProtocol  forKey: @"protocol"];
    }
}


//
//
//
- (NSString *) charset
{
  return [_parameters objectForKey: @"charset"];
}

- (void) setCharset: (NSString *) theCharset
{
  if (theCharset)
    {
      [_parameters setObject: theCharset  forKey: @"charset"];
    }
}


//
//
//
- (NSString *) defaultCharset
{
  return _defaultCharset;
}


//
//
//
- (void) setDefaultCharset: (NSString *) theCharset
{
  ASSIGN(_defaultCharset, theCharset);
}


//
//
//
- (void) setHeadersFromData: (NSData *) theHeaders
{
  NSAutoreleasePool *pool;
  NSArray *allLines;
  NSUInteger i, count;
  
  if (!theHeaders || [theHeaders length] == 0)
    {
      return;
    }

  // We initialize a local autorelease pool
  pool = [[NSAutoreleasePool alloc] init];

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

      if ([aLine hasCaseInsensitiveCPrefix: "Content-Description"])
	{
	  [CWParser parseContentDescription: aLine  inPart: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Content-Disposition"])
	{
	  [CWParser parseContentDisposition: aLine  inPart: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Content-ID"])
	{
	  [CWParser parseContentID: aLine  inPart: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Content-Length"])
	{
	  // We just ignore that for now.
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Content-Transfer-Encoding"])
	{
	  [CWParser parseContentTransferEncoding: aLine  inPart: self];
	}
      else if ([aLine hasCaseInsensitiveCPrefix: "Content-Type"])
	{
	  [CWParser parseContentType: aLine  inPart: self];
	}
    }

  RELEASE(pool);
}


//
//
//
- (id) parameterForKey: (NSString *) theKey
{
  return [_parameters objectForKey: theKey];
}

- (void) setParameter: (id) theParameter  forKey: (NSString *) theKey
{
  if (theParameter)
    {
      [_parameters setObject: theParameter  forKey: theKey];
    }
  else
    {
      [_parameters removeObjectForKey: theKey];
    }
}

//
//
//
- (NSDictionary *) allHeaders
{
  return _headers;
}

//
//
//
- (id) headerValueForName: (NSString *) theName
{
  NSArray *allKeys;
  NSUInteger count;

  allKeys = [_headers allKeys];
  count = [allKeys count];

  while (count--)
    {
      if ([[allKeys objectAtIndex: count] caseInsensitiveCompare: theName] == NSOrderedSame)
	{
	  return [_headers objectForKey: [allKeys objectAtIndex: count]];
	}
    }
  
  return nil;
}

//
//
//
- (void) setHeaders: (NSDictionary *) theHeaders
{
  if (theHeaders)
    {
      [_headers addEntriesFromDictionary: theHeaders];
    }
  else
    {
      [_headers removeAllObjects];
    }
}
@end
