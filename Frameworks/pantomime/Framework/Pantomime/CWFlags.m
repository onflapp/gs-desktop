/*
**  CWFlags.m
**
**  Copyright (c) 2001-2004 Ludovic Marcotte
**  Copyright (C) 2018      Riccardo Mottola
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

#import <Pantomime/CWFlags.h>

#import <Pantomime/NSData+Extensions.h>

#define CHECK_FLAG(c, value) \
  theRange = [theData rangeOfCString: c]; \
  if (theRange.length) { [self add: value]; }

//
//
//
@implementation CWFlags

- (id) initWithFlags: (PantomimeFlag) theFlags
{
  self = [super init];
  if (self)
    {
      flags = theFlags;
    }
  return self;
}


//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *) theCoder
{
  [theCoder encodeObject: [NSNumber numberWithInt: flags]];
}


- (id) initWithCoder: (NSCoder *) theCoder
{
  self = [super init];
  if (self)
    {
      flags = (PantomimeFlag)[[theCoder decodeObject] intValue];
    }
  return self;
}


//
// NSCopying protocol
//
- (id) copyWithZone: (NSZone *) zone
{
  CWFlags *copy;

  copy = [[CWFlags allocWithZone: zone] initWithFlags: flags];

  return copy;
}


//
//
//
- (void) add: (PantomimeFlag) theFlag
{
  flags = flags|theFlag;
}


//
//
//
- (void) addFlagsFromData: (NSData *) theData
		   format: (PantomimeFolderFormat) theFormat
{
  NSRange theRange;
  
  if (theData)
    {    
      if (theFormat == PantomimeFormatMbox)
	{
	  CHECK_FLAG("R", PantomimeSeen);
	  CHECK_FLAG("D", PantomimeDeleted);
	  CHECK_FLAG("A", PantomimeAnswered);
	  CHECK_FLAG("F", PantomimeFlagged);
	}
      else if (theFormat == PantomimeFormatMaildir)
	{
	  CHECK_FLAG("S", PantomimeSeen);
	  CHECK_FLAG("R", PantomimeAnswered);
	  CHECK_FLAG("F", PantomimeFlagged);
	  CHECK_FLAG("D", PantomimeDraft);
	  CHECK_FLAG("T", PantomimeDeleted);
	}
    }
}


//
//
//
- (BOOL) contain: (PantomimeFlag) theFlag
{
  if ((flags&theFlag) == theFlag) 
    {
      return YES;
    }
  else
    {
      return NO;
    }
}


//
//
//
- (void) replaceWithFlags: (CWFlags *) theFlags
{
  flags = theFlags->flags;
}

//
//
//
- (void) remove: (PantomimeFlag) theFlag
{
  flags = flags&(flags^theFlag);
}


//
//
//
- (void) removeAll
{
  flags = 0;
}


//
//
//
- (NSString *) statusString
{
  return [NSString stringWithFormat: @"%cO", ([self contain: PantomimeSeen] ? 'R' : ' ')];
}

//

// This is useful if we want to store the flags in the mbox file
// when expunging messages from it. We might write in the headers:
//
// X-Status: FA
//
// If the message had the "Flagged" and "Answered" flags.
//
// Note: We store the same value as pine does in order to ease
//       using mbox files between the two MUAs.
//
- (NSString *) xstatusString
{
  NSMutableString *aMutableString;

  aMutableString = [[NSMutableString alloc] init];
  
  if ([self contain: PantomimeDeleted])
    {
      [aMutableString appendFormat: @"%c", 'D'];
    }

  if ([self contain: PantomimeFlagged])
    {
      [aMutableString appendFormat: @"%c", 'F'];
    }

  if ([self contain: PantomimeAnswered])
    {
      [aMutableString appendFormat: @"%c", 'A'];
    }

  return AUTORELEASE(aMutableString);
}


//
//
//
- (NSString *) maildirString
{
  NSMutableString *aMutableString;
  
  aMutableString = [[NSMutableString alloc] initWithString: @"2,"];
  
  if ([self contain: PantomimeDraft])
    {
      [aMutableString appendString: @"D"];
    }
  
  if ([self contain: PantomimeFlagged])
    {
      [aMutableString appendString: @"F"];
    }
  
  if ([self contain: PantomimeAnswered])
    {
      [aMutableString appendString: @"R"];
    }
  
  if ([self contain: PantomimeSeen])
    {
      [aMutableString appendString: @"S"];
    }
  
  if ([self contain: PantomimeDeleted])
    {
      [aMutableString appendString: @"T"];
    }

  return AUTORELEASE(aMutableString);
}

@end
