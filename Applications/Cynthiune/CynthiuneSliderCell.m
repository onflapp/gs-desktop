/* CynthiuneSliderCell.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
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

#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>

#import <Foundation/NSString.h>

#import <math.h>

#import "CynthiuneSliderCell.h"

@implementation CynthiuneSliderCell : NSSliderCell

- (id) init
{
  if ((self = [super init]))
    {
      knobCell = [NSCell new];
    }

  return self;
}

- (void) setEnabled: (BOOL) enabled
{
  [super setEnabled: enabled];
  [knobCell setImage: [NSImage imageNamed: ((enabled)
                                            ? @"slider-knob-enabled"
                                            : @"slider-knob-disabled")]];
}

- (void) drawKnob: (NSRect) rect
{
  [knobCell drawInteriorWithFrame: rect inView: [self controlView]];
}

- (void) drawBarInside: (NSRect) cellFrame
               flipped: (BOOL) flipped;
{
  NSRect rect;

  rect = cellFrame;

  [[NSColor controlShadowColor] set];

  rect.size.width = 1;
  rect.size.height = 1;
  rect.origin.y += (cellFrame.size.height - 4) / 2 + 2;
  NSRectFill (rect);

  rect.origin.y += 1;
  NSRectFill (rect);

  rect.origin.x += 1;
  rect.size.width = cellFrame.size.width - 2;
  rect.origin.y++;
  NSRectFill (rect);

  [[NSColor highlightColor] set];

  rect.origin.x = NSMaxX (cellFrame) - 1;  
  rect.size.width = 1;
  rect.origin.y--;
  NSRectFill (rect);

  rect.origin.y--;
  NSRectFill (rect);

  rect.origin.x = NSMinX (cellFrame) + 1;
  rect.size.width = NSWidth (cellFrame) - 2;
  rect.origin.y--;
  NSRectFill (rect);
}

- (BOOL) isOpaque
{
  return NO;
}

- (float) knobThickness
{
  NSSize size;

  size = [[knobCell image] size];

  return size.height;
}

@end
