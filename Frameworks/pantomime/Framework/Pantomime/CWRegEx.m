/*
**  CWRegEx.m
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

#include <Pantomime/CWRegEx.h>

#include <Pantomime/CWConstants.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSValue.h>

#include <stdlib.h>


//
//
//
@implementation CWRegEx 

- (id) init
{
  return [self initWithPattern: @""];
}


//
//
//
- (id) initWithPattern: (NSString *) thePattern
{
  return [self initWithPattern: thePattern  flags: REG_EXTENDED];
}


//
//
//
- (id) initWithPattern: (NSString *) thePattern
		 flags: (int) theFlags
{
  int status;
  char *error;
  
  if ((self = [super init]))
    {
      status = regcomp(&_re, [thePattern cString], theFlags);
      if (status != 0)
        {
	  error = malloc(255*sizeof(char));
	  regerror(status, &_re, error, 255);
	  free(error);
	  
	  AUTORELEASE(self);
	  self = nil;
        }
    }

  return self;
}


//
//
//
+ (id) regexWithPattern: (NSString *) thePattern
{
  return AUTORELEASE([[self alloc] initWithPattern: thePattern]);
}


//
//
//
+ (id) regexWithPattern: (NSString *) thePattern
		  flags: (int) theFlags
{
  return AUTORELEASE([[self alloc] initWithPattern: thePattern  flags: theFlags]);
}


//
//
//
- (void)dealloc
{
  regfree(&_re);
  [super dealloc];
}


//
//
//
- (NSArray *) matchString: (NSString *) theString
{
  NSMutableArray *aMutableArray;
    
  int offset, status;
  char *s, *error;
  regmatch_t rm[1];
  
  s = (char*)[theString lossyCString];
  aMutableArray = [[NSMutableArray alloc] init];
  
  status = regexec(&_re, s, 1, rm, 0);
  offset = 0;
  
  while (status == 0)
    {
      NSValue *aValue;
      
      aValue = [NSValue valueWithRange: NSMakeRange(offset + rm[0].rm_so,  rm[0].rm_eo - rm[0].rm_so)];
      
      [aMutableArray addObject: aValue];
      
      offset += rm[0].rm_eo;
      
      if (rm[0].rm_eo - rm[0].rm_so == 0)
        {
	  status = 1;
        }
      else
        {
	  status = regexec(&_re, s + offset, 1, rm, REG_NOTBOL);
        }
    }
  
  if (status != REG_NOMATCH)
    {
      error = malloc(255*sizeof(char));
      regerror(status, &_re, error, 255);
      free(error);
    }
  
  return AUTORELEASE(aMutableArray);
}


//
//
//
+ (NSArray *) matchString: (NSString *) theString
	      withPattern: (NSString *) thePattern
	  isCaseSensitive: (BOOL) theBOOL
{
  int flags;
  CWRegEx *regex;
  NSArray *result;
  
  flags = REG_EXTENDED;
  
  if (!theBOOL)
    {
      flags |= REG_ICASE;
    }
  
  if ((regex = [CWRegEx regexWithPattern: thePattern  flags: flags]) == nil)
    {
      result = [NSArray array];
    }
  else
    {
      result = [regex matchString: theString];
    }
  
  return result;
}

@end
