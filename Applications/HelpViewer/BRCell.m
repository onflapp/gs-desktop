/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003 Nicolas Roard (nicolas@roard.com)
                  2020 Riccardo Mottola <rm@gnu.org>

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

#include "BRCell.h"

@implementation BRCell

+(BRCell *) sharedBRCell
{
static BRCell *brCell;
    if (!brCell)
	brCell = [[self alloc] init];
    return brCell;
}

- (void) drawWithFrame: (NSRect) cellFrame
    inView: (NSView*) controlView
{
      if (![controlView window])
	            return;

//      int space = 8;

      [[NSColor colorWithCalibratedRed: 0.37 green: 0.44 blue: 0.73 alpha: 1.0] set];
//      NSRectFill (NSMakeRect (cellFrame.origin.x + space, cellFrame.origin.y, 
//		  cellFrame.size.width - 2*space, cellFrame.size.height));
      NSRectFill (cellFrame);
}

-(NSRect) cellFrameForTextContainer: (NSTextContainer *)c
    proposedLineFragment: (NSRect)lf
    glyphPosition: (NSPoint)p
    characterIndex: (NSUInteger)ci
{
    NSNumber *width,*height;
    CGFloat w,h;
    
    width=[[[c layoutManager] textStorage] attribute: @"BRCellWidth"
	atIndex: ci
	effectiveRange: NULL];
    height=[[[c layoutManager] textStorage] attribute: @"BRCellHeight"
	atIndex: ci
	effectiveRange: NULL];

    if (width)
        w=[width floatValue];
    else
	w=lf.size.width;
    if (height)
        h=[height floatValue];
    else
	h=1.0;
    return NSMakeRect(0,0,w,h);
}

@end
