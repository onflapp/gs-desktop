/*  -*-objc-*-
 *
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

#import "NSScanner+Base64Encoding.h"

static NSString* b64 =
 @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
 @"abcdefghijklmnopqrstuvwxyz"
 @"0123456789+/";

int indexInB64( unichar unicharacter )
{
  char character = unicharacter & 0xff;
  
  if (character >= 'A' && character <= 'Z') {
    return character-'A';
  } else if (character >= 'a' && character <= 'z') {
    return character-'a'+26;
  } else if (character >= '0' && character <= '9') {
    return character-'0'+52;
  } else if (character == '+') {
    return 62;
  } else {
    NSCAssert2(
        character == '/',
        @"Character %c (%d) is not a valid Base64 character",
        character, character
    );
    return 63;
  }
}

@implementation NSScanner (Base64Encoding)

/**
 * Scans a Base64 encoded integer.
 * @param outputInteger the location to save the result
 * @return YES if and only if scanning succeeded.
 */
-(BOOL) scanBase64Int: (int*)outputInteger
{
  static NSCharacterSet* b64chars = nil;
  int i;
  
  if (b64chars == nil) {
    b64chars = [NSCharacterSet characterSetWithCharactersInString: b64];
    [b64chars retain];
  }
  
  NSString* scanned;
  
  if ([self scanCharactersFromSet: b64chars intoString: &scanned] == NO) {
    *outputInteger = 0;
    return NO;
  }
  
  (*outputInteger) = 0;
  for (i=0; i<[scanned length]; i++)
    {
      (*outputInteger) *= 64;
      (*outputInteger) += indexInB64([scanned characterAtIndex: i]);
    }
  
  // TEST XXX: test indexInB64() correctness
  #ifdef DEBUGGING
  for (i=0;i<64;i++) {
    NSAssert3(i==indexInB64([b64 characterAtIndex: i]),
	      @"iib64('%c') == %d != %d (<-soll)",
	      [b64 characterAtIndex: i],
	      indexInB64([b64 characterAtIndex: i]),
	      i);
  }
  #endif //DEBUGGING
  
  return YES;
}

@end
