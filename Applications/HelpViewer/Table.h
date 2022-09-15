/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003 Nicolas Roard (nicolas@roard.com)

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "GNUstep.h"

@interface Table : NSTextAttachmentCell
{
    NSMutableArray* table;
    float _width;
}
- (BOOL) addCell: (NSString*) text withSize: (float) size 
    withRowspan: (int) rowspan 
    withColspan: (int) colspan atRow: (int) row ;
- (void) setWidth: (float) width;
- (int) numberOfCols;
- (void) addRow;
- (void) drawInteriorWithFrame: (NSRect) cellFrame;
@end

@interface TableCell: NSCell
{
    float sizePixel;
    float sizePercent;
    BOOL sizeIsPixel;
    int colspan, rowspan;
    int x,y;
}
- (void) setX: (int) x;
- (void) setY: (int) y;
- (int) x;
- (int) y;
- (int) colspan;
- (int) rowspan;
- (void) setColspan: (int) col;
- (void) setRowspan: (int) row;
- (void) setSize: (float) percent;
- (float) sizePercent;
@end

