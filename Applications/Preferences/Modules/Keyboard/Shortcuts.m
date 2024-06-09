/* -*- mode: objc -*- */
//
// Project: Preferences
//
// Copyright (C) 2014-2019 OnFlApp
//
// This application is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This application is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this library; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
//

#import "Shortcuts.h"

@implementation Shortcuts

- (void)awakeFromNib
{
}

- (void)dealloc
{
  RELEASE(applications);
  RELEASE(shortcuts);

  [super dealloc];
}

- (void)reload
{
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
  NSArray* domains = [defs persistentDomainNames];
  NSMutableArray* alist = [NSMutableArray array];
  NSMutableDictionary* slist = [NSMutableDictionary dictionary];
  
  for (NSString* domain in domains) {
    NSDictionary* dict = [defs persistentDomainForName:domain];
    NSDictionary* vals = [dict valueForKey:@"NSUserKeyEquivalents"];
    if (vals) 
      {
        [alist addObject:domain];
        NSMutableArray* keys = [NSMutableArray array];
        for (id key in [vals allKeys]) {
          id val = [vals valueForKey:key];
          [keys addObject:[NSDictionary dictionaryWithObjectsAndKeys:key, @"name", val, @"key", nil]];
        }

      [slist setValue:keys forKey:domain];
    }
  }

  ASSIGN(applications, alist);
  ASSIGN(shortcuts, slist);

  [browser reloadColumn:0];
  [self select:nil];
}

//
// NSBrowser delegate
// 
- (NSInteger) browser:(NSBrowser *)sender
 numberOfRowsInColumn:(NSInteger)column
{
  if (column == 0)
    {
      return [applications count];
    }
  else
    {
      NSString* name = [[sender selectedCellInColumn:0] representedObject];
      NSArray* keys = [shortcuts valueForKey:name];
      return [keys count];
    }
}

- (void) browser:(NSBrowser *)sender
 willDisplayCell:(id)cell
           atRow:(NSInteger)row
          column:(NSInteger)column
{
  if (column == 0)
    {
      NSString* name = [applications objectAtIndex:row];
      [cell setRepresentedObject:name];
      [cell setTitle:name];
      [cell setLeaf:NO];
    }
  else if (column == 1)
    {
      NSString* name = [[sender selectedCellInColumn:0] representedObject];
      NSArray* keys = [shortcuts valueForKey:name];
      NSString* title = [[keys objectAtIndex:row] valueForKey:@"name"];
      [cell setTitle:title];
      [cell setLeaf:YES];
      [cell setRepresentedObject:[keys objectAtIndex:row]];
    }
}

- (IBAction)select:(id)sender
{
  NSString* name = [[sender selectedCellInColumn:0] representedObject];
  NSDictionary* key = [[sender selectedCellInColumn:1] representedObject];
  
  if (name && key) 
    {
      [applicationField setStringValue:name];
      [titleField setStringValue:[key valueForKey:@"name"]];
      [keyField setStringValue:[key valueForKey:@"key"]];
    
      [addButton setEnabled:YES];
      [removeButton setEnabled:YES];
    }
  else 
    {
      if (name)
        [applicationField setStringValue:name];
      else
        [applicationField setStringValue:@""];

      [titleField setStringValue:@""];
      [keyField setStringValue:@""];

      [addButton setEnabled:YES];
      [removeButton setEnabled:NO];
    }
}

- (IBAction)add:(id)sender
{
  NSString* name = [applicationField stringValue];
  NSString* title = [titleField stringValue];
  NSString* key = [keyField stringValue];
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];

  if ([name length] && [title length] && [key length]) 
    {
      NSMutableDictionary* dict = [[defs persistentDomainForName:name] mutableCopy];
      if (!dict)
        dict = [NSMutableDictionary dictionary];

      NSMutableDictionary* vals = [[dict valueForKey:@"NSUserKeyEquivalents"] mutableCopy];
      if (!vals)
        vals = [NSMutableDictionary dictionary];

      [vals setValue:key forKey:title];
      [dict setValue:vals forKey:@"NSUserKeyEquivalents"];

      [defs setPersistentDomain:dict forName:name];
      [defs synchronize];

      [self reload];
    }
}

- (IBAction)remove:(id)sender
{
  NSString* name = [applicationField stringValue];
  NSString* title = [titleField stringValue];
  NSString* key = [keyField stringValue];
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];

  if ([name length] && [title length] && [key length]) 
    {
      NSMutableDictionary* dict = [[defs persistentDomainForName:name] mutableCopy];
      if (!dict)
        return;

      NSMutableDictionary* vals = [[dict valueForKey:@"NSUserKeyEquivalents"] mutableCopy];
      if (!vals)
        return;

      [vals removeObjectForKey:title];
      [dict setValue:vals forKey:@"NSUserKeyEquivalents"];

      [defs setPersistentDomain:dict forName:name];
      [defs synchronize];

      [self reload];
    }
}

@end
