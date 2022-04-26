// ADEnvelopeAddressBook.m (this is -*- ObjC -*-)
// 
// Authors: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADLocalAddressBook.h"
#import "ADEnvelopeAddressBook.h"
#import "ADPublicAddressBook.h"
#import "ADRecord.h"
#import "ADPerson.h"
#import "ADPlugin.h"

static ADEnvelopeAddressBook *_envelopeAB = nil;

@implementation ADEnvelopeAddressBook
+ (ADAddressBook*) sharedAddressBook
{
  NSDictionary *domain; NSArray *config; NSDictionary *entry; 
  NSEnumerator *e; NSMutableArray *books;
  int primary = 0; BOOL havePrimary = NO; int i;
  
  if(_envelopeAB)
    return _envelopeAB;

  domain = [[NSUserDefaults standardUserDefaults]
	     persistentDomainForName: @"Addresses"];
  config = [domain objectForKey: @"AddressBooks"];
  if(!config)
    {
      _envelopeAB =
	[[self alloc]
	  initWithPrimaryAddressBook: [ADLocalAddressBook sharedAddressBook]];
      return _envelopeAB;
    }

  books = [NSMutableArray array];
  e = [config objectEnumerator];
  while((entry = [e nextObject]))
    {
      NSString *className; ADAddressBook *book = nil;

      className = [entry objectForKey: @"Class"];

      if([className isEqualToString: @"Remote"])
	{
	  NSString *host, *pwd; id server;

	  host = [entry objectForKey: @"Host"];
	  pwd = [entry objectForKey: @"Password"];

	  NSLog(@"Remote at %@; password %@\n", host, pwd);
	  server =
	    [NSConnection
	      rootProxyForConnectionWithRegisteredName: @"AddressServer"
	      host: host];
	  if(!server)
	    {
	      NSLog(@"Couldn't connect to AddressServer on %@\n", host);
	      continue;
	    }

	  book = [server addressBookForReadWriteAccessWithAuth: pwd];
	  if(!book)
	    {
	      NSLog(@"Trying readonly...\n");
	      book = [server addressBookForReadOnlyAccessWithAuth: pwd];
	    }
	  if(!book)
	    NSLog(@"AddressServer on %@ doesn't accept password\n", host);
	  else
	    NSLog(@"Got book.\n");
	}

      else if([className isEqualToString: @"Local"])
	{
	  NSString *location;

	  location = [entry objectForKey: @"Location"];
	  if(!location)
	      book = [ADLocalAddressBook sharedAddressBook];
	  else
	      book = [[[ADLocalAddressBook alloc] initWithLocation: location]
			 autorelease];
	}

      else
	  book = [[ADPluginManager sharedPluginManager] 
		     newAddressBookWithSpecification: entry];


      if(!book) continue;
      
      if([[entry objectForKey: @"Primary"] boolValue])
      {
	  if(havePrimary)
	      NSLog(@"Duplicate Primary entry\n");
	  else
	      primary = [books count];
      }
	  
      [books addObject: book];
    }

  _envelopeAB = [[ADEnvelopeAddressBook alloc]
		    initWithPrimaryAddressBook: [books objectAtIndex: primary]];
  for(i=0; i<[books count]; i++)
  {
      if(i==primary) continue;
      [_envelopeAB addAddressBook: [books objectAtIndex: i]];
  }

  return _envelopeAB;
}

- initWithPrimaryAddressBook: (ADAddressBook*) book
{
  _merge = YES;
  _books = [[NSMutableArray alloc] initWithCapacity: 1];
  [self setPrimaryAddressBook: book];
  return self;
}

- (void) dealloc
{
  [_books release];
  [super dealloc];
}

- (BOOL) addAddressBook: (ADAddressBook*) book
{
  if([_books indexOfObject: book] != NSNotFound)
    return NO;
  [_books addObject: book];
  return YES;
}

- (BOOL) removeAddressBook: (ADAddressBook*) book
{
  if([_books indexOfObject: book] == NSNotFound ||
     book == _primary)
    return NO;
  [_books removeObject: book];
  return YES;
}

- (void) setPrimaryAddressBook: (ADAddressBook*) book
{
  NSAssert(book, @"Primary address book cannot be nil");

  if([_books indexOfObject: book] == NSNotFound)
    [self addAddressBook: book];
  _primary = book;
}

- (ADAddressBook*) primaryAddressBook
{
  return _primary;
}

- (NSEnumerator*) addressBooksEnumerator
{
    return [_books objectEnumerator];
}

- (void) setMergesAddressBooks: (BOOL) merge
{
  _merge = merge;
}

- (BOOL) mergesAddressBooks
{
  return _merge;
}

/*
 * Subclass stuff
 */

- (NSArray*) recordsMatchingSearchElement: (ADSearchElement*) search
{
  NSMutableArray *arr;
  NSEnumerator *e;
  ADAddressBook *book;

  arr = [NSMutableArray array];
  e = [_books objectEnumerator];
  while((book = [e nextObject]))
    [arr addObjectsFromArray: [book recordsMatchingSearchElement: search]];
  return [NSArray arrayWithArray: arr];
}

- (BOOL) save
{
  return [_primary save];
}

- (BOOL) hasUnsavedChanges
{
  return [_primary hasUnsavedChanges];
}

- (ADPerson*) me
{
  NSEnumerator *e;
  ADAddressBook *book;

  if(!_merge || [_primary me])  return [_primary me];
  e = [_books objectEnumerator];
  while((book = [e nextObject]))
    if([book me]) return [book me];
  return nil;
}
  
- (void) setMe: (ADPerson*) me
{
  return [[me addressBook] setMe: me];
}

- (ADRecord*) recordForUniqueId: (NSString*) uniqueId
{
  NSEnumerator *e;
  ADAddressBook *book; ADRecord *retval;

  e = [_books objectEnumerator];
  while((book = [e nextObject]))
    {
      retval = [book recordForUniqueId: uniqueId];
      if(retval) return retval;
    }

  return nil;
}

- (BOOL) addRecord: (ADRecord*) record
{
  return [_primary addRecord: record];
}

- (BOOL) removeRecord: (ADRecord*) record
{
  [[record addressBook] removeRecord: record];
  return YES;
}

- (NSArray*) people
{
  NSMutableArray *arr;
  NSEnumerator *e;
  ADAddressBook *book;

  if(!_merge) return [_primary people];

  arr = [NSMutableArray arrayWithCapacity: 20];
  e = [_books objectEnumerator];
  while((book = [e nextObject]))
    [arr addObjectsFromArray: [book people]];
  return arr;
}

- (NSArray*) groups
{
  NSMutableArray *arr;
  NSEnumerator *e;
  ADAddressBook *book;

  if(!_merge) return [_primary groups];

  arr = [NSMutableArray arrayWithCapacity: 20];
  e = [_books objectEnumerator];
  while((book = [e nextObject]))
    [arr addObjectsFromArray: [book groups]];
  return arr;
}

@end // ADEnvelopeAddressBook

@implementation ADEnvelopeAddressBook(GroupAccess)
- (NSArray*) membersForGroup: (ADGroup*) group
{
  [NSException raise: ADUnimplementedError
	       format: @"ADEnvelopeAddressBook cannot implement %@",
	       NSStringFromSelector(_cmd)];
  return nil;
}
- (BOOL) addMember: (ADPerson*) person forGroup: (ADGroup*) group
{ 
  [NSException raise: ADUnimplementedError
	       format: @"ADEnvelopeAddressBook cannot implement %@",
	       NSStringFromSelector(_cmd)];
  return NO;
}
- (BOOL) removeMember: (ADPerson*) person forGroup: (ADGroup*) group
{ 
  [NSException raise: ADUnimplementedError
	       format: @"ADEnvelopeAddressBook cannot implement %@",
	       NSStringFromSelector(_cmd)];
  return NO;
}

- (NSArray*) subgroupsForGroup: (ADGroup*) group
{ 
  [NSException raise: ADUnimplementedError
	       format: @"ADEnvelopeAddressBook cannot implement %@",
	       NSStringFromSelector(_cmd)];
  return nil;
}
- (BOOL) addSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2
{ 
  [NSException raise: ADUnimplementedError
	       format: @"ADEnvelopeAddressBook cannot implement %@",
	       NSStringFromSelector(_cmd)];
  return NO;
}
- (BOOL) removeSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2
{ 
  [NSException raise: ADUnimplementedError
	       format: @"ADEnvelopeAddressBook cannot implement %@",
	       NSStringFromSelector(_cmd)];
  return NO;
}
- (NSArray*) parentGroupsForGroup: (ADGroup*) group;
{ 
  [NSException raise: ADUnimplementedError
	       format: @"ADEnvelopeAddressBook cannot implement %@",
	       NSStringFromSelector(_cmd)];
  return nil;
}
@end

