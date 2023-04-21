/*
   Project: ImageViewer

   Copyright (C) 2023 Free Software Foundation

   Author: Parallels

   Created: 2023-04-21 19:57:22 +0200 by parallels

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "ImageView.h"

@implementation ImageView

- (void) awakeFromNib {
   displayScale = 1;
}

- (NSRect) selectedRectangle {
   CGFloat x1 = dragRect.origin.x;
   CGFloat y1 = dragRect.origin.y;
   CGFloat x2 = dragRect.origin.x + dragRect.size.width;
   CGFloat y2 = dragRect.origin.y + dragRect.size.height;

   NSLog(@"xxx %f %f %f %f", x1, y1, x2, y2);

   if (x1 > x2) { CGFloat t = x1; x1 = x2; x2 = t; }
   if (y1 > y2) { CGFloat t = y1; y1 = y2; y2 = t; }

   NSLog(@"xxx %f %f %f %f", x1, y1, x2, y2);
   NSRect sr = NSMakeRect(x1, y1, x2-x1, y2-y1);

   return sr;
}

- (void) resetSelectionRectangle {
   dragRect.size.width = 0;
   dragRect.size.height = 0;
}

- (void) mouseDown:(NSEvent*) evt {
  [[self window] makeFirstResponder:self];
   if (displayScale != 1) return;

   NSPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];

   dragRect.size.width = 0;
   dragRect.size.height = 0;
   dragRect.origin.x = p.x;
   dragRect.origin.y = p.y;

   //[self setFrame:r];
   [self setNeedsDisplay:YES];
}

- (void) mouseDragged:(NSEvent*) evt {
   if (displayScale != 1) return;

   NSPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
   dragRect.size.width = p.x - dragRect.origin.x;
   dragRect.size.height = p.y - dragRect.origin.y;
   [self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect) aRect {
   [super drawRect:aRect];

   if (dragRect.size.height == 0 || dragRect.size.height == 0) return;

   [[NSGraphicsContext currentContext] saveGraphicsState];

   NSRect r = [self frame];
   CGFloat x1 = dragRect.origin.x;
   CGFloat y1 = dragRect.origin.y;
   CGFloat x2 = dragRect.origin.x + dragRect.size.width;
   CGFloat y2 = dragRect.origin.y + dragRect.size.height;

   //NSLog(@"DOWN >>> %f %f %f %f", x1, y1, x2, y2);

   if (x1 < 1) x1 = 0;
   if (y1 < 1) y1 = 0;
   if (x2 > r.size.width) x2 = r.size.width-1;
   if (y2 > r.size.height) y2 = r.size.height-1;
   if (x2 < 1) x2 = 0;
   if (y2 < 1) y2 = 0;

   NSInteger l = 1;
   if (displayScale > 1) l = l * displayScale;

   NSBezierPath *line = [NSBezierPath bezierPath];
   [line setLineCapStyle:NSLineCapStyleSquare];
   [line moveToPoint:NSMakePoint(x1, y1)];
   [line lineToPoint:NSMakePoint(x2, y1)];
   [line lineToPoint:NSMakePoint(x2, y2)];
   [line lineToPoint:NSMakePoint(x1, y2)];
   [line lineToPoint:NSMakePoint(x1, y1)];
   [line setLineWidth:l];
   [[NSColor redColor] set];
   [line stroke];

   [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void) zoomToScale:(CGFloat) scale {
   [self resetSelectionRectangle];

   NSRect r = [self frame];
   r.size.height = [self image].size.height * scale;
   r.size.width = [self image].size.width * scale;
   
   [self setFrame:r];
   [self setNeedsDisplay:YES];
}

- (IBAction) zoomIn:(id) sender {
   displayScale = displayScale * 2;
   if (displayScale > 8) displayScale = 8;
   [self zoomToScale:displayScale];
}

- (IBAction) zoomReset:(id) sender {
   displayScale = 1;
   [self zoomToScale:displayScale];
}

- (IBAction) zoomOut:(id) sender {
   displayScale = displayScale / 2;
   if (displayScale < 0.25) displayScale = 0.25;
   [self zoomToScale:displayScale];
}
@end
