/* CynthiuneTextCell.m - this file is part of Cynthiune
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

#import <Foundation/NSString.h>

#import <Cynthiune/utils.h>

#import "CynthiuneTextCell.h"

@implementation CynthiuneTextCell : NSTextFieldCell

- (id) init
{
  if ((self = [super init]))
    {
      highlightColor = nil;
    }

  return self;
}

- (void) dealloc
{
  if (highlightColor)
    [highlightColor release];
  [super dealloc];
}

- (void) setHighlightColor: (NSColor *) color
{
  SET (highlightColor, color);
}

- (NSColor *) highlightColor
{
  return highlightColor;
}

- (NSColor*) highlightColorWithFrame: (NSRect) cellFrame
                              inView: (NSView *) controlView
{
  return highlightColor;
}

#ifdef GNUSTEP
/* GNUSTEP is buggy so we work around */
- (void) drawWithFrame: (NSRect) cellFrame 
		inView: (NSView *) controlView
{
  BOOL drawsBackground, isHighlighted;

  drawsBackground = [self drawsBackground];
  isHighlighted = [self isHighlighted];

  if (isHighlighted)
    {
      if (drawsBackground)
        {
          [[self backgroundColor] set];
          NSRectFill (cellFrame);
          [self setDrawsBackground: NO];
        }
      [[self highlightColor] set];
      NSRectFill (cellFrame);
    }

  [super drawWithFrame: cellFrame inView: controlView];

  if (drawsBackground && isHighlighted)
    [self setDrawsBackground: YES];
}
#endif

/* NSCopying protocol */
- (id) copyWithZone: (NSZone *) theZone 
{
  CynthiuneTextCell *newTextCell;

  newTextCell = [[CynthiuneTextCell allocWithZone: theZone] init];
  [newTextCell setHighlightColor: highlightColor];

  return newTextCell;
}

/* NSCoding protocol */
- (void) encodeWithCoder: (NSCoder *) encoder
{
  [super encodeWithCoder: encoder];
  [encoder encodeObject: highlightColor forKey: @"highlightColor"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  if ((self = [super initWithCoder: decoder]))
    {
      if (highlightColor)
        [highlightColor release];
      highlightColor = [decoder decodeObjectForKey: @"highlightColor"];
      if (highlightColor)
        [highlightColor retain];
    }

  return self;
}

@end
