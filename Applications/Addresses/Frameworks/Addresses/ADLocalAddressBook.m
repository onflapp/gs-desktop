// ADLocalAddressBook.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADLocalAddressBook.h"
#import "ADRecord.h"

static NSString *_localABDefLoc = @"~/GNUstep/Library/Addresses";
static ADLocalAddressBook *_localAB = nil;

@interface ADLocalAddressBook(Private)
- (void) _invalidateCache;
- (NSString*) _nextValidID;
- (void) _handleRecordChanged: (NSNotification*) note;
- (void) _handleDBChangedExternally: (NSNotification*) note;
- (BOOL) _lockDatabase;
- (void) _unlockDatabase;
- (NSArray*) _toplevelRecordsOfClass: (Class) c;
- (NSArray*) _allGroupsEverywhere;
- (NSArray*) _allSubgroupsBelowGroup: (ADGroup*) group;
- (BOOL) removeRecord: (ADRecord*) record
	     forGroup: (ADGroup*) group
	    recursive: (BOOL) recursive;
@end

@implementation ADLocalAddressBook(Private)
- (void) _invalidateCache
{
  [_cache release];
  _cache = [[NSMutableDictionary alloc] init];
}

- (NSString*) _nextValidID
{
  unsigned long next;
  NSFileManager *fm;
  NSString *idFile;

  next = 0;
  fm = [NSFileManager defaultManager];
  idFile = [_loc stringByAppendingPathComponent: @"NEXTID"];
  if([fm fileExistsAtPath: idFile])
    next = [[NSString stringWithContentsOfFile: idFile] intValue];
  else
    {
      NSString *fname;
      NSEnumerator *e;

      e = [[fm directoryContentsAtPath: _loc] objectEnumerator];
      NSLog(@"Warning: Creating new NEXTID\n");
      while((fname = [e nextObject]))
	if([[fname pathExtension] isEqualToString: @"mfaddr"])
	  next = MAX(next, [[fname stringByDeletingPathExtension] intValue]);
      NSLog(@"New NEXTID is %lu\n", next);
    }
  next++;

  if(![[NSString stringWithFormat: @"%lu", next]
	writeToFile: idFile atomically: NO])
    [NSException raise: ADAddressBookInternalError
		 format: @"Couldn't save %@", idFile];
  
  return [NSString stringWithFormat: @"%lu", next];
}

- (void) _handleRecordChanged: (NSNotification*) note
{
  ADRecord *record;

  record = [note object];
  if([record addressBook] != self) return;
  
  if(![record uniqueId])
    return;

  if(![_unsaved objectForKey: [record uniqueId]])
    [_unsaved setObject: record forKey: [record uniqueId]];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: ADDatabaseChangedNotification
    object: self
    userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			      [record uniqueId],
			    @"UniqueIDOfChangedRecord",
			    self,
			    @"AddressBookContainingChangedRecord",
			    nil]];
}

- (void) _handleDBChangedExternally: (NSNotification*) note
{
  NSString *obj;
  NSDictionary *info;
  NSString *location, *pid;

  obj = [note object];
  info = [note userInfo];
  
  if(![obj isEqualToString: [self className]])
    return;
  location = [info objectForKey: @"Location"];
  pid = [info objectForKey: @"IDOfChangingProcess"];

  if(!location || !pid)
    return;
  if([location isEqualToString: _loc] &&
     ([pid intValue] != [[NSProcessInfo processInfo] processIdentifier]))
    {
      NSLog(@"Posting\n");
      
      [self _invalidateCache];
      [[NSNotificationCenter defaultCenter]
	postNotificationName: ADDatabaseChangedExternallyNotification
	object: self
	userInfo: [note userInfo]];
    }
}

- (BOOL) _lockDatabase
{
  int pid;
  NSString *contents;
  NSString *lockfile;

  pid = [[NSProcessInfo processInfo] processIdentifier];
  contents = [NSString stringWithFormat: @"%d", pid];
  lockfile = [_loc stringByAppendingPathComponent: @"LOCK"];
  
  if([[NSFileManager defaultManager] fileExistsAtPath: lockfile])
    {
      pid = [[NSString stringWithContentsOfFile: lockfile] intValue];
      NSLog(@"Lock file held by process with id %d\n", pid);
      return NO;
    }
  return [contents writeToFile: lockfile atomically: NO];
}

- (void) _unlockDatabase
{
  NSString *lockfile;

  lockfile = [_loc stringByAppendingPathComponent: @"LOCK"];
  [[NSFileManager defaultManager] removeFileAtPath: lockfile handler: nil];
}

- (NSArray*) _toplevelRecordsOfClass: (Class) c
{
  NSMutableArray *ppl;
  NSFileManager *fm;
  NSEnumerator *e;
  NSString *fname; ADRecord *record; 
  NSMutableDictionary *tmpUnsaved;

  ppl = [NSMutableArray arrayWithCapacity: 10];
  fm = [NSFileManager defaultManager];
  e = [[fm directoryContentsAtPath: _loc] objectEnumerator];
  
  while((fname = [e nextObject]))
    {
      NSString *str;
      NSString *uid;
      uid = [fname stringByDeletingPathExtension];

      record = [self recordForUniqueId: uid];
      if(!record || ![record isKindOfClass: c])
	continue;
      
      str = [record valueForProperty: @"Toplevel"];
      if(str && ![str boolValue])
	continue;
      
      [ppl addObject: record];
    }

  // add those that haven't been saved
  tmpUnsaved = [[_unsaved mutableCopy] autorelease];
  e = [ppl objectEnumerator];
  while((record = [e nextObject]))
    [tmpUnsaved removeObjectForKey: [record uniqueId]];
  e = [tmpUnsaved objectEnumerator];
  while((record = [e nextObject]))
    if([record isKindOfClass: c])
      {
	NSString *str = [record valueForProperty: @"Toplevel"];
	if(str && ![str boolValue])
	  continue;
      
	[ppl addObject: record];
      }
  
  return ppl;
}

- (NSArray*) _allGroupsEverywhere
{
  NSMutableArray *arr;
  NSEnumerator *e;
  ADGroup *group;

  arr = [NSMutableArray array];
  e = [[self groups] objectEnumerator];
  while((group = [e nextObject]))
    {
      NSArray *subgroups = [self _allSubgroupsBelowGroup: group];
      [arr addObject: group];
      [arr addObjectsFromArray: subgroups];
    }
  return arr;
}

- (NSArray*) _allSubgroupsBelowGroup: (ADGroup*) group
{
  NSMutableArray *arr;
  NSEnumerator *e;
  ADGroup *otherGroup;

  arr = [NSMutableArray array];
  e = [[group subgroups] objectEnumerator];  
  while((otherGroup = [e nextObject]))
    {
      NSArray *subgroups = [self _allSubgroupsBelowGroup: otherGroup];
      [arr addObject: otherGroup];
      [arr addObjectsFromArray: subgroups];
    }
  return arr;
}

- (BOOL) removeRecord: (ADRecord*) record
	     forGroup: (ADGroup*) group
	    recursive: (BOOL) recursive
{
  NSString *guid;
  NSString *muid;
  NSMutableArray *memberIds;
  int i; BOOL doneAnything;

  guid = [group uniqueId];
  if(!guid || [group addressBook] != self)
    {
      NSLog(@"Group being removed from is not part of this address book\n");
      return NO;
    }
  muid = [record uniqueId];
  if(!muid || [record addressBook] != self)
    {
      NSLog(@"Member being removed is not part of this address book\n");
      return NO;
    }

  memberIds = [NSMutableArray
		arrayWithArray: [group valueForProperty: ADMemberIDsProperty]];
  
  for(i=0; i<[memberIds count]; i++)
    {
      NSString *ruid;

      ruid = [memberIds objectAtIndex: i];
      if([ruid isEqualToString: muid])
	{
	  [memberIds removeObjectAtIndex: i--];
	  doneAnything = YES;
	}
    }

  // was this group changed? put it into _unsaved
  if(doneAnything)
    [group setValue: memberIds forProperty: ADMemberIDsProperty];

  if(recursive)
    {
      NSEnumerator *e;
      ADGroup *subgroup;

      e = [[group subgroups] objectEnumerator];
      while((subgroup = [e nextObject]))
	[self removeRecord: record forGroup: group recursive: YES];
    }
      
  return YES;
}
@end
  
@implementation ADLocalAddressBook
+ (NSString*) defaultLocation
{
  return _localABDefLoc;
}

+ (void) setDefaultLocation: (NSString*) location
{
  NSAssert(location, @"Location cannot be nil");

  [_localABDefLoc release];
  _localABDefLoc = [location retain];
}

+ (ADAddressBook*) sharedAddressBook
{
  if(!_localAB)
    _localAB = [[ADLocalAddressBook alloc]
		 initWithLocation: [self defaultLocation]];
  return _localAB;
}

+ (BOOL) makeLocalAddressBookAtLocation: (NSString*) location
{
  int i;
  NSString *currentPath;
  NSFileManager *fm;
  NSArray *arr;

  fm = [NSFileManager defaultManager];
  location = [location stringByExpandingTildeInPath];
  arr = [location pathComponents];
  currentPath = [arr objectAtIndex: 0];

  for(i=1; i<[arr count]; i++)
    {
      BOOL dir, result;
      
      currentPath = [currentPath
		      stringByAppendingPathComponent: [arr objectAtIndex: i]];

      result = [fm fileExistsAtPath: currentPath isDirectory: &dir];
      if((result == YES) && (dir == NO))
	return NO;

      if(result == NO)
	result = [fm createDirectoryAtPath: currentPath attributes: nil];

      if(result == NO)
	return NO;
    }

  return YES;
}

- initWithLocation: (NSString*) location
{
  BOOL dir;
  NSString *loc;
  NSAssert(location, @"Location cannot be nil");

  _cache = [[NSMutableDictionary alloc] init];

  loc = [location stringByExpandingTildeInPath];
  if(![[NSFileManager defaultManager] fileExistsAtPath: loc
				      isDirectory: &dir] ||
     !dir)
    if(![[self class] makeLocalAddressBookAtLocation: location])
      [NSException raise: ADAddressBookInternalError
		   format: @"Couldn't create local address book at %@",
		   location];
  
  [super init];

  _loc = [loc retain];
  _unsaved = [[NSMutableDictionary alloc] initWithCapacity: 10];
  _deleted = [[NSMutableDictionary alloc] initWithCapacity: 10];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_handleRecordChanged:)
    name: ADRecordChangedNotification
    object: nil];
  [[NSDistributedNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_handleDBChangedExternally:)
    name: ADDatabaseChangedExternallyNotification
    object: nil];
  
  return self;
}

- (void) dealloc
{
  [_loc release];
  [_unsaved release];
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
  [super dealloc];
}

- (NSString*) location
{
  return _loc;
}

- (BOOL) save
{
  NSEnumerator *e; ADRecord *r; NSString *path;
  NSFileManager *fm;
  NSString *pidStr;

  fm = [NSFileManager defaultManager];

  if(![self _lockDatabase])
    return NO;
  
  // save everything from _unsaved
  e = [_unsaved objectEnumerator];
  while((r = [e nextObject]))
    {
      path = [[_loc stringByAppendingPathComponent: [r uniqueId]]
	       stringByAppendingPathExtension: @"mfaddr"];
      
      if(![[r contentDictionary] writeToFile: path atomically: NO])
	{
	  NSLog(@"Couldn't write record to %@", path);
	  [self _unlockDatabase];
	  return NO;
	}
    }

  // delete everything from _deleted
  e = [_deleted objectEnumerator];
  while((r = [e nextObject]))
    {
      NSString *imgPath; NSEnumerator *e; NSString *imgFile;
      
      path = [[_loc stringByAppendingPathComponent: [r uniqueId]]
	       stringByAppendingPathExtension: @"mfaddr"];
      if(![fm removeFileAtPath: path handler: nil])
	NSLog(@"Error removing %@\n", path);

      imgPath = [_loc stringByAppendingPathComponent: @"IMAGES"];
      e = [[fm directoryContentsAtPath: imgPath] objectEnumerator];
      while((imgFile = [e nextObject]))
	{
	  if([[imgFile stringByDeletingPathExtension]
	       isEqualToString: [r uniqueId]])
	    {
	      imgFile = [imgPath stringByAppendingPathComponent: imgFile];
	      if(![fm removeFileAtPath: imgFile handler: nil])
		NSLog(@"Error removing %@\n", imgFile);
	    }
	}
    }

  [self _unlockDatabase];

  [_unsaved release];
  _unsaved = [[NSMutableDictionary alloc] initWithCapacity: 10];
  [_deleted release];
  _deleted = [[NSMutableDictionary alloc] initWithCapacity: 10];

  pidStr = [NSString stringWithFormat: @"%d",
		     [[NSProcessInfo processInfo] processIdentifier]];
  [[NSDistributedNotificationCenter defaultCenter]
    postNotificationName: ADDatabaseChangedExternallyNotification
    object: [self className]
    userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			      _loc, @"Location",
			    pidStr, @"IDOfChangingProcess", nil]];
  return YES;
}

- (BOOL) hasUnsavedChanges
{
  return (([_unsaved count] != 0) || ([_deleted count] != 0));
}

- (ADPerson*) me
{
  NSFileManager *fm;
  NSString *path;
  NSCharacterSet *wsp;
  NSString *uid;
  ADRecord *r;

  fm = [NSFileManager defaultManager];
  path = [_loc stringByAppendingPathComponent: @"ME"];
  if(![fm fileExistsAtPath: path])
    return nil;
  wsp = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  uid = [[NSString stringWithContentsOfFile: path]
		    stringByTrimmingCharactersInSet: wsp];
  r = [self recordForUniqueId: uid];
  if(!r || ![r isKindOfClass: [ADPerson class]])
    {
      NSLog(@"No record with uid '%@'\n", uid);
      [fm removeFileAtPath: path handler: nil];
      return nil;
    }
  return (ADPerson*)r;
}    

- (void) setMe: (ADPerson*) me
{
  NSString *path;
  NSString *uid;
  BOOL retval;

  path = [_loc stringByAppendingPathComponent: @"ME"];
  uid = [me uniqueId];

  if(!uid)
    {
      NSLog(@"Record for \"me\" has no UID!\n");
      return;
    }
  if(![self _lockDatabase])
    return;

  retval = [uid writeToFile: path atomically: NO];
  [self _unlockDatabase];

  if(!retval)
    NSLog(@"Couldn't write \"me\" record to %@\n", path);
}

- (ADRecord*) recordForUniqueId: (NSString*) uniqueId
{
  NSString *path;
  NSFileManager *fm;
  BOOL dir;
  id record;

  path = [_loc stringByAppendingPathComponent: uniqueId];
  fm = [NSFileManager defaultManager];
  
  // has it been deleted by us? if so, return nil!
  record = [_deleted objectForKey: uniqueId];
  if(record) return nil;

  // has it been modified by us?
  record = [_unsaved objectForKey: uniqueId];
  if(record) return record;

  // did we cache it?
  record = [_cache objectForKey: uniqueId];
  if(record) return record;

  path = [path stringByAppendingPathExtension: @"mfaddr"];
  if([fm fileExistsAtPath: path isDirectory: &dir] && !dir)
    record = [[ADRecord alloc]
	       initWithRepresentation: [NSString stringWithContentsOfFile: path]
	       type: @"mfaddr"];
  if(record)
    {
      [record setAddressBook: self];
      [_cache setObject: record forKey: [record uniqueId]];
      return [record autorelease];
    }

  return nil;
}

- (BOOL) addRecord: (ADRecord*) record
{
  NSString *type;
  NSData *data;
  NSString *uid;

  uid = [record uniqueId];
  if(uid)
    {
      NSLog(@"Record already contains an UID\n");
      return NO;
    }

  if([record addressBook])
    {
      NSLog(@"Record is already part of an address book\n");
      return NO;
    }
      
  uid = [self _nextValidID];
  [record setValue: uid forProperty: ADUIDProperty];
  [record setAddressBook: self];
  [_unsaved setObject: record forKey: uid];

  // save out image to temp file
  type = [record valueForProperty: ADImageTypeProperty];
  data = [record valueForProperty: ADImageProperty];
  if(type && data)
    {
      NSString *path;

      path =
	[NSTemporaryDirectory() stringByAppendingPathComponent: @"ADLABPic"];
      path = [path stringByAppendingPathExtension: type];
      if(![data writeToFile: path atomically: NO])
	NSLog(@"Couldn't write temp file %@\n", path);
      else if(![self setImageDataForPerson: (ADPerson*)record
		     withFile: path])
	NSLog(@"Couldn't set temp file %@\n", path);
      [[NSFileManager defaultManager]
	removeFileAtPath: path handler: nil];
    }
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName: ADDatabaseChangedNotification
    object: self
    userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			      [record uniqueId],
			    @"UniqueIDOfChangedRecord",
			    self,
			    @"AddressBookContainingChangedRecord",
			    nil]];
  return YES;
}

- (BOOL) removeRecord: (ADRecord*) record
{
  NSString *uid;
  NSEnumerator *e; ADGroup *g;

  uid = [record uniqueId];
  if(!uid)
    {
      NSLog(@"Record does not contain an UID\n");
      return NO;
    }

  if([record addressBook] != self)
    {
      NSLog(@"Record is not part of this address book\n");
      return NO;
    }

  [_unsaved removeObjectForKey: uid];

  if([record isKindOfClass: [ADGroup class]])
    {
      g = (ADGroup*)record;
      while([[g subgroups] count])
	[g removeSubgroup: [[g subgroups] objectAtIndex: 0]];
    }

  [_deleted setObject: record forKey: uid];

  e = [[self groups] objectEnumerator];
  while((g = [e nextObject]))
    [self removeRecord: record forGroup: g recursive: YES];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: ADDatabaseChangedNotification
    object: self
    userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			      uid, @"UniqueIDOfChangedRecord",
			    self, @"AddressBookContainingChangedRecord",
			    nil]];
  return YES;
}

- (NSArray*) people
{
  return [self _toplevelRecordsOfClass: [ADPerson class]];
}

- (NSArray*) groups
{
  return [self _toplevelRecordsOfClass: [ADGroup class]];
}
@end // ADLocalAddressBook

@implementation ADLocalAddressBook(GroupAccess)
- (NSArray*) recordsInGroup: (ADGroup*) group withClass: (Class) class
{
  NSMutableArray *members;
  NSMutableArray *memberIds;
  NSString *guid;
  int i;

  guid = [group uniqueId];
  if(!guid || [group addressBook] != self)
    {
      NSLog(@"Group being examined is not part of this address book\n");
      return nil;
    }

  members = [NSMutableArray array];
  memberIds = [group valueForProperty: ADMemberIDsProperty];
  for(i=0; i<[memberIds count]; i++)
    {
      ADRecord *r = [self recordForUniqueId: [memberIds objectAtIndex: i]];
      if(!r)
	{
	  NSLog(@"Error: Member %@ still in group, but doesn't exist\n",
		[memberIds objectAtIndex: i]);
	  [memberIds removeObjectAtIndex: i--]; continue;
	}
      if([r isKindOfClass: class])
	[members addObject: r];
    }
  return [NSArray arrayWithArray: members];
}

- (NSArray*) membersForGroup: (ADGroup*) group
{
  return [self recordsInGroup: group withClass: [ADPerson class]];
}

- (BOOL) addRecord: (ADRecord*) record forGroup: (ADGroup*) group
{
  NSString *guid;
  NSString *muid;
  NSMutableArray *memberIds;

  guid = [group uniqueId];
  if(!guid || [group addressBook] != self)
    {
      NSLog(@"Group being added to is not part of this address book\n");
      return NO;
    }

  muid = [record uniqueId];
  if(!muid || [record addressBook] != self)
    {
      if([record isKindOfClass: [ADGroup class]] &&
	 ![record addressBook] && !muid)
	{
	  muid = [self _nextValidID];
	  [record setValue: muid forProperty: ADUIDProperty];
	  [record setAddressBook: self];
	  [record setValue: @"NO" forProperty: @"Toplevel"];
	  [_unsaved setObject: record forKey: muid];
	}
      else
	{
	  NSLog(@"Member being added to group has no UID\n");
	  return NO;
	}
    }

  memberIds = [NSMutableArray
		arrayWithArray: [group valueForProperty: ADMemberIDsProperty]];
  if(!memberIds)
    {
      memberIds = [[[NSMutableArray alloc] init] autorelease];
      [group setValue: memberIds forProperty: ADMemberIDsProperty];
    }
  if([memberIds containsObject: muid])
    {
      NSLog(@"Record %@ already is a member of group\n", muid);
      return NO;
    }

  [memberIds addObject: muid];
  [group setValue: memberIds forProperty: ADMemberIDsProperty];

  return YES;
}

- (BOOL) addMember: (ADPerson*) person forGroup: (ADGroup*) group
{
  return [self addRecord: person forGroup: group];
}

- (BOOL) removeRecord: (ADRecord*) record
	     forGroup: (ADGroup*) group
{
  return [self removeRecord: record forGroup: group recursive: NO];
}

- (BOOL) removeMember: (ADPerson*) person forGroup: (ADGroup*) group
{
  return [self removeRecord: person forGroup: group];
}

- (NSArray*) subgroupsForGroup: (ADGroup*) group
{
  return [self recordsInGroup: group withClass: [ADGroup class]];
}

- (BOOL) addSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2
{
  return [self addRecord: g1 forGroup: g2];
}

- (BOOL) removeSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2
{
  NSArray *arr;
  int i;

  arr = [self subgroupsForGroup: g1];
  for(i=0; i<[arr count]; i++)
    [self removeSubgroup: [arr objectAtIndex: i] forGroup: g1];

  [self removeRecord: g1 forGroup: g2];

  // when a subgroup gets removed from the last parent group, it is
  // deleted, as opposed to when a person is removed.
  arr = [self parentGroupsForGroup: g1];
  if(![arr count])
    [_deleted setObject: g1 forKey: [g1 uniqueId]];

  return YES;
}

- (NSArray*) parentGroupsForGroup: (ADGroup*) group
{
  NSMutableArray *arr;
  NSEnumerator *e;
  ADGroup *g;
  NSString *guid;

  guid = [group uniqueId];
  if(!guid || [group addressBook] != self)
    {
      NSLog(@"Group being removed from is not part of this address book\n");
      return nil;
    }

  arr = [NSMutableArray array];
  e = [[self _allGroupsEverywhere] objectEnumerator];
  while((g = [e nextObject]))
    if([[g valueForProperty: ADMemberIDsProperty] containsObject: guid])
      [arr addObject: g];
  return [NSArray arrayWithArray: arr];
}
@end 

@implementation ADLocalAddressBook (ImageDataFile)
- (BOOL) setImageDataForPerson: (ADPerson*) person
		      withFile: (NSString*) filename
{
  NSString *uid;
  NSString *path;
  NSData *data;
  NSFileManager *fm;
  BOOL dir, ok;

  uid = [person uniqueId];
  if(!uid || [person addressBook] != self)
    {
      NSLog(@"Person for image file %@ is not part of this address book\n",
	    filename);
      return NO;
    }

  fm = [NSFileManager defaultManager];
  path = [_loc stringByAppendingPathComponent: @"IMAGES"];
  ok = [fm fileExistsAtPath: path isDirectory: &dir];
  if(ok && !dir)
    [NSException raise: ADAddressBookInternalError
		 format: @"%@ exists, but is not a directory!", path];
  if(!ok)
    ok = [fm createDirectoryAtPath: path attributes: nil];
  if(!ok)
    {
      NSLog(@"Error: Couldn't create directory %@\n", path);
      return NO;
    }

  data = [NSData dataWithContentsOfFile: filename];
  if(!data) return NO;

  path = [path stringByAppendingPathComponent: uid];
  path = [path stringByAppendingPathExtension: [filename pathExtension]];

  ok = [data writeToFile: path atomically: NO];
  if(!ok) return NO;
  [person setValue: [path pathExtension] forProperty: ADImageTypeProperty];
  return YES;
}

- (NSString*) imageDataFileForPerson: (ADPerson*) person
{
  NSString *uid;
  NSString *type;
  NSString *path;
  NSFileManager *fm;
  BOOL dir, ok;

  uid = [person uniqueId];
  if(!uid || [person addressBook] != self)
    {
      NSLog(@"Person whose image file is being queried is not part of "
	    @"this address book\n");
      return nil;
    }

  type = [person valueForProperty: ADImageTypeProperty];
  if(!type)
    {
      if([person valueForProperty: ADImageProperty])
	NSLog(@"Person whose image file is being queried has an image, but "
	      @"no ImageType property\n");
      return nil;
    }

  fm = [NSFileManager defaultManager];
  path = [_loc stringByAppendingPathComponent: @"IMAGES"];
  path = [path stringByAppendingPathComponent: uid];
  path = [path stringByAppendingPathExtension: type];

  ok = [fm fileExistsAtPath: path isDirectory: &dir];
  if(!ok)
    path = nil;
  if(ok && dir)
    [NSException raise: ADAddressBookInternalError
		 format: @"%@ exists, but is a directory!", path];
  return path;
}  
@end

@implementation ADLocalAddressBook(AddressesExtensions)
- (NSDictionary*) addressBookDescription
{
  return [NSDictionary dictionaryWithObjectsAndKeys: [self className],
		       @"Class", _loc, @"Location", nil];
}
@end
