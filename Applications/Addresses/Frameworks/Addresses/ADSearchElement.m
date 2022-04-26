// ADSearchElement.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADSearchElement.h"
#import "ADMultiValue.h"

@interface ADEnvelopeSearchElement: ADSearchElement
{
  ADSearchConjunction _conj;
  NSArray *_children;
}

+ (ADSearchElement*) searchElementForConjunction: (ADSearchConjunction) conj
					children: (NSArray*) children;
- initWithConjunction: (ADSearchConjunction) conj
	     children: (NSArray*) children;
- (void) dealloc;
- (BOOL) matchesRecord: (ADRecord*) record;
@end

@implementation ADEnvelopeSearchElement
+ (ADSearchElement*) searchElementForConjunction: (ADSearchConjunction) conj
					children: (NSArray*) children
{
  return [[self alloc] initWithConjunction: conj children: children];
}

- initWithConjunction: (ADSearchConjunction) conj
	     children: (NSArray*) children
{
  [super init];

  _conj = conj;
  _children = [[NSArray alloc] initWithArray: children];

  return self;
}

- (void) dealloc
{
  [_children release];
  [super dealloc];
}

- (BOOL) matchesRecord: (ADRecord*) record
{
  NSEnumerator *e;
  ADSearchElement *s;

  e = [_children objectEnumerator];

  while((s = [e nextObject]))
    {
      BOOL retval = [s matchesRecord: record];
      if(retval && (_conj == ADSearchOr))
	return YES;
      else if(!retval && (_conj == ADSearchAnd))
	return NO;
    }

  if(_conj == ADSearchOr) return NO;
  else return YES;
}
@end

@implementation ADRecordSearchElement
- initWithProperty: (NSString*) property
	     label: (NSString*) label
	       key: (NSString*) key
	     value: (id) value
	comparison: (ADSearchComparison) comparison
{
  [super init];
  
  if(!property || !value)
    {
      NSLog(@"%@ initialized with nil property or value!\n",
	    [self className]);
      return nil;
    }

  _property = [property copy];
  if(label) _label = [label copy]; else _label = nil;
  if(key) _key = [key copy]; else _key = nil;
  _val = [value retain]; 
  _comp = comparison;

  return self;
}

- (void) dealloc
{
  [_property release]; [_label release]; [_key release]; [_val release];
  [super dealloc];
}

- (BOOL) matchesValue: (id) v
{
  if([v isKindOfClass: [NSString class]])
    {
      NSRange r;
      
      if(![_val isKindOfClass: [NSString class]])
	{
	  NSLog(@"Can't compare %@ instance to %@ instance\n",
		[v className], [_val className]);
	  return NO;
	}
  
      switch(_comp)
	{
	case ADEqual:
	  return [v isEqualToString: _val];
	case ADNotEqual:
	  return ![v isEqualToString: _val];
	case ADLessThan:
	  return [v compare: _val] < NSOrderedSame;
	case ADLessThanOrEqual:
	  return [v compare: _val] <= NSOrderedSame;
	case ADGreaterThan:
	  return [v compare: _val] > NSOrderedSame;
	case ADGreaterThanOrEqual:
	  return [v compare: _val] >= NSOrderedSame;

	case ADEqualCaseInsensitive:
	  return [v caseInsensitiveCompare: _val] == NSOrderedSame;
	case ADContainsSubString:
	  return [v rangeOfString: _val].location != NSNotFound;
	case ADContainsSubStringCaseInsensitive:
	  r = [v rangeOfString: _val options: NSCaseInsensitiveSearch];
	  return r.location != NSNotFound;
	case ADPrefixMatch:
	  return [v rangeOfString: _val].location == 0;
	case ADPrefixMatchCaseInsensitive:
	  r = [v rangeOfString: _val options: NSCaseInsensitiveSearch];
	  return r.location == 0;
	default:
	  NSLog(@"Unknown search comparison %d\n", _comp);
	  return NO;
	}
    }
  else if([v isKindOfClass: [NSDate class]])
    {
      if(![_val isKindOfClass: [NSString class]])
	{
	  NSLog(@"Can't compare %@ instance to %@ instance\n",
		[v className], [_val className]);
	  return NO;
	}
  
      switch(_comp)
	{
	case ADEqual:
	  return [v isEqualToDate: _val];
	case ADNotEqual:
	  return ![v isEqualToDate: _val];
	case ADLessThan:
	  return [v earlierDate: _val] == v;
	case ADLessThanOrEqual:
	  return [v isEqualToDate: _val] || ([v earlierDate: _val] == v);
	case ADGreaterThan:
	  return [v laterDate: _val] == v;
	case ADGreaterThanOrEqual:
	  return [v isEqualToDate: _val] || ([v laterDate: _val] == v);

	case ADEqualCaseInsensitive:
	case ADContainsSubString:
	case ADContainsSubStringCaseInsensitive:
	case ADPrefixMatch:
	case ADPrefixMatchCaseInsensitive:
	  NSLog(@"Can't apply comparison %d to date objects\n", _comp);
	  return NO;
	default:
	  NSLog(@"Unknown search comparison %d\n", _comp);
	  return NO;
	}
    }
  else
    {
      NSLog(@"Can't test value of class %@ for match\n", [v className]);
      return NO;
    }
}
    

- (BOOL) matchesRecord: (ADRecord*) record
{
  int i; id val;
  
  val = [record valueForProperty: _property];
  if(!val) return NO;

  if([val isKindOfClass: [ADMultiValue class]])
    {
      id val2;
      
      for(i=0; i<[val count]; i++)
	{
	  if(_label)
	    {
	      // Have a label? Then, only regard values with the label
	      if([[val labelAtIndex: i] isEqualToString: _label])
		val2 = [val valueAtIndex: i];
	      else
		val2 = nil;
	    }
	  else
	    val2 = [val valueAtIndex: i];

	  if(!val2) continue;
	  
	  if([val2 isKindOfClass: [NSDictionary class]])
	    {
	      if(_key)
		return [self matchesValue: [val2 objectForKey: _key]];
	      else
		{
		  NSEnumerator *e = [val2 objectEnumerator];
		  id v;
		  while((v = [e nextObject]))
		    if([self matchesValue: v])
		      return YES;
		  return NO;
		}
	    }
	  else
	    return [self matchesValue: val2];
	}
    }
  else
    return [self matchesValue: val];
  return NO; // make compiler happy
}
@end

@implementation ADSearchElement
+ (ADSearchElement*) searchElementForConjunction: (ADSearchConjunction) conj
					children: (NSArray*) children
{
  return [[[ADEnvelopeSearchElement alloc]
	    initWithConjunction: conj
	    children: children]
	   autorelease];
}

- (BOOL) matchesRecord: (ADRecord*) record
{
  [self subclassResponsibility: _cmd];
  return NO;
}
@end

