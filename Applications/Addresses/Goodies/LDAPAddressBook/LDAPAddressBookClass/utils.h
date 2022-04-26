#ifndef UTILS_H
#define UTILS_H

#include <Foundation/Foundation.h>
#include <ldap.h>
#include <gsldap/GSLDAPConnection.h>
#include <gsldap/GSLDAPEntry.h>
#include <Addresses/Addresses.h>

NSString* authMethodToString(int authMethod);
int stringToAuthMethod(NSString* str);

NSString* scopeToString(int scope);
int stringToScope(NSString* str);

ADPerson* ldapEntryToPerson(GSLDAPEntry* entry);
GSLDAPEntry* personToLDAPEntry(ADPerson* person);

#endif // UTILS_H

