// ADRecord.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADAddressBook.h"
#import "ADGlobals.h"
#import "ADConverter.h"
#import "ADMultiValue.h"
#import "ADRecord.h"
#import "ADGroup.h"

@implementation ADRecord
- init
{
  _dict = nil;
  _book = nil;
  _readOnly = NO;

  if([self isKindOfClass: [ADPerson class]])
    [self setValue: @"Person" forProperty: @"Type"];
  else if([self isKindOfClass: [ADGroup class]])
    [self setValue: @"Group" forProperty: @"Type"];

  return [super init];
}

- (void) dealloc
{
  [_dict release];
  [_book release];
  [super dealloc];
}

- (id) valueForProperty: (NSString *) property
{
  return [_dict objectForKey: property];
}

- (BOOL) setValue: (id) value
      forProperty: (NSString *) property
{
  NSMutableDictionary *newDict;
  
  if(_readOnly)
    {
      NSLog(@"Trying to set value %@ for property %@ in read-only record %@\n",
	    value, property, [self uniqueId]);
      return NO;
    }

  if (_dict)
    newDict = [NSMutableDictionary dictionaryWithDictionary: _dict];
  else
    newDict = [NSMutableDictionary dictionary];
  
  if(!value || [value isEqual: @""])
    [newDict removeObjectForKey: property];
  else
    [newDict setObject: value forKey: property];

  [_dict release];
  _dict = [[NSDictionary alloc] initWithDictionary: newDict];

  if([property isEqualToString: ADModificationDateProperty])
    return NO;

  [self setValue: [NSDate date] forProperty: ADModificationDateProperty];

  if(![property isEqualToString: ADUIDProperty])
    [[NSNotificationCenter defaultCenter]
      postNotificationName: ADRecordChangedNotification
      object: self
      userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
				value, ADChangedValueKey,
			      property, ADChangedPropertyKey,
			      nil]];
  
  return YES;
}

- (BOOL) removeValueForProperty: (NSString*) property
{
  NSMutableDictionary *newDict;
  
  if(_readOnly)
    {
      NSLog(@"Trying to remove value for property %@ in read-only record %@\n",
	    property, [self uniqueId]);
      return NO;
    }

  newDict = [NSMutableDictionary dictionaryWithDictionary: _dict];
  [newDict removeObjectForKey: property];
  [_dict release];
  _dict = [[NSDictionary alloc] initWithDictionary: newDict];

  if(![property isEqualToString: ADUIDProperty])
    [[NSNotificationCenter defaultCenter]
      postNotificationName: ADRecordChangedNotification
      object: self
      userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
				property, ADChangedPropertyKey,
			      nil]];
  return YES;
}

- (ADAddressBook*) addressBook
{
  return _book;
}

- (void) setAddressBook: (ADAddressBook*) book
{
  if(_book)
    [NSException raise: ADAddressBookConsistencyError
		 format: @"Cannot set address book on record '%@'"
		 @" (already has one)", [self uniqueId]];
  if(!book)
    [NSException raise: ADAddressBookConsistencyError
		 format: @"Cannot set nil address book on record '%@'",
		 [self uniqueId]];
  _book = [book retain];
}

- (id) copyWithZone: (NSZone*) z
{
  ADRecord* obj = (ADRecord *)NSCopyObject(self, 0, z);
  obj->_readOnly = _readOnly;

  // delete UID if it has one
  if([_dict objectForKey: ADUIDProperty])
    {
      NSMutableDictionary *d =
	[NSMutableDictionary
	  dictionaryWithDictionary: [_dict copy]];
      [d removeObjectForKey: ADUIDProperty];
      obj->_dict = [[NSDictionary alloc] initWithDictionary: d];
    }
  else
    obj->_dict = [_dict copy];

  obj->_book = nil;
  
  return obj;
}
@end

@implementation ADRecord(ADRecord_Convenience)
- (NSString*) uniqueId
{
  return [self valueForProperty: ADUIDProperty];
}
@end

@implementation ADRecord(AddressesExtensions)
- (BOOL) readOnly
{
  return _readOnly;
}

- (void) setReadOnly
{
  _readOnly = YES;
}

- (id) initWithRepresentation: (NSString*) str
			 type: (NSString*) type
{
  id<ADInputConverting> converter; id obj;
  Class c;

  c = [self class];
  [self release];

  converter = [[ADConverterManager sharedManager]
		inputConverterForType: type];
  if(!converter) return nil;

  if(![converter useString: str])
    return nil;

  obj = [converter nextRecord];
  if(!obj) return nil;

  if(![[obj class] isSubclassOfClass: c])
    {
      NSLog(@"It's of %@, not %@\n", [c className], [obj className]);
      return nil;
    }

  return [obj retain];
}

- (NSString*) representationWithType: (NSString*) type
{
  id<ADOutputConverting> converter; 

  [self release];

  converter = [[ADConverterManager sharedManager]
		outputConverterForType: type];
  [converter storeRecord: self];
  return [converter string];
}

- (NSDictionary*) contentDictionary
{
  NSMutableDictionary *dict;
  NSEnumerator *e;
  NSString *key;

  dict = [NSMutableDictionary dictionaryWithCapacity: [_dict count]];
  e = [[_dict allKeys] objectEnumerator];
  while((key = [e nextObject]))
    {
      NSObject *obj = [_dict objectForKey: key];
      if([obj isKindOfClass: [ADMultiValue class]])
	[dict setObject: [(ADMultiValue*)obj contentArray] forKey: key];
      else if([obj isKindOfClass: [NSString class]] ||
	      [obj isKindOfClass: [NSData class]] ||
	      [obj isKindOfClass: [NSDate class]] ||
	      [obj isKindOfClass: [NSArray class]] ||
	      [obj isKindOfClass: [NSDictionary class]])
	[dict setObject: obj forKey: key];
      else
	NSLog(@"Value for \"%@\" in record \"%@\" has invalid class %@\n",
	      key, [self uniqueId], [obj className]);
    }
  
  return dict;
}
@end
