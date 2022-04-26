/*
**  NSScanner+Extensions.m
**
**  Copyright (c) 2005 Ludovic Marcotte
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Pantomime/NSScanner+Extensions.h>

#import <Foundation/NSString.h>

#include <ctype.h>

//
//
//
@implementation NSScanner (PantomimeScannerExtensions)

- (BOOL) scanUnsignedInt: (unsigned int *) theValue
{
  NSString *s;
  unsigned int d, v, l1, l2, len;

  l1 = l2 = [self scanLocation];
  s = [self string];
  len = [s length];

  while (l1 < len)
    {
      if (isdigit([s characterAtIndex: l1]))
	{
	  l2 = l1;
	  while (l2 < len && isdigit([s characterAtIndex: l2]))
	    {
	      l2++;
	    }
	  break;
	}
      l1++;
    }

  if (l2 <= l1)
    {
      [self setScanLocation: l1+1];
      return NO;
    }

  [self setScanLocation: (l2+1 > len ? len : l2+1)];

  v = 0;
  d = 1;
  l2--;

  while (l2 >= l1)
    {
      v += (([s characterAtIndex: l2]-48)*d);
      d *= 10;
      l2--;
    }

  *theValue = v;

  return YES;
}

@end
