// ADGlobals.m (this is -*- ObjC -*-)
// 
// Author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import <Foundation/Foundation.h>


#import "ADGlobals.h"
#import "ADAddressBook.h"
#import "ADLocalAddressBook.h"

NSString* const ADUIDProperty = @"UID";
NSString* const ADCreationDateProperty = @"CreationDate";
NSString* const ADModificationDateProperty = @"ModificationDate";
NSString* const ADSharedProperty = @"Shared";

NSString* const ADFirstNameProperty = @"FirstName";
NSString* const ADLastNameProperty = @"LastName";

NSString* const ADFirstNamePhoneticProperty = @"FirstNamePhonetic";
NSString* const ADLastNamePhoneticProperty = @"LastNamePhonetic";

NSString* const ADFormattedNameProperty = @"FormattedName";

NSString* const ADBirthdayProperty = @"BirthDate";
NSString* const ADOrganizationProperty = @"Organization";
NSString* const ADJobTitleProperty = @"JobTitle"; 
NSString* const ADHomePageProperty = @"HomePage";
NSString* const ADEmailProperty = @"Email";
NSString* const ADEmailWorkLabel = @"WorkEmail";
NSString* const ADEmailHomeLabel = @"HomeEmail";

NSString* const ADAddressProperty = @"Address";
NSString* const ADAddressStreetKey = @"Street";
NSString* const ADAddressCityKey = @"City";
NSString* const ADAddressStateKey = @"State";
NSString* const ADAddressZIPKey = @"ZIP";
NSString* const ADAddressCountryKey = @"Country";
NSString* const ADAddressCountryCodeKey = @"CountryCode";
NSString* const ADAddressPOBoxKey = @"POBox";             // EXTENSION
NSString* const ADAddressExtendedAddressKey = @"ExtAddr"; // EXTENSION
NSString* const ADAddressHomeLabel = @"HomeAddr";
NSString* const ADAddressWorkLabel = @"WorkAddr";

NSString* const ADPhoneProperty = @"Phone";
NSString* const ADPhoneWorkLabel = @"WorkPhone";
NSString* const ADPhoneHomeLabel = @"HomePhone";
NSString* const ADPhoneMobileLabel = @"MobilePhone";
NSString* const ADPhoneMainLabel = @"MainPhone";
NSString* const ADPhoneHomeFAXLabel = @"HomeFax";
NSString* const ADPhoneWorkFAXLabel = @"WorkFax";
NSString* const ADPhonePagerLabel = @"Pager";

NSString* const ADAIMInstantProperty = @"AIM";
NSString* const ADAIMWorkLabel = @"WorkAIM";
NSString* const ADAIMHomeLabel = @"HomeAIM";

NSString* const ADJabberInstantProperty = @"Jabber";
NSString* const ADJabberWorkLabel = @"WorkJabber";
NSString* const ADJabberHomeLabel = @"HomeJabber";

NSString* const ADMSNInstantProperty = @"MSN";
NSString* const ADMSNWorkLabel = @"WorkMSN";
NSString* const ADMSNHomeLabel = @"HomeMSN";

NSString* const ADYahooInstantProperty = @"Yahoo";
NSString* const ADYahooWorkLabel = @"WorkYahoo";
NSString* const ADYahooHomeLabel = @"HomeYahoo";

NSString* const ADICQInstantProperty = @"ICQ";
NSString* const ADICQWorkLabel = @"WorkICQ";
NSString* const ADICQHomeLabel = @"HomeICQ";

NSString* const ADNoteProperty = @"Note";

NSString* const ADMiddleNameProperty = @"MiddleName";
NSString* const ADMiddleNamePhoneticProperty = @"MiddleNamePhonetic";
NSString* const ADTitleProperty = @"Title";
NSString* const ADSuffixProperty = @"Suffix";
NSString* const ADNicknameProperty = @"Nickname";
NSString* const ADMaidenNameProperty = @"MaidenName";

NSString * const ADImageProperty = @"Image";
NSString * const ADImageTypeProperty = @"ImageType";

NSString* const ADGroupNameProperty = @"GroupName";
NSString* const ADMemberIDsProperty = @"Members";

NSString* const ADWorkLabel = @"Work";
NSString* const ADHomeLabel = @"Home";
NSString* const ADOtherLabel = @"Other";

NSString* const ADDatabaseChangedNotification=@"ADDatabaseChangedNotification";
NSString* const ADDatabaseChangedExternallyNotification=@"ADDatabaseChangedExternallyNotification";
NSString * const ADRecordChangedNotification=@"ADRecordChangedNotification";
NSString * const ADUniqueIDOfChangedRecordKey=@"ADUniqueIDOfChangedRecordKey";
NSString * const ADChangedPropertyKey=@"ADChangedPropertyKey";
NSString * const ADChangedValueKey=@"ADChangedValueKey";
NSString * const ADAddressBookContainingChangedRecordKey=@"ADAddressBookContainingChangedRecordKey";

NSString* ADAddressBookInaccessibleError = @"ADAddressBookInaccessibleError";
NSString* ADAddressBookConsistencyError = @"ADAddressBookConsistencyError";
NSString* ADAddressBookInternalError = @"ADAddressBookInternalError";
NSString* ADUnimplementedError = @"ADUnimplementedError";

static NSBundle *myBundle = nil;
NSString* ADLocalizedPropertyOrLabel(NSString* propertyOrLabel)
{
  NSString *str;
  if(!myBundle)
    myBundle = [NSBundle bundleForClass: [ADAddressBook class]];
  str = [myBundle localizedStringForKey: propertyOrLabel
			    value: propertyOrLabel
			    table: @"PropertiesAndLabels"];
  
  if(str) return str;
  return propertyOrLabel;
}

@implementation ADScriptingInfo
+ (NSDictionary*) namedObjectsForScripting
{
  return
    [NSDictionary
      dictionaryWithObjectsAndKeys:
	ADUIDProperty, @"ADUIDProperty",
      ADCreationDateProperty, @"ADCreationDateProperty",
      ADModificationDateProperty, @"ADModificationDateProperty",
      ADFirstNameProperty, @"ADFirstNameProperty",
      ADLastNameProperty, @"ADLastNameProperty",
      ADMiddleNameProperty, @"ADMiddleNameProperty",
      ADMiddleNamePhoneticProperty, @"ADMiddleNamePhoneticProperty",
      ADFirstNamePhoneticProperty, @"ADFirstNamePhoneticProperty",
      ADLastNamePhoneticProperty, @"ADLastNamePhoneticProperty",
      ADTitleProperty, @"ADTitleProperty",
      ADSuffixProperty, @"ADSuffixProperty",
      ADNicknameProperty, @"ADNicknameProperty",
      ADMaidenNameProperty, @"ADMaidenNameProperty",
      
      ADBirthdayProperty, @"ADBirthdayProperty",
      ADOrganizationProperty, @"ADOrganizationProperty",
      ADJobTitleProperty, @"ADJobTitleProperty",
      ADHomePageProperty, @"ADHomePageProperty",
      
      ADEmailProperty, @"ADEmailProperty",
      ADEmailWorkLabel, @"ADEmailWorkLabel",
      ADEmailHomeLabel, @"ADEmailHomeLabel",
      
      ADAddressProperty, @"ADAddressProperty",
      ADAddressStreetKey, @"ADAddressStreetKey",
      ADAddressCityKey, @"ADAddressCityKey",
      ADAddressStateKey, @"ADAddressStateKey",
      ADAddressZIPKey, @"ADAddressZIPKey",
      ADAddressCountryKey, @"ADAddressCountryKey",
      ADAddressCountryCodeKey, @"ADAddressCountryCodeKey",
      ADAddressPOBoxKey, @"ADAddressPOBoxKey",
      ADAddressExtendedAddressKey, @"ADAddressExtendedAddressKey",
      ADAddressHomeLabel, @"ADAddressHomeLabel",
      ADAddressWorkLabel, @"ADAddressWorkLabel",
      
      ADImageProperty, @"ADImageProperty",
      
      ADPhoneProperty, @"ADPhoneProperty",
      ADPhoneWorkLabel, @"ADPhoneWorkLabel",
      ADPhoneHomeLabel, @"ADPhoneHomeLabel",
      ADPhoneMobileLabel, @"ADPhoneMobileLabel",
      ADPhoneMainLabel, @"ADPhoneMainLabel",
      ADPhoneHomeFAXLabel, @"ADPhoneHomeFAXLabel",
      ADPhoneWorkFAXLabel, @"ADPhoneWorkFAXLabel",
      ADPhonePagerLabel, @"ADPhonePagerLabel",
      
      ADAIMInstantProperty, @"ADAIMInstantProperty",
      ADAIMWorkLabel, @"ADAIMWorkLabel",
      ADAIMHomeLabel, @"ADAIMHomeLabel",
      
      ADJabberInstantProperty, @"ADJabberInstantProperty",
      ADJabberWorkLabel, @"ADJabberWorkLabel",
      ADJabberHomeLabel, @"ADJabberHomeLabel",
      
      ADMSNInstantProperty, @"ADMSNInstantProperty",
      ADMSNWorkLabel, @"ADMSNWorkLabel",
      ADMSNHomeLabel, @"ADMSNHomeLabel",
      
      ADYahooInstantProperty, @"ADYahooInstantProperty",
      ADYahooWorkLabel, @"ADYahooWorkLabel",
      ADYahooHomeLabel, @"ADYahooHomeLabel",
      
      ADICQInstantProperty, @"ADICQInstantProperty",
      ADICQWorkLabel, @"ADICQWorkLabel",
      ADICQHomeLabel, @"ADICQHomeLabel",
      
      ADNoteProperty, @"ADNoteProperty",
      
      ADGroupNameProperty, @"ADGroupNameProperty",
      
      ADWorkLabel, @"ADWorkLabel",
      ADHomeLabel, @"ADHomeLabel",
      ADOtherLabel, @"ADOtherLabel",
      
      ADDatabaseChangedNotification, @"ADDatabaseChangedNotification",
      ADDatabaseChangedExternallyNotification, @"ADDatabaseChangedExternallyNotification",
      ADRecordChangedNotification, @"ADRecordChangedNotification",
      
      ADAddressBookInaccessibleError, @"ADAddressBookInaccessibleError",
      ADAddressBookConsistencyError, @"ADAddressBookConsistencyError",
      ADAddressBookInternalError, @"ADAddressBookInternalError",
      ADUnimplementedError, @"ADUnimplementedError",
      nil];
}
@end

/*
 * Utility functions
 */

NSArray*
ADReadOnlyCopyOfRecordArray(NSArray* arr)
{
  NSMutableArray *retval; NSEnumerator *e; ADRecord *r;

  retval = [NSMutableArray arrayWithCapacity: [arr count]];
  e = [arr objectEnumerator];

  while((r = [e nextObject]))
    {
      r = [[r copy] autorelease];
      [r setReadOnly];
      [retval addObject: r];
    }

  return [NSArray arrayWithArray: retval];
}
