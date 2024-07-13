/* -*- mode: objc -*- */
//
// Project: Preferences
//
// Copyright (C) 2024 OnFlApp
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

#import <AppKit/NSApplication.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSScroller.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSWorkspace.h>
#import <AppKit/NSPopUpButton.h>

#import "Touch.h"

static NSBundle                 *bundle = nil;

@implementation Touch

- (id)init
{
  self = [super init];
  
  bundle = [NSBundle bundleForClass:[self class]];
  NSString *imagePath = [bundle pathForResource:@"Touch" ofType:@"tiff"];
  image = [[NSImage alloc] initWithContentsOfFile:imagePath];

  return self;
}

- (void)dealloc
{
  NSLog(@"Touch -dealloc");

  [image release];

  if (view) {
    [view release];
  }
  
  [super dealloc];
}

- (void)awakeFromNib
{
  [view retain];
  [window release];

  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* domain = [defaults persistentDomainForName:@"GestureHelper"];

  BOOL val = [[domain valueForKey:@"ScrollEnabled"] boolValue];
  [scrollEnabled setState:val];

  val = [[domain valueForKey:@"ScrollReversed"] boolValue];
  [scrollReversed setState:val];

  val = [[domain valueForKey:@"ScrollVerticalEnabled"] boolValue];
  [scrollVerticalEnabled setState:val];

  val = [[domain valueForKey:@"ScrollHorizontalEnabled"] boolValue];
  [scrollHorizontalEnabled setState:val];
}

- (NSView *)view
{
  if (view == nil)
    {
      if (![NSBundle loadNibNamed:@"Touch" owner:self])
        {
          NSLog (@"Touch.preferences: Could not load NIB, aborting.");
          return nil;
        }
    }
  
  return view;
}

- (NSString *)buttonCaption
{
  return @"Touch Preferences";
}

- (NSImage *)buttonImage
{
  return image;
}

- (void) advancedConfig:(id) sender
{
  id app = [NSConnection rootProxyForConnectionWithRegisteredName:@"GestureHelper" 
                                                             host:@""];
  [app showPreferences];
}

- (void) changeConfig:(id) sender
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary* domain = [[defaults persistentDomainForName:@"GestureHelper"] mutableCopy];

  BOOL val = [scrollEnabled state];
  [domain setValue:[NSNumber numberWithBool:val] forKey:@"ScrollEnabled"];

  val = [scrollReversed state];
  [domain setValue:[NSNumber numberWithBool:val] forKey:@"ScrollReversed"];

  val = [scrollVerticalEnabled state];
  [domain setValue:[NSNumber numberWithBool:val] forKey:@"ScrollVerticalEnabled"];

  val = [scrollHorizontalEnabled state];
  [domain setValue:[NSNumber numberWithBool:val] forKey:@"ScrollHorizontalEnabled"];

  [defaults setPersistentDomain:domain forName:@"GestureHelper"];
  [defaults synchronize];

  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(_notifyConfigChange) 
             withObject:nil
             afterDelay:0.5];
}

- (void) _notifyConfigChange 
{
  id app = [NSConnection rootProxyForConnectionWithRegisteredName:@"GestureHelper" 
                                                             host:@""];
  [app syncPreferences];
}

@end
