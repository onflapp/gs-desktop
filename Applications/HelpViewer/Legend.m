/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003      Nicolas Roard (nicolas@roard.com)
                  2020-2021 Riccardo Mottola <rm@gnu.org>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the
    Free Software Foundation, Inc.  
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
*/

#include "Legend.h"

@implementation Legend

+ (id) legendWithString: (NSMutableAttributedString*) str andPoint: (NSPoint) p
{
    Legend* ret = [[Legend alloc] initWithString: str andPoint: p];
    return AUTORELEASE (ret);
}

- (id) initWithString: (NSMutableAttributedString*) str andPoint: (NSPoint) p
{
  if ((self = [super init]))
    {
      ASSIGN (legend, str);
      point = p;
      rightPos = NO;
    }
  return self;
}

- (void) dealloc 
{
  RELEASE (legend);
  [super dealloc];
}

- (NSComparisonResult) compareWith: (id)sender
{
  NSComparisonResult ret = NSOrderedAscending;
  NSPoint otherPoint;
  
  if (![sender isKindOfClass:[Legend class]])
    return NSOrderedSame; // in case we cannot tell

  otherPoint = [(Legend*)sender point];
  
  if (point.y == otherPoint.y)
    {
      if ((rightPos && (point.x < otherPoint.x)) ||  
	  (point.x > otherPoint.x))
	{
	    ret = NSOrderedDescending;
	}  
    }
  else if (point.y > otherPoint.y)
    ret = NSOrderedDescending;
  return ret;
}

- (NSMutableAttributedString*) legend { return legend; }
- (NSPoint) point { return point; }
- (void) setPoint: (NSPoint) p { point = p; }
- (CGFloat) height { return height; }
- (void) setHeight: (CGFloat) h { height = h; }
- (void) setRightPos { rightPos = YES; }
- (BOOL) isRightPos { return rightPos; }
@end

