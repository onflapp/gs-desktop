/* CynthiuneHeaderCell.m - this file is part of Cynthiune
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

#import <math.h>

#import <AppKit/NSBezierPath.h>
#import <AppKit/NSColor.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSString.h>

#import "CynthiuneHeaderCell.h"

@implementation CynthiuneHeaderCell : NSTableHeaderCell

- (id) init
{
  if ((self = [super init]))
    {
      comparisonResult = NSOrderedSame;
    }

  return self;
}

static inline NSPoint
RelativePoint (NSPoint point, NSPoint refPoint)
{
  return NSMakePoint (refPoint.x + point.x, refPoint.y + point.y);
}

- (void) _drawArrowOfSize: (NSSize) arrowSize
                  flipped: (BOOL) flipped
         atReferencePoint: (NSPoint) refPoint
{
  NSBezierPath *bezier;
  float pointA, pointB;

  bezier = [NSBezierPath bezierPath];
  [bezier setLineWidth: 0.0];
  [[self textColor] set];
  if ((!flipped && comparisonResult == NSOrderedAscending)
      || (flipped && comparisonResult == NSOrderedDescending)) {
    pointA = arrowSize.height;
    pointB = 0.0;
  } else {
    pointA = 0.0;
    pointB = arrowSize.height;
  }
  [bezier moveToPoint: RelativePoint (NSMakePoint(0, pointA), refPoint)];
  [bezier lineToPoint: RelativePoint (NSMakePoint(arrowSize.width / 2, pointB), refPoint)];
  [bezier lineToPoint: RelativePoint (NSMakePoint(arrowSize.width, pointA), refPoint)];
  [bezier lineToPoint: RelativePoint (NSMakePoint(0, pointA), refPoint)];
  [bezier closePath];
  [bezier fill];
}

- (void) drawInteriorWithFrame: (NSRect) cellFrame
                        inView: (NSView *) controlView
{
  NSRect arrowFrame, remainingFrame;
  NSPoint refPoint;
  float arrowHeight, arrowWidth;

  [super drawInteriorWithFrame: cellFrame
         inView: controlView];

  arrowHeight = cellFrame.size.height / 3.0;
  arrowWidth = ceil (arrowHeight * 1.3);

  if (comparisonResult != NSOrderedSame)
    {
      NSDivideRect (cellFrame, &arrowFrame, &remainingFrame,
                    arrowWidth + arrowOffset, NSMaxXEdge);
      refPoint = RelativePoint (NSMakePoint (0, (cellFrame.size.height
                                                 - arrowHeight) / 2),
                                arrowFrame.origin);
      [self _drawArrowOfSize: NSMakeSize (arrowWidth, arrowHeight)
            flipped: [controlView isFlipped]
            atReferencePoint: refPoint];
    }
}

- (void) setComparisonResult: (NSComparisonResult) result
{
  comparisonResult = result;
}

- (NSSize) cellSize
{
  NSSize size;

  size = [super cellSize];
  size.width += ceil ((size.height * 1.3) / 3.0) + arrowOffset;

  return size;
}

- (float) widthOfText: (NSString *) text
{
  NSSize size;

  size = [self cellSize];

  return ([self widthOfText: text]
          + ceil ((size.height * 1.3) / 3.0)
          + arrowOffset );
}

@end
