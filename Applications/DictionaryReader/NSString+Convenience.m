/*
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "NSString+Convenience.h"

@implementation NSString (Convenience)

// Note: startsWith: method was obsolete because of the existing hasPrefix: method.

/**
 * Returns the first index in the string where the
 * character given by the aCharacter parameter can
 * be found. If there's no such character in the
 * string, a value of -1 is returned.
 */
-(int)firstIndexOf: (unichar)aCharacter
{
  return [self firstIndexOf: aCharacter
	       fromIndex: 0];
}

/**
 * Searching from startIndex, this method returns the
 * first index in the string where the character given
 * by the aCharacter parameter can be found. If there's
 * no such character in the string, a value of -1 is
 * returned.
 */
-(int)firstIndexOf: (unichar)aCharacter
	 fromIndex: (int) startIndex
{
  // -1 means 'not found' or -inside this method- 'not *yet* found'
  int result = -1;
  
  // the length of this string
  unsigned length = [self length];
  
  // the index where we are searching at the moment
  unsigned index = startIndex;
  
  while (index < length && result == -1)
    {
      if ([self characterAtIndex: index] == aCharacter) {
	result = index;
      }
      
      index++;
    }
  
  return result;
}

@end
