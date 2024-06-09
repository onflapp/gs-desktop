/* Date.m
 *  
 * Copyright (C) 2005-2013 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
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

#import <math.h>

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

#import "Date.h"
#import "MapView.h"

@implementation DatePrefs

- (id)init
{
  NSBundle *bundle;
  NSString *imagePath;
  
  self = [super init];
  
  bundle = [NSBundle bundleForClass:[self class]];
  imagePath = [bundle pathForResource:@"Time" ofType:@"tiff"];
  image = [[NSImage alloc] initWithContentsOfFile:imagePath];
  
  return self;
}

- (void)dealloc
{
  NSLog(@"DatePrefs -dealloc");
  [image release];

  if (view) [view release];

  [super dealloc];
}

- (void)awakeFromNib
{
  if (mapView == nil)
    {
      NSBundle* bundle = [NSBundle bundleForClass:[self class]];
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSString *zone = [defaults objectForKey: @"Local Time Zone"];
      NSString *path = [bundle pathForResource: @"map" ofType: @"tiff"];
      NSImage *map = [[NSImage alloc] initWithContentsOfFile: path];

      path = [bundle pathForResource: @"zones" ofType: @"db"];

      mapView = [[MapView alloc] initWithFrame: [[imageBox contentView] frame]
				  withMapImage: map
				 timeZonesPath: path
			     forPreferencePane: self];

      [(NSBox *)imageBox setContentView: mapView];
      RELEASE (mapView);
      RELEASE (map);

      NSScrollView* scrollView = (NSScrollView *)[[imageBox superview] superview];
      [[scrollView contentView] scrollToPoint:NSMakePoint(80, 30)];
      [scrollView reflectScrolledClipView: [scrollView contentView]];


     [timeFormat setState:[[NXTDefaults globalUserDefaults] boolForKey:@"ClockView24HourFormat"]];

      if (zone)
	{
	  [zoneField setStringValue: zone];
	}
    }  

  [view retain];
  [window release];
}

- (NSView *) view
{
  if (view == nil)
    {
      if (![NSBundle loadNibNamed:@"Date" owner:self])
        {
          NSLog (@"Date.preferences: Could not load NIB, aborting.");
          return nil;
        }
      view = [[window contentView] retain];
    }

  return view;
}

- (NSString *) buttonCaption
{
  return @"Timezone Preferences";
}

- (NSImage *) buttonImage
{
  return image;
}

- (void)showInfoOfLocation:(MapLocation *)loc
{
  if (loc) {
    [zoneField setStringValue: [loc zone]];
    [codeField setStringValue: [loc code]];
    [commentsField setStringValue: (([loc comments] != nil) ? [loc comments] : @"")];
  } else {
    [zoneField setStringValue: @""];
    [codeField setStringValue: @""];
    [commentsField setStringValue: @""];
  }
}

- (IBAction)toggleTimeFormat:(id)sender
{
  NSInteger v = (NSInteger)[sender state];
  [[NXTDefaults globalUserDefaults] setBool:(BOOL)v forKey:@"ClockView24HourFormat"];
  [[NXTDefaults globalUserDefaults] synchronize];
}

- (IBAction)setButtAction:(id)sender
{
  CREATE_AUTORELEASE_POOL(arp);
  NSUserDefaults *defaults;
  NSMutableDictionary *domain;

  defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  domain = [[defaults persistentDomainForName: NSGlobalDomain] mutableCopy];

  [domain setObject: [zoneField stringValue] forKey: @"Local Time Zone"];  
  
  [defaults setPersistentDomain: domain forName: NSGlobalDomain];
  [defaults synchronize];
  RELEASE (domain);

  RELEASE (arp);
}


@end
