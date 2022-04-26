// ADPListConverter.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADPListConverter.h"
#import "ADPerson.h"
#import "ADGroup.h"
#import "ADLocalAddressBook.h"
#import "ADMultiValue.h"

@implementation ADPListConverter
- initForInput
{
  _done = NO; _plist = nil;
  return [super init];
}

- (BOOL) useString: (NSString*) str
{
  _plist = [str propertyList];
  if(![_plist isKindOfClass: [NSDictionary class]])
    {
      NSLog(@"String (%@) does not contain valid property list!\n", str);
      return NO;
    }
  return YES;
}

- (ADRecord*) nextRecord
{
  NSMutableArray *keys;
  NSString *key;
  ADRecord *r;
  NSEnumerator *e;

  keys = [NSMutableArray arrayWithArray: [_plist allKeys]];
  if([[_plist objectForKey: @"Type"] isEqualToString: @"Group"])
    {
      NSArray *members = [_plist objectForKey: @"Members"];
      r = [[[ADGroup alloc] init] autorelease];
      if(members)
	{
	  [r setValue: members forProperty: ADMemberIDsProperty];
	  [keys removeObject: @"Members"];
	}
      else
	[r setValue: [NSArray array] forProperty: ADMemberIDsProperty];
    }
  else
     r = [[[ADPerson alloc] init] autorelease];
  
  e = [keys objectEnumerator];
  while((key = [e nextObject]))
    {
      id val;
      ADPropertyType t;

      val = [_plist objectForKey: key];
      t = [ADPerson typeOfProperty: key];
      if(t & ADMultiValueMask)
	{
	  ADMutableMultiValue *mv;
	  int i;

	  if([val isKindOfClass: [NSString class]])
	    {
	      NSLog(@"Warning: Converting value for %@ from broken "
		    @"string representation\n", key);
	      val = [val propertyList];
	    }
	  mv = [[[ADMutableMultiValue alloc] initWithType: t] autorelease];
	  for(i=0; i<[val count]; i++)
	    {
	      NSDictionary *d;

	      d = [val objectAtIndex: i];
	      [mv addValue: [d objectForKey: @"Value"]
		  withLabel: [d objectForKey: @"Label"]
		  identifier: [d objectForKey: @"ID"]];
	    }

	  [r setValue: [[[ADMultiValue alloc] initWithMultiValue: mv]
			 autorelease]
	     forProperty: key];
	}
      else
	{
	  switch(t)
	    {
	    case ADDateProperty:
	      if([val isKindOfClass: [NSString class]])
		[r setValue: [NSCalendarDate dateWithString: val
					     calendarFormat: @"%Y-%m-%d"]
		   forProperty: key];
	      else if([val isKindOfClass: [NSCalendarDate class]])
		[r setValue: [val copy] forProperty: key];
	      else
		NSLog(@"Unknown date class %@\n", [val className]);
	      break;
	    default:
	      [r setValue: val
		 forProperty: key];
	    }
	}
    }

  return r;
}
@end
