/*
**  NSString+Extensions.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2014-2018 Riccardo Mottola
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

#ifndef _Pantomime_H_NSString_Extensions
#define _Pantomime_H_NSString_Extensions

#import <Foundation/NSString.h>
#import <Foundation/NSData.h>

#include <Pantomime/CWConstants.h>

@class CWPart;

/*!
  @category NSString (PantomimeStringExtensions)
  @abstract Pantomime NSString extensions for mail processing.
  @discussion This category is used to defined useful methods
              in order to facilitate mail processing.
*/
@interface NSString (PantomimeStringExtensions)

#ifdef MACOSX
/*!
  @method stringByTrimmingWhiteSpaces
  @discussion This method is used to trim the leading and trailing
              spaces (space characters, tabs, newlines, carriage returns
              or other characters with no visible representation)
              from the receiver.
  @result The trimmed string.
*/
- (NSString *) stringByTrimmingWhiteSpaces;
#else
#define stringByTrimmingWhiteSpaces stringByTrimmingSpaces
#endif

/*!
  @method indexOfCharacter:
  @discussion This method finds the first occurence of
              the character in the receiver and returns its index (zero-based)
  @param theCharacter The caracter to be searched for.
  @result The index of the character, NSNotFound if it's not found in the receiver.
*/
- (NSUInteger) indexOfCharacter: (unichar) theCharacter;

- (NSUInteger) indexOfCharacter: (unichar) theCharacter
               fromIndex: (NSUInteger) theIndex;

/*!
 @method indexOfLastCharacter:
 @discussion This method finds the last occurence of
             the character in the receiver and returns its index (zero-based)
 @param theCharacter The caracter to be searched for.
 @result The index of the character, NSNotFound if it's not found in the receiver.
 */
- (NSUInteger) indexOfLastCharacter: (unichar) theCharacter;

/*!
  @method hasCaseInsensitivePrefix:
  @discussion Same as -hasPrefix but the comparison is done
              in a case-insensitiveness matter.
  @param thePrefix The prefix to be used.
  @result YES the there is a match, NO otherwise.
*/
- (BOOL) hasCaseInsensitivePrefix: (NSString *) thePrefix;

/*!
  @method hasCaseInsensitiveSuffix:
  @discussion Same as -hasSuffix but the comparison is done
              in a case-insensitiveness matter.
  @param theSuffix The suffix to be used.
  @result YES the there is a match, NO otherwise.
*/
- (BOOL) hasCaseInsensitiveSuffix: (NSString *) theSuffix;

/*!
  @method stringFromQuotedString
  @discussion This method returns an unquoted string if the
              string has a leading AND trailing quote.
  @result The unquoted string or the original if it does not
          match the criteria.
*/
- (NSString *) stringFromQuotedString;

/*!
  @method stringValueOfTransferEncoding:
  @abstract Get the string value of the specified encoding.
  @discussion This method is used to return the string value of a
              specified encoding. If the encoding isn't found,
              it simply returns the default encoding, which is 7bit.
  @param theEncoding The int value of the specified encoding.
  @result Returns a NSString holding the string value of the encoding.
*/
+ (NSString *) stringValueOfTransferEncoding: (PantomimeEncoding) theEncoding;

/*!
  @method encodingForCharset:
  @discussion This method is used to obtain a string encoding
              based on the specified charset.
  @param theCharset The charset, as NSData.
  @result The encoding which might not be a NSStringEncoding.
*/
+ (unsigned long) encodingForCharset: (NSData *) theCharset;

/*!
  @method encodingForCharset:convertToNSStringEncoding:
  @discussion This method is used to obtain a string encoding
  based on the specified charset.
  @param theCharset The charset, as NSData.
  @param shouldConvert Set to YES if NSString's en/decoding is going
  to be used. If set to NO will only be usable for CoreFoundation.
  @result The encoding which might not be a NSStringEncoding.
*/
+ (unsigned long) encodingForCharset: (NSData *) theCharset
 convertToNSStringEncoding: (BOOL) shouldConvert;

/*!
  @method encodingForPart:
  @discussion Same as +encodingForCharset: but uses the
              Part: -defaultCharset or -charset.
  @param thePart The Part object from which the encoding
                 will be derived from.
  @result The encoding which might not be a NSStringEncoding.
*/
+ (unsigned long) encodingForPart: (CWPart *) thePart;

/*!
  @method encodingForPart:convertToNSStringEncoding:
  @discussion Same as +encodingForCharset:convertToNSStringEncoding:
  but uses the Part: -defaultCharset or -charset.
  @param thePart The Part object from which the encoding
  will be derived from.
  @param shouldConvert Set to YES if NSString's en/decoding is going
  to be used. If set to NO will only be usable for CoreFoundation.
  @result The encoding which might not be a NSStringEncoding.
*/
+ (unsigned long) encodingForPart: (CWPart *) thePart
 convertToNSStringEncoding: (BOOL) shouldConvert;

/*!
  @method stringWithData:charset:
  @discussion This method builds a NSString object from the
              data object, using the specified charset.
  @param theData The data from which the string will be built.
  @param theCharset The charset to use when building the string object.
  @result The string object, nil on error.
*/
+ (NSString *) stringWithData: (NSData *) theData
                      charset: (NSData *) theCharset;

/*!
  @method charset
  @discussion This method is used to guess the best charset
              that can be used.
  @result The best charset, UTF-8 otherwise.
*/
- (NSString *) charset;

/*!
  @method modifiedUTF7String
  @discussion This method returns a newly created NSString
              object which can be converted using the NSASCIIStringEncoding
	      using the modified UTF-7 encoding described in RFC3501.
	      A modified UTF-7 string MUST be used in IMAP for maibox names.
  @result A modified UTF-7 string.
*/
- (NSString *) modifiedUTF7String;

/*!
  @method stringFromModifiedUTF7
  @discussion This method creates a new string NSString object
              from the modified UTF-7 string which is 7-bit based.
              The newly created string can contain Unicode characters.
  @result An Unicode string object, nil if the conversion failed.
*/
- (NSString *) stringFromModifiedUTF7;

/*!
  @method hasREPrefix
  @discussion This method is used to check if the string has
              a "re:", "re :" and so on prefix.
  @result YES if such prefix exists, NO otherwise.
*/
- (BOOL) hasREPrefix;

/*!
  @method stringByReplacingOccurrencesOfCharacter:withCharacter:
  @discussion This method is used to replace all occurences of <i>theTarget</i>
              by <i>theReplacement</i> character.
  @param theTarget The character to be replaced.
  @param theReplacement The characterthat will be used as the replacement.
  @result The modified string where all occurences of theTarget are replaced
          by theReplacement.
*/
- (NSString *) stringByReplacingOccurrencesOfCharacter: (unichar) theTarget
                                         withCharacter: (unichar) theReplacement;

/*!
  @method stringByDeletingLastPathComponentWithSeparator:
  @discussion This method is used to delete the last path component
              by using <i>theSeparator</i> as the path separator. For example,
	      some IMAP servers use '.' as the separator.
  @param theSeparator The separator to use.
  @result A string without the last path component.
*/
- (NSString *) stringByDeletingLastPathComponentWithSeparator: (unichar) theSeparator;

/*!
  @method stringByDeletingFirstPathSeparator:
  @discussion This method removes the first occurence of theSeparator from the string.
              For example "/foo/bar/baz" becomes "foo/bar/baz" and ".a.b.c" becomes "a.b.c".
  @param theSeparator The separator to use.
  @result A string without the leading separator.
*/
- (NSString *) stringByDeletingFirstPathSeparator: (unichar) theSeparator;

/*!
  @method is7bitSafe
  @discussion This method is used to verify if the string contains any
              character greater than 0x007E.
  @result YES if it does, NO otherwise.
*/
- (BOOL) is7bitSafe;

/*!
  @method dataUsingEncodingForPart:
  @discussion Convenience for dataUsingEncodingForPart:allowLossyConversion:
  where no lossy conversion is allowed.
  @param thePart The Part object from which the encoding
  will be derived from.
  @result The data.
*/
- (NSData *) dataUsingEncodingFromPart: (CWPart *) thePart;

/*!
  @method dataUsingEncodingForPart:allowLossyConversion:
  @discussion Convenience for getting data out of the string in the correct
  encoding using the Part.
  @param thePart The Part object from which the encoding
  will be derived from.
  @param lossy Indicate if lossy conversion is allowed.
  @result The data.
*/
- (NSData *) dataUsingEncodingFromPart: (CWPart *) thePart
                  allowLossyConversion: (BOOL)lossy;

/*!
  @method dataUsingEncodingWithCharset:
  @discussion Convenience for dataUsingEncodingWithCharset:allowLossyConversion:
  where no lossy conversion is allowed.
  @param theCharset The character set that is used for the encoding.
  @result The data.
*/
- (NSData *) dataUsingEncodingWithCharset: (NSString *) theCharset;

/*!
  @method dataUsingEncodingWithCharset:allowLossyConversion:
  @discussion Convenience for getting data out of the string in with the
  given character set
  @param theCharset The character set that is used for the encoding.
  @param lossy Indicate if lossy conversion is allowed.
  @result The data.
*/
- (NSData *) dataUsingEncodingWithCharset: (NSString *) theCharset
                     allowLossyConversion: (BOOL)lossy;

/*!
  @method stringFromRecipients: type:
  @discussion This method is used obtain a string from a list
              of recipients. The returned addresses are only
	      the ones that match <i>theRecipientType</i>.
  @param theRecipients A NSArray of InternetAddress instances.
  @param theRecipientType The type of recipient.
  @result The formatted string.
*/
+ (NSString *) stringFromRecipients: (NSArray *) theRecipients
                               type: (PantomimeRecipientType) theRecipientType;
@end

#endif // _Pantomime_H_NSString_Extensions
