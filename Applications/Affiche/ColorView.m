/*
**  ColorView.m
**
**  Copyright (c) 2001
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import "ColorView.h"

#import "Constants.h"

@implementation ColorView

- (id) init
{
  self = [super init];

  [self setColor: [NSColor colorWithDeviceRed: 0.44
			   green: 1.0
			   blue: 1.0
			   alpha: 1.0]];

  return self;
}

- (void) dealloc
{
  RELEASE(color);

  [super dealloc];
}


- (void) drawRect: (NSRect) theRect
{
  [[self color] set];

  NSRectFill( theRect );
}

//
// access/mutation methods
//

- (NSColor *) color
{
  return color;
}

- (void) setColor: (NSColor *) theColor
{
  RETAIN(theColor);
  RELEASE(color);
  color = theColor;
}


//
// static methods
//

+ (id) colorView
{
  return AUTORELEASE( [[ColorView alloc] init] );
}

@end
