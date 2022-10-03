/* -*-objc-*-
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

#import "NSString+DictLineParsing.h"

@implementation NSString (DictLineParsing)

/**
 * Splits a Dict-protocol-style string into its components and returns
 * an array with those components. A string like this consists of one
 * or more strings that are separated by a whitespace. A string that
 * contains whitespaces itself can be put into quotation marks.
 *
 * Example:
 * The string
 *     '151 "Awful" gcide "The Collaborative International Dict..."'
 *
 * would decode to:
 *     ['151', 'Awful', 'gcide', 'The Collaborative Internation...']
 */
-(NSArray*) parseDictLine
{
  NSScanner* scanner = [NSScanner scannerWithString: self];
  
  NSCharacterSet* space =
    [NSCharacterSet characterSetWithCharactersInString: @" "];
  
  NSCharacterSet* quotationMarks =
    [NSCharacterSet characterSetWithCharactersInString: @"\""];
  
  NSMutableArray* result = [NSMutableArray arrayWithCapacity: 4];
  
  while ([scanner isAtEnd] == NO) {
    // Location: At the beginning of a word, possible quotation
    //           marks not yet eaten.
    
    BOOL isQuoted = [scanner scanCharactersFromSet: quotationMarks
			     intoString: (NSString**) nil];
    
    if (isQuoted) {
      // Location: At the beginning of a word, right after the quotation
      //           mark. (FIXME: This is assuming there is no empty string!)
      
      NSString* word;
      
      [scanner scanUpToCharactersFromSet: quotationMarks
	       intoString: &word];
      
      [result addObject: [word retain]];
      
      // Location: At the end of a word, with the pointer pointing to
      //           the closing quotation marks
      
      // eat closing quotation marks
      [scanner scanCharactersFromSet: quotationMarks
	       intoString: (NSString**) nil];
      
      // Location: At the end of a word, after the quotation mark
    } else {
      // Case 2: The word is not quoted, parse to the next whitespace!
      
      // Location: At the beginning of a word without quotation marks
      NSString* word;
      
      [scanner scanUpToCharactersFromSet: space intoString: &word];
      
      [result addObject: [word retain]];
      // Location: At the end of a non-quoted word.
    }
    
    // Location: At the end of a word, we still need to eat some white
    //           spaces to reach the next word.
    [scanner scanCharactersFromSet: space
	     intoString: (NSString**) nil];
    
  } //end of while loop
  
  return result;
}

-(NSString*) dictLineComponent: (int)index
{
  NSArray* array = [self parseDictLine];
  
  if (array == nil)
    return nil;
  
  NSString* component = (NSString*) [array objectAtIndex: index];
  
  return component; // implicitely: returns nil if component was nil
}

@end
