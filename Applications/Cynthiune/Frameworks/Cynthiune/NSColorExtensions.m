/* NSColorExtensions.m - this file is part of Cynthiune
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

#import "NSColorExtensions.h"

@implementation NSColor (CynthiuneExtensions)

+ (NSColor *) evenRowsBackgroundColor
{
  return [NSColor colorWithDeviceRed: 0.88
                  green: 0.88
                  blue: 1.0
                  alpha: 1.0];
}

+ (NSColor *) oddRowsBackgroundColor
{
  return [self colorWithDeviceRed: 0.98
               green: 0.98
               blue: 1.0
               alpha: 1.0];
}

+ (NSColor *) rowsHighlightColor
{
  return [NSColor colorWithDeviceRed: 0.92
                  green: 0.893
                  blue: 0.209
                  alpha: 1.00];
//   return [NSColor alternateSelectedControlColor];
}


@end
