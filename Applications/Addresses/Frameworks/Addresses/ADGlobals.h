// ADGlobals.h (this is -*- ObjC -*-)
//
// \author: BjÅˆrn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#ifndef _ADGLOBALS_H_
#define _ADGLOBALS_H_

#import <Foundation/NSString.h>


/*
 * Properties common to all Records
 */
extern NSString * const ADUIDProperty;                // string
extern NSString * const ADCreationDateProperty;       // date
extern NSString * const ADModificationDateProperty;   // date
extern NSString * const ADSharedProperty;             // @"YES"/@"NO" NON-APPLE

/*
 * Person-specific properties
 */
extern NSString * const ADFirstNameProperty;          // string
extern NSString * const ADLastNameProperty;           // string
extern NSString * const ADMiddleNameProperty;	      // string UNSUPP
extern NSString * const ADMiddleNamePhoneticProperty; // string UNSUPP
extern NSString * const ADFirstNamePhoneticProperty;  // string UNSUPP
extern NSString * const ADLastNamePhoneticProperty;   // string UNSUPP
extern NSString * const ADTitleProperty;	      // string UNSUPP
extern NSString * const ADSuffixProperty;             // string UNSUPP
extern NSString * const ADNicknameProperty;           // string UNSUPP
extern NSString * const ADMaidenNameProperty;         // string UNSUPP

extern NSString * const ADFormattedNameProperty;

extern NSString * const ADBirthdayProperty;           // date
extern NSString * const ADOrganizationProperty;       // string
extern NSString * const ADJobTitleProperty;           // string
extern NSString * const ADHomePageProperty;           // string

extern NSString * const ADEmailProperty;              // multi-string
extern NSString * const ADEmailWorkLabel;
extern NSString * const ADEmailHomeLabel;

extern NSString * const ADAddressProperty;            // multi-dictionary
extern NSString * const ADAddressStreetKey;
extern NSString * const ADAddressCityKey;
extern NSString * const ADAddressStateKey;
extern NSString * const ADAddressZIPKey;
extern NSString * const ADAddressCountryKey;
extern NSString * const ADAddressCountryCodeKey;
extern NSString * const ADAddressPOBoxKey;           // NON-APPLE EXTENSION
extern NSString * const ADAddressExtendedAddressKey; // NON-APPLE EXTENSION
extern NSString * const ADAddressHomeLabel;
extern NSString * const ADAddressWorkLabel;

extern NSString * const ADImageProperty;
extern NSString * const ADImageTypeProperty;         // NON-APPLE EXTENSION

extern NSString * const ADPhoneProperty;     // multi-string
extern NSString * const ADPhoneWorkLabel;
extern NSString * const ADPhoneHomeLabel;
extern NSString * const ADPhoneMobileLabel;
extern NSString * const ADPhoneMainLabel;
extern NSString * const ADPhoneHomeFAXLabel;
extern NSString * const ADPhoneWorkFAXLabel;
extern NSString * const ADPhonePagerLabel;

extern NSString * const ADAIMInstantProperty;    // multi-string
extern NSString * const ADAIMWorkLabel;
extern NSString * const ADAIMHomeLabel;

extern NSString * const ADJabberInstantProperty; // multi-string
extern NSString * const ADJabberWorkLabel;
extern NSString * const ADJabberHomeLabel;

extern NSString * const ADMSNInstantProperty;    // multi-string
extern NSString * const ADMSNWorkLabel;
extern NSString * const ADMSNHomeLabel;

extern NSString * const ADYahooInstantProperty;  // multi-string
extern NSString * const ADYahooWorkLabel;
extern NSString * const ADYahooHomeLabel;

extern NSString * const ADICQInstantProperty;    // multi-string
extern NSString * const ADICQWorkLabel;
extern NSString * const ADICQHomeLabel;

extern NSString * const ADNoteProperty;          // string

/*
 * Group-specific
 */
extern NSString * const ADGroupNameProperty;     // string
extern NSString * const ADMemberIDsProperty;     // array; NON-APPLE EXTENSION

/*
 * Generic labels
 */
extern NSString * const ADWorkLabel;
extern NSString * const ADHomeLabel;
extern NSString * const ADOtherLabel;

/*
 * Notifications and parameters
 */
extern NSString * const ADDatabaseChangedNotification;
extern NSString * const ADDatabaseChangedExternallyNotification;
extern NSString * const ADRecordChangedNotification; // EXTENSION

extern NSString * const ADUniqueIDOfChangedRecordKey;
extern NSString * const ADChangedPropertyKey;
extern NSString * const ADChangedValueKey;
extern NSString * const ADAddressBookContainingChangedRecordKey;

// Return localized version of built-in properties, labels or keys
NSString *ADLocalizedPropertyOrLabel(NSString *propertyOrLabel);

/*
 * Some errors
 */
extern NSString* ADAddressBookInaccessibleError;
extern NSString* ADAddressBookConsistencyError;
extern NSString* ADAddressBookInternalError; // report this to author!
extern NSString* ADUnimplementedError; // report this to author!

@interface ADScriptingInfo: NSObject
+ (NSDictionary*) namedObjectsForScripting;
@end

/*
 * Some utility functions
 */

NSArray *ADReadOnlyCopyOfRecordArray(NSArray* arr);

#endif
