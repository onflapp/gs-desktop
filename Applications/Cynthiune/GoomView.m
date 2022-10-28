/* GoomView.m - this file is part of Cynthiune
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

#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphics.h>

#import <Cynthiune/NSTimerExtensions.h>

#import <math.h>
#import <goom/goom.h>

#import "GoomView.h"

#define step .01

// #define goomSizeX 320
// #define goomSizeY 200

@implementation GoomView : NSView

- (id) initWithFrame: (NSRect) frameRect
{
  static unsigned char *plane[1];

  if ((self = [super initWithFrame: frameRect]))
    {
      goom = goom_init (frameRect.size.width, frameRect.size.width);
      plane[0] = goom->outputBuf;
      bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: plane
                                         pixelsWide: NSWidth (frameRect)
                                         pixelsHigh: NSHeight (frameRect)
                                         bitsPerSample: 8
                                         samplesPerPixel: 4
                                         hasAlpha: NO
                                         isPlanar: NO
                                         colorSpaceName: NSDeviceRGBColorSpace
                                         bytesPerRow: 0
                                         bitsPerPixel: 32];
    }
 
  return self;
}

- (void) _resetTimer
{
  if (timer)
    [timer invalidate];
  timer = [NSTimer scheduledTimerWithTimeInterval: (1.0 / fps)
                   target: self
                   selector: @selector (display)
                   userInfo: nil
                   repeats: YES];
  [timer explode];
}

- (void) setFPS: (unsigned int) newFPS
{
  fps = newFPS;
  [self _resetTimer];
}

// - (void) awakeFromNib
// {
//   [self setFPS: 10];

//   bitmap = nil;
// }

- (void) drawRect: (NSRect)rect
{
  [bitmap draw];
}

- (PluginInfo *) goom
{
  return goom;
}

@end
