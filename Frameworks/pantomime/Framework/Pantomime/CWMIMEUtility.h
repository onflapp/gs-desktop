/*
**  CWMIMEUtility.h
**
**  Copyright (c) 2001-2004 Ludovic Marcotte
**  Copyright (C) 2018      Riccardo Mottola
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

#ifndef _Pantomime_H_CWMIMEUtility
#define _Pantomime_H_CWMIMEUtility

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

#include <Pantomime/CWConstants.h>

@class CWMessage;
@class CWMIMEMultipart;
@class CWPart;


/*!
  @class CWMIMEUtility
  @abstract MIME utility class.
  @discussion This class provides static methods to deal with the MIME standard.
              Normally, you should not invoke any of those methods directly.
*/
@interface CWMIMEUtility: NSObject


/*!
  @method decodeHeader: charset:
  @discussion This method is used to decode a header value
              encoded in base64 or quoted-printable. RFC 2047
	      describes how those headers should be encoded
	      (in particular, "2. Syntax of encoded-words").
              If <i>theCharset</i> is not nil, it is used to
	      decode the header. Otherwise, the charset used
	      in the header is used.
  @param theData The data to decode.
  @param theCharset The charset to force.
  @result The decoded header.
*/
+ (NSString *) decodeHeader: (NSData *) theData
                    charset: (NSString *) theCharset;

/*!
  @method encodeHeader: charset: encoding:
  @discussion This method is used to encode a header value
              in the format specified by RFC 2047 (in particular,
	      "2. Syntax of encoded-words").
  @param theText The text to encode.
  @param theCharset The charset to use. For example, "iso-8859-1".
  @param theEncoding The encoding to use. Valid values are
                     part of the PantomimeEncoding enum.
  @result The encoded data.
*/
+ (NSData *) encodeHeader: (NSString *) theText
                  charset: (NSString *) theCharset
                 encoding: (PantomimeEncoding) theEncoding;

+ (NSData *) encodeWordUsingBase64: (NSString *) theWord
                      prefixLength: (int) thePrefixLength;

+ (NSData *) encodeWordUsingQuotedPrintable: (NSString *) theWord
                               prefixLength: (NSUInteger) thePrefixLength;

/*!
  @method globallyUniqueBoundary
  @discussion This method is used to generate a unique MIME boundary
              (or any kind of boundary).
  @result The boundary, as a NSData instance.
*/
+ (NSData *) globallyUniqueBoundary;

/*!
  @method globallyUniqueID
  @discussion This method is used to generate a unique ID that CWMessage (or CWPart)
              instances use as their unique ID. (Message-ID, Content-ID, etc.)
  @result The unique ID, as a NSData instance.
*/
+ (NSData *) globallyUniqueID;

/*!
  @method compositeMessageContentFromRawSource:
  @discussion This method is used to obtain a composite type (message)
              from <i>theData</i>.
  @param theData The bytes to use.
  @result A Message instance, nil on error.
*/
+ (CWMessage *) compositeMessageContentFromRawSource: (NSData *) theData;

/*!
  @method compositeMultipartContentFromRawSource:boundary:
  @discussion This method is used to obtain a composity type (multipart)
              from <i>theData</i>, using <i>theBoundary</i>.
  @param theData The bytes to use.
  @param theBoundary The boundary to use.
  @result A CWMIMEMultipart instance, nil on error.
*/
+ (CWMIMEMultipart *) compositeMultipartContentFromRawSource: (NSData *) theData
                                                    boundary: (NSData *) theBoundary;

/*!
  @method discreteContentFromRawSource: encoding: charset: part:
  @discussion This method is used to obtain discrete types such as
              text/, application/, image/, etc. It might return a NSString
	      or a NSData object (if the encoding is PantomimeEncodingBase64).
  @param theData The bytes to use.
  @param theEncoding The encoding to use. Valid values are
                     part of the PantomimeEncoding enum.
  @result A NSData instance.
*/
+ (id) discreteContentFromRawSource: (NSData *) theData
                           encoding: (PantomimeEncoding) theEncoding;

/*!
  @method setContentFromRawSource: inPart:
  @discussion This method is used to initialize a message, or a part
              of the message using <i>theData</i>. The CWPart's Content-Type
	      MUST be defined BEFORE calling this function otherwise
              the content will be considered as a pure string.
  @param theData The bytes to use.
  @param thePart The part to use, which can be a Part or a Message instance.
*/
+ (void) setContentFromRawSource: (NSData *) theData
                          inPart: (CWPart *) thePart;

/*!
  @method plainTextContentFromPart:
  @discussion This method is used to obtain a pure "text" part.
              For example, it can be used to strip any
	      HTML content from a part in order to get only
	      the text.
  @param thePart The Part instance from which to obtain the text.
  @result The pure "text".
*/
+ (NSData *) plainTextContentFromPart: (CWPart *) thePart;

@end

#endif // _Pantomime_H_CWMIMEUtility
