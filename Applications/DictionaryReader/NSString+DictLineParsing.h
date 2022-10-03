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

#import <Foundation/Foundation.h>

@interface NSString (DictLineParsing)

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
-(NSArray*) parseDictLine;

/**
 * Splits the string into its dict-style components (see documentation
 * for @see(parseDictLine) for more information) and returns the
 * component with the index given in the index argument.
 */
-(NSString*) dictLineComponent: (int)index;

@end

