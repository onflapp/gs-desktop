// main.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// 
// 
// $Author: rmottola $
// $Locker:  $
// $Revision: 1.1 $
// $Date: 2007/05/01 23:07:09 $

/* system includes */
#include <Foundation/Foundation.h>
#include <Addresses/Addresses.h>

/* my includes */
/* (none) */

@class Group;
@class Address;

int groupsConverted = 0;
int peopleConverted = 0;

@interface AddressBook: NSObject<NSCoding>
{
  NSMutableArray *allGroups;
}
- (void) addToAddressBook;
@end
@interface Group: NSObject<NSCoding>
{
  NSString *name; NSMutableArray *addresses;
}
- (ADGroup*) addToAddressBook;
@end
@interface Address: NSObject<NSCoding>
{
  NSString *name; NSString *emailAddress;
}
- (ADPerson*) addToAddressBook;
@end

@implementation AddressBook
- (id) initWithCoder: (NSCoder*) theCoder
{
  allGroups = [[theCoder decodeObject] retain];
  return self;
}
- (void) encodeWithCoder: (NSCoder*) theCoder {}
- (void) addToAddressBook
{
  NSEnumerator *e;
  Group *g;
  
  e = [allGroups objectEnumerator]; 
  while((g = [e nextObject])) [g addToAddressBook];
  [[ADAddressBook sharedAddressBook] save];
}
@end

@implementation Group
- (id) initWithCoder: (NSCoder*) theCoder
{
  name = [[theCoder decodeObject] retain];
  addresses = [[theCoder decodeObject] retain];
  return self;
}
- (void) encodeWithCoder: (NSCoder*) theCoder {}
- (ADGroup*) addToAddressBook
{
  ADPerson *p; Address *a;
  ADGroup *g;
  NSEnumerator *e;
  
  g = [[ADGroup alloc] init];
  [g setValue: name forProperty: ADGroupNameProperty];
  [[ADAddressBook sharedAddressBook] addRecord: g];
  groupsConverted++;
  e = [addresses objectEnumerator];
  while((a = [e nextObject]))
    {
      p = [a addToAddressBook];
      [g addMember: p];
    }
  return g;
}
@end

@implementation Address
- (id) initWithCoder: (NSCoder*) theCoder
{
  name = [[theCoder decodeObject] retain];
  emailAddress = [[theCoder decodeObject] retain];
  return self;
}
- (void) encodeWithCoder: (NSCoder*) theCoder {}
- (ADPerson*) addToAddressBook
{
  ADPerson *p;
  ADMutableMultiValue *mv;

  p = [[ADPerson alloc] init];

  if(name && ![name isEqualToString: @""])
    {
      NSRange r;

      r = [name rangeOfString: @","];
      if(r.location == NSNotFound)
	{
	  NSArray *com = [name componentsSeparatedByString: @" "];
	  if([com count] > 1)
	    {
	      NSString *first, *last;
	      
	      first = [[com subarrayWithRange: NSMakeRange(0, [com count]-1)]
			componentsJoinedByString: @" "];
	      last = [com objectAtIndex: [com count]-1];
	      [p setValue: first forProperty: ADFirstNameProperty];
	      [p setValue: last forProperty: ADLastNameProperty];
	    }
	  else
	    [p setValue: name forProperty: ADLastNameProperty];
	}
      else
	{
	  NSArray *com = [name componentsSeparatedByString: @","];
	  if([com count] > 1)
	    {
	      NSString *last, *first;

	      last = [com objectAtIndex: 0];
	      first = [com objectAtIndex: 1];
	      [p setValue: first forProperty: ADFirstNameProperty];
	      [p setValue: last forProperty: ADLastNameProperty];
	    }
	  else
	    [p setValue: name forProperty: ADLastNameProperty];
	}
    }
  else
    {
      [p setValue: @"UNKNOWN" forProperty: ADLastNameProperty];
      [p setValue: emailAddress forProperty: ADFirstNameProperty];
    }

  mv = [[ADMutableMultiValue alloc]
	 initWithMultiValue: [p valueForProperty: ADEmailProperty]];
  [mv addValue: emailAddress withLabel: ADEmailWorkLabel];
  [p setValue: mv forProperty: ADEmailProperty];

  [[ADAddressBook sharedAddressBook] addRecord: p];
  peopleConverted++;
  return p;
}
@end


int main(int argc, const char **argv)
{
  NSString *path;
  AddressBook *obj;
  
  [[NSAutoreleasePool alloc] init];

  if(argc != 2)
    {
      fprintf(stderr, "Usage: %s PATH_TO_GNUMAIL_ADDRESS_BOOK\n", argv[0]);
      return -1;
    }

  path = [NSString stringWithCString: argv[1]];

  printf("Converting from '%s'...\n", [path cString]);
  
  obj = [NSUnarchiver unarchiveObjectWithFile: path];
  [obj addToAddressBook];

  printf("Converted %d groups and %d people\n",
	 groupsConverted, peopleConverted);
  
  return 0;
}
