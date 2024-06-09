/* Services.m
 *  
 * Copyright (C) 2005-2013 Free Software Foundation, Inc.
 *
 * Author: OnFlApp
 * Date: December 2005
 *
 * This file is part of the GNUstep TimeZone Preference Pane
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

#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontPanel.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSOpenPanel.h>

#import <AppKit/NSApplication.h>

#import <DesktopKit/NXTDefaults.h>

#import "Services.h"

NSString* niceName(NSString* str) {
  NSRange r = [str rangeOfString:@"/"];
  if (r.location != NSNotFound) {
    return [str substringFromIndex:r.location+1];
  }
  else {
    return str;
  }
}

@implementation GSServicesManager (all)
- (NSDictionary*) allServices
{
  id _title2info_save = [_title2info retain];
  id _allDisabled_save = [_allDisabled retain];

  ASSIGN(_allDisabled, nil);
  [self rebuildServices];
  id _title2info_all = [_title2info retain];

  ASSIGN(_title2info, _title2info_save);
  ASSIGN(_allDisabled, _allDisabled_save);

  return _title2info_all;
}
@end

@implementation ServicesPrefs

- (id)init
{
  NSBundle *bundle;
  NSString *imagePath;
  
  self = [super init];
  
  bundle = [NSBundle bundleForClass:[self class]];
  imagePath = [bundle pathForResource:@"Services" ofType:@"tiff"];
  image = [[NSImage alloc] initWithContentsOfFile:imagePath];
  
  return self;
}

- (void)dealloc
{
  NSLog(@"ServicesPrefs -dealloc");
  [image release];
  [apps release];
  [services release];
  [servicesManager release];

  if (view) [view release];

  [super dealloc];
}

- (void)awakeFromNib
{
}

- (void)changeStatus:(id) sender 
{
  NSString* item = [[browser selectedCellInColumn:1] representedObject];
  if (item) {
    BOOL show = ![servicesManager showsServicesMenuItem:item];
    [servicesManager setShowsServicesMenuItem:item to:show];

    [browser reloadColumn:0];
  }
}
- (void)selectService:(id) sender 
{
  NSString* item = [[sender selectedCellInColumn:1] representedObject];
  if (item) {
    BOOL show = [servicesManager showsServicesMenuItem:item];
    [statusButton setState:(show?NSOnState:NSOffState)];
    [statusButton setEnabled:YES];
  }
  else {
    [statusButton setEnabled:NO];
  }
}
- (void)refreshServices
{
  GSServicesManager* sman = [GSServicesManager newWithApplication:nil];
  NSDictionary* ls        = [sman allServices];
  NSMutableArray* alist   = [NSMutableArray array];

  for (id key in [ls allKeys]) {
    id val = [ls valueForKey:key];
    NSString* aname = [val valueForKey:@"NSPortName"];
    if ([alist containsObject:aname] == NO) {
      [alist addObject:aname];
    }
  }

  ASSIGN(apps, alist);
  ASSIGN(services, ls);
  ASSIGN(servicesManager, sman);
}

- (NSArray*)servicesForApp:(NSString*) app
{
  NSMutableArray* slist = [NSMutableArray array];
  for (id key in [services allKeys]) {
    id val = [services valueForKey:key];
    NSString* aname = [val valueForKey:@"NSPortName"];
    if ([app isEqualToString:aname] == YES) {
      [slist addObject:val];
    }
  }
  return slist;
}

- (NSView *)view
{
  if (view == nil)
    {
      if (![NSBundle loadNibNamed:@"Services" owner:self])
        {
          NSLog (@"Services.preferences: Could not load NIB, aborting.");
          return nil;
        }
      view = [[window contentView] retain];
    }

  [self refreshServices];
  [browser reloadColumn:0];
  return view;
}

- (void) browser:(NSBrowser*) brow willDisplayCell:(NSBrowserCell*) cell atRow:(NSInteger)row column:(NSInteger)col 
{
  if (col == 0) {
    NSString* app = [apps objectAtIndex:row];
    NSArray* ls = [self servicesForApp:app];

    [cell setRepresentedObject:ls];
    [cell setLeaf:NO];
    [cell setStringValue:app];

  }
  else {
    NSArray* ls = [[brow selectedCellInColumn:0] representedObject];
    id it = [ls objectAtIndex:row];
    NSString* name = [it valueForKeyPath:@"NSMenuItem.default"];
    [cell setLeaf:YES];
    [cell setStringValue:niceName(name)];
    [cell setRepresentedObject:name];
  }
}

- (NSInteger) browser:(NSBrowser*) brow numberOfRowsInColumn:(NSInteger) col 
{
  if (col == 0) {
    return [apps count];
  }
  else {
    NSArray* ls = [[brow selectedCellInColumn:0] representedObject];
    return [ls count];
  }
}

- (NSString *) buttonCaption
{
  return @"Services Preferences";
}

- (NSImage *) buttonImage
{
  return image;
}

@end
