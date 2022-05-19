/*
**  LabelWidget.m
**
**  Copyright (c) 2002
** 
**  Author: Jonathan B. Leffert <jonathan@leffert.net>
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

#import "LabelWidget.h"

#import "Constants.h"

@implementation LabelWidget

- (id) initWithFrame: (NSRect) theFrame
{
  self = [super initWithFrame: theFrame];

  [self setEditable: NO];
  [self setSelectable: NO];
  [self setBezeled: NO];
  [self setDrawsBackground: NO];

  return self;
}

- (id) initWithFrame: (NSRect) theFrame label: (NSString *) theLabel
{
  self = [self initWithFrame: theFrame];

  if ( theLabel )
    {
      [self setStringValue: theLabel];
    }
  else
    {
      [self setStringValue: @""];
    }

  return self;
}

+ (id) labelWidgetWithFrame: (NSRect) theFrame label: (NSString *) theLabel
{
  LabelWidget *lw = [[self alloc] initWithFrame: theFrame
				  label: theLabel];
  return AUTORELEASE(lw);
}

@end
