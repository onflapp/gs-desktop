/*
**  CWUUFile.m
**
**  Copyright (c) 2002-2004 Ludovic Marcotte
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

#import <Pantomime/CWUUFile.h>

#import <Pantomime/CWConstants.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSValue.h>

#define UUDECODE(c)  (((c) - ' ') & 077)

//
//
//
void uudecodeline(char *line, NSMutableData *data)
{
  int c, len;
  
  len = UUDECODE(*line++);
  
  while (len)
    {
      c = UUDECODE(*line) << 2 | UUDECODE(line[1]) >> 4;
      
      [data appendBytes: &c
	    length: 1];
      
      if (--len)
	{
	  c = UUDECODE(line[1]) << 4 | UUDECODE(line[2]) >> 2;
	  
	  [data appendBytes: &c
		length: 1];
	  
	  if (--len)
	    {
	      c = UUDECODE(line[2]) << 6 | UUDECODE(line[3]);
	      [data appendBytes: &c
		    length: 1];
	      len--;
	    }
	}
      line += 4;
    }
  
  return;
}


//
//
//
@implementation CWUUFile

- (id) initWithName: (NSString *) theName
	       data: (NSData *) theData
	 attributes: (NSDictionary *) theAttributes
{
  self = [super init];
  if (self)
    {
      [self setName: theName];
      [self setData: theData];
      [self setAttributes: theAttributes];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_name);
  RELEASE(_data);
  RELEASE(_attributes);
  [super dealloc];
}


//
// access / mutation methods
//
- (NSString *) name
{
  return _name;
}

- (void) setName: (NSString *) theName
{
  ASSIGN(_name, theName);
}


//
//
//
- (NSData *) data
{
  return _data;
}

- (void) setData: (NSData *) theData
{
  ASSIGN(_data, theData);
}


//
//
//
- (NSDictionary *) attributes
{
  return _attributes;
}

- (void) setAttributes: (NSDictionary *) theAttributes
{
  ASSIGN(_attributes, theAttributes);
}


//
//
//
+ (CWUUFile *) fileFromUUEncodedString: (NSString *) theString
{
  NSString *aString, *aFilename;
  NSNumber *theFilePermissions;
  NSMutableData *aMutableData;
  NSArray *allLines;
  CWUUFile *aUUFile;
  int i, count;

  aMutableData = [NSMutableData dataWithCapacity: [theString length]];

  allLines = [theString componentsSeparatedByString: @"\n"];

  // We decode our filename and our mode
  aString = [allLines objectAtIndex: 0];

  theFilePermissions = [NSNumber numberWithInt: [[[aString componentsSeparatedByString: @" "] objectAtIndex: 1] intValue]];
  aFilename = [[aString componentsSeparatedByString: @" "] objectAtIndex: 2];
  
  // We now get the data representing our uuencoding string
  count = [allLines count]-1;
  for (i = 1; i < count; i++)
    {
      uudecodeline((char *)[[allLines objectAtIndex: i] cString], aMutableData);
    }

  // We finally initialize our file wrapper will all our informations
  aUUFile = [[CWUUFile alloc] initWithName: aFilename
			      data: aMutableData
			      attributes: [NSDictionary dictionaryWithObject: theFilePermissions
						      forKey: NSFilePosixPermissions]];
  
  return AUTORELEASE(aUUFile);
}


//
// FIXME, we currently ignore theRange
//
+ (NSRange) rangeOfUUEncodedStringFromString: (NSString *) theString
                                       range: (NSRange) theRange
{
  NSRange r1, r2;

  r1 = [theString rangeOfString: @"begin "];

  if (r1.length == 0)
    {
      return NSMakeRange(NSNotFound, 0);
    }

  r2 = [theString rangeOfString: @"\nend"
		  options: 0
		  range: NSMakeRange(r1.location, [theString length] - r1.location)];
  
  if (r2.length == 0)
    {
      return NSMakeRange(NSNotFound, 0);
    }
  
  return NSMakeRange(r1.location, (r2.location + r2.length) - r1.location);
}

@end
