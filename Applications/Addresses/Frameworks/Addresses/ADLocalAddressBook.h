// ADLocalAddressBook.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
//

#import <Addresses/ADAddressBook.h>
#import <Addresses/ADGroup.h>


@interface ADLocalAddressBook: ADAddressBook
{
  NSString *_loc;
  NSMutableDictionary *_unsaved;
  NSMutableDictionary *_deleted;
  NSMutableDictionary *_cache;
}

+ (NSString*) defaultLocation;
+ (void) setDefaultLocation: (NSString*) location;

+ (ADAddressBook*) sharedAddressBook;

+ (BOOL) makeLocalAddressBookAtLocation: (NSString*) location;

- initWithLocation: (NSString*) location;
- (NSString*) location;
@end

@interface ADLocalAddressBook(GroupAccess)
- (NSArray*) membersForGroup: (ADGroup*) group;
- (BOOL) addMember: (ADPerson*) person forGroup: (ADGroup*) group;
- (BOOL) removeMember: (ADPerson*) person forGroup: (ADGroup*) group;

- (NSArray*) subgroupsForGroup: (ADGroup*) group;
- (BOOL) addSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2;
- (BOOL) removeSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2;
- (NSArray*) parentGroupsForGroup: (ADGroup*) group;
@end

@interface ADLocalAddressBook(ImageDataFile)
- (BOOL) setImageDataForPerson: (ADPerson*) person
		      withFile: (NSString*) filename;
- (NSString*) imageDataFileForPerson: (ADPerson*) person;
@end

