/* TimeZone.h
 *  
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
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

#import <Preferences.h>

@class MapView;
@class MapLocation;

@interface DatePrefs: NSObject <PrefsModule>
{
  IBOutlet id            window;;
  IBOutlet id            view;
  NSImage                *image; 

  IBOutlet NSBox *imageBox;
  MapView *mapView;
  IBOutlet id zoneField;
  IBOutlet id codeField;
  IBOutlet id commentsField;
  IBOutlet id setButt;
  IBOutlet id timeFormat;
}

- (void)showInfoOfLocation:(MapLocation *)loc;

- (IBAction)setButtAction:(id)sender;
- (IBAction)toggleTimeFormat:(id)sender;

@end
