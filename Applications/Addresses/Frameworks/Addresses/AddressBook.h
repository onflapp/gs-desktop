// AddressBook.h (this is -*- ObjC -*-)
// 
// Author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import <Addresses/Addresses.h>


// main classes
#define ABAddressBook       ADAddressBook
#define ABGroup             ADGroup
#define ABMultiValue        ADMultiValue
#define ABMutableMultiValue ADMutableMultiValue
#define ABPerson            ADPerson
#define ABRecord            ADRecord
#define ABSearchElement     ADSearchElement

// typedefs
#define kABMultiValueMask          ADMultiValueMask
#define kABErrorInProperty         ADErrorInProperty
#define kABStringProperty          ADStringProperty
#define kABIntegerProperty         ADIntegerProperty
#define kABRealProperty            ADRealProperty
#define kABDateProperty            ADDateProperty
#define kABArrayProperty           ADArrayProperty
#define kABDictionaryProperty      ADDictionaryProperty
#define kABDataProperty            ADDataProperty
#define kABMultiStringProperty     ADMultiStringProperty
#define kABMultiIntegerProperty    ADMultiIntegerProperty
#define kABMultiRealProperty       ADMultiRealProperty 
#define kABMultiDateProperty       ADMultiDateProperty
#define kABMultiArrayProperty      ADMultiArrayProperty
#define kABMultiDictionaryProperty ADMultiDictionaryProperty
#define kABMultiDataProperty       ADMultiDataProperty
#define ABPropertyType ADPropertyType

#define kABEqual                            ADEqual
#define kABNotEqual                         ADNotEqual
#define kABLessThan                         ADLessThan
#define kABLessThanOrEqual                  ADLessThanOrEqual
#define kABGreaterThan                      ADGreaterThan
#define kABGreaterThanOrEqual               ADGreaterThanOrEqual
#define kABEqualCaseInsensitive             ADEqualCaseInsensitive
#define kABContainsSubString                ADContainsSubString
#define kABContainsSubStringCaseInsensitive ADContainsSubStringCaseInsensitive
#define kABPrefixMatch                      ADPrefixMatch
#define kABPrefixMatchCaseInsensitive       ADPrefixMatchCaseInsensitive
#define ABSearchComparison ADSearchComparison

#define kABSearchAnd ADSearchAnd
#define kABSearchOr  ADSearchOr
#define ABSearchConjunction ADSearchConjunction

// globals
#define kABUIDProperty                ADUIDProperty
#define kABCreationDateProperty       ADCreationDateProperty
#define kABModificationDateProperty   ADModificationDateProperty
#define kABFirstNameProperty          ADFirstNameProperty
#define kABLastNameProperty           ADLastNameProperty
#define kABMiddleNameProperty         ADMiddleNameProperty
#define kABMiddleNamePhoneticProperty ADMiddleNamePhoneticProperty
#define kABFirstNamePhoneticProperty  ADFirstNamePhoneticProperty
#define kABLastNamePhoneticProperty   ADLastNamePhoneticProperty
#define kABTitleProperty              ADTitleProperty
#define kABSuffixProperty             ADSuffixProperty
#define kABNicknameProperty           ADNicknameProperty
#define kABMaidenNameProperty         ADMaidenNameProperty
#define kABBirthdayProperty           ADBirthdayProperty
#define kABOrganizationProperty       ADOrganizationProperty
#define kABJobTitleProperty           ADJobTitleProperty
#define kABHomePageProperty           ADHomePageProperty
#define kABEmailProperty              ADEmailProperty
#define kABEmailWorkLabel             ADEmailWorkLabel
#define kABEmailHomeLabel             ADEmailHomeLabel
#define kABAddressProperty            ADAddressProperty
#define kABAddressStreetKey           ADAddressStreetKey
#define kABAddressCityKey             ADAddressCityKey
#define kABAddressStateKey            ADAddressStateKey
#define kABAddressZIPKey              ADAddressZIPKey
#define kABAddressCountryKey          ADAddressCountryKey
#define kABAddressCountryCodeKey      ADAddressCountryCodeKey
#define kABAddressHomeLabel           ADAddressHomeLabel
#define kABAddressWorkLabel           ADAddressWorkLabel
#define kABPhoneProperty              ADPhoneProperty
#define kABPhoneWorkLabel             ADPhoneWorkLabel
#define kABPhoneHomeLabel             ADPhoneHomeLabel
#define kABPhoneMobileLabel           ADPhoneMobileLabel
#define kABPhoneMainLabel             ADPhoneMainLabel
#define kABPhoneHomeFAXLabel          ADPhoneHomeFAXLabel
#define kABPhoneWorkFAXLabel          ADPhoneWorkFAXLabel
#define kABPhonePagerLabel            ADPhonePagerLabel
#define kABAIMInstantProperty         ADAIMInstantProperty
#define kABAIMWorkLabel               ADAIMWorkLabel
#define kABAIMHomeLabel               ADAIMHomeLabel
#define kABJabberInstantProperty      ADJabberInstantProperty
#define kABJabberWorkLabel            ADJabberWorkLabel
#define kABJabberHomeLabel            ADJabberHomeLabel
#define kABMSNInstantProperty         ADMSNInstantProperty
#define kABMSNWorkLabel               ADMSNWorkLabel
#define kABMSNHomeLabel               ADMSNHomeLabel
#define kABYahooInstantProperty       ADYahooInstantProperty
#define kABYahooWorkLabel             ADYahooWorkLabel
#define kABYahooHomeLabel             ADYahooHomeLabel
#define kABICQInstantProperty         ADICQInstantProperty
#define kABICQWorkLabel               ADICQWorkLabel
#define kABICQHomeLabel               ADICQHomeLabel
#define kABNoteProperty               ADNoteProperty
#define kABGroupNameProperty          ADGroupNameProperty
#define kABWorkLabel                  ADWorkLabel
#define kABHomeLabel                  ADHomeLabel
#define kABOtherLabel                 ADOtherLabel

#define kABDatabaseChangedNotification ADDatabaseChangedNotification
#define kABDatabaseChangedExternallyNotification ADDatabaseChangedExternallyNotification

#define ABLocalizedPropertyOrLabel ADLocalizedPropertyOrLabel
