// ADAddressBook.h (this is -*- ObjC -*-)
// 
// Author: BjÅˆrn Giesler <bjoern@giesler.de>
// 
// Address Book Framework for GNUstep
// 

#ifndef _ADADDRESSBOOK_H_
#define _ADADDRESSBOOK_H_

#import <Foundation/Foundation.h>

#import <Addresses/ADTypedefs.h>
#import <Addresses/ADGlobals.h>

@class ADRecord;
@class ADPerson;
@class ADGroup;
@class ADSearchElement;
@class ADConverter;

@interface ADAddressBook: NSObject
+ (ADAddressBook*) sharedAddressBook;

- (NSArray*) recordsMatchingSearchElement: (ADSearchElement*) search;

- (BOOL) save;
- (BOOL) hasUnsavedChanges;

- (ADPerson*) me;
- (void) setMe: (ADPerson*) me;

- (ADRecord*) recordForUniqueId: (NSString*) uniqueId;

- (BOOL) addRecord: (ADRecord*) record;
- (BOOL) removeRecord: (ADRecord*) record;

- (NSArray*) people;
- (NSArray*) groups;
@end

@interface ADAddressBook(GroupAccess)
- (NSArray*) membersForGroup: (ADGroup*) group;
- (BOOL) addMember: (ADPerson*) person forGroup: (ADGroup*) group;
- (BOOL) removeMember: (ADPerson*) person forGroup: (ADGroup*) group;

- (NSArray*) subgroupsForGroup: (ADGroup*) group;
- (BOOL) addSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2;
- (BOOL) removeSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2;
- (NSArray*) parentGroupsForGroup: (ADGroup*) group;
@end

@interface ADAddressBook(AddressesExtensions)
- (NSArray*) groupsContainingRecord: (ADRecord*) record;
- (NSDictionary*) addressBookDescription;
@end

#endif
