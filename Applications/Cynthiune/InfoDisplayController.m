/* InfoDisplayController.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004  Wolfgang Sourdeau
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

#import <AppKit/NSFont.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSImageView.h>
#import <AppKit/NSTextField.h>

#import <Cynthiune/NSNumberExtensions.h>
#import <Cynthiune/NSTimerExtensions.h>
#import <Cynthiune/utils.h>

#import "CynthiuneFadingTextField.h"
#import "FormatTester.h"
#import "InfoDisplayController.h"
#import "Song.h"

#define LOCALIZED(X) NSLocalizedString (X, nil)

@implementation InfoDisplayController : NSObject

- (void) initializeWidgets
{
  NSFont *myFont;

  myFont = [NSFont boldSystemFontOfSize: 12.0];
  [songTitleField setFont: myFont];
  myFont = [NSFont systemFontOfSize: 12.0];
  [songTimerField setFont: myFont];
  [songNumberField setFont: myFont];
  [songArtistField setFont: myFont];
  [songAlbumField setFont: myFont];

  [splashImage setImage: [NSImage imageNamed: @"cynthiune-splash"]];

  [songTitleField setSelectable: NO];
  [songNumberField setSelectable: NO];
  [songArtistField setSelectable: NO];
  [songAlbumField setSelectable: NO];

  [songTitleField setStringValue: @""];
  [songTimerField setStringValue: @""];
  [songNumberField setStringValue: @""];
  [songArtistField setStringValue: @""];
  [songAlbumField setStringValue: @""];
}

- (id) init
{
  if ((self = [super init]))
    {
      hideTimer = nil;
      reverseTimer = NO;
      totalTime = 0;
    }

  return self;
}

- (void) show
{
  if (hideTimer)
    {
      [hideTimer invalidate];
      hideTimer = nil;
    }
  else
    {
      [splashImage setImage: [NSImage imageNamed: @"cynthiune-splash-faded"]];

      [songTitleField setSelectable: YES];
      [songNumberField setSelectable: YES];
      [songArtistField setSelectable: YES];
      [songAlbumField setSelectable: YES];
    }
}

- (void) _reallyHide
{
  [songTimerField setStringValue: @""];
  [splashImage setImage: [NSImage imageNamed: @"cynthiune-splash"]];

  [songTitleField setSelectable: NO];
  [songNumberField setSelectable: NO];
  [songArtistField setSelectable: NO];
  [songAlbumField setSelectable: NO];

  hideTimer = nil;
}

- (void) hide
{
  float hideInterval;

  [songTitleField setStringValue: @""];
  [songNumberField setStringValue: @""];
  [songArtistField setStringValue: @""];
  [songAlbumField setStringValue: @""];

  if (hideTimer)
    [hideTimer invalidate];
  hideInterval = ([songTitleField interval]
                  * [songTitleField numberOfIterations]);
  hideTimer = [NSTimer scheduledTimerWithTimeInterval: hideInterval
                       target: self
                       selector: @selector (_reallyHide)
                       userInfo: nil
                       repeats: NO];
  [hideTimer explode];
}

- (void) updateInfoFieldsFromSong: (Song *) aSong
{
  NSString *title;

  title = [aSong title];
  if ([title isEqualToString: @""])
    title = [NSString stringWithFormat: @"[%@]", [aSong filename]];
  [songArtistField setStringValue: [aSong artist]];
  [songAlbumField setStringValue: [aSong album]];
  [songTitleField setStringValue: title];
  [songNumberField setStringValue: [aSong trackNumber]];
  totalTime = [[aSong duration] unsignedIntValue];
}

- (void) setReverseTimer: (BOOL) reversed
{
  reverseTimer = reversed;
}

- (BOOL) timerIsReversed
{
  return reverseTimer;
}

- (void) _setTimerFromUnsignedInt: (unsigned int) timer
{
  NSNumber *seconds;

  seconds = [NSNumber numberWithUnsignedInt: timer];

  [songTimerField setStringValue: [seconds timeStringValue]];
}

- (void) setTimerFromSeconds: (unsigned int) seconds
{
  [self _setTimerFromUnsignedInt: ((reverseTimer)
                                   ? totalTime - seconds
                                   : seconds)];
}

@end
