/*
**  CWPOP3Message.m
**
**  Copyright (c) 2001-2006 Ludovic Marcotte
**                2018      Riccardo Mottola
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

#import <Pantomime/CWPOP3Message.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWFlags.h>
#import <Pantomime/CWPOP3Folder.h>
#import <Pantomime/CWPOP3Store.h>

@implementation CWPOP3Message 

- (id) init
{
  self = [super init];
  if (self)
    {
      [self setUID: nil];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_UID);
  [super dealloc];
}


//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *) theCoder
{
  // Must also encode Message's superclass
  [super encodeWithCoder: theCoder];
  [theCoder encodeObject: [self UID]];
}


//
//
//
- (id) initWithCoder: (NSCoder *) theCoder
{
  // Must also decode Message's superclass
  self = [super initWithCoder: theCoder];
  if (self)
    {
      [self setUID: [theCoder decodeObject]];
    }
  return self;
}


//
//
//
- (NSString *) UID
{
  return _UID;
}


//
//
//
- (void) setUID: (NSString *) theUID
{
  ASSIGN(_UID, theUID);
}


//
//
//
- (NSData *) rawSource
{
  if (!_rawSource)
    {
      [[[self folder] store] sendCommand: POP3_RETR  arguments: @"RETR %d", [self messageNumber]];
    }

  return _rawSource;
}


//
//
//
- (void) setInitialized: (BOOL) theBOOL
{
  [super setInitialized: theBOOL];
  
  if (!theBOOL)
    {
      DESTROY(_content);
      return;
    }

  if (!_content)
    {
      [[[self folder] store] sendCommand: POP3_RETR_AND_INITIALIZE  arguments: @"RETR %d", [self messageNumber]];
      [super setInitialized: NO];
    }
}


//
//
//
- (void) setFlags: (CWFlags *) theFlags
{
  if ([theFlags contain: PantomimeDeleted])
    {
      [[[self folder] store] sendCommand: POP3_DELE  arguments: @"DELE %d", [self messageNumber]];
    }

  [super setFlags: theFlags];
}

@end
