/*
**  NSData+Extensions.h
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

#ifndef _Pantomime_H_NSData_Extensions
#define _Pantomime_H_NSData_Extensions

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

#import "CWConstants.h"

/*!
  @category NSData (PantomimeExtensions)
  @abstract Pantomime extensions to NSData.
  @discussion This category provides useful extensions for handling
              NSData objects.
*/
@interface NSData (PantomimeExtensions)

/*!
  @method decodeBase64
  @abstract Decode using the base64 encoding.
  @discussion This method is used to decode data that has been encoded
              using the base64 method.
  @result Returns the decoded bytes, as a NSData instance.
*/
- (NSData *) decodeBase64;

/*!
  @method encodeBase64WithLineLength:
  @abstract Encoding the bytes using the base64 encoding
  @discussion Pending.
  @param theLength Specifies the length of the lines if wrapping
                   should be done. 0 disables any wrapping.
  @result Returns a NSData object on success, nil on error.
*/
- (NSData *) encodeBase64WithLineLength: (NSUInteger) theLength;

/*!
  @method unfoldLines
  @abstract Unfold lines contained in this object.
  @discussion This method is used to replace all occurences
              of "\n " or "\n\t" by "\n".
  @result Returns a new NSData object.
*/
- (NSData *) unfoldLines;

/*!
  @method decodeQuotedPrintableInHeader
  @abstract Decode using the quoted-printable encoding.
  @discussion This method is used to decode data that has been
              encoded using the quoted-printable method.
  @param aBOOL Specifies if we are decoding data from
               a message header, or not.
  @result Returns a new NSData object.
*/
- (NSData *) decodeQuotedPrintableInHeader: (BOOL) aBOOL;

/*!
  @method encodeQuotedPrintableWithLineLength:inHeader:
  @abstract Encoding the bytes using the quoted-printable encoding
  @discussion Pending.
  @param aBOOL Specifies if we are encoding data from
               a message header, or not.
  @param theLength Specifies the length of the lines if wrapping
                   should be done. 0 disables any wrapping.
  @result Returns a NSData object.
*/
- (NSData *) encodeQuotedPrintableWithLineLength: (NSUInteger) theLength
                                        inHeader: (BOOL) aBOOL;
/*!
  @method rangeOfData:
  @discussion This method searches for <i>theData</i> in the receiver
              and returns the associated NSRange.
  @param theData The data to search for in the receiver.
  @result The associated range.
*/
-(NSRange) rangeOfData: (NSData *) theData;

/*!
  @method rangeOfCString:
  @discussion Invokes rangeOfCString:options:range: with no option
              and the complete range.
  @param theCString The C string to search for.
  @result The associated range of the C string in the receiver.
*/
-(NSRange) rangeOfCString: (const char *) theCString;

/*!
  @method rangeOfCString:
  @discussion Invokes rangeOfCString:options:range: with <i>theOptions</i>
              and the complete range.
  @param theCString The C string to search for.
  @param theOptions The options used during the search.
  @result The associated range of the C string in the receiver.
*/
-(NSRange) rangeOfCString: (const char *) theCString
                  options: (NSUInteger) theOptions;

/*!
  @method rangeOfCString:
  @discussion Search for <i>theCString<i> using <i>theOptions</i>
              and <i>theRange</i> in the receiver.
  @param theCString The C string to search for.
  @param theOptions The options used during the search.
  @param theRange The range to use when performing the search.
  @result The associated range of the C string in the receiver.
*/
-(NSRange) rangeOfCString: (const char *) theCString
                  options: (NSUInteger) theOptions
	            range: (NSRange) theRange;

/*!
  @method subdataFromIndex:
  @discussion This method is used to obtain the subdata from <i>theIndex</i>
              in the receiver. The byte at <i>theIndex</i> is part of the
	      returned NSData instance.
  @param theIndex The index used to get the subdata from.
  @result The subdata.
*/
- (NSData *) subdataFromIndex: (NSUInteger) theIndex;

/*!
  @method subdataToIndex:
  @discussion This method is used to obtain the subdata to <i>theIndex</i>
              from the receiver. The byte at <i>theIndex</i> is not included in
	      returned NSData instance.
  @param theIndex The index used to get the subdata to.
  @result The subdata.
*/
- (NSData *) subdataToIndex: (NSUInteger) theIndex;

/*!
  @method dataByTrimmingWhiteSpaces
  @discussion This method is used to trim the leading and trailing
              spaces (space characters, tabs, newlines, carriage returns
              or other characters with no visible representation)
              from the receiver.
  @result The trimmed data.
*/
- (NSData *) dataByTrimmingWhiteSpaces;

/*!
  @method dataFromQuotedData
  @discussion This method returns an unquoted data if the
              data has a leading AND trailing quote.
  @result The unquoted data or the original if it does not
          match the criteria.
*/
- (NSData *) dataFromQuotedData;

/*!
  @method dataFromSemicolonTerminatedData
  @discussion This method returns the data by omitting the
              ending semicolon, if present.
  @result The data without the ending semicolon.
*/
- (NSData *) dataFromSemicolonTerminatedData;

/*!
  @method dataByRemovingLineFeedCharacters
  @discussion This method is used to return the receiver without
              any occurences of the line feed (LF, control-J, ASCII 10)
	      character.
  @result The data withtout line feed characters.
*/
- (NSData *) dataByRemovingLineFeedCharacters;

/*!
  @method indexOfCharacter:
  @discussion This method finds the first occurence of
              the character in the receiver and returns its index (zero-based)
  @param theCharacter The caracter to be searched for.
  @result The index of the character, NSNotFound if it's not found in the receiver.
*/
- (NSUInteger) indexOfCharacter: (unichar) theCharacter;

/*!
  @method hasCPrefix:
  @discussion This method is used to verify if the receiver has <i>theCString</i>
              as a prefix.
  @param theCString The C string to look for.
  @result YES if <i>theCString</i> is a prefix of the receiver, NO otherwise.
*/
- (BOOL) hasCPrefix: (const char *) theCString;

/*!
  @method hasCSuffix:
  @discussion This method is used to verify if the receiver has <i>theCString</i>
              as a suffix.
  @param theCString The C string to look for.
  @result YES if <i>theCString</i> is a suffix of the receiver, NO otherwise.
*/
- (BOOL) hasCSuffix: (const char *) theCString;

/*!
  @method hasCaseInsensitiveCPrefix:
  @discussion Same as -hasCPrefix but the comparison is done
              in a case-insensitiveness matter.
  @param thePrefix The prefix to be used.
  @result YES the there is a match, NO otherwise.
*/
- (BOOL) hasCaseInsensitiveCPrefix: (const char *) theCString;

/*!
  @method hasCaseInsensitiveCSuffix:
  @discussion Same as -hasCSuffix but the comparison is done
              in a case-insensitiveness matter.
  @param theSuffix The suffix to be used.
  @result YES the there is a match, NO otherwise.
*/
- (BOOL) hasCaseInsensitiveCSuffix: (const char *) theCString;

/*!
  @method caseInsensitiveCCompare:
  @discussion This method is used to compare <i>theCString</i> with our
              receiver's bytes.
  @param theCString The C string to compare the receiver with.
  @result One of the three possible values of the NSComparisonResult enum.
*/
- (NSComparisonResult) caseInsensitiveCCompare: (const char *) theCString;

/*!
  @method componentsSeparatedByCString:
  @discussion This method is used to separate the receiver into subdata,
              using <i>theCString</i> as the separator.
  @param theCString The separator to use, as a C string.
  @result An instance of NSArray holding all components. The array is
          empty if the separator was not found in the receiver.
*/
- (NSArray *) componentsSeparatedByCString: (const char *) theCString;

/*!
  @method asciiString
  @discussion This method turns the receiver into a NSString object.
              The receiver's bytes must be all-ASCII bytes.
  @result A NSString instance, nil if the conversion failed.
*/
-(NSString *) asciiString;

/*!
  @method cString
  @discussion This method returns the receiver's byte as a NULL terminated
              C string.
  @result The NULL terminated C string.
*/
-(const char *) cString;

- (unichar) characterAtIndex: (NSUInteger) theIndex;

/*!
  @method quoteWithLevel:wrappingLimit:
  @discussion This method is used to quote an unwrapped string.
  @param theLevel The quoting level.
  @param theLimit The line wrapping limit to use, in number of characters.
  @result Returns a quoted string as a NSData instance. An empty NSData 
          instance is returned if <i>theLevel</i> is greater than <i>theLimit</i>.
*/
- (NSData *) quoteWithLevel: (NSUInteger) theLevel
             wrappingLimit: (NSUInteger) theLimit;

/*!
  @method unwrapWithLimit:
  @discussion This method is used to unwrap the string using a quote limit.
              This method implements the behavior specified in RFC2646.
  @param theQuoteLimit The quote limit to use for unwrapping the string.
  @result The unwrapped string, as a NSData instance.
*/
- (NSData *) unwrapWithLimit: (NSUInteger) theQuoteLimit;

/*!
  @method wrapWithLimit:
  @discussion This method wraps the string at the <i>theLimit</i> with
              respect to RFC2646. 
  @param theLimit The limit to use for wrapping the string. The limit
                  corresponds to the maximum length of a line, specified
                  in characters.
  @result The wrapped string.
*/
- (NSData *) wrapWithLimit: (NSUInteger) theLimit;

@end

/*!
  @category NSMutableData (PantomimeExtensions)
  @abstract Pantomime extensions to NSMutableData.
  @discussion This category provides useful extensions for handling
              NSMutableData objects.
*/
@interface NSMutableData (PantomimeExtensions)

/*!
  @method appendCFormat:
  @discussion This method is used to append the variable arguments
              to the receiver. The bytes of the arguments must
	      be composed only of ASCII characters.
  @param theFormat The format of the rest of the argument, as this
                   method is a variadic method.
*/
-(void) appendCFormat: (NSString *) theFormat, ...;

/*!
  @method appendCString:
  @discussion This method is used to append the C string to the receiver.
  @param theCString The C string to append.
*/
-(void) appendCString: (const char *) theCString;

/*!
  @method insertCString: atIndex:
  @discussion This method is used to insert the C string into
              the received at the specified index. If <i>theIndex</i> is zero,
	      the C string will be added at the beginning of the
	      receiver. If <i>theIndex</i> is greater than the receiver's length,
	      the C string will be appended to the receiver.
  @param theCString The C string to insert into the receiver.
  @param theIndex The index where to insert the C string.
*/
- (void) insertCString: (const char *) theCString
               atIndex: (NSUInteger) theIndex;

/*!
  @method replaceCRLFWithLF
  @discussion This method destructively elides all carriage return
              (CR, Control-M, ASCII 13) from the receiver.
*/
- (void) replaceCRLFWithLF;

/*!
  @method replaceLFWithCRLF
  @discussion This method is used to replace all occurences of line feed
              characters by sequences of a carriage return followed by
	      line feed characters in the receiver.
*/
- (NSMutableData *) replaceLFWithCRLF;

@end

#endif // _Pantomime_H_NSData_Extensions
