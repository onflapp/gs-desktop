/*
**  CWPOP3CacheObject.m
**
**  Copyright (c) 2001-2004 Ludovic Marcotte
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

#import <Pantomime/CWPOP3CacheObject.h>

#import <Pantomime/CWConstants.h>

static int currentPOP3CacheObjectVersion = 1;


//
//
//
@implementation CWPOP3CacheObject

- (id) init
{
  self = [super init];
  if (self)
    {
      [CWPOP3CacheObject setVersion: currentPOP3CacheObjectVersion];
    }
  return self;
}


//
//
//
- (id) initWithUID: (NSString *) theUID
	      date: (NSCalendarDate *) theDate
{
  self = [self init];
  if (self)
    {
      [self setUID: theUID];
      [self setDate: theDate];
    }
  
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_date);
  RELEASE(_UID);

  [super dealloc];
}


//
//
//
- (void) encodeWithCoder: (NSCoder *) theCoder
{
  [CWPOP3CacheObject setVersion: currentPOP3CacheObjectVersion];
  [theCoder encodeObject: _UID];
  [theCoder encodeObject: _date];
}


//
//
//
- (id) initWithCoder: (NSCoder *) theCoder
{
  int version;
  
  version = [theCoder versionForClassName: NSStringFromClass([self class])];

  self = [super init];

  // Initial version of the serialized POP3 cache object
  if (version == 0)
    {
      [self setUID: [theCoder decodeObject]];
      [self setDate: [NSCalendarDate calendarDate]];
    }
  else
    {
      [self setUID: [theCoder decodeObject]];
      [self setDate: [theCoder decodeObject]];
    }
  
  return self;
}


//
//
//
- (NSCalendarDate *) date
{
  return _date;
}

- (void) setDate: (NSCalendarDate *) theDate
{
  ASSIGN(_date, theDate);
}

- (NSString *) UID
{
  return _UID;
}


- (void) setUID: (NSString *) theUID
{
  ASSIGN(_UID, theUID);
}
@end
