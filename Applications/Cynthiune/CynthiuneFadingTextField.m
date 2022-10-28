/* CynthiuneFadingTextField.m - this file is part of Cynthiune
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

#import <Foundation/NSString.h>

#import <Cynthiune/NSTimerExtensions.h>

#import "CynthiuneFadingTextField.h"

#ifdef __MACOSX__ /* alpha channels don't work correctly on GNUstep */
#define _colorWithFactor(X)              \
        [NSColor colorWithDeviceRed: red \
                 green: green            \
                 blue: blue              \
                 alpha: (alpha * X)]
#else /* __MACOSX__ */
#define _colorWithFactor(X)                    \
        [NSColor colorWithDeviceRed: (red * X) \
                 green: (green * X)            \
                 blue: (blue * X)              \
                 alpha: (alpha * X)]
#endif /* __MACOSX__ */

@implementation CynthiuneFadingTextField : NSTextField

- (void) _setDefaults
{
  NSColor *color;

  color = [super textColor];
  [color getRed: &red green: &green blue: &blue alpha: &alpha];

  fadeoutClone = [[NSTextField alloc] initWithFrame: [self frame]];
  [fadeoutClone setCell: [[self cell] copy]];
  [fadeoutClone setStringValue: [self stringValue]];
  [fadeoutClone setBezeled: NO];
  [fadeoutClone setBordered: NO];
  [fadeoutClone setDrawsBackground: NO];
  [fadeoutClone setTextColor: color];

  iteration = 0;
  interval = 0.050;
  numberOfIterations = 16;
}

- (void) awakeFromNib
{
  [[self superview] addSubview: fadeoutClone
                    positioned: NSWindowBelow
                    relativeTo: self];
}

- (id) initWithFrame: (NSRect) frame
{
  if ((self = [super initWithFrame: frame]))
    {
      [self _setDefaults];
    }

  return self;
}

- (void) dealloc
{
  [fadeoutClone release];
  [super dealloc];
}

- (void) setTextColorWithFactor: (float) factor
{
  [super setTextColor: _colorWithFactor (factor)];
  [fadeoutClone setTextColor: _colorWithFactor (1.0 - factor)];
}

- (void) _fadingIteration
{
  float factor;

  iteration++;

  factor = (float) iteration / numberOfIterations;
  [self setTextColorWithFactor: factor];

  if (iteration == numberOfIterations)
    {
      [fadeoutClone setStringValue: @""];
      [fadingTimer invalidate];
      fadingTimer = nil;
    }
}

- (void) _createFadingTimer
{
  fadingTimer = [NSTimer timerWithTimeInterval: interval
                         target: self
                         selector: @selector (_fadingIteration)
                         userInfo: nil
                         repeats: YES];
  [fadingTimer explode];
}

- (void) setStringValue: (NSString *) string
{
  NSString *oldString;

  oldString = [self stringValue];
  if (![oldString isEqualToString: string])
    {
      iteration = 0;
      [self setTextColorWithFactor: 0.0];

      [fadeoutClone setStringValue: oldString];
      [super setStringValue: string];

      if (!fadingTimer)
        [self _createFadingTimer];
    }
}

- (void) setFont: (NSFont *) font
{
  [fadeoutClone setFont: font];
  [super setFont: font];
}

- (void) setAlignment: (NSTextAlignment) mode
{
  [fadeoutClone setAlignment: mode];
  [super setAlignment: mode];
}

- (void) setTextColor: (NSColor *) color
{
  [color getRed: &red green: &green blue: &blue alpha: &alpha];

  if (!fadingTimer)
    [self setTextColorWithFactor: 1.0];
}

- (NSColor *) textColor
{
  return _colorWithFactor (1.0);
}

- (void) setInterval: (NSTimeInterval) timeInterval
{
  interval = timeInterval;
}

- (NSTimeInterval) interval
{
  return interval;
}

- (void) setNumberOfIterations: (unsigned int) integer
{
  numberOfIterations = integer;
}

- (unsigned int) numberOfIterations
{
  return numberOfIterations;
}

- (id) initWithCoder: (NSCoder*) aDecoder
{
  self = [super initWithCoder: aDecoder];
  [super setStringValue: @""];
  [self _setDefaults];

  return self;
}

@end
