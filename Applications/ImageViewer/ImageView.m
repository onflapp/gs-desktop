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
#import "InspectorPanel.h"
#import <math.h>

NSRect flipRect(NSRect r) {
   CGFloat x1 = r.origin.x;
   CGFloat y1 = r.origin.y;
   CGFloat x2 = r.origin.x + r.size.width;
   CGFloat y2 = r.origin.y + r.size.height;

   if (x1 > x2) { CGFloat t = x1; x1 = x2; x2 = t; }
   if (y1 > y2) { CGFloat t = y1; y1 = y2; y2 = t; }

   return NSMakeRect(x1, y1, x2-x1, y2-y1);
}

@implementation ImageView

- (void) awakeFromNib {
   displayScale = 1;

   linePattern[0] = 3.0; //segment painted with stroke color
   linePattern[1] = 3.0; //segment not painted with a color

   [[self superview] setBackgroundColor:[NSColor whiteColor]];
}

- (NSRect) selectedRectangle {
   return selectionRect;
}

- (void) updateSelectionRect {
   selectionRect = flipRect(dragRect);

   if (displayScale == 1) return;

   selectionRect.origin.x = selectionRect.origin.x / displayScale;
   selectionRect.origin.y = selectionRect.origin.y / displayScale;
   selectionRect.size.width = selectionRect.size.width / displayScale;
   selectionRect.size.height = selectionRect.size.height / displayScale;
}

- (void) updateDrawRect {
   if (displayScale == 1) return;

   dragRect.origin.x = (CGFloat)round(dragRect.origin.x / displayScale) * displayScale;
   dragRect.origin.y = (CGFloat)round(dragRect.origin.y / displayScale) * displayScale;
   dragRect.size.width = (CGFloat)round(dragRect.size.width / displayScale) * displayScale;
   dragRect.size.height = (CGFloat)round(dragRect.size.height / displayScale) * displayScale;
}

- (void) resetSelectionRectangle {
   dragRect.size.width = 0;
   dragRect.size.height = 0;

   selectionRect.size.width = 0;
   selectionRect.size.height = 0;
}

- (void) setSelectionRectangle:(NSRect) r {
   [self resetSelectionRectangle];

   selectionRect = r;

   if (selectionRect.size.width > 0 && selectionRect.size.height > 0) {
      dragRect.origin.x = selectionRect.origin.x * displayScale;
      dragRect.origin.y = selectionRect.origin.y * displayScale;
      dragRect.size.width = selectionRect.size.width * displayScale;
      dragRect.size.height = selectionRect.size.height * displayScale;
   }
   
   [self setNeedsDisplay:YES];
}

- (NSImage*) croppedImage:(NSRect) r2 {
  NSImage* img = [self image];
  NSRect r1 = NSMakeRect(0, 0, img.size.width, img.size.height);
  NSImageRep* rep = [img bestRepresentationForRect:r1 context:nil hints:nil];

  NSImage* nimg = [[NSImage alloc] initWithSize:r2.size];
  [nimg lockFocus];
  [rep setSize:img.size];
  [rep drawInRect:NSMakeRect(0, 0, r2.size.width, r2.size.height) 
         fromRect:r2
        operation:NSCompositeCopy
         fraction:1.0
   respectFlipped:YES
            hints:nil];
  [nimg unlockFocus];

  return [nimg autorelease];
}

- (void) mouseDown:(NSEvent*) evt {
  [[self window] makeFirstResponder:self];

   NSPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];

   if (NSPointInRect(p, flipRect(dragRect))) {
      moveOffset.x = p.x - dragRect.origin.x;
      moveOffset.y = p.y - dragRect.origin.y;
      selectionMove = YES;
      return;
   }
   else {
      selectionMove = NO;

      dragRect.size.width = 0;
      dragRect.size.height = 0;
      dragRect.origin.x = p.x;
      dragRect.origin.y = p.y;
   }

   [self updateDrawRect];
   [self updateSelectionRect];

   [self setNeedsDisplay:YES];

   [NSObject cancelPreviousPerformRequestsWithTarget:self];
   [self performSelector:@selector(updateInspector) withObject:nil afterDelay:0.1];
}

- (void) mouseDragged:(NSEvent*) evt {
   NSPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];

   if (selectionMove) {
      dragRect.origin.x = p.x - moveOffset.x;
      dragRect.origin.y = p.y - moveOffset.y;
   }
   else {
      dragRect.size.width = p.x - dragRect.origin.x;
      dragRect.size.height = p.y - dragRect.origin.y;
   }

   [self updateDrawRect];
   [self updateSelectionRect];

   [self setNeedsDisplay:YES];

   [NSObject cancelPreviousPerformRequestsWithTarget:self];
   [self performSelector:@selector(updateInspector) withObject:nil afterDelay:0.3];
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
   //if (displayScale > 1) l = l * displayScale;

   NSBezierPath *line = [NSBezierPath bezierPath];
   [line setLineDash:linePattern count: 2 phase: 0.0];
   [line setLineCapStyle:NSLineCapStyleSquare];
   [line setLineWidth:l];
   [[NSColor redColor] set];

   [line moveToPoint:NSMakePoint(x1, y1)];
   [line lineToPoint:NSMakePoint(x2, y1)];
   [line lineToPoint:NSMakePoint(x2, y2)];
   [line lineToPoint:NSMakePoint(x1, y2)];
   [line lineToPoint:NSMakePoint(x1, y1)];
   [line stroke];

   [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void) updateInspector {
   [[InspectorPanel sharedInstance] updateSelection:[self selectedRectangle]];
}

- (void) zoomToScale:(CGFloat) scale {
   NSRect r = [self frame];
   r.size.height = [self image].size.height * scale;
   r.size.width = [self image].size.width * scale;

   if (selectionRect.size.width > 0 && selectionRect.size.height > 0) {
      dragRect.origin.x = selectionRect.origin.x * displayScale;
      dragRect.origin.y = selectionRect.origin.y * displayScale;
      dragRect.size.width = selectionRect.size.width * displayScale;
      dragRect.size.height = selectionRect.size.height * displayScale;
   }
   
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
