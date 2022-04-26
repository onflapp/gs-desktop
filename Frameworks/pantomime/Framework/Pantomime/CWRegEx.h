/*
**  CWRegEx.h
**
**  Copyright (c) 2001-2004 Ludovic Marcotte, Francis Lachapelle
**
**  Author: Francis Lachapelle <francis@Sophos.ca>
**          Ludovic Marcotte <ludovic@Sophos.ca>
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

#ifndef _Pantomime_H_CWRegEx
#define _Pantomime_H_CWRegEx

#include <sys/types.h>
#include <regex.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/*!
  @class CWRegEx
  @abstract Provides a simple object-oriented wrapper around POSIX regex.
  @discussion This class provides a simple and efficient interface around
              POSIX regex, which are available on most UNIX (or like) systems.
*/
@interface CWRegEx : NSObject
{
  @private
    regex_t _re;
}

/*!
  @method initWithPattern:
  @discussion This method invokes initWithPattern: flags: with
              the default REG_EXTENDED flag.
  @param thePattern The regular expression to use.
  @result An instance of CWRegEx, nil in case of an error.
*/
- (id) initWithPattern: (NSString *) thePattern;

/*!
  @method initWithPattern: flags:
  @discussion This method is used to initialize a CWRegEx instance
              using the specified pattern and flags.
  @param thePattern The regular expression to use.
  @param theFlags The flags to use. See regcomp(3) for a description
                  of the available flags.
  @result An instance of CWRegEx, nil in case of an error.
*/
- (id) initWithPattern: (NSString *) thePattern
                 flags: (int) theFlags;

/*!
  @method regexWithPattern:
  @discussion Invokes initWithPattern: with <i>thePattern</i> and
              autoreleases the returned instance.
*/
+ (id) regexWithPattern: (NSString *) thePattern;

/*!
  @method regexWithPattern: flags:
  @discussion Invokes initWithPattern: flags: with <i>thePattern</i> and
              <i>theFlags</i>, then autoreleases the returned instance.
*/
+ (id) regexWithPattern: (NSString *) thePattern
                  flags: (int) theFlags;

/*!
  @method matchString:
  @discussion This method is used to try to match <i>theString</i>
              using the instance's pattern.
  @param theString The string to match.
  @result An array of matches (NSString instances), which can be empty but not nil.
*/
- (NSArray *) matchString: (NSString *) theString;

/*!
  @method matchString: withPattern: isCaseSensitive:
  @discussion This method provides an easy way to quickly
              match a string with the specified pattern, in a
	      case-sensitive manner or not.
  @param theString The string to match.
  @param thePattern The regular expression to use.
  @param theBOOL Case-sensitive, or not.
  @result An array of matches (NSString instances), which can be empty but not nil.
*/
+ (NSArray *) matchString: (NSString *) theString
              withPattern: (NSString *) thePattern
          isCaseSensitive: (BOOL) theBOOL;

@end

#endif // _Pantomime_H_CWRegEx
