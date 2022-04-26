/*
**  CWInternetAddress.h
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

#ifndef _Pantomime_H_CWInternetAddress
#define _Pantomime_H_CWInternetAddress

#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

#include <Pantomime/CWConstants.h>

/*!
  @class CWInternetAddress
  @abstract Class that wraps support around email addresses.
  @discussion This class is used to decode an email address,
              as described in RFC2821, and to hold the information
	      with regard to it.
*/
@interface CWInternetAddress : NSObject <NSCoding>
{
  @private
    PantomimeRecipientType _type;
    NSString *_address;
    NSString *_personal;

    // Needed for scripting.
    id _container; 
}

/*!
  @method initWithString:
  @discussion This method initializes a CWInternetAddress instance
              using <i>theString</i> and decodes from it the
	      personal and address parts of an Internet address.
  @param theString The string from which to decode the information.
                   If nil is passed, the instance is autoreleased
		   and nil will be returned.
  @result The CWInternetAddress instance, nil on error.
*/
- (id) initWithString: (NSString *) theString;

/*!
  @method initWithPersonal: address:
  @discussion This method is used to initialize a CWInternetAddress
              instance using the specified personal and address
              part of an Internet address.
  @param thePersonal The personal part of the Internet address.
  @param theAddress The address part of the Internet address.
  @result The CWInternetAddress instance, nil on error.
*/
- (id) initWithPersonal: (NSString *) thePersonal
                address: (NSString *) theAddress;

/*!
  @method address
  @discussion This method is used to obtain the address part
              of the receiver.
  @result The address part, as a NSString instance.
*/
- (NSString *) address;

/*!
  @method setAddress:
  @discussion This method is used to set the address part
              of the receiver, replacing the previous
	      value, if any.
  @param theAddress The new address part.
*/
- (void) setAddress: (NSString *) theAddress;

/*!
  @method personal
  @discussion This method is used to obtain the personal part
              of the receiver. The personal part is generally
	      the name of a person, like John Doe.
  @result The personal part, as a NSString instance.
*/
- (NSString *) personal;

/*!
  @method setPersonal:
  @discussion This method is used to set the personal part
              of the receiver, replacing the previous
	      value, if any. The personal part is generally
	      the name of a person, like John Doe.
  @param thePersonal The new personal part.
*/
- (void) setPersonal: (NSString *) thePersonal;

/*!
  @method type
  @discussion This method is used to obtain the type of
              the receiver. Values can be one of the
	      PantomimeRecipientType enum.
  @result The type.
*/
- (PantomimeRecipientType) type;

/*!
  @method setType:
  @discussion This method is used to set the receiver's type.
              The accepted values are the one of the
	      PantomimeRecipientType enum.
  @param theType The new type, which replaces the previous value.
*/
- (void) setType: (PantomimeRecipientType) theType;

/*!
  @method stringValue
  @discussion This method is used to return the receiver's personal
              and address parts in a correctly (ie., RFC2821 safe)
	      formatted way. No encoding (ie., using quoted-printable)
	      will be performed on the receiver's personal part).
  @result The formatted object.
*/
- (NSString *) stringValue;

/*!
  @method dataValue
  @discussion This method is used to return the receiver's personal
              and address parts in a correctly (ie., RFC2821 safe)
	      formatted way. Encoding (ie., using quoted-printable)
	      will be performed on the receiver's personal part).
  @result The formatted object.
*/
- (NSData *) dataValue;


/*!
  @method compare:
  @discussion This method is used to compare anAddress with the receiver
              (using -stringValue).
  @result The NSComparisonResult value.
*/
- (NSComparisonResult) compare: (id) theAddress;


/*!
  @method isEqualToAddress:
  @discussion This method is used to compare anAddress with the receiver's
              address only.
  @result A boolean value
*/
- (BOOL) isEqualToAddress: (CWInternetAddress *) theAddress;

/*!
  @method container
  @discussion This method is used to get the container for scripting.
  @result The container.
*/
- (id) container;

/*!
  @method setContainer:
  @discussion This method is used to set the container for scripting.
  @param theContainer The container for scripting.
*/
- (void) setContainer: (id) theContainer;

@end

/*!
  @class ToRecipient
  @discussion This class is used to ease scripting in Pantomime.
*/
@interface ToRecipient: CWInternetAddress
@end

/*!
  @class CcRecipient
  @discussion This class is used to ease scripting in Pantomime.
*/
@interface CcRecipient: CWInternetAddress
@end

/*!
  @class BccRecipient
  @discussion This class is used to ease scripting in Pantomime.
*/
@interface BccRecipient: CWInternetAddress
@end


#endif // _Pantomime_H_CWInternetAddress
