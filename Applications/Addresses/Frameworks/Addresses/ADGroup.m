// ADGroup.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADGroup.h"
#import "ADAddressBook.h"
#import "ADTypedefs.h"
#import "ADGlobals.h"
#import "ADMultiValue.h"

static NSMutableDictionary *_propTypes;
#define N(x) [NSNumber numberWithInt: x]

@implementation ADGroup
+ (void) initialize
{
  _propTypes = [[NSMutableDictionary alloc]
		 initWithObjectsAndKeys:
		 N(ADStringProperty), ADUIDProperty,
		 N(ADStringProperty), ADGroupNameProperty,
		 N(ADArrayProperty),  ADMemberIDsProperty,
		 N(ADDateProperty),   ADCreationDateProperty,
		 N(ADDateProperty),   ADModificationDateProperty,
		 N(ADStringProperty),   ADSharedProperty,
		 nil];
}

- (NSArray*) members
{
  NSArray *arr;
  
  NSAssert([self addressBook], @"Address book must be set!");
  arr = [[self addressBook] membersForGroup: self];
  
  if([self readOnly]) return ADReadOnlyCopyOfRecordArray(arr);
  return arr;
}

- (BOOL) addMember: (ADPerson*) person
{
  NSAssert([self addressBook], @"Address book must be set!");

  if([self readOnly]) return NO;
  return [[self addressBook] addMember: person forGroup: self];
}

- (BOOL) removeMember: (ADPerson*) person
{
  NSAssert([self addressBook], @"Address book must be set!");

  if([self readOnly]) return NO;
  return [[self addressBook] removeMember: person forGroup: self];
}

- (NSArray*) subgroups
{
  NSArray *arr;

  NSAssert([self addressBook], @"Address book must be set!");
  arr = [[self addressBook] subgroupsForGroup: self];

  if([self readOnly]) return ADReadOnlyCopyOfRecordArray(arr);
  return arr;
}

- (BOOL) addSubgroup: (ADGroup*) group
{
  NSAssert([self addressBook], @"Address book must be set!");

  if([self readOnly]) return NO;
  return [[self addressBook] addSubgroup: group forGroup: self];
}

- (BOOL) removeSubgroup: (ADGroup*) group
{
  NSAssert([self addressBook], @"Address book must be set!");

  if([self readOnly]) return NO;
  return [[self addressBook] removeSubgroup: group forGroup: self];
}

- (NSArray*) parentGroups
{
  NSAssert([self addressBook], @"Address book must be set!");
  return [[self addressBook] parentGroupsForGroup: self];
}

- (BOOL) setDistributionIdentifier: (NSString*) identifier
		       forProperty: (NSString*) property
			    person: (ADPerson*) person
{
  [NSException raise: ADUnimplementedError
	       format: @"Distribution identifiers not yet implemented"];
  return NO;
}

- (NSString*) distributionIdentifierForProperty: (NSString*) property
					 person: (ADPerson*) person
{
  [NSException raise: ADUnimplementedError
	       format: @"Distribution identifiers not yet implemented"];
  return nil;
}

+ (int) addPropertiesAndTypes: (NSDictionary*) properties
{
  int retval = 0;
  NSEnumerator *e;
  NSString *key;

  e = [properties keyEnumerator];
  while((key = [e nextObject]))
    if(![_propTypes objectForKey: key])
      {
	[_propTypes setObject: [properties objectForKey: key]
		    forKey: key];
	retval++;
      }
  return retval;
}

+ (int) removeProperties: (NSArray*) properties
{
  int retval = 0;
  NSEnumerator *e;
  NSString* key;

  e = [properties objectEnumerator];
  while((key = [e nextObject]))
    if([_propTypes objectForKey: key])
      {
	[_propTypes removeObjectForKey: key];
	retval++;
      }
  return retval;
}
  
+ (NSArray*) properties
{
  return [_propTypes allKeys];
}

+ (ADPropertyType) typeOfProperty: (NSString*) property
{
  return (ADPropertyType)[[_propTypes objectForKey: property]
			  intValue];
}

+ (ADSearchElement*) searchElementForProperty: (NSString*) property 
					label: (NSString*) label 
					  key: (NSString*) key 
					value: (id) value 
				   comparison: (ADSearchComparison) comparison
{
  return [[[ADRecordSearchElement alloc]
	    initWithProperty: property
	    label: label
	    key: key
	    value: value
	    comparison: comparison]
	   autorelease];
}

- (BOOL) setValue: (id) value
      forProperty: (NSString *) property
{
  if([self readOnly])
    return NO;

  if(([[self class] typeOfProperty: property] & ADMultiValueMask) &&
     ([property isKindOfClass: [ADMutableMultiValue class]]))
    {
      // make sure no mutable multivalues are inserted
      ADMultiValue *mv;

      mv = [[[ADMultiValue alloc] initWithMultiValue: value]
	     autorelease];
      return [self setValue: mv forProperty: property];
    }
  return [super setValue: value forProperty: property];
}

@end
