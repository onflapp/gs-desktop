/* OSSPreference.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002, 2003 Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <wolfgang@contre.com>
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#import <AppKit/NSBox.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSUserDefaults.h>

#import <Cynthiune/Preference.h>
#import <Cynthiune/utils.h>

#import "OSS.h"
#import "OSSPreference.h"

#define LOCALIZED(X) _b ([OSS class], X)

@implementation OSSPreference : NSObject

+ (id) instance
{
  static OSSPreference *singleton = nil;

  if (!singleton)
    singleton = [[OSSPreference alloc] _init];

  return singleton;
}

- (OSSPreference *) _init
{
  NSDictionary *tmpDict;

  if ((self = [super init]))
    {
      tmpDict = [[NSUserDefaults standardUserDefaults]
                  dictionaryForKey: @"OSS"];
      preference = [NSMutableDictionary dictionaryWithDictionary: tmpDict];
      [preference retain];
    }

  return self;
}

- (NSView *) preferenceSheet
{
  NSView *aView;

  [NSBundle loadNibNamed: @"OSSPreferences" owner: self];
  aView = [prefsWindow contentView];
  [aView retain];
  [aView removeFromSuperview];
  [prefsWindow release];
  [aView autorelease];

  return aView;
}

- (void) _initDefaults
{
  NSString *dspDevice;
  static BOOL initted = NO;

  if (!initted)
    {
      dspDevice = [preference objectForKey: @"dspDevice"];
      if (!dspDevice)
        {
          dspDevice = @"/dev/dsp";
          [preference setObject: dspDevice forKey: @"dspDevice"];
        }
      initted = YES;
    }
}

- (void) awakeFromNib
{
  [self _initDefaults];

  [dspBox setTitle: LOCALIZED (@"DSP device")];
  [dspDeviceLabel setStringValue: LOCALIZED (@"Filename")];
  [dspDeviceField setStringValue: [preference objectForKey: @"dspDevice"]];
}

- (NSString *) preferenceTitle
{
  return @"OSS";
}

- (void) save
{
  NSUserDefaults *defaults;

  defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject: preference forKey: @"OSS"];
  [defaults synchronize];
}

- (NSString *) dspDevice
{
  [self _initDefaults];

  return [preference objectForKey: @"dspDevice"];
}

- (void) controlTextDidEndEditing: (NSNotification *) notification
{
  [preference setObject: [[notification object] stringValue]
              forKey: @"dspDevice"];
}

@end
