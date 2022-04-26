// ADMultiValue.h (this is -*- ObjC -*-)
// 
// Authors: Björn Giesler <giesler@ira.uka.de>
//          Riccardo Mottola
// 
// Address Book Framework for GNUstep
// 

#ifndef _ADMULTIVALUE_H_
#define _ADMULTIVALUE_H_

#import <Foundation/Foundation.h>

#import <Addresses/ADTypedefs.h>

@interface ADMultiValue : NSObject <NSCopying, NSMutableCopying>
{
  NSString *_primaryId;
  ADPropertyType _type;
  NSMutableArray *_arr;
}

- (NSUInteger) count;

- (id) valueAtIndex: (NSUInteger) index;
- (NSString*) labelAtIndex: (NSUInteger) index;
- (NSString*) identifierAtIndex: (NSUInteger) index;
    
- (NSUInteger) indexForIdentifier: (NSString*) identifier;

- (NSString*) primaryIdentifier;
    
- (ADPropertyType) propertyType;
@end

@interface ADMultiValue(AddressesExtensions)
- (id) initWithMultiValue: (ADMultiValue*) mv;
- (id) initWithType: (ADPropertyType) type;
- (NSArray*) contentArray;
@end

@interface ADMutableMultiValue: ADMultiValue
{
  int _nextId;
}

- (NSString*) addValue: (id) value
	     withLabel: (NSString*) label;
- (NSString *) insertValue: (id) value
		 withLabel: (NSString*) label
		   atIndex: (NSUInteger) index;
- (BOOL) removeValueAndLabelAtIndex: (NSUInteger) index;
- (BOOL) replaceValueAtIndex: (NSUInteger) index
		   withValue: (id) value;    
- (BOOL) replaceLabelAtIndex: (NSUInteger) index
		   withLabel: (NSString*) label;

- (BOOL)setPrimaryIdentifier:(NSString *)identifier;
@end

@interface ADMutableMultiValue(AddressesExtensions)
- (BOOL) addValue: (id) value
	withLabel: (NSString*) label
       identifier: (NSString*) identifier;
@end

#endif
