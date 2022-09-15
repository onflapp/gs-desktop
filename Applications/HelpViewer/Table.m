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

#import "Table.h"

@implementation Table
- (id) init 
{
    if (self = [super init])
    {
	table = [[NSMutableArray alloc] init];
    }
    return self;
}
- (BOOL) addCell: (NSString*) text withSize: (float) size withRowspan: (int) rowspan 
    withColspan: (int) colspan atRow: (int) row 
{
    BOOL res = NO;
    printf ("addCell with size : %.2f\n", size);
    if (row < [table count])
    {
	TableCell* cell = [[TableCell alloc] initTextCell: text];
	[cell setBordered: YES];
	[cell setSize: size];
	[cell setRowspan: rowspan];
	[cell setColspan: colspan];
	printf ("rowspan : %d\n", [cell rowspan]);
	printf ("sizePercent : %.2f\n", [cell sizePercent]);
	[[table objectAtIndex: row] addObject: cell];
	res = YES;
    }
    return res;
}

- (void) addRow
{
    [table addObject: [NSMutableArray array]];
}

- (float) height
{
    return [table count] * 16;
}

- (void) setWidth: (float) width
{
    _width = width - 10;
}

- (NSSize) cellSize
{
    int width, height;

    if ((table != nil) && ([table count] > 0))
	height = 16 * [table count] + 3;
    else height = 16 + 3;
    
    if (_width <= 0) width = 300;
    else width = _width + 10;
    
    return NSMakeSize (width,height);
}

- (void) moveCellsFrom: (int) pos ofRow: (int) irow of: (int) nb
{
    int i;
    NSArray* row = [table objectAtIndex: irow];
    printf ("moveCellsFrom: %d ofRow: %d\n", pos, irow);
    for (i=0; i < [row count]; i++)
    {
	TableCell* cell = [row objectAtIndex: i];
	if ([cell x] >= pos) 
	{
	    printf ("[%d] (%d)=><%d>\n", irow, [cell x], [cell x] + nb);
	    [cell setX: [cell x] + nb];
	}
    }
}

- (int) numberOfCols
{
    int i, j, k;
    int ret = 0;

    for (i = 0; i < [table count]; i++)
    {
	NSArray* row = [table objectAtIndex: i];
	for (j = 0; j < [row count]; j++)
	{
	    TableCell* cell = [row objectAtIndex: j];
	    [cell setX: j];
	}
    }

    for (i = 0; i < [table count]; i++)
    {
	NSArray* row = [table objectAtIndex: i];
	
	for (j = 0; j < [row count]; j++)
	{
	    TableCell* cell = [row objectAtIndex: j];
	    if ([cell colspan] > 1)
	    {
		if (j+1 < [row count])  
		    [self moveCellsFrom: [cell x] +1 ofRow: i of: [cell colspan] - 1];
	    }
	    if ([cell rowspan] > 1)
	    {
		for (k = 1; k < [cell rowspan]; k++)
		{
		    if (i+k < [table count]) 
		    {
			// On doit décaler toutes les cellules de la 
			// ligne du dessous à partir de cette position
			[self moveCellsFrom: [cell x] ofRow: i+k of: [cell colspan]];
		    }
		}
	    }
	}
    }
    for (i = 0; i < [table count]; i++)
    {
	NSArray* row = [table objectAtIndex: i];
	for (j = 0; j < [row count]; j++)
	{
	    TableCell* cell = [row objectAtIndex: j];
	    if([cell x] > ret) ret = [cell x];
	}
    }
    ret++; // (vu qu'on commence à l'index 0)
    printf ("ret final : %d\n", ret);
    return ret;
}

- (void) drawInteriorWithFrame: (NSRect) cellFrame
    inView: (NSView*) controllView
{
    int i,j;
    float width = cellFrame.size.width -3;
    int cols = [self numberOfCols];

    printf ("cellFrame : x <%.2f> y <%.2f> w <%.2f> h <%.2f>\n", cellFrame.origin.x,
	    cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    printf ("table count : %d \n", [table count]);
    
    
    for (i = 0; i < [table count]; i++)
    {
	NSArray* row = [table objectAtIndex: i];
	printf ("row count : %d \n", [row count]);
	for (j = 0; j < [row count]; j++)
	{
	    NSRect rect;
	    TableCell* cell = [row objectAtIndex: j];
	    float widthCell = width / cols;
	    rect = NSMakeRect (cellFrame.origin.x + 2 + widthCell*[cell x], 
			cellFrame.origin.y + 2 + i*16, widthCell*[cell colspan] - 1, 16*[cell rowspan] - 1);
	    [cell drawWithFrame: rect inView: controllView];
	    printf ("[%d]==>(%d)\n", i, [cell x]);
	}
    }
}
@end

@implementation TableCell

- (void) setX: (int) px { x = px; }
- (void) setY: (int) py { y = py; }
- (int) x { return x; }
- (int) y { return y; }
- (int) colspan { return colspan; }
- (int) rowspan { return rowspan; }
- (void) setColspan: (int) col { colspan = col; }
- (void) setRowspan: (int) row { rowspan = row; }

- (void) setSize: (float) percent
{
    sizeIsPixel = NO;
    sizePercent = percent;
}

- (float) sizePercent
{
    return sizePercent;
}

@end
