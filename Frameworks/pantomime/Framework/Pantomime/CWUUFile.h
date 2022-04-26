/*
**  CWUUFile.h
**
**  Copyright (c) 2002-2004 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWUUFile
#define _Pantomime_H_CWUUFile

#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/*!
  @class CWUUFile
  @abstract Provides an interface to decode information that is uuencoded.
  @discussion This class provides an interface to decode uuencoded information
              from a string and access / mutation methods to access or modify the
	      decoded information.
*/
@interface CWUUFile : NSObject
{
  NSDictionary *_attributes;
  NSString *_name;
  NSData *_data;
}

/*!
  @method initWithName: data: attributes:
  @discussion This is the designated initializer for the CWUUFile class.
  @param theName The name of the file.
  @param theData The bytes of the file.
  @param theAttributes The file attributes of the original file.
  @result An instance of CWUUFile, nil on error.
*/
- (id) initWithName: (NSString *) theName
               data: (NSData *) theData
         attributes: (NSDictionary *) theAttributes;

/*!
  @method name
  @discussion This method is used to obtain the name of the file.
  @result The name of the file.
*/
- (NSString *) name;

/*!
  @method setName:
  @discussion This method is used to set the name of the file.
  @param theName The name of the file.
*/
- (void) setName: (NSString *) theName;

/*!
  @method data
  @discussion This method is used to obtain the bytes of the file,
              as an NSData instance.
  @result The bytes of the file.
*/
- (NSData *) data;

/*!
  @method setData:
  @discussion This method is used to set the bytes of the file,
              as an NSData instance.
  @param theData The bytes of the file.
*/
- (void) setData: (NSData *) theData;

/*!
  @method data
  @discussion This method is used to obtain the attributes of the file,
  @result The attributes of the file.
*/
- (NSDictionary *) attributes;

/*!
  @method setAttributes:
  @discussion This method is used to set the attributes of the file.
  @param theName The attributes of the file.
*/
- (void) setAttributes: (NSDictionary *) theAttributes;

/*!
  @method fileFromUUEncodedString:
  @discussion This method will decode a uuencoded file from <i>theString</i>.
              You must pass the entire string of the uuencoded file, and
	      only this.
  @result The CWUUFile instance.
*/
+ (CWUUFile *) fileFromUUEncodedString: (NSString *) theString;

/*!
  @method rangeOfUUEncodedStringFromString: range:
  @discussion This method is used to obtain the range of a uuencoded
              file from <i>theString</i> in <i>theRange</i>.
  @result The range of the uuencoded file.
*/
+ (NSRange) rangeOfUUEncodedStringFromString: (NSString *) theString
                                       range: (NSRange) theRange;

@end

#endif // _Pantomime_H_CWUUFile
