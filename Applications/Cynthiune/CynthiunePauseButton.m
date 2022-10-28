/* CynthiunePauseButton.m - this file is part of Cynthiune
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

#import <AppKit/NSImage.h>

#import <Cynthiune/NSTimerExtensions.h>
#import <Cynthiune/utils.h>

#import "CynthiunePauseButton.h"

@implementation CynthiunePauseButton : NSButton

- (id) init
{
  self = [super init];
  if (self)
    {
      animationTimer = nil;
      primaryImage = nil;
      secondaryImage = nil;
      animate = NO;
      animationStatus = NO;
    }

  return self;
}

- (void) dealloc
{
  if (primaryImage)
    [primaryImage release];
  if (secondaryImage)
    [primaryImage release];
  [super dealloc];
}

- (void) _animate
{
  if (animationStatus)
    {
      [super setImage: primaryImage];
      animationStatus = NO;
    }
  else
    {
      [super setImage: secondaryImage];
      animationStatus = YES;
    }
}

- (void) _startAnimation
{
  [super setImage: secondaryImage];
  animationStatus = YES;
  animationTimer = [NSTimer scheduledTimerWithTimeInterval: 0.65
                                 target: self
                                 selector: @selector (_animate)
                                 userInfo: nil
                                 repeats: YES];
  [animationTimer explode];
}

- (void) _stopAnimation
{
  [animationTimer invalidate];
  animationTimer = nil;
  [super setImage: primaryImage];
}

- (void) setImage: (NSImage *) image
{
  [super setImage: image];
  SET (primaryImage, image);
}

- (void) setAlternateImage: (NSImage *) image
{
  SET (secondaryImage, image);
}

- (void) setState: (NSInteger) state
{
  if ([self isEnabled])
    {
      if (state)
        {
          if (!animate)
            {
              [self _startAnimation];
              animate = YES;
            }
        }
      else
        {
          if (animate)
            {
              [self _stopAnimation];
              animate = NO;
            }
        }
    }
  [super setState: state];
}

@end
