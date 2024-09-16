/* ModifierKeys.h
 *  
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: December 2005
 *
 * This file is part of the GNUstep ModifierKeys Preference Pane
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

#include <AppKit/AppKit.h>
#include "ModifierKeys.h"

#import <DesktopKit/NXTDefaults.h>
#import <SystemKit/OSEKeyboard.h>

static NSString *menuEntries = @"\
{\
\"None\" = \"NoSymbol\"; \
\"AltGr (XFree86 4.3+)\" = \"ISO_Level3_Shift\"; \
\"Left Alt\" = \"Alt_L\"; \
\"Left Control\" = \"Control_L\"; \
\"Left Hyper\" = \"Hyper_L\"; \
\"Left Meta\" = \"Meta_L\"; \
\"Left Super\" = \"Super_L\"; \
\"Right Alt\" = \"Alt_R\"; \
\"Right Control\" = \"Control_R\"; \
\"Right Hyper\" = \"Hyper_R\"; \
\"Right Meta\" = \"Meta_R\"; \
\"Right Super\" = \"Super_R\"; \
\"Mode Switch\" = \"Mode_switch\"; \
\"Multi-Key\" = \"Multi_key\"; \
} \
";

@implementation ModifierKeys

- (void)awakeFromNib
{
  if (loaded == NO) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [menuEntries propertyList];
    id entry;

    [self setItemsForMenu: firstAlternatePopUp fromDictionary: dict];
    entry = [defaults objectForKey: @"GSFirstAlternateKey"];    
    [self selectItemWithRepresentedObject: entry
                                   inMenu: firstAlternatePopUp]; 

    [self setItemsForMenu: firstCommandPopUp fromDictionary: dict];
    entry = [defaults objectForKey: @"GSFirstCommandKey"];    
    [self selectItemWithRepresentedObject: entry
                                   inMenu: firstCommandPopUp]; 

    [self setItemsForMenu: firstControlPopUp fromDictionary: dict];
    entry = [defaults objectForKey: @"GSFirstControlKey"];    
    [self selectItemWithRepresentedObject: entry
                                   inMenu: firstControlPopUp]; 

    [self setItemsForMenu: secondAlternatePopUp fromDictionary: dict];
    entry = [defaults objectForKey: @"GSSecondAlternateKey"];    
    [self selectItemWithRepresentedObject: entry
                                   inMenu: secondAlternatePopUp]; 

    [self setItemsForMenu: secondCommandPopUp fromDictionary: dict];
    entry = [defaults objectForKey: @"GSSecondCommandKey"];    
    [self selectItemWithRepresentedObject: entry
                                   inMenu: secondCommandPopUp]; 

    [self setItemsForMenu: secondControlPopUp fromDictionary: dict];
    entry = [defaults objectForKey: @"GSSecondControlKey"];    
    [self selectItemWithRepresentedObject: entry
                                   inMenu: secondControlPopUp]; 

    loaded = YES;
  }

  NXTDefaults *keydefaults = [NXTDefaults globalUserDefaults];
  NSInteger val = [keydefaults integerForKey:OSEKeyboardAltCmdSwap];
  if (val < 0) val = 0;
  [swapAltCmdBtn setState:val];
}

- (NSView*) contentView 
{
  return [window contentView];
}

- (void)setItemsForMenu:(id)menu 
         fromDictionary:(NSDictionary *)dict
{
  NSArray *titles = [dict allKeys];
  unsigned i;

  [menu removeAllItems];

  for (i = 0; i < [titles count]; i++) {
    NSString *title = [titles objectAtIndex: i];
    id <NSMenuItem> item;

    [menu addItemWithTitle: title];
    item = [menu lastItem];
    [item setRepresentedObject: [dict objectForKey: title]];
  }
}

- (id)itemWithRepresentedObject:(id)anobject
                         inMenu:(id)menu
{
  NSArray *items = [menu itemArray];
  unsigned i;

  for (i = 0; i < [items count]; i++) {
    id <NSMenuItem> item = [items objectAtIndex: i];
    id repobj = [item representedObject];

    if (repobj && [repobj isEqual: anobject]) {
      return item;
    }
  }

  return nil;
}

- (void)selectItemWithRepresentedObject:(id)anobject
                                 inMenu:(id)menu
{
  if (anobject) {
    id item = [self itemWithRepresentedObject: anobject inMenu: menu];

    if (item) {
      [menu selectItem: item];
    } else {
      [menu selectItemWithTitle: @"None"];
    }

  } else {
    [menu selectItemWithTitle: @"None"];  
  }
}

- (IBAction)swapAction:(id)sender
{
  NXTDefaults *keydefaults = [NXTDefaults globalUserDefaults];
  if (sender == swapAltCmdBtn)
    {
      [keydefaults setInteger:[sender state] forKey:OSEKeyboardAltCmdSwap];
    }

  //[OSEKeyboard configureWithDefaults:keydefaults];
  [[NSApp delegate]configureMouseAndKeyboard];
}

- (IBAction)popupsAction:(id)sender
{
  id modifier = [[sender selectedItem] representedObject];

  if (modifier) {
    CREATE_AUTORELEASE_POOL(arp);
    NSUserDefaults *defaults;
    NSMutableDictionary *domain;

    defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    domain = [[defaults persistentDomainForName: NSGlobalDomain] mutableCopy];

    if (sender == firstAlternatePopUp) {
      if ([modifier isEqualToString:@"NoSymbol"]) {
        [domain removeObjectForKey:@"GSFirstAlternateKey"];
        [domain removeObjectForKey:@"GSSecondAlternateKey"];
      }
      else {
        [domain setObject: modifier forKey: @"GSFirstAlternateKey"];
        [domain setObject: modifier forKey: @"GSSecondAlternateKey"];
      }
    } else if (sender == firstCommandPopUp) {
      if ([modifier isEqualToString:@"NoSymbol"]) [domain removeObjectForKey:@"GSFirstCommandKey"];
      else                                        [domain setObject: modifier forKey: @"GSFirstCommandKey"];
    } else if (sender == firstControlPopUp) {
      if ([modifier isEqualToString:@"NoSymbol"]) [domain removeObjectForKey:@"GSFirstControlKey"];
      else                                        [domain setObject: modifier forKey: @"GSFirstControlKey"];
    } else if (sender == secondAlternatePopUp) {
      if ([modifier isEqualToString:@"NoSymbol"]) [domain removeObjectForKey:@"GSSecondAlternateKey"];
      else                                        [domain setObject: modifier forKey: @"GSSecondAlternateKey"];
    } else if (sender == secondCommandPopUp) {
      if ([modifier isEqualToString:@"NoSymbol"]) [domain removeObjectForKey:@"GSSecondCommandKey"];
      else                                        [domain setObject: modifier forKey: @"GSSecondCommandKey"];
    } else if (sender == secondControlPopUp) {
      if ([modifier isEqualToString:@"NoSymbol"]) [domain removeObjectForKey:@"GSSecondControlKey"];
      else                                        [domain setObject: modifier forKey: @"GSSecondControlKey"];
    }

    [defaults setPersistentDomain: domain forName: NSGlobalDomain]; 
    [defaults synchronize];
    RELEASE (domain);
    RELEASE (arp); 
  }
}

@end	













