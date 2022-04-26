/*
**  CWMD5.h
**
**  Copyright (c) 2002-2006 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWMD5
#define _Pantomime_H_CWMD5

#import <Foundation/NSData.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/*!
  @class CWMD5
  @abstract MD5 Message-Digest algorithm implementation.
  @discussion This class provides an easy interface to the MD5 Message-Digest algorithm.
              This algorithm is described in RFC 1321. It also supports the HMAC
	      keyed-hashing for message authentication (described in RFC 2104). HMAC
	      is used in the CRAM-MD5 SASL authentication mechanim.
*/
@interface CWMD5 : NSObject
{
  @private
    NSData *_data;

    BOOL _has_computed_digest;
    unsigned char _digest[16];
}

/*!
  @method initWithData:
  @discussion This is the designated initializer for the CWMD5 class.
  @param theData The data to use for the MD5 operation.
  @result An instance of CWMD5, nil on failure.
*/
- (id) initWithData: (NSData *) theData;

/*!
  @method computeDigest
  @discussion This method is used to compute the MD5 digest
              for the instance's data.
*/
- (void) computeDigest;

/*!
  @method digest
  @discussion This method is used to obtain the computed digest,
              from the instance's data.
  @result The digest, as a NSData instance.
*/
- (NSData *) digest;

/*!
  @method digestAsString
  @discussion See -digest.
  @result Returns the digest as a NSString instance.
*/
- (NSString *) digestAsString;

/*!
  @method hmacAsStringUsingPassword:
  @discussion Computes the HMAC using <i>thePassword</i> and returns it.
  @param thePassword The password to use when computing the HMAC.
  @result The computed HMAC, as a NSString instance.
*/
- (NSString *) hmacAsStringUsingPassword: (NSString *) thePassword;

@end

#endif // _Pantomime_H_CWMD5
