/* $OUTPUT$.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004 Wolfgang Sourdeau
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

#ifndef _REENTRANT
#define _REENTRANT 1
#endif

#import <AppKit/AppKit.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>
#import <Cynthiune/Preference.h>

#import "$OUTPUT$.h"

#define LOCALIZED(X) _b ([$OUTPUT$ class], X)

@implementation $OUTPUT$ : NSObject

+ (NSString *) bundleDescription
{
  return @"Output plug-in for the Wawa sound daemon";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2005  Wawa Ragga",
                  nil];
}

+ (BOOL) isThreaded
{
  return NO;
}

- (void) setParentPlayer: (id) aPlayer;
{
  parentPlayer = aPlayer;
}

- (id) init
{
  if ((self = [super init]))
    {
    }

  return self;
}

- (BOOL) prepareDeviceWithChannels: (unsigned int) numberOfChannels
                           andRate: (unsigned long) sampleRate
{
  return NO;
}

- (BOOL) openDevice
{
  return NO;
}

- (void) closeDevice
{
}

- (void) playChunk: (NSData *) chunk
{
}

@end
