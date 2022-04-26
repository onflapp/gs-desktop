// ADPlugin.h (this is -*- ObjC -*-)
// 
// Author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADAddressBook.h"

/** 
    This class defines the interface for address book class plugins. An
    address book class plugin is contained in a bundle that gets loaded at
    runtime. It can create address books of one specific kind (see the LDAP
    plugin as an example, and the main README file for an overview). 

    Specifications to create address books are given as dictionaries,
    contained in the AddressBooks array in the Addresses user defaults
    domain. Typically, an address book class plugin is accompanied by a
    configurator gui plugin that gets loaded by AddressManager. The gui writes
    the defaults entry.

    An address book class plugin's name ends in ".abclass", not in ".bundle"!
*/

@protocol ADPluggedInAddressBook
/** Return a new address book according to the dictionary contained in the
    specification. */
- initWithSpecification: (NSDictionary*) aSpec;
@end

@interface ADPluginManager: NSObject
{
    NSMutableArray* abClassPlugins;
}

+ (ADPluginManager*) sharedPluginManager;

/** Check the usual places for bundles that end in ".abclass", and which have
    not already been loaded. */
- (BOOL) checkForNewPlugins;

/** Look for "ClassName" in aSpec, then look for an appropriate class in
    abClassPlugins, then try to create an instance using aSpec and return
    it. */ 
- (ADAddressBook*) newAddressBookWithSpecification: (NSDictionary*) aSpec;
@end
