/* NSViewExtensions.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
 *               2012 The Free Software Foundation
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
 *         Riccardo Mottola <rm@gnu.org>
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

#import <Foundation/NSString.h>

#import "NSViewExtensions.h"

#define interviewSpacing 5.0

@implementation NSView (CynthiuneExtension)

- (void) arrangeViewRightTo: (NSView *) view
{
  NSRect selfFrame, viewFrame;

  selfFrame = [self frame];
  viewFrame = [view frame];

  selfFrame.origin.x = NSMaxX (viewFrame) + interviewSpacing;

  [self setFrame: selfFrame];
  [self setNeedsDisplay: YES];
}

- (void) arrangeViewLeftTo: (NSView *) view
{
  NSRect selfFrame, viewFrame;

  selfFrame = [self frame];
  viewFrame = [view frame];

  selfFrame.origin.x = (NSMinX (viewFrame) - interviewSpacing
                        - NSWidth (selfFrame));

  [self setFrame: selfFrame];
  [self setNeedsDisplay: YES];
}

- (void) centerViewHorizontally
{
  NSView *superView;
  NSRect superFrame, selfFrame;
  NSPoint newOrigin;

  superView = [self superview];
  if (superView)
    {
      NSRect tempRect;

      superFrame = [superView frame];
      selfFrame = [self frame];
      newOrigin = selfFrame.origin;
      newOrigin.x = (NSWidth (superFrame) - NSWidth (selfFrame)) / 2.0;
      tempRect = NSMakeRect(newOrigin.x, newOrigin.y, selfFrame.size.width, selfFrame.size.height);
      tempRect = [superView centerScanRect: tempRect];
      newOrigin.x = tempRect.origin.x;
      newOrigin.y = tempRect.origin.y;
      [self setFrameOrigin: newOrigin];
    }
  else
    NSLog (@"NSView '%@' has no superview", self);
}

@end
