/* CynthiuneAnimatedImageView.m - this file is part of Cynthiune
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

#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#import <Cynthiune/NSTimerExtensions.h>
#import <Cynthiune/utils.h>

#import "CynthiuneAnimatedImageView.h"

@implementation CynthiuneAnimatedImageView : NSImageView

- (id) init
{
  if ((self = [super init]))
    {
      frames = [NSMutableArray new];
      frameNumber = -1;
      animationTimer = nil;
      interval = .075;
    }

  return self;
}

- (void) dealloc
{
  if (animationTimer)
    [animationTimer release];
  [frames release];
  [super dealloc];
}

- (void) addFramesFromImagenames: (NSString *) firstImagename, ...
{
  va_list ap;
  NSString *imagename;
  NSImage *image;

  va_start (ap, firstImagename);
  imagename = firstImagename;
  while (imagename)
    {
      image = [NSImage imageNamed: imagename];
      if (image)
        [frames addObject: image];
      else
        NSLog (@"no such image: '%@'", imagename);
      imagename = va_arg (ap, NSString *);
    }

  va_end (ap);
}

- (void) setInterval: (NSTimeInterval) newInterval
{
  interval = newInterval;
}

- (void) _iteration
{
  frameNumber++;

  if (frameNumber == [frames count])
    frameNumber = 0;

  [self setImage: [frames objectAtIndex: frameNumber]];
}

- (void) startAnimation
{
  frameNumber = -1;

  if ([frames count])
    {
      animationTimer = [NSTimer scheduledTimerWithTimeInterval: interval
                                target: self
                                selector: @selector (_iteration)
                                userInfo: nil
                                repeats: YES];
      [animationTimer explode];
    }
  else
    NSLog (@"No frames in animation. Not starting.");
}

- (void) stopAnimation
{
  if (animationTimer)
    {
      [animationTimer invalidate];
      animationTimer = nil;
    }
  [self setImage: nil];
}

- (void) encodeWithCoder: (NSCoder*) aCoder
{
  [super encodeWithCoder: aCoder];
//   [aCoder encodeInt: interval forKey: @"interval"];
//   [aCoder encodeObject: frames forKey: @"frames"];
}

- (id) initWithCoder: (NSCoder*) aDecoder
{
  self = [self init];
  self = [super initWithCoder: aDecoder];

  return self;
}

@end
