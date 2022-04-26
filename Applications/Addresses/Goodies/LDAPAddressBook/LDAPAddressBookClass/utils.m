#include "utils.h"
#include <ldap.h>

NSString* authMethodToString(int authMethod)
{
    switch(authMethod)
    {
	case LDAP_AUTH_NONE: return @"NONE";
	case LDAP_AUTH_SIMPLE: return @"SIMPLE";
	case LDAP_AUTH_SASL: return @"SASL";
	case LDAP_AUTH_KRBV4: return @"KRBV4";
	case LDAP_AUTH_KRBV41: return @"KRBV41";
	case LDAP_AUTH_KRBV42: return @"KRBV42";
	default: return @"UNKNOWN";
    }
}

int stringToAuthMethod(NSString* str)
{
    str = [str uppercaseString];
    if([str isEqualToString: @"NONE"]) return LDAP_AUTH_NONE;
    if([str isEqualToString: @"SIMPLE"]) return LDAP_AUTH_SIMPLE;
    if([str isEqualToString: @"SASL"]) return LDAP_AUTH_SASL;
    if([str isEqualToString: @"KRBV4"]) return LDAP_AUTH_KRBV4;
    if([str isEqualToString: @"KRBV41"]) return LDAP_AUTH_KRBV41;
    if([str isEqualToString: @"KRBV42"]) return LDAP_AUTH_KRBV42;
    return -1;
}

NSString* scopeToString(int scope)
{
    switch(scope)
    {
	case LDAP_SCOPE_DEFAULT: return @"DEFAULT";
	case LDAP_SCOPE_BASE: return @"BASE";
	case LDAP_SCOPE_ONELEVEL: return @"ONELEVEL";
	case LDAP_SCOPE_SUBTREE: return @"SUBTREE";
	default: return @"UNKNOWN";
    }
}

int stringToScope(NSString* str)
{
    str = [str uppercaseString];
    if([str isEqualToString: @"DEFAULT"]) return LDAP_SCOPE_DEFAULT;
    if([str isEqualToString: @"BASE"]) return LDAP_SCOPE_BASE;
    if([str isEqualToString: @"ONELEVEL"]) return LDAP_SCOPE_ONELEVEL;
    if([str isEqualToString: @"SUBTREE"]) return LDAP_SCOPE_SUBTREE;
    return -1;
}

NSArray *mapping = NULL;
NSArray *skip = NULL;
@class LDAPAddressBook;

void initMapping(void)
{
    if(!mapping)
    {
	NSBundle *currentBundle; NSString *path; 
	currentBundle = [NSBundle bundleForClass: [LDAPAddressBook class]];
	path = [currentBundle pathForResource: @"LDAPPersonMapping"
			      ofType: @"plist"];
	mapping = [[NSString stringWithContentsOfFile: path] propertyList];
	[mapping retain];
    }
    if(!skip)
    {
	skip = [[NSArray alloc] initWithObjects: @"cn", @"objectClass", NULL];
    }
}

id addressesKeyForLDAPKey(NSString *key)
{
    int i, j;

    if(!mapping) initMapping();

    for(i=0; i<[mapping count]; i++)
    {
	NSArray *arr = [[mapping objectAtIndex: i] 
			   objectForKey: @"LDAPKeys"];
	for(j=0; j<[arr count]; j++)
	    if([[arr objectAtIndex: j] caseInsensitiveCompare: key] == 
	       NSOrderedSame)
		return [[mapping objectAtIndex: i] 
			   objectForKey: @"AddressesKey"];
    }

    return nil;
}
		       

ADPerson* ldapEntryToPerson(GSLDAPEntry* entry)
{
    ADPerson *p; NSEnumerator *nameE; NSString *name;

    p = [[[ADPerson alloc] init] autorelease];
    nameE = [entry attributeNameEnumerator];
    while((name = [nameE nextObject]))
    {
	NSArray *val; id addrKey; int i;
	NSString *property = nil, *label = nil, *key = nil;
	ADPropertyType type;

	if([skip containsObject: name]) continue;

	val = [entry valuesForAttributeNamed: name];
	addrKey = addressesKeyForLDAPKey(name);

	if(!addrKey)
	{
	    NSLog(@"Can't handle LDAP key %@ yet\n", name);
	    continue;
	}

	if([addrKey isEqualToString: @"Skip"])
	    continue;

	if([addrKey isKindOfClass: [NSString class]])
	    property = addrKey;
	else
	{
	    property = [addrKey objectForKey: @"Property"];
	    label = [addrKey objectForKey: @"Label"];
	    key = [addrKey objectForKey: @"Key"];
	}

	type = [[ADPerson class] typeOfProperty: property];
	if(!type)
	{
	    NSLog(@"Error in Property %@ for %@\n",
		  property, name);
	    continue;
	}

	// string? set it directly
	if(type == ADStringProperty)
	{
	    [p setValue: [val objectAtIndex: 0]
	       forProperty: property];
	    continue;
	}
	   
	// multi-value, but not multi-dictionary
	else if(type == ADMultiStringProperty)
	{
	    ADMultiValue *v; ADMutableMultiValue *mv;

	    v = [p valueForProperty: property];
	    if(!v)
		mv = [[[ADMutableMultiValue alloc] init] autorelease];
	    else
		mv = [v mutableCopy];
	    
	    for(i=0; i<[val count]; i++)
		[mv addValue: [val objectAtIndex: i]
		    withLabel: label];

	    [p setValue: [[[ADMultiValue alloc] initWithMultiValue: mv]
			     autorelease]
	       forProperty: property];
	}
	
	else if(type == ADMultiDictionaryProperty)
	{
	    ADMultiValue *v; ADMutableMultiValue *mv;
	    NSDictionary *d; NSMutableDictionary *md;
	    int index; BOOL have;

	    v = [p valueForProperty: property];
	    if(!v)
		mv = [[[ADMutableMultiValue alloc] init] autorelease];
	    else
		mv = [v mutableCopy];
	    
	    d = nil; have = NO;
	    for(index=0; index<[mv count]; index++)
		if([[mv labelAtIndex: index] isEqualToString: label])
		{
		    have = YES;
		    d = [mv valueAtIndex: index];
		    break;
		}

	    if(!d) md = [NSMutableDictionary dictionary];
	    else md = [[[NSMutableDictionary alloc] initWithDictionary: d]
			  autorelease];

	    [md setObject: [val objectAtIndex: 0] forKey: key];
	    
	    if(have)
		[mv replaceValueAtIndex: index
		    withValue: [NSDictionary dictionaryWithDictionary: md]];
	    else
		[mv addValue: [NSDictionary dictionaryWithDictionary: md]
		    withLabel: label];

	    [p setValue: [[[ADMultiValue alloc] initWithMultiValue: mv]
			     autorelease]
	       forProperty: property];
	}

	else
	{
	    NSLog(@"Can't handle values of type %d yet\n", type);
	}
    }

    return p;
}

GSLDAPEntry* personToLDAPEntry(ADPerson* person)
{
    return nil;
}
