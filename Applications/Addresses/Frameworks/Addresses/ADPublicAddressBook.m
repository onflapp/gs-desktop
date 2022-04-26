// ADPublicAddressBook.m (this is -*- ObjC -*-)
// 
// \Athor: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADPublicAddressBook.h"
#import "ADRecord.h"

@implementation ADPublicAddressBook
- initWithAddressBook: (ADAddressBook*) book
	     readOnly: (BOOL) ro
{
  if(![super init]) return nil;
  
  NSAssert(book, @"Address Book may not be nil!");

  _book = [book retain];
  _readOnly = ro;
  return self;
}

- (NSArray*) recordsMatchingSearchElement: (ADSearchElement*) search
{
  NSArray *arr;

  arr = [_book recordsMatchingSearchElement: search];
  if(_readOnly) arr = ADReadOnlyCopyOfRecordArray(arr);

  return arr;
} 

- (BOOL) save
{
  if(_readOnly) return NO;
  return [_book save];
}
  
- (BOOL) hasUnsavedChanges
{
  if(_readOnly) return NO;
  return [_book hasUnsavedChanges];
}

- (ADPerson*) me
{
  if(_readOnly)
    {
      ADRecord *r;

      r = (ADRecord*)[_book me];
      if(!r) return nil;
      r = [r copy];
      [r setReadOnly];

      return (ADPerson*)r;
    }

  return [_book me];
}

- (void) setMe: (ADPerson*) me
{
  if(_readOnly) return;
  [_book setMe: me];
}

- (ADRecord*) recordForUniqueId: (NSString*) uniqueId
{
  ADRecord *r = [_book recordForUniqueId: uniqueId];
  if(!r) return nil;

  if(_readOnly)
    {
      r = [r copy];
      [r setReadOnly];
    }
  return r;
}

- (BOOL) addRecord: (ADRecord*) record
{
  if(_readOnly) return NO;

  return [_book addRecord: record];
}

- (BOOL) removeRecord: (ADRecord*) record
{
  if(_readOnly) return NO;

  return [_book removeRecord: record];
}

- (NSArray*) people
{
  NSArray *arr = [_book people];
  if(_readOnly) return ADReadOnlyCopyOfRecordArray(arr);
  return arr;
}

- (NSArray*) groups
{
  NSArray *arr = [_book groups];
  if(_readOnly) return ADReadOnlyCopyOfRecordArray(arr);
  return arr;
}
@end

#if 0 // add this later
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
@end
#endif
