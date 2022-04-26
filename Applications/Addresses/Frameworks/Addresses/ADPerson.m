// ADPerson.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADAddressBook.h"
#import "ADPerson.h"
#import "ADGlobals.h"
#import "ADTypedefs.h"
#import "ADMultiValue.h"

static NSMutableDictionary *_propTypes;
static ADScreenNameFormat _scrNameFormat = ADScreenNameLastNameFirst;
#define N(x) [NSNumber numberWithInt: x]

@implementation ADPerson
+ (void) initialize
{
  NSDictionary *dom;
  NSString *scrName;

  _propTypes = [[NSMutableDictionary alloc]
		 initWithObjectsAndKeys:
		   N(ADStringProperty),        ADUIDProperty,
		 N(ADDateProperty),            ADCreationDateProperty,
		 N(ADDateProperty),            ADModificationDateProperty,
		 N(ADStringProperty),          ADSharedProperty,
		 N(ADStringProperty),          ADFirstNameProperty,
		 N(ADStringProperty),          ADLastNameProperty,
		 N(ADStringProperty),          ADFirstNamePhoneticProperty,
		 N(ADStringProperty),          ADLastNamePhoneticProperty,
		 N(ADDateProperty),            ADBirthdayProperty,
		 N(ADStringProperty),          ADOrganizationProperty,
		 N(ADStringProperty),          ADJobTitleProperty,
		 N(ADStringProperty),          ADHomePageProperty,
		 N(ADMultiStringProperty),     ADEmailProperty,
		 N(ADMultiDictionaryProperty), ADAddressProperty,
		 N(ADMultiStringProperty),     ADPhoneProperty,
		 
		 N(ADMultiStringProperty),     ADAIMInstantProperty,
		 N(ADMultiStringProperty),     ADJabberInstantProperty,
		 N(ADMultiStringProperty),     ADMSNInstantProperty,
		 N(ADMultiStringProperty),     ADYahooInstantProperty,
		 N(ADMultiStringProperty),     ADICQInstantProperty,
		 
		 N(ADStringProperty),          ADNoteProperty,
		 
		 N(ADStringProperty),          ADMiddleNameProperty,
		 N(ADStringProperty),          ADMiddleNamePhoneticProperty,
		 N(ADStringProperty),          ADTitleProperty,
		 N(ADStringProperty),          ADSuffixProperty,
		 N(ADStringProperty),          ADNicknameProperty,
		 N(ADStringProperty),          ADMaidenNameProperty,

		 N(ADDataProperty),            ADImageProperty,
		 N(ADStringProperty),          ADImageTypeProperty,
		 nil];

  dom = [NSMutableDictionary dictionaryWithDictionary:
			       [[NSUserDefaults standardUserDefaults]
				 persistentDomainForName: @"Addresses"]];
  if(!dom)
    {
      _scrNameFormat = ADScreenNameLastNameFirst;
      scrName = @"LastNameFirst";
      dom = [NSDictionary dictionaryWithObjectsAndKeys: scrName,
			  @"ScreenNameFormat", nil];
    }
  else
    {
      scrName = [dom objectForKey: @"ScreenNameFormat"];
      if(!scrName || [scrName isEqualToString: @"LastNameFirst"])
	{
	  _scrNameFormat = ADScreenNameLastNameFirst;
	  scrName = @"LastNameFirst";
	}
      else if([scrName isEqualToString: @"FirstNameFirst"])
	{
	  _scrNameFormat = ADScreenNameFirstNameFirst;
	  scrName = @"FirstNameFirst";
	}
      else
	{
	  NSLog(@"Unknown value %@ for ScreenNameFormat. "
		@"Using LastNameFirst.\n", scrName);
	  _scrNameFormat = ADScreenNameFirstNameFirst;
	  scrName = @"LastNameFirst";
	}
    }

  [[NSUserDefaults standardUserDefaults] setPersistentDomain: dom
					 forName: @"Addresses"];
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
  id val;

  val = [_propTypes objectForKey: property];
  if(val) return (ADPropertyType)[val intValue];
  return ADErrorInProperty;
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

- (ADPropertyType) typeOfProperty: (NSString*) property
{
  return [[self class] typeOfProperty: property];
}

- (id) valueForProperty: (NSString*) property
{
  id val;
  ADPropertyType type;

  val = [super valueForProperty: property];
  type = [[self class] typeOfProperty: property];
  // multi-value? If so, create empty one and put it in
  if(!val && (type & ADMultiValueMask) && ![self readOnly])
    {
      NSMutableDictionary *newDict;
      
      val = [[[ADMultiValue alloc] initWithType: type] autorelease];
      newDict = [NSMutableDictionary dictionaryWithDictionary: _dict];
      [newDict setObject: val forKey: property];
      [_dict release];
      _dict = [[NSDictionary alloc] initWithDictionary: newDict];
    }

  return val;
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

      mv = [[[ADMultiValue alloc] initWithMultiValue: value] autorelease];
      return [self setValue: mv forProperty: property];
    }
  return [super setValue: value forProperty: property];
}

- (NSArray*) parentGroups
{
  if(![self addressBook])
    return [NSArray array];
  return [[self addressBook] groupsContainingRecord: self];
}

- (id) initWithVCardRepresentation: (NSData*) vCardData
{
  NSString *str = [[[NSString alloc] initWithData: vCardData
				     encoding: NSUTF8StringEncoding]
		    autorelease];
  if(!str)
    {
      str = [[[NSString alloc] initWithData: vCardData
			       encoding: NSASCIIStringEncoding]
	      autorelease];
      str = [[[NSString alloc] initWithCString: [str cString]]
	      autorelease];
    }
  if(!str)
    return nil;

  return [self initWithRepresentation: str type: @"vcf"];
}

- (NSData *) vCardRepresentation
{
  NSString *str; const char *utf8str;

  str = [self representationWithType: @"vcf"];
  utf8str = [str UTF8String];
  return [NSData dataWithBytes: utf8str
		 length: strlen(utf8str)];
}
@end

@implementation ADPerson (AddressesExtensions)
+ (ADScreenNameFormat) screenNameFormat
{
  return _scrNameFormat;
}

+ (void) setScreenNameFormat: (ADScreenNameFormat) aFormat
{
  NSDictionary *oldDom; NSMutableDictionary *newDom;

  if(aFormat == _scrNameFormat) return;
  _scrNameFormat = aFormat;

  oldDom = [[NSUserDefaults standardUserDefaults]
	     persistentDomainForName: @"Addresses"];
  NSAssert(oldDom, @"User defaults Domain 'Addresses' must exist");
  newDom = [NSMutableDictionary dictionaryWithDictionary: oldDom];
  
  if(_scrNameFormat == ADScreenNameLastNameFirst)
    [newDom setObject: @"LastNameFirst" forKey: @"ScreenNameFormat"];
  else
    [newDom setObject: @"FirstNameFirst" forKey: @"ScreenNameFormat"];

  [[NSUserDefaults standardUserDefaults]
    setPersistentDomain: newDom forName: @"Addresses"];
}

- (NSString*) screenName
{
  return [self screenNameWithFormat: _scrNameFormat];
}

- (NSString*) screenNameWithFormat: (ADScreenNameFormat) aFormat
{
  NSString *last, *first, *fn;

  last = [self valueForProperty: ADLastNameProperty];
  first = [self valueForProperty: ADFirstNameProperty];
  if (!last && !first) {
    fn = [self valueForProperty: ADFormattedNameProperty];
    if (fn)
      return fn;
    return @"New Person";
  }
  if (!first)
    return last;
  if (!last)
    return first;
  if(aFormat == ADScreenNameFirstNameFirst)
    return [NSString stringWithFormat: @"%@ %@", first, last];
  return [NSString stringWithFormat: @"%@, %@", last, first];
}

- (NSComparisonResult) compareByScreenName: (ADPerson*) theOtherGuy
{
  NSString *myName, *hisName;
  NSComparisonResult result;

  myName = [self screenName];
  hisName = [theOtherGuy screenName];
  
  if([myName isEqualToString: @"New Person"])
    return NSOrderedAscending;
  else if([hisName isEqualToString: @"New Person"])
    return NSOrderedDescending;
  result = [[self screenName] compare: [theOtherGuy screenName]];
  return result;
}

- (BOOL) shared
{
  if(![self valueForProperty: ADSharedProperty])
    return NO;
  return [[self valueForProperty: ADSharedProperty] boolValue];
}

- (void) setShared: (BOOL) yesno
{
  if([self shared] == yesno) return;

  if(yesno) [self setValue: @"YES" forProperty: ADSharedProperty];
  else [self setValue: @"NO" forProperty: ADSharedProperty];
}
@end

