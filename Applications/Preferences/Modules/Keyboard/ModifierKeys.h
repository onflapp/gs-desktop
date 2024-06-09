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

#ifndef MODIFIER_KEYS_H
#define MODIFIER_KEYS_H

#import <AppKit/AppKit.h>
#import <Preferences.h>

@interface ModifierKeys : NSObject
{
  IBOutlet NSWindow* window;
  IBOutlet id firstAlternateLabel;
	IBOutlet id firstAlternatePopUp;
  IBOutlet id firstCommandLabel;  
	IBOutlet id firstCommandPopUp;
  IBOutlet id firstControlLabel;  
	IBOutlet id firstControlPopUp;
  
  IBOutlet id secondAlternateLabel;  
	IBOutlet id secondAlternatePopUp;
  IBOutlet id secondCommandLabel;  
	IBOutlet id secondCommandPopUp;
  IBOutlet id secondControlLabel;  
	IBOutlet id secondControlPopUp;
  
  BOOL loaded;
}

- (void)setItemsForMenu:(id)menu 
         fromDictionary:(NSDictionary *)dict;

- (id)itemWithRepresentedObject:(id)anobject
                         inMenu:(id)menu;

- (void)selectItemWithRepresentedObject:(id)anobject
                                 inMenu:(id)menu;

- (IBAction)popupsAction:(id)sender;

@end

#endif	// MODIFIER_KEYS_H
