#include <Addresses/Addresses.h>
#include <ldap.h>
#include <gsldap/GSLDAPConnection.h>
#include <gsldap/GSLDAPEntry.h>
#include "utils.h"

@interface LDAPAddressBook: ADAddressBook <ADPluggedInAddressBook>
{
    GSLDAPConnection *connection;
    NSString *disabledReason;
    NSString *host;
    int port;
    unsigned int authMethod;
    NSString *bindDN, *bindPassword, *baseDN;
    unsigned int scope, flags;
}
@end

@interface LDAPAddressBook (Private)
- (BOOL) checkConnection;
@end

@implementation LDAPAddressBook (Private)
- (BOOL) checkConnection
{
    if(!connection ||
       (![connection isConnected] && ![connection connect]))
    {
	disabledReason = @"Could not open connection";
	return NO;
    }
    return YES;
}
@end

@implementation LDAPAddressBook
- initWithSpecification: (NSDictionary*) aSpec
{
    disabledReason = nil;

    host = nil; 
    port = 389; 
    authMethod = LDAP_AUTH_NONE;
    bindDN = @""; 
    bindPassword = @"";
    baseDN = @"";
    scope = 0;
    flags = (GSLDAPConnection__bindOnConnect | GSLDAPConnection__autoConnect);

    if([aSpec objectForKey: @"Host"]) 
	host = [aSpec objectForKey: @"Host"];
    if([aSpec objectForKey: @"Port"]) 
	port = [[aSpec objectForKey: @"Port"] intValue];
    if([aSpec objectForKey: @"AuthMethod"]) 
	authMethod = stringToAuthMethod([aSpec objectForKey: @"AuthMethod"]);
    if([aSpec objectForKey: @"BindDN"]) 
	bindDN = [aSpec objectForKey: @"BindDN"];
    if([aSpec objectForKey: @"BindPassword"]) 
	bindPassword = [aSpec objectForKey: @"BindPassword"];
    if([aSpec objectForKey: @"BaseDN"]) 
	baseDN = [aSpec objectForKey: @"BaseDN"];
    if([aSpec objectForKey: @"Scope"]) 
	scope = stringToScope([aSpec objectForKey: @"Scope"]);

    // Fixme method, etc.

    if(!host)
    {
	disabledReason = @"No host given";
	return self;
    }

    NSLog(@"Auth method: %d\n", authMethod);

    connection = [[GSLDAPConnection alloc] initWithHost: host
					   port: port
					   authMethod: authMethod
					   bindDN: bindDN
					   bindPassword: bindPassword
					   baseDN: baseDN
					   scope: scope
					   flags: flags];

    [self checkConnection];
    return self;
}

// LDAP can't change records
- (BOOL) save { return YES; }
- (BOOL) hasUnsavedChanges { return NO; }
- (ADPerson*) me { return nil; }
- (void) setMe: (ADPerson*) me {}
- (BOOL) addRecord: (ADRecord*) record { return NO; } 
- (BOOL) removeRecord: (ADRecord*) record { return NO; }
- (BOOL) addMember: (ADPerson*) person forGroup: (ADGroup*) group 
{ return NO; }
- (BOOL) removeMember: (ADPerson*) person forGroup: (ADGroup*) group
{ return NO; }
- (BOOL) addSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2
{ return NO; }
- (BOOL) removeSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2
{ return NO; }

- (ADRecord*) recordForUniqueId: (NSString*) uniqueId;
{ 
    // FIXME 
    [self subclassResponsibility: _cmd]; return nil; 
}
- (NSArray*) people
{ 
    NSArray *ldapResult;
    NSMutableArray *retval;
    int i;

    if(![self checkConnection]) return nil;

    ldapResult = [connection searchFilter: @"(objectclass=person)" 
			     attributes: nil];
    if(![ldapResult count])
	return [NSMutableArray array];

    retval = [NSMutableArray arrayWithCapacity: [ldapResult count]];
    for(i=0; i<[ldapResult count]; i++)
    {
	ADPerson *p = ldapEntryToPerson([ldapResult objectAtIndex: i]);
	[p setAddressBook: self];
	[retval addObject: p];
    }
    return retval;
}
- (NSArray*) groups
{
    // FIXME 
    [self subclassResponsibility: _cmd]; return nil; 
}
- (NSArray*) membersForGroup: (ADGroup*) group
{
    // FIXME
    [self subclassResponsibility: _cmd]; return nil; 
}
- (NSArray*) subgroupsForGroup: (ADGroup*) group
{ 
    // FIXME 
    [self subclassResponsibility: _cmd]; return nil; 
}
- (NSArray*) parentGroupsForGroup: (ADGroup*) group;
{ 
    // FIXME 
    [self subclassResponsibility: _cmd]; return nil; 
}

- (NSDictionary*) addressBookDescription
{
    NSMutableDictionary *dict =
	[NSMutableDictionary 
	    dictionaryWithObjectsAndKeys: [self className], @"Class", 
	    host, @"Host", [NSString stringWithFormat: @"%d", port], @"Port",
	    bindDN, @"BindDN", bindPassword, @"BindPassword",
	    baseDN, @"BaseDN", 
	    authMethodToString(authMethod), @"AuthMethod",
	    scopeToString(scope), @"Scope", 
	    nil];

    if(disabledReason)
	[dict setObject: disabledReason forKey: @"Error"];

    return [NSDictionary dictionaryWithDictionary: dict];
}
@end
