// ADGroup.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#ifndef _ADGROUP_H
#define _ADGROUP_H

#import <Addresses/ADRecord.h>
#import <Addresses/ADPerson.h>
#import <Addresses/ADTypedefs.h>
#import <Addresses/ADSearchElement.h>


@interface ADGroup: ADRecord
- (NSArray*) members;
- (BOOL) addMember: (ADPerson*) person;
- (BOOL) removeMember: (ADPerson*) person;

- (NSArray*) subgroups;
- (BOOL) addSubgroup: (ADGroup*) group;
- (BOOL) removeSubgroup: (ADGroup*) group;
- (NSArray*) parentGroups;

- (BOOL) setDistributionIdentifier: (NSString*) identifier
		       forProperty: (NSString*) property
			    person: (ADPerson*) person;
- (NSString*) distributionIdentifierForProperty: (NSString*) property
					 person: (ADPerson*) person;

+ (int) addPropertiesAndTypes: (NSDictionary*) properties;
+ (int) removeProperties: (NSArray*) properties;
+ (NSArray*) properties;
+ (ADPropertyType) typeOfProperty: (NSString*) property;

+ (ADSearchElement*) searchElementForProperty: (NSString*) property
				       label: (NSString*) label
					 key: (NSString*) key
				       value: (id) value
				  comparison: (ADSearchComparison) comparison;
@end

#endif
