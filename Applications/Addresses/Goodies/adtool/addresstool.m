// abview.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// 
// 
// $Author: rmottola $
// $Locker:  $
// $Revision: 1.1 $
// $Date: 2007/05/01 23:07:09 $

/* system includes */
#include <unistd.h>
#include <Addresses/Addresses.h>

/* my includes */
/* (none) */

extern char** environ;

#define DIE(message...) do {fprintf(stderr, message); return -1;} while(0)

@interface ADView: NSObject
{
  ADAddressBook *book;
  NSString *progname, *command;
  NSArray *args;
  BOOL localize, header;
}

- initWithArguments: (char**) argv
	      count: (int) count;

- (int) people;
- (int) showperson;
- (int) setme;
- (int) exportimage;
- (int) importimage;

- (int) groups;
- (int) members;
- (int) addmember;
- (int) delmember;
- (int) subgroups;
- (int) addgroup;
- (int) delgroup;

- (int) tree;
- (int) config;
- (int) import;

- (int) execute;
- (int) die;
@end;

@implementation ADView
- initWithArguments: (char**) argv
	      count: (int) count
{
  int start;
  NSArray *arr;
  
  [NSProcessInfo initializeWithArguments: argv
		 count: count
		 environment: environ];
  arr = [[NSProcessInfo processInfo] arguments];
  
  command = nil;
  header = YES;
  localize = NO;
  
  progname = [arr objectAtIndex: 0];
  start = 1;

  while(start < [arr count])
    {
      NSString *arg = [arr objectAtIndex: start];
      if(![[arg substringWithRange: NSMakeRange(0, 1)]
	    isEqualToString: @"-"])
	{
	  command = arg;
	  start++;
	  break;
	}
      else
	{
	  if([arg isEqualToString: @"-l"])
	    localize = YES;
	  else if([arg isEqualToString: @"-h"])
	    header = NO;
	  else
	    {
	      [self die];
	      exit(-1);
	    }
	}

      start++;
    }
      
  if(!command)
    {
      [self die];
      exit(-1);
    }

  if(start < count)
    args = [arr subarrayWithRange: NSMakeRange(start, count-start)];
  else
    args = nil;

  book = [ADAddressBook sharedAddressBook];
  if(!book)
    {
      fprintf(stderr, "Error: NIL address book\n");
      exit(-1);
    }
	      
  return [super init];
}

/*
 * person management
 */

- (int) people
{
  NSEnumerator *e;
  ADPerson *p;

  if([args count] != 0) return [self die];
  e = [[book people] objectEnumerator];

  if(header)
    printf("ID    Person Name\n");
  while((p = [e nextObject]))
    printf("%-5s %s %s\n", [[p valueForProperty: ADUIDProperty] cString],
	    [[p valueForProperty: ADFirstNameProperty] cString],
	    [[p valueForProperty: ADLastNameProperty] cString]);

  return 0;
}

- (int) showperson
{
  ADPerson *p;
  NSString *property;
  NSArray *props;
  NSEnumerator *e;

  if([args count] != 1) return [self die];

  if([[args objectAtIndex: 0] isEqualToString: @"me"])
    p = [book me];
  else
    p = (ADPerson*)[book recordForUniqueId: [args objectAtIndex: 0]];
  
  if(!p) DIE("No such record\n");
  if(![p isKindOfClass: [ADPerson class]])
    DIE("Record with index %s is not a person\n",
	[[args objectAtIndex: 0] cString]);

  props = [[ADPerson properties]
		     sortedArrayUsingSelector: @selector(compare:)];
  e = [props objectEnumerator];

  printf("%s %s\n",
	  [[p valueForProperty: ADFirstNameProperty] cString],
	  [[p valueForProperty: ADLastNameProperty] cString]);
	  
  while((property = [e nextObject]))
    {
      id val;

      val = [p valueForProperty: property];
      if(!val) continue;

      if([val isKindOfClass: [NSString class]] ||
	 [val isKindOfClass: [NSDate class]])
	{
	  if(localize)
	    printf("%-20s: %s\n",
		    [ADLocalizedPropertyOrLabel(property) cString],
		    [[val description] cString]);
	  else
	    printf("%-20s: %s\n",
		    [property cString],
		    [[val description] cString]);
	}
      else if([val isKindOfClass: [ADMultiValue class]])
	{
	  int i;

	  if(![val count]) continue;

	  for(i=0; i<[val count]; i++)
	    {
	      NSString *label, *identifier; id v;
	      v = [val valueAtIndex: i];
	      label = [val labelAtIndex: i];
	      identifier = [val identifierAtIndex: i];

	      if(i==0)
		{
		  if(localize)
		    printf("%-20s: %-5s ",
			    [ADLocalizedPropertyOrLabel(property) cString],
			    [identifier cString]);
		  else
		    printf("%-20s: %-5s",
			    [property cString], [identifier cString]);


		}
	      else
		printf("%-21s %-5s ", "", [identifier cString]);

	      if(localize)
		printf("%-20s ",
			[ADLocalizedPropertyOrLabel(label) cString]);
	      else
		printf("%-20s ", [label cString]);

	      printf("%s\n", [[v description] cString]);
	    }
	}
      else
	{
	  if(localize)
	    printf("%-20s: Undisplayable (class %s)\n",
		    [ADLocalizedPropertyOrLabel(property) cString],
		    [[val className] cString]);
	  else
	    printf("%-20s: Undisplayable (class %s)\n",
		    [property cString],
		    [[val className] cString]);
	}
    }

  return 0; 
}

- (int) setme
{
  ADPerson *p;

  if([args count] != 1) return [self die];

  p = (ADPerson*)[book recordForUniqueId: [args objectAtIndex: 0]];
  
  if(!p) DIE("No such record\n");
  if(![p isKindOfClass: [ADPerson class]])
    DIE("Record with index %s is not a person\n",
	[[args objectAtIndex: 0] cString]);

  [book setMe: p];
  return 0; 
}

- (int) exportimage
{
  ADPerson *p;
  NSString *filename;
  NSData *pic;
  
  if([args count] != 2) return [self die];

  p = (ADPerson*)[book recordForUniqueId: [args objectAtIndex: 0]];
  if(!p) DIE("No such record\n");
  if(![p isKindOfClass: [ADPerson class]])
    DIE("Record with index %s is not a person\n",
	[[args objectAtIndex: 0] cString]);

  filename = [args objectAtIndex: 1];
  pic = [p imageData];
  if(!pic) DIE("No image associated with person\n");
  if(![pic writeToFile: filename atomically: NO])
    DIE("Couldn't write image file %s\n", [filename cString]);

  return 0;
}

- (int) importimage
{
  ADPerson *p;
  NSString *filename;
  NSData *pic;

  if([args count] != 2) return [self die];
  p = (ADPerson*)[book recordForUniqueId: [args objectAtIndex: 0]];
  if(!p) DIE("No such record\n");
  if(![p isKindOfClass: [ADPerson class]])
    DIE("Record with index %s is not a person\n",
	[[args objectAtIndex: 0] cString]);

  filename = [args objectAtIndex: 1];
  pic = [NSData dataWithContentsOfFile: filename];
  if(!pic) DIE("Couldn't read image file %s\n", [filename cString]);
  if(![p setImageData: pic])
    DIE("Couldn't set image in person\n");

  if(![book save]) DIE("Error saving address book!\n");

  return 0;
}


/*
 * group management
 */

- (int) groups
{
  ADGroup *g;
  NSEnumerator *e;

  if([args count] != 0) return [self die];

  e = [[book groups] objectEnumerator];

  if(header)
    printf("ID    Group Name\n");
  while((g = [e nextObject]))
    printf("%-5s %s\n",
	   [[g valueForProperty: ADUIDProperty] cString],
	   [[g valueForProperty: ADGroupNameProperty] cString]);      
  return 0;
}

- (int) members
{
  ADGroup *g;
  ADPerson *p;
  NSEnumerator *e;

  if([args count] != 1) return [self die];

  g = (ADGroup*)[book recordForUniqueId: [args objectAtIndex: 0]];
  if(!g) DIE("No group with id %s\n", [[args objectAtIndex: 0] cString]);
  if(![g isKindOfClass: [ADGroup class]])
    DIE("Record with index %s is not a group\n",
	[[args objectAtIndex: 0] cString]);
  
  e = [[g members] objectEnumerator];

  if(header)
    printf("ID    Person Name\n");
  while((p = [e nextObject]))
    printf("%-5s %s %s\n",
	    [[p valueForProperty: ADUIDProperty] cString],
	    [[p valueForProperty: ADFirstNameProperty] cString],
	    [[p valueForProperty: ADLastNameProperty] cString]);
  return 0;
}

- (int) addmember
{
  ADGroup *g;
  ADPerson *p;

  if([args count] != 2) return [self die];
  g = (ADGroup*)[book recordForUniqueId: [args objectAtIndex: 0]];
  p = (ADPerson*)[book recordForUniqueId: [args objectAtIndex: 1]];
  if(!g) DIE("No group with id %s\n", [[args objectAtIndex: 0] cString]);
  if(![g isKindOfClass: [ADGroup class]])
    DIE("Record with id %s is not a group!\n",
	[[args objectAtIndex: 0] cString]);
  if(![p isKindOfClass: [ADPerson class]])
    DIE("Record with id %s is not a person!\n",
	[[args objectAtIndex: 0] cString]);

  if(![g addMember: p]) DIE("Error\n");
  return 0;
}  

- (int) delmember
{
  ADGroup *g;
  ADPerson *p;

  if([args count] != 2) return [self die];
  g = (ADGroup*)[book recordForUniqueId: [args objectAtIndex: 0]];
  p = (ADPerson*)[book recordForUniqueId: [args objectAtIndex: 1]];
  if(!g) DIE("No group with id %s\n", [[args objectAtIndex: 0] cString]);
  if(!p) DIE("No person with id %s\n", [[args objectAtIndex: 1] cString]);
  if(![g isKindOfClass: [ADGroup class]])
    DIE("Record with id %s is not a group!\n",
	[[args objectAtIndex: 0] cString]);
  if(![p isKindOfClass: [ADPerson class]])
    DIE("Record with id %s is not a person!\n",
	[[args objectAtIndex: 0] cString]);

  if(![g removeMember: p]) DIE("Error\n");
  return 0;
}  

- (int) subgroups
{
  ADGroup *g;
  NSEnumerator *e;

  if([args count] != 1) return [self die];
  g = (ADGroup*)[book recordForUniqueId: [args objectAtIndex: 0]];
  if(!g) DIE("No group with id %s\n", [[args objectAtIndex: 0] cString]);
  if(![g isKindOfClass: [ADGroup class]])
    DIE("Record with id %s is not a group!\n",
	[[args objectAtIndex: 0] cString]);
    
  e = [[g subgroups] objectEnumerator];
  if(header)
     printf("ID    Group Name\n");
  while((g = [e nextObject]))
    printf("%-5s %s\n",
	    [[g valueForProperty: ADUIDProperty] cString],
	    [[g valueForProperty: ADGroupNameProperty] cString]);
  return 0;
}

- (int) addgroup
{
  ADGroup *group;

  if([args count] != 1 && [args count] != 2) return [self die];
  group = [[ADGroup alloc] init];

  if([args count] == 1)
    {
      [group setValue: [args objectAtIndex: 0]
	     forProperty: ADGroupNameProperty];

      if(![book addRecord: group]) DIE("Error\n");
    }
  else
    {
      id sg;
      [group setValue: [args objectAtIndex: 1]
	     forProperty: ADGroupNameProperty];
      sg = [book recordForUniqueId: [args objectAtIndex: 0]];
      if(!sg)
	DIE("No group with id %s\n", [[args objectAtIndex: 0] cString]);
      else if(![sg isKindOfClass: [ADGroup class]])
	DIE("Record with id %s is not a group\n",
	    [[args objectAtIndex: 0] cString]);

      if(![sg addSubgroup: group]) DIE("Error\n");
    }
  printf("%s\n", [[group uniqueId] cString]);
  return 0;
}

- (int) delgroup
{
  if([args count] != 1 && [args count] != 2) return [self die];
  
  if([args count] == 1)
    {
      ADGroup *group;

      group = (ADGroup*)[book recordForUniqueId: [args objectAtIndex: 0]];
      if(![book removeRecord: group]) DIE("Error\n");
    }
  else
    {
      ADGroup *g1, *g2;

      g1 = (ADGroup*)[book recordForUniqueId: [args objectAtIndex: 0]];
      g2 = (ADGroup*)[book recordForUniqueId: [args objectAtIndex: 1]];
      if(![g1 removeSubgroup: g2]) DIE("Error\n");
    }
  return 0;
}

- (int) parentgroups
{
  id record;
  ADGroup *g;
  NSArray *parents;
  NSEnumerator *e;

  if([args count] != 1) return [self die];
  record = [book recordForUniqueId: [args objectAtIndex: 0]];

  if(!record) DIE("No record with id %s\n", [[args objectAtIndex: 0] cString]);

  parents = [record parentGroups];
  e = [parents objectEnumerator];

  if(header)
    printf("ID    Group Name\n");
  while((g = [e nextObject]))
    printf("%-5s %s\n",
	    [[g valueForProperty: ADUIDProperty] cString],
	    [[g valueForProperty: ADGroupNameProperty] cString]);

  return 0;
}
  
- (int) _showTreeForGroup: (ADGroup*) group level: (int) level
{
  NSArray *subgroups, *members;
  NSEnumerator *e; ADPerson *p; ADGroup *g;
  
  if(!group)
    {
      subgroups = [book groups];
      members = [book people];
    }
  else
    {
      subgroups = [group subgroups];
      members = [group members];
    }

  e = [subgroups objectEnumerator];
  while((g = [e nextObject]))
    {
      printf("%*sGROUP  %-5s %s\n", level, "", [[g uniqueId] cString],
	     [[g valueForProperty: ADGroupNameProperty] cString]);
      [self _showTreeForGroup: g level: level+2];
    }
  e = [members objectEnumerator];
  while((p = [e nextObject]))
    printf("%*sPERSON %-5s %s, %s\n", level, "", [[p uniqueId] cString],
	   [[p valueForProperty: ADLastNameProperty] cString],
	   [[p valueForProperty: ADFirstNameProperty] cString]);

  return 0;
}
  
- (int) tree
{
  if([args count] != 0) return [self die];
  return [self _showTreeForGroup: nil level: 0];
}

- (void) showInfoForAddressBook: (ADAddressBook*) ab
{
    NSDictionary *descr;
    NSEnumerator *e; NSString *key;
    ADEnvelopeAddressBook *env = (ADEnvelopeAddressBook*) book;

    descr = [ab addressBookDescription];
    fprintf(stderr, "%s", [[descr objectForKey: @"Class"] cString]);
    if(ab == [env primaryAddressBook])
	fprintf(stderr, " (Primary)\n");
    else
	fprintf(stderr, "\n");

    e = [[[descr allKeys] sortedArrayUsingSelector: @selector(compare:)] 
	    objectEnumerator];
    while((key = [e nextObject]))
    {
	if([key isEqualToString: @"Class"]) continue;
	fprintf(stderr, "\t%s: %s\n", [key cString], 
		[[descr objectForKey: key] cString]);
    }
}

- (int) config
{
    NSEnumerator *e; ADAddressBook *ab;
    ADEnvelopeAddressBook *env = (ADEnvelopeAddressBook*) book;

    if([args count] != 0) return [self die];
    [self showInfoForAddressBook: [env primaryAddressBook]];
    
    e = [env addressBooksEnumerator];
    while((ab = [e nextObject]))
    {
	if(ab == [env primaryAddressBook]) continue;
	[self showInfoForAddressBook: ab];
    }
    return 0;
}

- (int) import
{
  NSEnumerator *e;
  NSString *str;

  if(!args) return [self die];
  e = [args objectEnumerator];
  while((str = [e nextObject]))
    {
      NSLog(@"file: %@", str);
      id obj;
      id<ADInputConverting> conv =
	[[ADConverterManager sharedManager] inputConverterWithFile: str];

      if(!conv)
	{
	  fprintf(stderr, "Cannot import %s (no converter)\n",
		  [str cString]);
	  continue;
	}

      while((obj = [conv nextRecord]))
	[book addRecord: obj];
    }
  return 0;
}

- (int) execute
{
  int retval;
  NSMethodSignature *sig;
  NSInvocation *inv;
  
  if(![self respondsToSelector: NSSelectorFromString(command)])
    return [self die];

  sig =
    [self methodSignatureForSelector: @selector(execute)];
  inv =
    [NSInvocation invocationWithMethodSignature: sig];
  [inv setSelector: NSSelectorFromString(command)];
  [inv invokeWithTarget: self];

  [inv getReturnValue: &retval];
  if(retval == 0)
    {
      if([book hasUnsavedChanges])
	{
	  fprintf(stderr, "Saving address book.\n");
	  if(![book save])
	    {
	      fprintf(stderr, "Error saving address book.\n");
	      return -1;
	    }
	}
    }
  return retval;
}

- (int) die;
{
  const char *s = [progname cString];
  NSArray *arr;
  
  fprintf(stderr,
	  "\n%s: Command-line utility for the Addresses framework\n\n"
	  "Usage: %s [OPTIONS] COMMAND [PARAMETERS]\n\n"
	  "Options:\n"
	  "\t-l\tturn on localization of property names\n"
	  "\t-h\tturn off printing of header\n\n"
	  "Person Management Commands:\n"
	  "\tpeople\n\t\tShow all people (ID and name)\n"
	  "\tshowperson {PERSONID|me}\n\t\tShow a person's complete record\n"
	  "\tsetme PERSONID\n\t\tMark the given person as the 'me' record\n"
	  "\texportimage PERSONID FILENAME\n\t\tExport a person's image\n"
	  "\timportimage PERSONID FILENAME\n\t\tExport a person's image\n"
	  "\n"
	  "Group Management Commands:\n"
	  "\tgroups\n\t\tShow toplevel groups\n"
	  "\tmembers GROUPID\n\t\tDisplay the members of the given group\n"
	  "\taddmember GROUPID PERSONID\n\t\tAdd a person to a group\n"
	  "\tdelmember GROUPID PERSONID\n\t\tRemove a person from a group\n"
	  "\tsubgroups SUPERGROUPID\n\t\tShow a group's subgroups\n"
	  "\taddgroup [SUPERGROUPID] NAME\n"
	  "\t\tAdd a group to toplevel or the given supergroup\n"
	  "\tdelgroup [SUPERGROUPID] GROUPID\n"
	  "\t\tRemove a group from toplevel or the given supergroup\n"
	  "\tparentgroups {GROUPID|PERSONID}\n"
	  "\t\tShow a record's parent group(s)\n"
	  "\n"
	  "General Commands:\n"
	  "\ttree\n"
	  "\t\tShow a tree view of all members and groups\n"
	  "\tconfig\n"
	  "\t\tShow the current address book configuration\n"
	  "\timport FILE [FILE ...]\n"
	  "\t\tMerge file(s) with the database\n\t\tSupported file types: ",
	  s, s);

  arr = [[ADConverterManager sharedManager]
		   inputConvertableFileTypes];
  if(![arr count]) printf("None\n\n");
  else
    {
      int i;
      for(i=0; i<[arr count]-1; i++)
	printf("%s, ", [[arr objectAtIndex: i] cString]);
      printf("%s\n\n", [[arr objectAtIndex: [arr count]-1] cString]);
    }
  return -1;
}
@end

int main(int argc, char **argv, char **env)
{
  int retval;
  NSAutoreleasePool *pool;

  pool = [[NSAutoreleasePool alloc] init];
  retval = [[[ADView alloc] initWithArguments: argv count: argc] execute];
  [pool release];
  return retval;
}

