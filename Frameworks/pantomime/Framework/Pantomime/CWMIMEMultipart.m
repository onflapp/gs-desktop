/*
**  CWMIMEMultipart.m
**
**  Copyright (c) 2001-2004 Ludovic Marcotte
**  Copyright (C) 2017      Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
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

#import <Pantomime/CWMIMEMultipart.h>

#import <Pantomime/CWConstants.h>

//
//
//
@implementation CWMIMEMultipart

- (id) init
{
  self = [super init];
  if (self)
    {
      _parts = [[NSMutableArray alloc] init];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_parts);
  [super dealloc];
}


//
//
//
- (void) addPart: (CWPart *) thePart 
{
  if (thePart)
    {
      [_parts addObject: thePart];
    }
}


//
//
//
- (void) removePart: (CWPart *) thePart
{
  if (thePart)
    {
      [_parts removeObject: thePart];
    }
}


//
//
//
- (NSUInteger) count
{
  return [_parts count];
}


//
//
//
- (CWPart *) partAtIndex: (NSUInteger) theIndex
{
  return [_parts objectAtIndex: theIndex];
}

@end
