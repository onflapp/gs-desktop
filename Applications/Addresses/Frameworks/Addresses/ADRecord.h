// ADRecord.h (this is -*- ObjC -*-)
// 
// Authors: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 


#ifndef _ADRECORD_H_
#define _ADRECORD_H_

#import <Foundation/Foundation.h>


@class ADAddressBook;

@interface ADRecord: NSObject <NSCopying>
{
  BOOL _readOnly;
  ADAddressBook *_book;
  NSDictionary *_dict;
}

- (id) valueForProperty: (NSString *) property;
- (BOOL) setValue: (id) value forProperty: (NSString *) property;
- (BOOL) removeValueForProperty: (NSString *) property;

/*!
  \brief Return the address book this record is part of.

  Can return nil, if this is a new record which has not been added to
  any address book yet.
  
  \note This is a non-Apple extension; Apple's API doesn't need it as
  it knows nothing about multiple address books.
*/
- (ADAddressBook *) addressBook;

/*!
  \brief Set the address book this record is part of.

  Can only be set once (since a record cannot be *moved* between
  address books); raises if it has been called before, or if book is
  nil.

  \note This is a non-Apple extension; Apple's API doesn't need it as
  it knows nothing about multiple address books.
*/
- (void) setAddressBook: (ADAddressBook *) book;
@end

@interface ADRecord(Convenience)
- (NSString*) uniqueId;
@end


// Addresses Extensions
@interface ADRecord(AddressesExtensions)
- (id) initWithRepresentation: (NSString*) str
			 type: (NSString*) type;
- (NSString*) representationWithType: (NSString*) type;

- (BOOL) readOnly;    // return whether this is a read-only record
- (void) setReadOnly; // set this record to be read-only. cannot be reset.

- (NSDictionary*) contentDictionary;
@end

#endif

