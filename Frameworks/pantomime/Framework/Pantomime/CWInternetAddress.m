/*
**  CWInternetAddress.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2017-2018  Riccardo Mottola
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
#import <Pantomime/CWInternetAddress.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWMIMEUtility.h>
#import <Pantomime/NSString+Extensions.h>

#import <Foundation/Foundation.h>

//
//
//
@implementation CWInternetAddress : NSObject

- (id) initWithString: (NSString *) theString
{
  NSUInteger idxLeftPar;
  NSUInteger idxLeftAngBrk;
  NSUInteger idxLeftAddr;
  
  if (nil == theString || [theString length] == 0)
    {
      AUTORELEASE(self);
      return nil;
    }
  
  self = [super init];
  if (self)
    {
      // Some potential addresses:
      //
      // Ludovic Marcotte <ludovic@Sophos.ca>
      // ludovic@Sophos.ca
      // <ludovic@Sophos.ca>
      // "Marcotte, Ludovic" <ludovic@Sophos.ca>
      // "Joe" User <joe@acme.com>
      // "joe@acme.com (Joe User)"
      // "Joe <joe@acme.com>" <joe@acme.com>

      // Given the case of address inside quote " <xx>" <xx> we search from the back!
      idxLeftAngBrk = [theString indexOfLastCharacter:'<'];
      idxLeftPar = [theString indexOfCharacter: '('];

      if (idxLeftAngBrk != NSNotFound)
	{
	  NSUInteger idxRightAddr;
	
	  idxLeftAddr = idxLeftAngBrk;
	  idxRightAddr = [theString indexOfCharacter: '>'  fromIndex: idxLeftAddr+1];

	  // If the trailing '>' is missing, then just take the rest of the string
	  if (idxRightAddr == NSNotFound)
	    {
	      idxRightAddr = [theString length];
	    }
      
	  [self setAddress: [theString substringWithRange: NSMakeRange(idxLeftAddr+1,idxRightAddr-idxLeftAddr-1)]];
	  
	  if (idxLeftAddr != NSNotFound && idxLeftAddr > 0)
	    {
	      NSString *nameSubStr;
	      NSUInteger idxFirstQuote;

	      nameSubStr = [[theString substringToIndex:idxLeftAddr] stringByTrimmingWhiteSpaces];
	      idxFirstQuote = [nameSubStr indexOfCharacter: '"'];

	      if (idxFirstQuote != NSNotFound)
		{
		  NSRange rangeLastQuote;

		  // check for the last quote
		  rangeLastQuote = [nameSubStr rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString:@"\""] options:NSBackwardsSearch range:NSMakeRange(0, [nameSubStr length])];
	      
		  // first check for a sane case
		  if (idxFirstQuote < rangeLastQuote.location)
		    {
		      NSRange rangeLastQuotedQuote;
		      // check for the last quoted quote
		      rangeLastQuotedQuote = [nameSubStr rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString:@"\\"""] options:NSBackwardsSearch range:NSMakeRange(0, [nameSubStr length])];

		      // "Marcotte, Ludovic" <ludovic@Sophos.ca>
		      // we unquote only if the first quote is the first character and the last one is not an escaped quote
		      if (idxFirstQuote == 0 && rangeLastQuote.location != rangeLastQuotedQuote.location)
			{
			  nameSubStr = [nameSubStr substringWithRange:NSMakeRange(1, rangeLastQuote.location - 1)];
			}
		    }
	      
		  // un-escape certain characters
		  if ([nameSubStr rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString:@"\\()[]"""]].location != NSNotFound)
		    {
		      NSMutableString *mutStr;
                  
		      mutStr = [NSMutableString stringWithString:nameSubStr];
		      [mutStr replaceOccurrencesOfString:@"\\(" withString:@"(" options:0 range:NSMakeRange(0, [mutStr length])];
		      [mutStr replaceOccurrencesOfString:@"\\)" withString:@")" options:0 range:NSMakeRange(0, [mutStr length])];
		      [mutStr replaceOccurrencesOfString:@"\\[" withString:@"]" options:0 range:NSMakeRange(0, [mutStr length])];
		      [mutStr replaceOccurrencesOfString:@"\\[" withString:@"]" options:0 range:NSMakeRange(0, [mutStr length])];
		      [mutStr replaceOccurrencesOfString:@"\\""" withString:@"""" options:0 range:NSMakeRange(0, [mutStr length])];
		      nameSubStr = [NSString stringWithString:mutStr];
		    }
		  [self setPersonal: nameSubStr];
		}
	      else
		{
		  [self setPersonal: [[theString substringWithRange: NSMakeRange(0,idxLeftAddr)]
				       stringByTrimmingWhiteSpaces]];
		}
	    }
	}
      else if (idxLeftPar != NSNotFound)
	{
	  NSUInteger idxRightPar;
	  NSUInteger idxFirstQuote;
	  NSString *addrStr;
      
	  // we may have:
	  // john@doe.com (John Doe (Jonny))
	  // so we check the right parentheses from the end
	  idxRightPar = [theString indexOfLastCharacter: ')'];
	  idxFirstQuote = [theString indexOfCharacter: '"'];

	  addrStr = [theString substringWithRange: NSMakeRange(0, idxLeftPar)];
	  if (idxFirstQuote == 0)
	    addrStr = [addrStr substringFromIndex:1];
      
	  [self setAddress: [addrStr stringByTrimmingWhiteSpaces]];

	  if (idxRightPar != NSNotFound && idxRightPar > idxLeftPar)
	    {
	      NSString *nameStr;
          
	      nameStr = [theString substringWithRange: NSMakeRange(idxLeftPar+1, idxRightPar-idxLeftPar-1)];
	      [self setPersonal: nameStr];
	    }
	  else
	    NSLog(@"Issue decoding personal part from |%@|", theString); 
	} 
      else
	{
	  [self setAddress: theString];
	}
    }
  return self;
}


//
//
//
- (id) initWithPersonal: (NSString *) thePersonal
		address: (NSString *) theAddress
{
  self = [super init];
  if (self)
    {
      [self setPersonal: thePersonal];
      [self setAddress: theAddress];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_address);
  RELEASE(_personal);
  [super dealloc];
}


//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *) theCoder
{
  [theCoder encodeObject: [NSNumber numberWithInt: _type]];
  [theCoder encodeObject: _address];
  [theCoder encodeObject: [self personal]];
}

- (id) initWithCoder: (NSCoder *) theCoder
{
  self = [super init];
  if (self)
    {
      [self setType: [[theCoder decodeObject] intValue]];
      [self setAddress: [theCoder decodeObject]];
      [self setPersonal: [theCoder decodeObject]];
    }
  return self;
}


//
//
//
- (NSString *) address
{
  return _address;
}

- (void) setAddress: (NSString *) theAddress
{
  ASSIGN(_address, theAddress);
}


//
//
//
- (NSString *) personal
{
  return _personal;
}

- (void) setPersonal: (NSString *) thePersonal
{
  ASSIGN(_personal, thePersonal);
}

- (NSString *) personalQuoted
{
  NSString *quoted;

  // We verify if we need to quote the name
  if ([_personal indexOfCharacter: ','] != NSNotFound  &&
      ![_personal hasPrefix: @"\""] &&
      ![_personal hasSuffix: @"\""])
    {
      quoted = [NSString stringWithFormat: @"\"%@\"", _personal];
    }
  else
    quoted = [NSString stringWithString:_personal];

  return quoted;
}



//
//
//
- (PantomimeRecipientType) type 
{
  return _type;
}

- (void) setType: (PantomimeRecipientType) theType
{
  _type = theType;
}


//
//
//
- (NSData *) dataValue
{
  if ([self personal] && [[self personal] length] > 0)
    {
      NSMutableData *aMutableData;

      aMutableData = [[NSMutableData alloc] init];

      [aMutableData appendData: [CWMIMEUtility encodeWordUsingQuotedPrintable: [self personal] prefixLength: 0]];

      if (_address)
	{
	  [aMutableData appendBytes: " <"  length: 2];
	  [aMutableData appendData: [_address dataUsingEncoding: NSASCIIStringEncoding]];
	  [aMutableData appendBytes: ">" length: 1];
	}

      return AUTORELEASE(aMutableData);
    }
  else
    {
      return [_address dataUsingEncoding: NSASCIIStringEncoding];
    }
}

//
//
//
- (NSString *) stringValue
{
  if ([self personal] && [[self personal] length] > 0)
    {
      if (_address)
	{
	  return [NSString stringWithFormat: @"%@ <%@>", [self personalQuoted], _address];
	}
      else
	{
	  return [NSString stringWithFormat: @"%@", [self personalQuoted]];
	}
    }
  else
    {
      return _address;
    }
}

//
//
//
- (NSComparisonResult) compare: (id) theAddress
  
{
  return [[self stringValue] compare: [(NSObject *)theAddress valueForKey: @"stringValue"]];
}

//
//
//
- (BOOL) isEqualToAddress: (CWInternetAddress *) theAddress
{
  if (![theAddress isMemberOfClass: [self class]])
    {
      return NO;
    }

  return [_address isEqualToString: [theAddress address]];
}


//
// For debugging support
//
- (NSString *) description
{
  return [self stringValue];
}

//
// For scripting support 
//
- (id) container
{
  return _container;
}

- (void) setContainer: (id) theContainer
{
  _container = theContainer;
}
@end


//
// For scripting support 
//
@implementation ToRecipient

- (id) init
{
  self = [super init];
  [self setType: PantomimeToRecipient];
  return self;
}

@end


//
// For scripting support 
//
@implementation CcRecipient

- (id) init
{
  self = [super init];
  [self setType: PantomimeCcRecipient];
  return self;
}

@end


//
// For scripting support 
//
@implementation BccRecipient

- (id) init
{
  self = [super init];
  [self setType: PantomimeBccRecipient];
  return self;
}


@end


