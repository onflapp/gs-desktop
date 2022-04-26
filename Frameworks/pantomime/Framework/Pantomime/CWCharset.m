/*
**  CWCharset.m
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

#import <Pantomime/CWCharset.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWISO8859_1.h>
#import <Pantomime/CWISO8859_2.h>
#import <Pantomime/CWISO8859_3.h>
#import <Pantomime/CWISO8859_4.h>
#import <Pantomime/CWISO8859_5.h>
#import <Pantomime/CWISO8859_6.h>
#import <Pantomime/CWISO8859_7.h>
#import <Pantomime/CWISO8859_8.h>
#import <Pantomime/CWISO8859_9.h>
#import <Pantomime/CWISO8859_10.h>
#import <Pantomime/CWISO8859_11.h>
#import <Pantomime/CWISO8859_13.h>
#import <Pantomime/CWISO8859_14.h>
#import <Pantomime/CWISO8859_15.h>
#import <Pantomime/CWKOI8_R.h>
#import <Pantomime/CWKOI8_U.h>
#import <Pantomime/CWWINDOWS_1250.h>
#import <Pantomime/CWWINDOWS_1251.h>
#import <Pantomime/CWWINDOWS_1252.h>
#import <Pantomime/CWWINDOWS_1253.h>
#import <Pantomime/CWWINDOWS_1254.h>

#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>

static NSMutableDictionary *charset_name_description = nil;
static NSMutableDictionary *charset_instance_cache = nil;

//
//
//
@implementation CWCharset

+ (void) initialize
{
  if (!charset_instance_cache)
    {
      charset_instance_cache = [[NSMutableDictionary alloc] init];
    }

  if (!charset_name_description)
    {
      charset_name_description = [[NSMutableDictionary alloc] init];
    }
} 


//
//
//
- (id) initWithCodeCharTable: (const struct charset_code *) c
		      length: (int) n
{
  self = [super init];
  
  _codes = c;
  _num_codes = n; 
  _identity_map = 0x20;
  
  if (n > 0 && _codes[0].code == 0x20)
    {
      int i = 1;
      for (_identity_map=0x20;
	   i < _num_codes && _codes[i].code == _identity_map + 1 && _codes[i].value == _identity_map + 1;
	   _identity_map++,i++) ;
    }

  return self;
}


//
// TODO: what should this return for eg. \t and \n?
//
- (int) codeForCharacter: (unichar) theCharacter
{
  int i;

  if (theCharacter <= _identity_map)
    {
      return theCharacter;
    }
  
  for (i = 0; i < _num_codes; i++)
    {
      if (_codes[i].value == theCharacter)
	{
	  return _codes[i].code;
	}
    }
  
  return -1;
}


//
//
//
- (BOOL) characterIsInCharset: (unichar) theCharacter
{
  if (theCharacter <= _identity_map)
    {
      return YES;
    }

  if ([self codeForCharacter: theCharacter] != -1)
    {
      return YES;
    }
  
  return NO;
}


//
// Returns the name of the Charset. Like:
// "iso-8859-1"
// 
- (NSString *) name
{
  [self subclassResponsibility: _cmd];
  return nil;
}


//
//
//
+ (NSDictionary *) allCharsets
{
  if (![charset_name_description count])
    {
      [charset_name_description setObject: _(@"Western European (ISO Latin 1)")     forKey: @"iso-8859-1"];
      [charset_name_description setObject: _(@"Western European (ISO Latin 9)")     forKey: @"iso-8859-15"];
      [charset_name_description setObject: _(@"Western European (Windows Latin 1)") forKey: @"windows-1252"];

      [charset_name_description setObject: _(@"Japanese (ISO 2022-JP)")             forKey: @"iso-2022-jp"];
      [charset_name_description setObject: _(@"Japanese (EUC-JP)")                  forKey: @"euc-jp"];

      [charset_name_description setObject: _(@"Traditional Chinese (BIG5)")         forKey: @"big5"];
  
      [charset_name_description setObject: _(@"Arabic (ISO 8859-6)")                forKey: @"iso-8859-6"];
  
      [charset_name_description setObject: _(@"Greek (ISO 8859-7)")                 forKey: @"iso-8859-7"];
      [charset_name_description setObject: _(@"Greek (Windows)")                    forKey: @"windows-1253"];

      [charset_name_description setObject: _(@"Hebrew (ISO 8859-8)")                forKey: @"iso-8859-8"];
  
      [charset_name_description setObject: _(@"Cyrillic (ISO 8859-5)")              forKey: @"iso-8859-5"];
      [charset_name_description setObject: _(@"Cyrillic (KOI8-R)")                  forKey: @"koi8-r"];
      [charset_name_description setObject: _(@"Cyrillic (Windows)")                 forKey: @"windows-1251"];

      [charset_name_description setObject: _(@"Thai (ISO 8859-11)")                 forKey: @"iso-8859-11"];

      [charset_name_description setObject: _(@"Central European (ISO Latin 2)")     forKey: @"iso-8859-2"];
      [charset_name_description setObject: _(@"Central European (Windows Latin 2)") forKey: @"windows-1250"];
  
      [charset_name_description setObject: _(@"Turkish (Latin 5)")                  forKey: @"iso-8859-9"];
      [charset_name_description setObject: _(@"Turkish (Windows)")                  forKey: @"windows-1254"];
  
      [charset_name_description setObject: _(@"South European (ISO Latin 3)")       forKey: @"iso-8859-3"];
      [charset_name_description setObject: _(@"North European (ISO Latin 4)")       forKey: @"iso-8859-4"];
 
      [charset_name_description setObject: _(@"Nordic (ISO Latin 6)")               forKey: @"iso-8859-10"];
      [charset_name_description setObject: _(@"Baltic Rim (ISO Latin 7)")           forKey: @"iso-8859-13"];
      [charset_name_description setObject: _(@"Celtic (ISO Latin 8)")               forKey: @"iso-8859-14"];

      [charset_name_description setObject: _(@"Simplified Chinese (GB2312)")        forKey: @"gb2312"];
      [charset_name_description setObject: _(@"UTF-8")                              forKey: @"utf-8"];

#ifdef MACOSX
      [charset_name_description setObject: _(@"Korean (EUC-KR/KS C 5601)")          forKey: @"euc-kr"];
      [charset_name_description setObject: _(@"Japanese (Win/Mac)")                 forKey: @"shift_jis"];
#endif
    }

  return charset_name_description;
}


//
// This method is used to obtain a charset from the name
// of this charset. It caches this charset for future
// usage when it's found.
//
+ (CWCharset *) charsetForName: (NSString *) theName
{
  CWCharset *theCharset;

  theCharset = [charset_instance_cache objectForKey: [theName lowercaseString]];

  if (!theCharset)
    {
      CWCharset *aCharset;
      
      if ([[theName lowercaseString] isEqualToString: @"iso-8859-2"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_2 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-3"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_3 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-4"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_4 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-5"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_5 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-6"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_6 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-7"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_7 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-8"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_8 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-9"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_9 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-10"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_10 alloc] init];
 	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-11"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_11 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-13"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_13 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-14"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_14 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"iso-8859-15"])
	{
	  aCharset = (CWCharset *)[[CWISO8859_15 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"koi8-r"])
	{
	  aCharset = (CWCharset *)[[CWKOI8_R alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"koi8-u"])
	{
	  aCharset = (CWCharset *)[[CWKOI8_U alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"windows-1250"])
	{
	  aCharset = (CWCharset *)[[CWWINDOWS_1250 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"windows-1251"])
	{
	  aCharset = (CWCharset *)[[CWWINDOWS_1251 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"windows-1252"])
	{
	  aCharset = (CWCharset *)[[CWWINDOWS_1252 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"windows-1253"])
	{
	  aCharset = (CWCharset *)[[CWWINDOWS_1253 alloc] init];
	}
      else if ([[theName lowercaseString] isEqualToString: @"windows-1254"])
	{
	  aCharset = (CWCharset *)[[CWWINDOWS_1254 alloc] init];
	}
      else
	{
	  aCharset = (CWCharset *)[[CWISO8859_1 alloc] init];
	}
      
      [charset_instance_cache setObject: aCharset
			      forKey: [theName lowercaseString]];
      RELEASE(aCharset);

      return aCharset;
    }

  return theCharset;
}

@end
