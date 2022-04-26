/* All Rights reserved */

#import <AppKit/AppKit.h>
#import <Addresses/Addresses.h>
#import <AddressView/ADSinglePropertyView.h>
#include "Controller.h"

@implementation Controller
- (void) awakeFromNib
{
  [propSelector removeAllItems];

  NSArray *contents = [[[ADPerson class] properties]  
			sortedArrayUsingSelector: @selector(compare:)];
  [propSelector addItemsWithTitles: contents];
  [propSelector selectItemWithTitle: [propView displayedProperty]];
  [propView setDelegate: self];

  NSUInteger index = [autoselPopup indexOfItemWithTag: [propView autoselectMode]];
  if(index != NSNotFound)
    [autoselPopup selectItemAtIndex: index];
  else
    NSLog(@"Item with tag %d not found!\n", [propView autoselectMode]);
}

- (void) selectProperty: (id)sender
{
  NSLog(@"Selecting %@\n", [sender stringValue]);
  [propView setDisplayedProperty: [sender stringValue]];
}


- (void) printSelected: (id)sender
{
  NSEnumerator *e = [[propView selectedNamesAndValues] objectEnumerator];
  NSArray *a;
  NSLog(@"*** Selected:\n");
  while((a = [e nextObject]))
    {
      NSLog(@"%@\t%@\n", [a objectAtIndex: 0], [a objectAtIndex: 1]);
    }
}

- (void) setAutoselect: (id) sender
{
  [propView setAutoselectMode: [[sender selectedItem] tag]];
}

- (void) setPreferred: (id) sender
{
  if([[sender stringValue] isEqualToString: @""])
    [propView setPreferredLabel: nil];
  else
    [propView setPreferredLabel: [sender stringValue]];
}

- (void) doubleClickOnName: (NSString*) name
		     value: (NSString*) value
		    inView: (ADSinglePropertyView*) aView
{
  NSLog(@"Clicked on name: '%@' value: '%@'\n", name, value);
}

@end
