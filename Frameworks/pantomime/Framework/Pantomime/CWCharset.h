/*
**  CWCharset.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWCharset
#define _Pantomime_H_CWCharset

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

struct charset_code
{
  int code;
  unichar value;
};

/*!
  @class CWCharset
  @discussion This class provides a useful interface for dealing with 
              Internet message character sets.
*/
@interface CWCharset : NSObject
{
  @private
    const struct charset_code *_codes;
    int _num_codes;
    int _identity_map;
}

/*!
  @method initWithCodeCharTable: length:
  @discussion This method is used to initialize a CWCharset instance
              based on the charset code table. You should never
	      call this initializer directly. You should rather
	      invoke directly -init on CWCharset's subclasses.
  @param codes The charset code table which must be sorted by code.
  @param num_codes The size of the table.
*/
- (id) initWithCodeCharTable: (const struct charset_code *) codes
                      length: (int) num_codes;

/*!
  @method codeForCharacter:
  @discussion This method is used to obtain the right code from
              a Unicode character, in the code table.
  @param theCharacter The Unicode character to use.
  @result The code from the code table.
*/
- (int) codeForCharacter: (unichar) theCharacter;

/*!
  @method characterIsInCharset:
  @discussion This method is used to verify if <i>theCharacter</i>
              is present in the receiver.
  @param theCharacter The Unicode character to verify the availability.
  @result YES if it is present, NO otherwise.
*/
- (BOOL) characterIsInCharset: (unichar) theCharacter;

/*!
  @method name
  @discussion This method is used to get the name of the receiver.
              Values returned are like "iso-8859-1", "koi8-r" and
	      so on.
  @result The Internet name of the charset.
*/
- (NSString *) name;

/*!
  @method allCharsets
  @discussion This method is used to obtain a dictionary of all supported
              charsets by Pantomime. The keys are the name of the charsets
	      (NSString instances) and the values are a description 
	      of the charset (NSString instances).
  @result The dictionary of all supported character sets.
*/
+ (NSDictionary *) allCharsets;

/*!
  @method charsetForName:
  @discussion This method is used to obtain a CWCharset subclass instance
              from the Internet name of a charset.
  @param theName The Internet name of a charset, like "iso-8859-1".
  @result The CWCharset instance. If a non-supported name was specified,
          an instance of CWISO8859_1 is returned.
*/
+ (CWCharset *) charsetForName: (NSString *) theName;

@end

#endif // _Pantomime_H_CWCharset
