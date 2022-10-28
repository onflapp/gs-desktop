/* CynthiuneFadingTextField.h - this file is part of Cynthiune
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

#ifndef CYNTHIUNEFADINGTEXTFIELD_H
#define CYNTHIUNEFADINGTEXTFIELD_H

#import <AppKit/NSTextField.h>

#if defined(__APPLE__) && (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
#ifndef CGFloat
#define CGFloat float
#endif
#endif


@class NSFont;
@class NSString;
@class NSTimer;

@interface CynthiuneFadingTextField : NSTextField
{
  NSTextField *fadeoutClone;

  NSTimer *fadingTimer;
  NSTimeInterval interval;
  unsigned int numberOfIterations;
  unsigned int iteration;

  CGFloat red;
  CGFloat green;
  CGFloat blue;
  CGFloat alpha;
}

- (void) setStringValue: (NSString *) string;
- (void) setFont: (NSFont *) font;
- (void) setAlignment: (NSTextAlignment) mode;

- (void) setTextColor: (NSColor *) color;
- (NSColor *) textColor;

- (void) setInterval: (NSTimeInterval) timeInterval;
- (void) setNumberOfIterations: (unsigned int) integer;
- (NSTimeInterval) interval;
- (unsigned int) numberOfIterations;

- (void) setTextColorWithFactor: (float) factor;

@end

#endif /* CYNTHIUNEFADINGTEXTFIELD_H */
