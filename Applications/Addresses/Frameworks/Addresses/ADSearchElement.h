// ADSearchElement.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep

#import <Foundation/Foundation.h>

#import <Addresses/ADRecord.h>
#import <Addresses/ADTypedefs.h>
#import <Addresses/ADGlobals.h>



@interface ADSearchElement: NSObject
+ (ADSearchElement*) searchElementForConjunction: (ADSearchConjunction) conj
					children: (NSArray*) children;
- (BOOL) matchesRecord: (ADRecord*) record;
@end

@interface ADRecordSearchElement: ADSearchElement // EXTENSION
{
  NSString *_property, *_label, *_key;
  id _val;
  ADSearchComparison _comp;
}

- initWithProperty: (NSString*) property
	     label: (NSString*) label
	       key: (NSString*) key
	     value: (id) value
	comparison: (ADSearchComparison) comparison;
- (void) dealloc;
- (BOOL) matchesValue: (id) value;
- (BOOL) matchesRecord: (ADRecord*) record;
@end
