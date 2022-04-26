/*
**  CWParser.h
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

#ifndef _Pantomime_H_CWParser
#define _Pantomime_H_CWParser

#import <Foundation/NSData.h>
#import <Foundation/NSObject.h>

#include <Pantomime/CWConstants.h>

@class CWPart;
@class CWMessage;

/*!
  @class CWParser
  @abstract Utility class providing class methods to parse messages.
  @discussion This class provide useful methods (all class methods) to
              parse messages from their raw representation.
*/
@interface CWParser: NSObject

/*!
  @method parseContentDescription: inPart:
  @discussion This method is used to parse a Content-Disposition header line.
  @param theLine The line to parse.
  @param thePart The part in which to store the parsed value, if any.
*/
+ (void) parseContentDescription: (NSData *) theLine
                          inPart: (CWPart *) thePart;

/*!
  @method parseContentDisposition: inPart:
  @discussion This method is used to parse a Content-Disposition header line.
              It supports the following parameters: "filename" ; case-insensitive
  @param theLine The line to parse.
  @param thePart The part in which to store the parsed value, if any.
*/
+ (void) parseContentDisposition: (NSData *) theLine
                          inPart: (CWPart *) thePart;

/*!
  @method parseContentID: inPart:
  @discussion This method is used to parse a Content-ID header line.
  @param theLine The line to parse.
  @param thePart The part in which to store the parsed value, if any.
*/
+ (void) parseContentID: (NSData *) theLine
                 inPart: (CWPart *) thePart;

/*!
  @method parseContentTransferEncoding: inPart:
  @discussion This method is used to parse a Content-Transfer-Encoding header line.
              It supports: "7bit" (or none) ;  case-insensitive
               "quoted-printable"
               "base64"
               "8bit"
               "binary"
  @param theLine The line to parse.
  @param thePart The part in which to store the parsed value, if any.
*/
+ (void) parseContentTransferEncoding: (NSData *) theLine
                               inPart: (CWPart *) thePart;

/*!
  @method parseContentType: inPart:
  @discussion This method is used to parse a Content-Type header line.
              This method parses correct lines like:  
              "Content-Type: text/plain",
              "Content-Type: Text/plain;"
              "Content-Type: text/plain; charset="iso-8859-1"",
              "Content-Type: text",
              "Content-Type:    text/plain", and so on.
              This method also parses (if it needs to) the following parameters: 
              "boundary" (if Content-Type is multipart/something), "charset" (if Content-Type is text/plain)
              "name", "format" and so on.
  @param theLine The line to parse.
  @param thePart The part in which to store the parsed values, if any.
*/
+ (void) parseContentType: (NSData *) theLine
                   inPart: (CWPart *) thePart;

/*!
  @method parseDate: inMessage:
  @discussion This method is used to parse a Date header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (void) parseDate: (NSData *) theLine
         inMessage: (CWMessage *) theMessage;

/*!
  @method parseDestination: forType: inMessage:
  @discussion This method is used to parse the To: Cc: Bcc: headers value.
  @param theLine The line to parse.
  @param theType The type to parse (one of the values of the PantomimeRecipientType enum)
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (NSData *) parseDestination: (NSData *) theLine
                      forType: (PantomimeRecipientType) theType
                    inMessage: (CWMessage *) theMessage
                        quick: (BOOL) theBOOL;

/*!
  @method parseFrom: inMessage:
  @discussion This method is used to parse a From header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (NSData *) parseFrom: (NSData *) theLine
             inMessage: (CWMessage *) theMessage
                 quick: (BOOL) theBOOL;

/*!
  @method parseInReplyTo: inMessage:
  @discussion This method is used to parse a In-Reply-To header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (NSData *) parseInReplyTo: (NSData *) theLine
                  inMessage: (CWMessage *) theMessage
                      quick: (BOOL) theBOOL;

/*!
  @method parseMessageID: inMessage:
  @discussion This method is used to parse a Message-ID header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (NSData *) parseMessageID: (NSData *) theLine
                  inMessage: (CWMessage *) theMessage
                      quick: (BOOL) theBOOL;

/*!
  @method parseMIMEVersion: inMessage:
  @discussion This method is used to parse a MIME-Version header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (void) parseMIMEVersion: (NSData *) theLine
                inMessage: (CWMessage *) theMessage;

/*!
  @method parseReferences: inMessage:
  @discussion This method is used to parse a References header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (NSData *) parseReferences: (NSData *) theLine
                   inMessage: (CWMessage *) theMessage
                       quick: (BOOL) theBOOL;

/*!
  @method parseReply: inMessage:
  @discussion This method is used to parse a Reply-To header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (void) parseReplyTo: (NSData *) theLine
            inMessage: (CWMessage *) theMessage;

/*!
  @method parseResentFrom: inMessage:
  @discussion This method is used to parse a Resent-From header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (void) parseResentFrom: (NSData *) theLine
               inMessage: (CWMessage *) theMessage;

/*!
  @method parseStatus: inMessage:
  @discussion This method is used to parse a Status header line. This
              header is commonly added by some MUA:s like Pine.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (void) parseStatus: (NSData *) theLine
           inMessage: (CWMessage *) theMessage;

/*!
  @method parseXStatus: inMessage:
  @discussion This method is used to parse a X-Status header line. This
              header is commonly added by some MUA:s like Pine.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (void) parseXStatus: (NSData *) theLine
            inMessage: (CWMessage *) theMessage;

/*!
  @method parseSubject: inMessage:
  @discussion This method is used to parse a Subject header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (NSData *) parseSubject: (NSData *) theLine
                inMessage: (CWMessage *) theMessage
                    quick: (BOOL) theBOOL;

/*!
  @method parseUnknownHeader: inMessage:
  @discussion This method is used to parse the headers that we don't "support natively".
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (void) parseUnknownHeader: (NSData *) theLine
                  inMessage: (CWMessage *) theMessage;

/*!
  @method parseOrganization: inMessage:
  @discussion This method is used to parse a Organization header line.
  @param theLine The line to parse.
  @param theMessage The message in which to store the parsed value, if any.
*/
+ (void) parseOrganization: (NSData *) theLine
                 inMessage: (CWMessage *) theMessage;

@end

#endif // _Pantomime_H_CWParser
