/*
**  CWCacheManager.m
**
**  Copyright (c) 2004-2007 Ludovic Marcotte
**  Copyright (C) 2013-2020 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola
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

#import <Pantomime/CWCacheManager.h>
#import <Pantomime/CWConstants.h>

#import <Foundation/NSArchiver.h>
#import <Foundation/NSException.h>

@implementation CWCacheManager

- (id) initWithPath: (NSString *) thePath
{
  if ((self = [super init]))
    {
      ASSIGN(_path, thePath);
    }
  
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_path);
  [super dealloc];
}

//
//
//
- (NSString *) path
{
  return _path;
}

- (void) setPath: (NSString *) thePath
{
  ASSIGN(_path, thePath);
}


//
//
//
- (void) invalidate
{
  //[_cache removeAllObjects];
}

//
//
//
- (BOOL) synchronize
{
  [self subclassResponsibility: _cmd];
  return NO;
}

//
//
//
- (void) expunge
{
  [self subclassResponsibility: _cmd];
}

//
//
//
- (NSUInteger) count
{
  return _count;
}

@end
