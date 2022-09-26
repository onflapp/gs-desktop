/* Defaults.m
 *  
 * Copyright (C) 2006-2013 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 *         Riccardo Mottola <rm@gnu.org>
 * Date: February 2006
 *
 * This file is part of the GNUstep "Defaults" Preference Pane
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import <AppKit/AppKit.h>
#import "Defaults.h"

#include <limits.h>  // For INT_MAX and INT_MIN

@implementation Defaults

- (void)dealloc
{
  TEST_RELEASE (defaultsEntries);
  TEST_RELEASE (stringEditorBox);
  TEST_RELEASE (boolEditorBox);
  TEST_RELEASE (numberEditorBox);
  TEST_RELEASE (arrayEditorBox);
  TEST_RELEASE (listEditorBox);
  
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (![NSBundle loadNibNamed: @"Defaults" owner: self]) {
    NSLog (@"Defaults: Could not load nib \"Defaults\", aborting.");
    return nil;
  }

  [window setFrameAutosaveName:@"domains_window"];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *dictpath = [bundle pathForResource: @"Defaults" ofType: @"plist"];
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: dictpath];
  NSArray *keys = [[dict allKeys] sortedArrayUsingSelector: @selector(compare:)];
  id cell;
  float fonth;
  NSUInteger i;
  
  RETAIN (stringEditorBox);
  [stringEditorBox removeFromSuperview];
  RETAIN (boolEditorBox);
  [boolEditorBox removeFromSuperview];
  RETAIN (numberEditorBox);
  [numberEditorBox removeFromSuperview];
  RETAIN (arrayEditorBox);
  [arrayEditorBox removeFromSuperview];
  RETAIN (listEditorBox);
  [listEditorBox removeFromSuperview];
  RELEASE (editorsWin);
  
  [defaults synchronize];
  defaultsEntries = [NSMutableArray new];
  
  for (i = 0; i < [keys count]; i++) {
    NSString *defname = [keys objectAtIndex: i];
    NSDictionary *info = [dict objectForKey: defname];
    NSString *category = [info objectForKey: @"category"];
    NSString *description;
    NSArray *values = [info objectForKey: @"values"];
    id defvalue = [info objectForKey: @"defaultvalue"];
    int edtype = [[info objectForKey: @"editor"] intValue];
    DefaultEntry *entry;
    
    description = [bundle localizedStringForKey:defname value:@"Description not found" table:nil];
    entry = [[DefaultEntry alloc] initWithUserDefaults: defaults
                                              withName: defname 
                                            inCategory: category
                                           description: description
                                                values: values
                                          defaultValue: defvalue 
                                           editorType: edtype];
    [defaultsEntries addObject: entry];
    RELEASE (entry);
  }
  
  [namesScroll setBorderType: NSBezelBorder];
  [namesScroll setHasHorizontalScroller: NO];
  [namesScroll setHasVerticalScroller: YES]; 

  cell = [NSBrowserCell new];
  fonth = [[cell font] defaultLineHeightForFont];

  namesMatrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                           mode: NSRadioModeMatrix 
                                      prototype: cell
                                   numberOfRows: 0 
                                numberOfColumns: 0];
  RELEASE (cell);                     
  [namesMatrix setIntercellSpacing: NSZeroSize];
  [namesMatrix setCellSize: NSMakeSize([namesScroll contentSize].width, fonth)];
  [namesMatrix setAutoscroll: YES];
  [namesMatrix setAllowsEmptySelection: YES];
  [namesMatrix setTarget: self]; 
  [namesMatrix setAction: @selector(namesMatrixAction:)]; 
  [namesScroll setDocumentView: namesMatrix];	
  RELEASE (namesMatrix);
  
  for (i = 0; i < [defaultsEntries count]; i++) {
    DefaultEntry *entry = [defaultsEntries objectAtIndex: i];
    NSString *name = [entry name];
    NSUInteger count = [[namesMatrix cells] count];
    
    [namesMatrix insertRow: count];
    cell = [namesMatrix cellAtRow: count column: 0];   
    [cell setStringValue: name];
    [cell setLeaf: YES];  
  }
  
  [namesMatrix sizeToCells]; 
      
  [descriptionView setFont: [NSFont systemFontOfSize: 10]];
  [descriptionView setDrawsBackground: NO];
  // FIXME can't turn off this attribute in Gorm at present
  [descriptionView setEditable: NO];

  currentEntry = nil;    
      
  // String
  [stringEdField setStringValue: @""];
  [stringEdField setDelegate: self];
  
  // Bool
  [boolEdPopup selectItemAtIndex: 0];

  // Number
  [numberEdField setStringValue: @""];
  [numberEdField setDelegate: self];
  
  // Array
  [arrayEdField setStringValue: @""];
  [arrayEdField setDelegate: self];
  
  [arrayEdScroll setBorderType: NSBezelBorder];
  [arrayEdScroll setHasHorizontalScroller: NO];
  [arrayEdScroll setHasVerticalScroller: YES]; 
  
  arrayEdMatrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                             mode: NSRadioModeMatrix 
                                        prototype: cell
                                     numberOfRows: 0 
                                  numberOfColumns: 0];
  [arrayEdMatrix setIntercellSpacing: NSZeroSize];
  [arrayEdMatrix setCellSize: NSMakeSize([arrayEdScroll contentSize].width, fonth)];
  [arrayEdMatrix setAutoscroll: YES];
  [arrayEdMatrix setAllowsEmptySelection: YES];
  [arrayEdMatrix setTarget: self]; 
  [arrayEdMatrix setAction: @selector(arrayEdMatrixAction:)]; 
  [arrayEdScroll setDocumentView: arrayEdMatrix];
  RELEASE (arrayEdMatrix);

  // List
  [listEdPopup selectItemAtIndex: 0];


  [self disableControls];

  /* set some locales */
  [categoryLabel setStringValue: [bundle localizedStringForKey:@"category" value:@"n/f" table:nil]];
  [descriptionLabel setStringValue: [bundle localizedStringForKey:@"description" value:@"n/f" table:nil]];
  
  return self;
}

- (void) showPanel:(id) sender {
  [window makeKeyAndOrderFront:sender];
}

- (DefaultEntry *)entryWithName:(NSString *)name
{
  NSUInteger i;

  for (i = 0; i < [defaultsEntries count]; i++)
    {
      DefaultEntry *entry = [defaultsEntries objectAtIndex: i];
      
      if ([[entry name] isEqual: name])
        return entry;
    }
    
  return nil;
}

- (void)namesMatrixAction:(id)sender
{
  id cell = [namesMatrix selectedCell];  

  [self disableControls];    
    
  if (cell) {    
    int edtype;
    id defvalue;
    id usrvalue;
    NSArray *values;
    id value;
       
    currentEntry = [self entryWithName: [cell stringValue]];
    edtype = [currentEntry editorType];
    defvalue = [currentEntry defaultValue];  
    usrvalue = [currentEntry userValue];
    values = [currentEntry values];
    value = (usrvalue == nil) ? defvalue : usrvalue;
          
    [descriptionView setString: [currentEntry description]];
    [categoryField setStringValue: [currentEntry category]];
    
    switch (edtype) {
      case STRING_EDITOR:
        [editorBox setContentView: stringEditorBox];
        [stringEdField setStringValue: value];
        [stringEdDefaultRevert setEnabled: (usrvalue && ([usrvalue isEqual: defvalue] == NO))];
        break;

      case BOOL_EDITOR:
        [editorBox setContentView: boolEditorBox];
        [boolEdPopup selectItemAtIndex: [value boolValue]];
        [boolEdDefaultRevert setEnabled: (usrvalue && ([usrvalue isEqual: defvalue] == NO))];
        break;

      case NUMBER_EDITOR:
        [editorBox setContentView: numberEditorBox];
        [numberEdField setStringValue: [value stringValue]];
        [numberEdDefaultRevert setEnabled: (usrvalue && ([usrvalue isEqual: defvalue] == NO))];
        break;

      case ARRAY_EDITOR:
        {
          NSUInteger i;
          
          [editorBox setContentView: arrayEditorBox];
          
          if ([arrayEdMatrix numberOfColumns] > 0) { 
            [arrayEdMatrix removeColumn: 0];
          }
          
          for (i = 0; i < [value count]; i++) {
            NSString *str = [value objectAtIndex: i];
            NSUInteger count = [[arrayEdMatrix cells] count];

            [arrayEdMatrix insertRow: count];
            cell = [arrayEdMatrix cellAtRow: count column: 0];   
            [cell setStringValue: str];
            [cell setLeaf: YES];  
          }

          [arrayEdMatrix sizeToCells];         
          [arrayEdDefaultRevert setEnabled: (usrvalue && ([usrvalue isEqual: defvalue] == NO))];
          break;    
        }

    case LIST_EDITOR:
      [editorBox setContentView: listEditorBox];
      if (values && [values count] > 0)
        {
          [listEdPopup removeAllItems];
          [listEdPopup addItemsWithTitles:values];
          [listEdPopup selectItemWithTitle: value];
        }
      [listEdDefaultRevert setEnabled: (usrvalue && ([usrvalue isEqual: defvalue] == NO))];
      break;
        
      default:
        break;
    }
  } else {
    currentEntry = nil;
    [editorBox setContentView: nil];
  }
}

- (void)disableControls
{
  [stringEdDefaultRevert setEnabled: NO];
  [stringEdSet setEnabled: NO];

  [boolEdDefaultRevert setEnabled: NO];
  [boolEdSet setEnabled: NO];

  [numberEdDefaultRevert setEnabled: NO];
  [numberEdSet setEnabled: NO];

  [arrayEdAdd setEnabled: NO];
  [arrayEdRemove setEnabled: NO];
  [arrayEdDefaultRevert setEnabled: NO];
  [arrayEdSet setEnabled: NO];
}

- (void)updateDefaults
{
  CREATE_AUTORELEASE_POOL (arp);
  NSString *defname = [currentEntry name];
  id defvalue = [currentEntry defaultValue];
  id usrvalue = [currentEntry userValue];  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary *domain;

  [defaults synchronize];
  domain = [[defaults persistentDomainForName: NSGlobalDomain] mutableCopy];

  if (usrvalue != nil) {
    if ([usrvalue isEqual: defvalue] == NO) {
   //      NSLog(@"setting: %@ for: %@", [usrvalue description], defname);
      [domain setObject: usrvalue forKey: defname]; 
    } else {
   //   NSLog(@"removing: %@", defname);
      [domain removeObjectForKey: defname];
    }
  } else {
  //  NSLog(@"removing: %@", defname);
    [domain removeObjectForKey: defname];
  }

  [defaults setPersistentDomain: domain forName: NSGlobalDomain];
  [defaults synchronize];

  RELEASE (domain);  
  RELEASE (arp);
}

@end


@implementation Defaults (Editing)

- (void)controlTextDidChange:(NSNotification *)aNotification
{
  id sender = [aNotification object];  
  NSString *str = [sender stringValue];
  id defvalue = [currentEntry defaultValue];
  id usrvalue = [currentEntry userValue];

  if (sender == stringEdField) {
    [stringEdDefaultRevert setEnabled: ([defvalue isEqual: str] == NO)];
      
    if (usrvalue) {
      [stringEdSet setEnabled: ([usrvalue isEqual: str] == NO)];
    } else {
      [stringEdSet setEnabled: ([defvalue isEqual: str] == NO)];
    }
  
  } else if (sender == numberEdField) {
    [numberEdDefaultRevert setEnabled: ([[defvalue stringValue] isEqual: str] == NO)];
    
    if (usrvalue) {
      [numberEdSet setEnabled: ([[usrvalue stringValue] isEqual: str] == NO)];
    } else {
      [numberEdSet setEnabled: ([[defvalue stringValue] isEqual: str] == NO)];
    }
    
  } else if (sender == arrayEdField) {
    if (usrvalue) {
      [arrayEdAdd setEnabled: ([str length] && ([usrvalue containsObject: str] == NO))];
    } else {
      [arrayEdAdd setEnabled: ([str length] && ([defvalue containsObject: str] == NO))];
    }
  }
}

//
// String
//
- (IBAction)stringDefaultRevertAction:(id)sender
{
  id defvalue = [currentEntry defaultValue];
  id usrvalue = [currentEntry userValue];

  [stringEdField setStringValue: defvalue];
  [stringEdDefaultRevert setEnabled: NO];
    
  if (usrvalue) {
    [stringEdSet setEnabled: ([usrvalue isEqual: defvalue] == NO)];  
  } else {
    [stringEdSet setEnabled: NO];  
  }
}

- (IBAction)stringSetAction:(id)sender
{
  NSString *str = [stringEdField stringValue];
  id usrvalue = [currentEntry userValue];
   
  if ((usrvalue == nil) || ([str isEqual: usrvalue] == NO)) {
    [currentEntry setUserValue: str];
    [self updateDefaults];
  }
  
  [stringEdSet setEnabled: NO];
}

//
// Bool
//
- (IBAction)boolPopupAction:(id)sender
{
  NSNumber *num = [NSNumber numberWithInt: [boolEdPopup indexOfSelectedItem]];  
  id defvalue = [currentEntry defaultValue];
  id usrvalue = [currentEntry userValue];

  [boolEdDefaultRevert setEnabled: ([num isEqual: defvalue] == NO)];  

  if (usrvalue) {
    [boolEdSet setEnabled: ([num isEqual: usrvalue] == NO)];
  } else {
    [boolEdSet setEnabled: ([num isEqual: defvalue] == NO)];
  }
}

- (IBAction)boolDefaultRevertAction:(id)sender
{
  id defvalue = [currentEntry defaultValue];
  id usrvalue = [currentEntry userValue];

  [boolEdPopup selectItemAtIndex: [defvalue intValue]];
  [boolEdDefaultRevert setEnabled: NO];

  if (usrvalue) {
    [boolEdSet setEnabled: ([usrvalue isEqual: defvalue] == NO)];  
  } else {
    [boolEdSet setEnabled: NO];  
  }
}

- (IBAction)boolSetAction:(id)sender
{
  NSNumber *num = [NSNumber numberWithInt: [boolEdPopup indexOfSelectedItem]];  
  id usrvalue = [currentEntry userValue];
   
  if ((usrvalue == nil) || ([num isEqual: usrvalue] == NO)) {
    [currentEntry setUserValue: num];
    [self updateDefaults];
  }
  
  [boolEdSet setEnabled: NO];
}

//
// Number
//
- (IBAction)numberDefaultRevertAction:(id)sender
{
  id defvalue = [currentEntry defaultValue];
  id usrvalue = [currentEntry userValue];

  [numberEdField setStringValue: [defvalue stringValue]];
  [numberEdDefaultRevert setEnabled: NO];
    
  if (usrvalue) {
    [numberEdSet setEnabled: ([usrvalue isEqual: defvalue] == NO)];  
  } else {
    [numberEdSet setEnabled: NO];  
  }
}

- (IBAction)numberSetAction:(id)sender
{
  NSString *str = [numberEdField stringValue];
  id usrvalue = [currentEntry userValue];
  NSNumber *num = nil;
    
  if ([str length]) {  
    int n = [str intValue];
    
    if ((n != INT_MAX) && (n != INT_MIN)) {
      num = [NSNumber numberWithInt: n];
    }
  }  
  
  if (num == nil) {
    num = [currentEntry defaultValue];
  }
  
  if ((usrvalue == nil) || ([num isEqual: usrvalue] == NO)) {
    [currentEntry setUserValue: num];    
    [self updateDefaults];
  }
    
  [numberEdSet setEnabled: NO];  
}

//
// Array
//
- (void)arrayEdMatrixAction:(id)sender
{
  [arrayEdRemove setEnabled: ([arrayEdMatrix selectedCell] != nil)];
}

- (IBAction)arrayAddAction:(id)sender
{
  NSString *str = [arrayEdField stringValue];
  
  if ([str length]) {
    CREATE_AUTORELEASE_POOL (arp);
    id defvalue = [currentEntry defaultValue];
    id usrvalue = [currentEntry userValue];
    NSMutableArray *newvalue = [NSMutableArray array];
    NSArray *cells = [arrayEdMatrix cells];
    unsigned count = [cells count];
    BOOL exists = NO;
    
    if (count > 0) {
      NSUInteger i;
      
      for (i = 0; i < count; i++) {
        NSString *cellstr = [[cells objectAtIndex: i] stringValue];
        
        [newvalue addObject: cellstr];
      
        if ([cellstr isEqual: str]) {
          exists = YES;
        }
      }
    }
    
    if (exists == NO) {
      [arrayEdMatrix insertRow: count];
      [[arrayEdMatrix cellAtRow: count column: 0] setStringValue: str]; 
      [newvalue addObject: str];
      [arrayEdMatrix sizeToCells]; 
      [arrayEdField setStringValue: @""];
    }
    
    [arrayEdDefaultRevert setEnabled: ([defvalue isEqual: newvalue] == NO)];
    
    if (usrvalue) {
      [arrayEdSet setEnabled: ([usrvalue isEqual: newvalue] == NO)];
    } else {
      [arrayEdSet setEnabled: ([defvalue isEqual: newvalue] == NO)];
    }    
    
    RELEASE (arp);
  }
  
  [arrayEdAdd setEnabled: NO];   
}

- (IBAction)arrayRemoveAction:(id)sender
{
  id cell = [arrayEdMatrix selectedCell];  
  
  if (cell) {  
    CREATE_AUTORELEASE_POOL (arp);
    id defvalue = [currentEntry defaultValue];
    id usrvalue = [currentEntry userValue];
    NSMutableArray *newvalue = [NSMutableArray array];  
    NSArray *cells;
    NSInteger row, col;
    NSUInteger i;
    
    [arrayEdMatrix getRow: &row column: &col ofCell: cell];
    [arrayEdMatrix removeRow: row];
    [arrayEdMatrix sizeToCells];   
    
    cells = [arrayEdMatrix cells];

    for (i = 0; i < [cells count]; i++) {
      [newvalue addObject: [[cells objectAtIndex: i] stringValue]];
    }
    
    [arrayEdDefaultRevert setEnabled: ([defvalue isEqual: newvalue] == NO)];
    
    if (usrvalue) {
      [arrayEdSet setEnabled: ([usrvalue isEqual: newvalue] == NO)];
    } else {
      [arrayEdSet setEnabled: ([defvalue isEqual: newvalue] == NO)];
    }    
    
    RELEASE (arp);
  }
  
  [arrayEdRemove setEnabled: NO];   
}

- (IBAction)arrayDefaultRevertAction:(id)sender
{
  id defvalue = [currentEntry defaultValue];
  id usrvalue = [currentEntry userValue];
  id cell;
  NSUInteger i;
       
  if ([arrayEdMatrix numberOfColumns] > 0) {        
    [arrayEdMatrix removeColumn: 0];
  }
  
  for (i = 0; i < [defvalue count]; i++) {
    NSString *str = [defvalue objectAtIndex: i];
    NSUInteger count = [[arrayEdMatrix cells] count];

    [arrayEdMatrix insertRow: count];
    cell = [arrayEdMatrix cellAtRow: count column: 0];   
    [cell setStringValue: str];
    [cell setLeaf: YES];  
  }

  [arrayEdMatrix sizeToCells];    
  
  [arrayEdDefaultRevert setEnabled: NO]; 
    
  if (usrvalue) {
    [arrayEdSet setEnabled: ([usrvalue isEqual: defvalue] == NO)];  
  } else {
    [arrayEdSet setEnabled: NO];  
  }
}

- (IBAction)arraySetAction:(id)sender
{
  CREATE_AUTORELEASE_POOL (arp);
  id usrvalue = [currentEntry userValue];
  NSArray *cells = [arrayEdMatrix cells];
  NSMutableArray *newvalue = [NSMutableArray array];
  NSUInteger i;

  for (i = 0; i < [cells count]; i++) {
    [newvalue addObject: [[cells objectAtIndex: i] stringValue]];
  }

  if ((usrvalue == nil) || ([usrvalue isEqual: newvalue] == NO)) {
    [currentEntry setUserValue: newvalue];
    [self updateDefaults];
  }
    
  [arrayEdSet setEnabled: NO];
  
  RELEASE (arp);  
}

//
// List
//
- (IBAction)listPopupAction:(id)sender
{
  NSString *str = [listEdPopup titleOfSelectedItem];
  id defvalue = [currentEntry defaultValue];
  id usrvalue = [currentEntry userValue];

  [listEdDefaultRevert setEnabled: ([str isEqual: defvalue] == NO)];  

  if (usrvalue)
    {
      [listEdSet setEnabled: ([str isEqual: usrvalue] == NO)];
    }
  else
    {
      [listEdSet setEnabled: ([str isEqual: defvalue] == NO)];
    }
}

- (IBAction)listDefaultRevertAction:(id)sender
{
  id defvalue = [currentEntry defaultValue];
  id usrvalue = [currentEntry userValue];

  [listEdPopup selectItemWithTitle: defvalue];
  [listEdDefaultRevert setEnabled: NO];

  if (usrvalue)
    {
      [listEdSet setEnabled: ([usrvalue isEqual: defvalue] == NO)];  
    }
  else
    {
      [listEdSet setEnabled: NO];  
    }
}

- (IBAction)listSetAction:(id)sender
{
  NSString *str = [listEdPopup titleOfSelectedItem];  
  id usrvalue = [currentEntry userValue];

  if ((usrvalue == nil) || ([str isEqual: usrvalue] == NO))
    {
      [currentEntry setUserValue: str];
      [self updateDefaults];
    }
  
  [listEdSet setEnabled: NO];
}

@end


@implementation DefaultEntry

- (void)dealloc
{
  RELEASE (name);
  RELEASE (category);
  RELEASE (description);
  TEST_RELEASE (userValue);
  RELEASE (defaultValue);
  RELEASE (values);
  [super dealloc];
}

- (id)initWithUserDefaults:(NSUserDefaults *)defaults
                  withName:(NSString *)dfname
                inCategory:(NSString *)cat
               description:(NSString *)desc
		    values:(NSArray *)vals
              defaultValue:(id)dval
                editorType:(int)edtype
{
  self = [super init];
  
  if (self) {
    ASSIGN (name, dfname);
    ASSIGN (category, cat);
    ASSIGN (description, desc);
    ASSIGN (defaultValue, dval);
    ASSIGN (values, vals);
    editorType = edtype;
    
    userValue = [defaults objectForKey: name];
    TEST_RETAIN (userValue);
  }
  
  return self;
}

- (NSString *)name
{
  return name;
}

- (NSString *)category
{
  return category;
}

- (NSString *)description
{
  return description;
}

- (id)defaultValue
{
  return defaultValue;
}

- (id)userValue
{
  return userValue;
}

- (void)setUserValue:(id)usval
{
  if (usval != nil) {
    ASSIGN (userValue, usval);
  } else {
    DESTROY (userValue);
  }
}

- (NSArray *)values
{
  return values;
}

- (int)editorType
{
  return editorType;
}

@end

