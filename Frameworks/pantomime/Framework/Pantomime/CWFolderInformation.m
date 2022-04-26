/*
**  CWFolderInformation.m
**
**  Copyright (c) 2002-2004 Ludovic Marcotte
**  Copyright (C) 2017 Riccardo Mottola
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

#import <Pantomime/CWFolderInformation.h>

//
//
//
@implementation CWFolderInformation

- (id) init
{
  self = [super init];
  if (self)
    {
      _nb_of_messages = 0;
      _nb_of_unread_messages = 0;
      _size = 0;
    }
  return self;
}


//
//
//
- (NSUInteger) nbOfMessages
{
  return _nb_of_messages;
}


//
//
//
- (void) setNbOfMessages: (NSUInteger) theValue
{
  _nb_of_messages = theValue;
}


//
//
//
- (NSUInteger) nbOfUnreadMessages
{
  return _nb_of_unread_messages;
}


//
//
//
- (void) setNbOfUnreadMessages: (NSUInteger) theValue
{
  _nb_of_unread_messages = theValue;
}


//
//
//
- (NSUInteger) size
{
  return _size;
}


//
//
//
- (void) setSize: (NSUInteger) theSize
{
  _size = theSize;
}

@end
