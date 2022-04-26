/*
**  CWPart.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2017      Riccardo Mottola
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

#ifndef _Pantomime_H_CWPart
#define _Pantomime_H_CWPart

#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

#include <Pantomime/CWConstants.h>

/*!
  @class CWPart
  @discussion This class defines what Internet messages are composed of.
              An Internet message is composed of various parts which can
	      be text parts, images, PDF documents and so on. Even a message
	      is a part, with additional headers (like "From:", "Subject:"
	      and so on). CWMessage is a superclass of CWPart.
*/
@interface CWPart : NSObject <NSCoding>
{
  @protected    
    NSMutableDictionary *_parameters;
    NSMutableDictionary *_headers;
    NSString *_defaultCharset;
    NSObject *_content;

    NSUInteger _line_length;
    unsigned long _size;
}

/*!
  @method initWithData:
  @discussion This method is used to initialize the CWPart instance
              with the specified data. It splits the header
	      part with the content part and calls -setHeadersFromData:
	      with the header part and CWMIMEUtility: +setContentFromRawSource: inPart:
	      with the content part. This method will recursively go in
	      sub-parts (if needed) and initilize them also.
  @param theData The bytes to use.
  @result A CWPart instance, nil on error.
*/
- (id) initWithData: (NSData *) theData;

/*!
  @method initWithData: charset:
  @discussion This method acts like -initWithData: but it uses
              <i>theCharset</i> instead of the Part's charset
	      (found in theData).
  @param theData The bytes to use.
  @param theCharset The charset to force.
  @result A CWPart instance, nil on error.
*/
- (id) initWithData: (NSData *) theData
            charset: (NSString *) theCharset;

/*!
  @method setHeadersFromData:
  @discussion This method initalize all the headers of a part
              from the raw data source. It replaces previously 
	      defined values of headers found in <i>theHeaders</i>.
  @param theHeaders The bytes to use.
*/
- (void) setHeadersFromData: (NSData *) theHeaders;

/*!
  @method contentType
  @discussion This method is used to get the value of the
              receiver's "Content-Type" header. If none is
	      specified, nil will be returned. It's up to the
	      callee to use whatever charset it wants. Section
	      5.2 or RFC2045 recommends to use "text/plain" in
	      this case.
  @result The value. If none was set, nil will
          be returned.
*/ 
- (NSString *) contentType;

/*!
  @method setContentType:
  @discussion This method is used to set the value of
              the receiver's "Content-Type" header.
  @param theContentType The "Content-Type" value.
*/
- (void) setContentType: (NSString*) theContentType;

/*!
  @method contentID
  @discussion This method is used to get the value of the
              receiver's "Content-ID" header.
  @result The value. If none was set, nil will
          be returned.
*/ 
- (NSString *) contentID;

/*!
  @method setContentID:
  @discussion This method is used to set the value of
              the receiver's "Content-ID" header.
  @param theContentID The "Content-ID" value.
*/                 
- (void) setContentID: (NSString *) theContentID;
 
/*!
  @method contentDescription
  @discussion This method is used to get the value of the
              receiver's "Content-Description" header.
  @result The value. If none was set, nil will
          be returned.
*/ 
- (NSString *) contentDescription;

/*!
  @method setContentDescription:
  @discussion This method is used to set the value of
              the receiver's "Content-Description" header.
  @param theContentDescription The "Content-Description" value.
*/                              
- (void) setContentDescription: (NSString *) theContentDescription;

/*!
  @method contentDisposition
  @discussion This method is used to get the value of the
              receiver's "Content-Disposition" header.
  @result The value. If none was set, PantomimeInlineDisposition
          will be returned.
*/
- (PantomimeContentDisposition) contentDisposition;

/*!
  @method setContentDisposition:
  @discussion This method is used to set the value of
              the receiver's "Content-Disposition" header.
  @param theContentDisposition The "Content-Disposition" value.
*/                                 
- (void) setContentDisposition: (PantomimeContentDisposition) theContentDisposition; 

/*!
  @method contentTransferEncoding
  @discussion This method is used to get the value of the
              receiver's "Content-Transfer-Encoding" header.
  @result The value. If none was set, PantomimeEncodingNone
          will be returned.
*/
- (PantomimeEncoding) contentTransferEncoding;

/*!
  @method setContentTransferEndocing:
  @discussion This method is used to set the value of
              the receiver's "Content-Transfer-Encoding" header.
  @param theEncoding The "Content-Transfer-Encoding" value. Accepted
                     values are part of the PantomimeEncoding enum.
*/                 
- (void) setContentTransferEncoding: (PantomimeEncoding) theEncoding;

/*!
  @method filename
  @discussion This method is used to get the name of the receiver's
              file, if any.
  @result The name of the file, nil if none was specified.
*/
- (NSString *) filename;

/*!
  @method setFilename:
  @discussion This method is used to set the name of the receiver's file.
  @param theFilename The name of the file. If nil is passed or if
                     the length of the string is 0, "unknown" will
		     be set as the filename.
*/
- (void) setFilename: (NSString *) theFilename;     

/*!
  @method format
  @discussion This method is used to obtain the format of the receiver.
              Possible values are part of the PantomimeMessageFormat.
	      See RFC 2646 for a detailed description of the "flowed" format.
  @result The format, PantomimeFormatUnknown if no value was previously set.
*/
- (PantomimeMessageFormat) format;

/*!
  @method setFormat:
  @discussion This method is used to set the format of the receiver.
              Accepted values are part of the PantomimeMessageFormat enum.
  @param theFormat The format to use.
*/
- (void) setFormat: (PantomimeMessageFormat) theFormat;

/*!
  @method lineLength
  @discussion This method is used to return the maximum length that
              a line can use in a text part.
  @result The length, 0 if not defined.
*/
- (NSUInteger) lineLength;

/*!
  @method setLineLength:
  @discussion This method is used to set the maximum length of a
              line that can be used for a text part.
  @param theLineLength The length.
*/
- (void) setLineLength: (NSUInteger) theLineLength;

/*!
  @method isMIMEType: subType:
  @discussion This method is used to verify if the receiver matches
              a specific MIME type. The "*" wildcard can be used
	      for the sub-type.
  @param thePrimaryType The left part of the MIME type.
  @param theSubType The right part of the MIME type.
  @result YES if it matches, NO otherwise.
*/
- (BOOL) isMIMEType: (NSString *) thePrimaryType
            subType: (NSString *) theSubType;

/*!
  @method content
  @discussion This method is used to obtain the decoded content
              of the receiver. The returned value can be a NSString
	      instance, a NSData instance, a CWMIMEMultipart instance
	      or a CWMessage instance.
  @result The decoded content of the part.
*/
- (NSObject *) content;

/*!
  @method setContent:
  @discussion This method is used to set the content of the receiver.
              The content will later be correctly encoded before the
	      message is submitted or saved on disk (using -dataValue).
	      Accepted values are instances of NSData, CWMIMEMultipart
	      or CWMessage otherwise, a NSInvalidArgumentException
	      will be thrown.
  @param theContent The content of the part.
*/
- (void) setContent: (NSObject *) theContent;

/*!
  @method size
  @discussion This method is used to obtain the receiver's size
              (total number of bytes of its raw representation).
  @result The size of the receiver.
*/
- (unsigned long) size;

/*!
  @method setSize:
  @discussion This method is used to set the receiver's size.
  @param theSize The value of the size.
*/
- (void) setSize: (unsigned long) theSize;

/*!
  @method dataValue
  @discussion This method is used to encoded the receiver's using
              the MIME standard before it is ready for submisssion
	      (using a Transport method) or being saved on disk.
	      The CWMessage class overwrites this method in order
	      to add Message-specific headers such as "From",
	      "Subject" and so on.
  @result The encoded CWPart instance, as a NSData instance.
*/
- (NSData *) dataValue;

/*!
  @method boundary
  @discussion This method is used to get the boundary that separates
              parts that compose a multipart composite part.
  @result The boundary as a NSData instance, nil if none was set.
*/
- (NSData *) boundary;

/*!
  @method setBoundary:
  @discussion This method is used to set the boundary used to separate
              parts that compose a multipart composite part message.
  @param theBoundary The value of the boundary.
*/
- (void) setBoundary: (NSData *) theBoundary;

/*!
  @method protocol
  @discussion This method is used to obtain the value of the "protocol"
              parameter found in some Content-Type headers. This parameter
	      is often present in PGP encoded messages.
  @result The value of the "protocol" parameter, nil if none was set.
*/
- (NSData *) protocol;

/*!
  @method setProtocol:
  @discussion This method is used to set the value of the "protocol"
              parameter. This parameter will be added to the ones
	      found in the Content-Type header in -dataValue.
  @param theProtocol The value of the "protocol" parameter.
*/
- (void) setProtocol: (NSData *) theProtocol;

/*!
  @method charset
  @discussion This method is used to obtain the value of the "charset"
              parameter found in the Content-Type header.
  @result The value of the "charset" parameter, "us-ascii" if none was set.
*/
- (NSString *) charset;

/*!
  @method setCharset:
  @discussion This method is used to set the value of the "charset" parameter
              found in the Content-Type header.
  @param theCharset The charset to use.
*/
- (void) setCharset: (NSString *) theCharset;

/*!
  @method defaultCharset
  @discussion This method is used to get the charset that will be
              enforced for usage when decoding the part.
  @result The enforced charset.
*/
- (NSString *) defaultCharset;

/*!
  @method setDefaultCharset:
  @discussion This method is used to set the charset that will be
              enforced for usage when the part is being decoded.
  @param theCharset The charset to force.
*/
- (void) setDefaultCharset: (NSString *) theCharset;

/*!
  @method parameterForKey:
  @discussion This method is used to obtain a parameter value
              based on its name. The name serves as the key.
	      Parameters are only part of the Content-Type
	      header field.They are NOT part of the
	      Content-Disposition header.
  @param theKey  The key for which the value will be returned.
  @result The parameter value, nil if non-existent.
*/
- (id) parameterForKey: (NSString *) theKey;

/*!
  @method setPrameter:forKey:
  @discussion This method is used to set a parameter value
              based on its name. The name serves as the key.
	      Parameters are only part of the Content-Type
	      header field. They are NOT part of the
	      Content-Disposition header.
  @param theParameter The value of the parameter. A nil value
                      will remove any existing defined value
		      for the specified key,
  @param theKey  The key for which the value will be set.
*/
- (void) setParameter: (id) theParameter  forKey: (NSString *) theKey;

/*!
  @method allHeaders
  @discussion This method is used to return all header names / values.
  @result The NSDictionary holding everything.
*/
- (NSDictionary *) allHeaders;

/*!
  @method headerValueForName:
  @discussion This method is used to obtain the value
              of the header specified by <i>theName</i>. The search
	      is performed in a case-insensitive way.
  @param theName The name of the header. For example, it could be "Date".
  @result The value of the header.
*/
- (id) headerValueForName: (NSString *) theName;

/*!
  @method setHeaders:
  @discussion This method is used to add the headers of
              <i>theHeaders</i> to the list of headers
	      of the receiver.
  @param theHeaders The headers to add.
*/
- (void) setHeaders: (NSDictionary *) theHeaders;

@end

#endif // _Pantomime_H_CWPart
