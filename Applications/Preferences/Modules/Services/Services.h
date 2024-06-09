/* Services.h
 *  
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author: OnFlApp
 * Date: December 2005
 *
 * This file is part of the GNUstep TimeZone Preference Pane
 * Take from the apps-systempreferences app
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

#import <GNUstepGUI/GSServicesManager.h>
#import <Preferences.h>

@interface ServicesPrefs: NSObject <PrefsModule>
{
  IBOutlet id            window;
  IBOutlet id            view;
  IBOutlet NSBrowser*    browser;
  IBOutlet NSButton*     statusButton;

  NSImage                *image;

  GSServicesManager      *servicesManager;
  NSDictionary           *services;
  NSArray                *apps;
}

- (void) selectService:(id) sender;
- (void) changeStatus:(id) sender;

@end
