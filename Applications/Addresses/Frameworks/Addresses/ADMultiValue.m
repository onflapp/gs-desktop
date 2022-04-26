// ADMultiValue.m (this is -*- ObjC -*-)
// 
// Authors: Björn Giesler <giesler@ira.uka.de>
//          Riccardo Mottola
// 
// Address Book API for GNUstep
// 




/* my includes */
#import "ADMultiValue.h"

#define IS_A(obj,cls) [obj isKindOfClass: [cls class]]

static ADPropertyType _propTypeFromDict(NSDictionary *dict)
{
  id obj = [dict objectForKey: @"Value"];
  
  if(IS_A(obj, NSString))
    return ADStringProperty;
  if(IS_A(obj, NSDate))
    return ADDateProperty;
  if(IS_A(obj, NSArray))
    return ADArrayProperty;
  if(IS_A(obj, NSDictionary))
    return ADDictionaryProperty;
  if(IS_A(obj, NSData))
    return ADDataProperty;
  if(IS_A(obj, NSValue))
    return ADIntegerProperty;

  return ADErrorInProperty;
}

@interface ADMultiValue (Private)
- (NSArray*) array;
- (ADPropertyType) type;
@end

@implementation ADMultiValue
- (id)initWithMultiValue: (ADMultiValue*) mv
{
  [super init];
  _arr = [[[mv array] mutableCopy] retain];
  _primaryId = [[mv primaryIdentifier] copy];
  _type = [mv type];
  return self;
}

- (id) initWithType: (ADPropertyType) type
{
  _arr = [[NSMutableArray alloc] initWithCapacity: 5];
  _primaryId = nil;
  _type = type;
  return [super init];
}

- (void) dealloc
{
  [_arr release];
  [_primaryId release];
  [super dealloc];
}

- (NSArray*) contentArray
{
  return _arr;
}

- (NSUInteger) count
{
  return [_arr count];
}

- (id) valueAtIndex: (NSUInteger) index
{
  return [[_arr objectAtIndex: index] objectForKey: @"Value"];
}

- (NSString*) labelAtIndex: (NSUInteger) index
{
  return [[_arr objectAtIndex: index] objectForKey: @"Label"];
}

- (NSString*) identifierAtIndex: (NSUInteger) index
{
  return [[_arr objectAtIndex: index] objectForKey: @"ID"];
}

- (NSUInteger) indexForIdentifier: (NSString*) identifier
{
  NSUInteger i;

  for(i=0; i<[_arr count]; i++)
    if([[[_arr objectAtIndex: i] objectForKey: @"ID"]
	 isEqualToString: identifier])
      return i;
  return NSNotFound;
}

- (NSString*) primaryIdentifier
{
  return _primaryId;
}

- (ADPropertyType) propertyType
{
  NSEnumerator *e;
  id obj;
  ADPropertyType assumedType;

  if(![_arr count])
    return ADErrorInProperty;

  e = [_arr objectEnumerator];
  obj = [e nextObject];
  assumedType = _propTypeFromDict(obj);
  while((obj = [e nextObject]))
    if(assumedType != _propTypeFromDict(obj))
      return ADErrorInProperty;

  return assumedType;
}

- (NSString*) description
{
  return [_arr description];
}

- (id) copyWithZone: (NSZone*) zone
{
  return [[ADMultiValue alloc] initWithMultiValue: self];
}

- (id) mutableCopyWithZone: (NSZone*) zone
{
  return [[ADMutableMultiValue alloc] initWithMultiValue: self];
}
@end

@implementation ADMultiValue (Private)
- (NSArray*) array
{
  return _arr;
}

- (ADPropertyType) type
{
  return _type;
}
@end

#define POSTCHANGE [[NSNotificationCenter defaultCenter] postNotificationName: @"_MVChg" object: self];

@implementation ADMutableMultiValue
- initWithType: (ADPropertyType) type
{
  _nextId = 0;
  return [super initWithType: type];
}

- (NSString*) _nextValidID
{
  NSEnumerator *e;
  NSDictionary *dict;
  int max;

  e = [_arr objectEnumerator];
  max = 0;
  while((dict = [e nextObject]))
    max = MAX(max, [[dict objectForKey: @"ID"] intValue]);
  
  return [NSString stringWithFormat: @"%d", max+1];
}

- (NSString*) addValue: (id) value
	     withLabel: (NSString*) label
{
  NSString *identifier;
  NSMutableDictionary *dict;

  identifier = [self _nextValidID];
  dict = [NSMutableDictionary dictionary];
  
  // make sure nothing mutable gets added
  if(_type == ADMultiArrayProperty &&
     [value isKindOfClass: [NSMutableArray class]])
    value = [NSArray arrayWithArray: value];
  else if(_type == ADMultiDictionaryProperty &&
	  [value isKindOfClass: [NSMutableDictionary class]])
    value = [NSDictionary dictionaryWithDictionary: value];
  else if(_type == ADMultiDataProperty &&
	  [value isKindOfClass: [NSMutableData class]])
    value = [NSData dataWithData: value];
  
  if(value) [dict setObject: value forKey: @"Value"];
  if(label) [dict setObject: label forKey: @"Label"];
  [dict setObject: identifier forKey: @"ID"];

  [_arr addObject: [NSDictionary dictionaryWithDictionary: dict]];

  return identifier;
}

- (NSString *) insertValue: (id) value
		 withLabel: (NSString*) label
		   atIndex: (NSUInteger) index
{
  NSString* identifier;
  NSMutableDictionary *dict;

  identifier = [self _nextValidID];

  // make sure nothing mutable gets added
  if(_type == ADMultiArrayProperty &&
     [value isKindOfClass: [NSMutableArray class]])
    value = [NSArray arrayWithArray: value];
  else if(_type == ADMultiDictionaryProperty &&
	  [value isKindOfClass: [NSMutableDictionary class]])
    value = [NSDictionary dictionaryWithDictionary: value];
  else if(_type == ADMultiDataProperty &&
	  [value isKindOfClass: [NSMutableData class]])
    value = [NSData dataWithData: value];
  
  dict = [NSDictionary dictionaryWithObjectsAndKeys:
			 value, @"Value",
		       label, @"",
		       identifier, @"ID",
		       nil];

  [_arr insertObject: dict atIndex: index];

  return identifier;
}

- (BOOL) removeValueAndLabelAtIndex: (NSUInteger) index
{
  if(index >= [_arr count]) return NO;
  [_arr removeObjectAtIndex: index];

  return YES;
}

- (BOOL) replaceValueAtIndex: (NSUInteger) index
		   withValue: (id) value
{
  NSMutableDictionary *dict;

  if(index >= [_arr count]) return NO;

  // make sure nothing mutable gets added
  if(_type == ADMultiArrayProperty &&
     [value isKindOfClass: [NSMutableArray class]])
    value = [NSArray arrayWithArray: value];
  else if(_type == ADMultiDictionaryProperty &&
	  [value isKindOfClass: [NSMutableDictionary class]])
    value = [NSDictionary dictionaryWithDictionary: value];
  else if(_type == ADMultiDataProperty &&
	  [value isKindOfClass: [NSMutableData class]])
    value = [NSData dataWithData: value];
  
  dict = [NSMutableDictionary
	   dictionaryWithDictionary: [_arr objectAtIndex: index]];
  [dict setObject: value forKey: @"Value"];
  [_arr replaceObjectAtIndex: index withObject: dict];
  
  return YES;
}

- (BOOL) replaceLabelAtIndex: (NSUInteger) index
		   withLabel: (NSString*) label
{
  NSMutableDictionary *dict;

  if(index >= [_arr count]) return NO;
  dict = [NSMutableDictionary
	   dictionaryWithDictionary: [_arr objectAtIndex: index]];
  [dict setObject: label forKey: @"Label"];
  [_arr replaceObjectAtIndex: index withObject: dict];

  return YES;
}

- (BOOL)setPrimaryIdentifier:(NSString *)identifier
{
  [_primaryId release];
  _primaryId = [identifier retain];

  return YES;
}
@end

@implementation ADMutableMultiValue(AddressesExtensions)
- (BOOL) addValue: (id) value
	withLabel: (NSString*) label
       identifier: (NSString*) identifier
{
  NSMutableDictionary *dict;

  if([self indexForIdentifier: identifier] != NSNotFound)
    return NO;
  
  dict =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
			   value, @"Value",
			 label, @"Label",
			 identifier, @"ID",
			 nil];

  [_arr addObject: [NSDictionary dictionaryWithDictionary: dict]];

  return YES;
}
@end
