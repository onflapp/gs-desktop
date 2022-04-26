/*
**  NSString+Extensions.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2014-2022 Riccardo Mottola
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

#import <Pantomime/NSString+Extensions.h>

#import <Pantomime/CWCharset.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/CWInternetAddress.h>
#import <Pantomime/CWPart.h>
#import <Pantomime/NSData+Extensions.h>

#import <Foundation/NSBundle.h>

//
// We include the CoreFoundation headers under Mac OS X so we can support
// more string encodings.
//
#ifdef MACOSX
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/CFStringEncodingExt.h>
#endif

#include <ctype.h>

#ifdef HAVE_ICONV
#include <iconv.h>
#if defined (MACOSX) || defined (__NetBSD__) || defined (__FreeBSD__)
#define iconv_const_qualifier const
#else
#define iconv_const_qualifier
#endif
#endif

#define IS_PRINTABLE(c) (isascii(c) && isprint(c))

//
//
//
@implementation NSString (PantomimeStringExtensions)

#ifdef MACOSX
- (NSString *) stringByTrimmingWhiteSpaces
{
  NSMutableString *aMutableString;

  aMutableString = [[NSMutableString alloc] initWithString: self];
  CFStringTrimWhitespace((CFMutableStringRef)aMutableString);
  
  return AUTORELEASE(aMutableString);
}
#endif


//
//
//
- (NSUInteger) indexOfCharacter: (unichar) theCharacter
{
  return [self indexOfCharacter: theCharacter  fromIndex: 0u];
}

//
//
//
- (NSUInteger) indexOfLastCharacter: (unichar) theCharacter
{
  NSUInteger len;
  NSUInteger i;
    
  len = [self length];
    
  for (i = 1; i <= len; i++)
    {
      if ([self characterAtIndex: len-i] == theCharacter)
        {
          return len-i;
        }
    }
    
    return NSNotFound;
}


//
//
//
- (NSUInteger) indexOfCharacter: (unichar) theCharacter
               fromIndex: (NSUInteger) theIndex
{
  NSUInteger len;
  NSUInteger i;
  
  len = [self length];
  
  for (i = theIndex; i < len; i++)
    {
      if ([self characterAtIndex: i] == theCharacter)
	{
	  return i;
	}
    }
  
  return NSNotFound;
}


//
//
//
- (BOOL) hasCaseInsensitivePrefix: (NSString *) thePrefix
{
  if (thePrefix)
    {
      return [[self uppercaseString] hasPrefix: [thePrefix uppercaseString]];
    }
  
  return NO;
}


//
//
//
- (BOOL) hasCaseInsensitiveSuffix: (NSString *) theSuffix
{
  if (theSuffix)
    {
      return [[self uppercaseString] hasSuffix: [theSuffix uppercaseString]];
    }
  
  return NO;
}


//
//
//
- (NSString *) stringFromQuotedString
{
  NSUInteger len;

  len = [self length];
  
  if (len > 1 &&
      [self characterAtIndex: 0] == '"' &&
      [self characterAtIndex: (len-1)] == '"')
    {
      return [self substringWithRange: NSMakeRange(1, len-2)];
    }
  
  return self;
}


//
//
//
+ (NSString *) stringValueOfTransferEncoding: (PantomimeEncoding) theEncoding
{
  switch (theEncoding)
    {
    case PantomimeEncodingNone:
      break;
    case PantomimeEncodingQuotedPrintable:
      return @"quoted-printable";
    case PantomimeEncodingBase64:
      return @"base64";
    case PantomimeEncoding8bit:
      return @"8bit";
    case PantomimeEncodingBinary:
      return @"binary";
    default:
      break;
    }

  // PantomimeEncoding7bit will also fall back here.
  return @"7bit";
}

//
//
//
+ (unsigned long) encodingForCharset: (NSData *) theCharset
{
  return [self encodingForCharset: theCharset convertToNSStringEncoding: YES];
}

//
// Convenience to be able to use CoreFoundation conversion instead of NSString
//
+ (unsigned long) encodingForCharset: (NSData *) theCharset
 convertToNSStringEncoding: (BOOL) shouldConvert
{
  // We define some aliases for the string encoding.
  static struct { NSString *name; unsigned long encoding; BOOL fromCoreFoundation; } encodings[] = {
    {@"ascii"         ,NSASCIIStringEncoding          ,NO},
    {@"us-ascii"      ,NSASCIIStringEncoding          ,NO},
    {@"default"       ,NSASCIIStringEncoding          ,NO},  // Ah... spammers.
    {@"utf-8"         ,NSUTF8StringEncoding           ,NO},
    {@"iso-8859-1"    ,NSISOLatin1StringEncoding      ,NO},
    {@"x-user-defined",NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Outlook.
    {@"unknown"       ,NSISOLatin1StringEncoding      ,NO},  // Once more, blame Outlook.
    {@"x-unknown"     ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Pine 4.21.
    {@"unknown-8bit"  ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Mutt/1.3.28i
    {@"0"             ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in QUALCOMM Windows Eudora Version 6.0.1.1
    {@""              ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Ximian Evolution
    {@"iso8859_1"     ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Openwave WebEngine
    {@"iso-8859-2"    ,NSISOLatin2StringEncoding      ,NO},
#ifndef MACOSX
    {@"iso-8859-3"   ,NSISOLatin3StringEncoding                 ,NO},
    {@"iso-8859-4"   ,NSISOLatin4StringEncoding                 ,NO},
    {@"iso-8859-5"   ,NSISOCyrillicStringEncoding               ,NO},
    {@"iso-8859-6"   ,NSISOArabicStringEncoding                 ,NO},
    {@"iso-8859-7"   ,NSISOGreekStringEncoding                  ,NO},
    {@"iso-8859-8"   ,NSISOHebrewStringEncoding                 ,NO},
    {@"iso-8859-9"   ,NSISOLatin5StringEncoding                 ,NO},
    {@"iso-8859-10"  ,NSISOLatin6StringEncoding                 ,NO},
    {@"iso-8859-11"  ,NSISOThaiStringEncoding                   ,NO},
    {@"iso-8859-13"  ,NSISOLatin7StringEncoding                 ,NO},
    {@"iso-8859-14"  ,NSISOLatin8StringEncoding                 ,NO},
    {@"iso-8859-15"  ,NSISOLatin9StringEncoding                 ,NO},
    {@"koi8-r"       ,NSKOI8RStringEncoding                     ,NO},
    {@"big5"         ,NSBig5StringEncoding                      ,NO},
    {@"gb2312"       ,NSHZ_GB_2312StringEncoding                ,NO},
    {@"utf-7"        ,NSUTF7StringEncoding                      ,NO},
    {@"unicode-1-1-utf-7", NSUTF7StringEncoding                 ,NO},  // To prever a bug (sort of) in MS Hotmail
    {@"euc-kr"       ,NSKoreanEUCStringEncoding                 ,NO},
#else // Core foundation support
    {@"iso-8859-3"   ,kCFStringEncodingISOLatin3                ,YES},
    {@"koi8-r"       ,kCFStringEncodingKOI8_R                   ,YES},
    {@"gb2312"       ,kCFStringEncodingEUC_CN                   ,YES},  // tested instead of proper GB2312-80
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
    {@"koi8-u"       ,kCFStringEncodingKOI8_U                   ,YES},
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    {@"utf-7"        ,kCFStringEncodingUTF7                     ,YES},
#endif
#endif
    {@"euc-kr"       ,kCFStringEncodingEUC_KR                   ,YES},
#endif
    {@"windows-1250" ,NSWindowsCP1250StringEncoding             ,NO},
    {@"windows-1251" ,NSWindowsCP1251StringEncoding             ,NO},
    {@"cyrillic (windows-1251)", NSWindowsCP1251StringEncoding  ,NO},  // To prevent a bug in MS Hotmail
    {@"windows-1252" ,NSWindowsCP1252StringEncoding             ,NO},
    {@"windows-1253" ,NSWindowsCP1253StringEncoding             ,NO},
    {@"windows-1254" ,NSWindowsCP1254StringEncoding             ,NO},
    {@"iso-2022-jp"  ,NSISO2022JPStringEncoding                 ,NO},
    {@"euc-jp"       ,NSJapaneseEUCStringEncoding               ,NO},
  };
  
  NSString *name;
  unsigned i;

  name = [[NSString stringWithCString: [theCharset bytes] length: [theCharset length]] lowercaseString];
  for (i = 0; i < sizeof(encodings)/sizeof(encodings[0]); i++)
    {
      if ([name isEqualToString: encodings[i].name])
        {
          unsigned long enc = encodings[i].encoding;
          // Under OS X, we use CoreFoundation if necessary to convert the encoding
          // to a NSString encoding.
#ifdef MACOSX
          if (encodings[i].fromCoreFoundation)
            {
              if (shouldConvert)
		{
                  NSStringEncoding nsEnc;
                  
                  nsEnc = CFStringConvertEncodingToNSStringEncoding ((CFStringEncoding)enc);
                  return (unsigned long)nsEnc;
		}
	      else
		{
		  return enc;
		}
	    }
          else
            {
              if (shouldConvert)
		{
                  return enc;
		}
              else
		{
                  unsigned long enc2;
                  
                  enc2 = (unsigned long)CFStringConvertNSStringEncodingToEncoding(enc);
                  return enc2;
		}
	    }
#else
          return enc;
#endif
        }
    }

#ifdef MACOSX
  // Last resort: try using CoreFoundation...
  CFStringEncoding enc;
  
  enc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)name);
  if (kCFStringEncodingInvalidId != enc)
    {
      if (shouldConvert)
	{
	  return CFStringConvertEncodingToNSStringEncoding(enc);
	}
      else
	{
	  return enc;
	}
    }
#endif
  
  return NSNotFound;
}

//
//
//
+ (unsigned long) encodingForPart: (CWPart *) thePart
{
  return [self encodingForPart: thePart convertToNSStringEncoding: YES];
}

//
// Convenience to be able to use CoreFoundation conversion instead of NSString
//
+ (unsigned long)    encodingForPart: (CWPart *) thePart
 convertToNSStringEncoding: (BOOL) shouldConvert
{
  unsigned long encoding;
  
  // We get the encoding we are gonna use. We always favor the default encoding.
  if ([thePart defaultCharset])
    {
      encoding = [self encodingForCharset: [[thePart defaultCharset] dataUsingEncoding: NSASCIIStringEncoding]
		       convertToNSStringEncoding: shouldConvert];
    }
  else if ([thePart charset])
    {
      encoding = [self encodingForCharset: [[thePart charset] dataUsingEncoding: NSASCIIStringEncoding]
		       convertToNSStringEncoding: shouldConvert];
    }
  else
    {
      encoding = [NSString defaultCStringEncoding];
    }
  
  if (encoding == NSNotFound || encoding == NSASCIIStringEncoding)
    {
      encoding = NSISOLatin1StringEncoding;
    }
  
  return encoding;
}


//
//
//
+ (NSString *) stringWithData: (NSData *) theData
                      charset: (NSData *) theCharset
{
  unsigned long encoding;
  
  if (theData == nil)
    {
      return nil;
    }
  
#ifdef MACOSX
  encoding = [NSString encodingForCharset: theCharset
                convertToNSStringEncoding: NO];
#else
  encoding = [NSString encodingForCharset: theCharset];
#endif

  if (encoding == NSNotFound)
    {
#ifdef HAVE_ICONV
      NSString *aString;

      const char *i_bytes, *from_code;
      char *o_bytes;
      char *o_buff;

      size_t i_length, o_length, ret;
      size_t total_length;
      iconv_t conv;
      
      // Instead of calling cString directly on theCharset, we first try
      // to obtain the ASCII string of the data object.
      from_code = [[theCharset asciiString] cString];
      NSLog(@"stringWithData - iconv fallback, charset: %s", from_code);
      if (!from_code)
	{
	  return nil;
	}
      
      conv = iconv_open("UTF-8", from_code);
      
      if (conv == (iconv_t)-1)
	{
	  // Let's assume we got US-ASCII here.
	  return AUTORELEASE([[NSString alloc] initWithData: theData  encoding: NSASCIIStringEncoding]);
	}
      
      i_bytes = [theData bytes];
      i_length = [theData length];

      total_length = sizeof(unichar)*i_length;
      o_length = total_length;
      o_buff = (char *)malloc(o_length); // original pointer to the buffer
      o_bytes = o_buff; // o_bytes is the working iconv pointer

      if (o_bytes == NULL) return nil;

      while (i_length > 0)
	{
	  ret = iconv(conv, (iconv_const_qualifier char **)&i_bytes, &i_length, &o_bytes, &o_length);
	  
	  // *i_bytes  Pointer to the byte just after the last character fetched.
	  // *i_bytes  Number of remaining bytes in the source buffer.
	  // *o_bytes  Pointer to the byte just after the last character stored.
	  // *o_length Number of remainder bytes in the destination buffer.
	  if (ret == (size_t)-1)
	    {
              // was our buffer too small?
              if (errno == E2BIG)
                {
                  // realloc and try again
		  total_length += sizeof(unichar);
		  o_buff = realloc(o_buff, total_length);
                  if (o_buff == NULL)
                    {
                      NSLog(@"stringWithData, realloc() failed while enlarging, returning nil");
                      iconv_close(conv);
                      return nil;
                    }
		  o_bytes = o_buff;
		  o_length = total_length;
                }
              else
                {
                  // we could have had an invalid sequence EILSEQ or incomplete sequence EINVAL
                  NSLog(@"stringWithData, invalid sequence, returning nil");
	          iconv_close(conv);
	          free(o_buff);
	          return nil;
                }
	    }
	}

      total_length = total_length - o_length;

      // If we haven't used all our allocated buffer, we do not need shrink it.
      // We just pass the reduced length to NSData and tell it not to free it
      aString = [[NSString alloc] initWithData: [NSData dataWithBytesNoCopy: o_buff
								     length: total_length
							       freeWhenDone:NO]
				      encoding: NSUTF8StringEncoding];

      iconv_close(conv);
      
      // free the whole original buffer, NSData will be invalid, but aString remains fine
      free(o_buff);
      return AUTORELEASE(aString);
#else
      return nil;
#endif
    }

#ifdef MACOSX
  return AUTORELEASE((NSString *)CFStringCreateFromExternalRepresentation(NULL, (CFDataRef)theData, (CFStringEncoding)encoding));
#else    
  return AUTORELEASE([[NSString alloc] initWithData: theData  encoding: encoding]);
#endif  
}


//
//
// Return only charset which we can also later encoode (encodingForCharset:)
#warning return Charset instead?
- (NSString *) charset
{
  NSMutableArray *aMutableArray;
  NSString *aString;
  CWCharset *aCharset;
  NSUInteger i, j;

  aMutableArray = [[NSMutableArray alloc] initWithCapacity: 21];

  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-1"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1252"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-2"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1251"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1253"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1250"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1254"]];
#ifndef MACOSX
  [aMutableArray addObject: [CWCharset charsetForName: @"koi8-r"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"koi8-u"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-3"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-4"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-5"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-6"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-7"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-8"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-9"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-10"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-11"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-13"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-14"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-15"]];
#endif

  // we look for possible charsets, either we find no possible ones
  // or finish the string with a one or more charsets
  i = 0;
  while (i < [self length] && [aMutableArray count] > 0)
    {
      j = 0;
      // For character we remove all charset it cannot be represented with
      while (j < [aMutableArray count])
        {
          if ([[aMutableArray objectAtIndex: j] characterIsInCharset: [self characterAtIndex: i]])
            {
              j++;
            }
          else
            {
              // Character is not in the charset
              [aMutableArray removeObjectAtIndex: j];
            }
        }
      i++;
    }

  NSDebugLog(@"We have %lu charsets: %@", (unsigned long) [aMutableArray count], aMutableArray);
  if ([aMutableArray count])
    {
      aCharset = [aMutableArray objectAtIndex: 0];
      [aMutableArray removeAllObjects];
      aString = [aCharset name];
    }
  else
    {
      // We have no charset, we try to "guess" a default charset
      if ([self canBeConvertedToEncoding: NSISO2022JPStringEncoding])
	{      
	  // ISO-2022-JP is the standard of Japanese character encoding
	  aString = @"iso-2022-jp";
	}
      else
	{
	  // We have no charset, we return a default charset
	  aString = @"utf-8";
	}
    }

  RELEASE(aMutableArray);
  return aString;
}


//
//
//
- (NSString *) modifiedUTF7String
{
#ifndef MACOSX
  NSMutableData *aMutableData, *modifiedData;
  NSString *aString;

  const char *b;
  BOOL escaped;
  unichar ch;
  NSUInteger i, len;

  //
  // We UTF-7 encode _only_ the non-ASCII parts.
  //
  aMutableData = [[NSMutableData alloc] init];
  AUTORELEASE(aMutableData);
  len = [self length];
  
  for (i = 0; i < len; i++)
    {
      ch = [self characterAtIndex: i];
      
      if (IS_PRINTABLE(ch))
	{
	  [aMutableData appendCFormat: @"%c", ch];
	}
      else
	{
	  NSUInteger j;

	  j = i+1;
	  // We got a non-ASCII character, let's get the substring and encode it using UTF-7.
	  while (j < len && !IS_PRINTABLE([self characterAtIndex: j]))
	    {
	      j++;
	    }
	  
	  // Get the substring.
	  [aMutableData appendData: [[self substringWithRange: NSMakeRange(i,j-i)] dataUsingEncoding: NSUTF7StringEncoding]];
	  i = j-1;
	}
    }

  b = [aMutableData bytes];
  len = [aMutableData length];
  escaped = NO;

  //
  // We replace:
  //
  // &   ->  &-
  // +   ->  &
  // +-  ->  +
  // /   ->  ,
  //
  // in order to produce our modified UTF-7 string.
  //
  modifiedData = [[NSMutableData alloc] init];
  AUTORELEASE(modifiedData);

  for (i = 0; i < len; i++, b++)
    {
      if (!escaped && *b == '&')
	{
	  [modifiedData appendCString: "&-"];
	}
      else if (!escaped && *b == '+')
	{
	  if (*(b+1) == '-')
	    {
	      [modifiedData appendCString: "+"];
	    }
	  else
	    {
	      [modifiedData appendCString: "&"];

	      // We enter the escaped mode.
	      escaped = YES;
	    }
	}
      else if (escaped && *b == '/')
	{
	  [modifiedData appendCString: ","];
	}
      else if (escaped && *b == '-')
	{
	  [modifiedData appendCString: "-"];

	  // We leave the escaped mode.
	  escaped = NO;
	}
      else
	{
	  [modifiedData appendCFormat: @"%c", *b];
	}
    }
  
  // If we're still in the escaped mode we haven't added our trailing -,
  // let's add it right now.
  if (escaped)
    {
      [modifiedData appendCString: "-"];
    }

  aString = AUTORELEASE([[NSString alloc] initWithData: modifiedData  encoding: NSASCIIStringEncoding]);

  return (aString != nil ? aString : self);
#else
  return self;
#endif
}

//
//
//
- (NSString *) stringFromModifiedUTF7
{
#ifndef MACOSX
  NSMutableData *aMutableData;

  BOOL escaped;
  unichar ch;
  NSUInteger i, len;

  aMutableData = [[NSMutableData alloc] init];
  AUTORELEASE(aMutableData);

  len = [self length];
  escaped = NO;

  //
  // We replace:
  //
  // &   ->  +
  // &-  ->  &
  // ,   ->  /
  //
  // If we are in escaped mode. That is, between a &....-
  //
  for (i = 0; i < len; i++)
    {
      ch = [self characterAtIndex: i];
      
      if (!escaped && ch == '&')
	{
	  if ( (i+1) < len && [self characterAtIndex: (i+1)] != '-' )
	    {
	      [aMutableData appendCString: "+"];
	      
	      // We enter the escaped mode.
	      escaped = YES;
	    }
	  else
	    {
	      // We replace &- by &
	      [aMutableData appendCString: "&"];
	      i++;
	    }
	}
      else if (escaped && ch == ',')
	{
	  [aMutableData appendCString: "/"];
	}
      else if (escaped && ch == '-')
	{
	  [aMutableData appendCString: "-"];

	  // We leave the escaped mode.
	  escaped = NO;
	}
      else
	{
	  [aMutableData appendCFormat: @"%c", ch];
	}
    }

  return AUTORELEASE([[NSString alloc] initWithData: aMutableData  encoding: NSUTF7StringEncoding]);
#else
  return nil;
#endif
}


//
//
//
- (BOOL) hasREPrefix
{
  if ([self hasCaseInsensitivePrefix: @"re:"] ||
      [self hasCaseInsensitivePrefix: @"re :"] ||
      [self hasCaseInsensitivePrefix: _(@"PantomimeReferencePrefix")] ||
      [self hasCaseInsensitivePrefix: _(@"PantomimeResponsePrefix")])
    {
      return YES;
    }
  
  return NO;
}



//
//
//
- (NSString *) stringByReplacingOccurrencesOfCharacter: (unichar) theTarget
                                         withCharacter: (unichar) theReplacement
{
  NSMutableString *aMutableString;
  NSUInteger len, i;
  unichar c;

  if (!theTarget || !theReplacement || theTarget == theReplacement)
    {
      return self;
    }

  len = [self length];
  
  aMutableString = [NSMutableString stringWithCapacity: len];

  for (i = 0; i < len; i++)
    {
      c = [self characterAtIndex: i];
      
      if (c == theTarget)
	{
	  [aMutableString appendFormat: @"%c", theReplacement];
	}
      else
	{
	  [aMutableString appendFormat: @"%c", c];
	}
    }

  return aMutableString;
}

//
//
//
- (NSString *) stringByDeletingLastPathComponentWithSeparator: (unichar) theSeparator
{
  NSUInteger i;
  NSUInteger c;
  
  c = [self length];

  for (i = c; i > 0; i--)
    {
      if ([self characterAtIndex: i-1] == theSeparator)
	{
	  return [self substringToIndex: i-1];
	}
    }

  return @"";
}

//
// 
//
- (NSString *) stringByDeletingFirstPathSeparator: (unichar) theSeparator
{
  if ([self length] && [self characterAtIndex: 0] == theSeparator)
    {
      return [self substringFromIndex: 1];
    }
  
  return self;
}

//
//
//
- (BOOL) is7bitSafe
{
  NSUInteger i, len;
  
  // We search for a non-ASCII character.
  len = [self length];
  
  for (i = 0; i < len; i++)
    {
      if ([self characterAtIndex: i] > 0x007E)
	{
	  return NO;
	}
    }
  
  return YES;
}

//
//
//
- (NSData *) dataUsingEncodingFromPart: (CWPart *) thePart
{
  return [self dataUsingEncodingFromPart: thePart  allowLossyConversion: NO];
}

//
//
//
- (NSData *) dataUsingEncodingFromPart: (CWPart *) thePart
                  allowLossyConversion: (BOOL) lossy
{
#ifdef MACOSX
  // Use the CF decoding to get the data, bypassing Foundation...
  unsigned long enc;
  NSData *data;
  
  enc = [NSString encodingForPart: thePart convertToNSStringEncoding: NO];
  data = (NSData *)CFStringCreateExternalRepresentation(NULL, (CFStringRef)self,
							(CFStringEncoding)enc, (lossy) ? '?' : 0);
  return [data autorelease];
#else
  return [self dataUsingEncoding: [object_getClass(self)
					encodingForPart: thePart]
	    allowLossyConversion: lossy];
#endif
}


//
//
//
- (NSData *) dataUsingEncodingWithCharset: (NSString *) theCharset
{
  return [self dataUsingEncodingWithCharset: theCharset  allowLossyConversion: NO];
}


//
//
//
- (NSData *) dataUsingEncodingWithCharset: (NSString *) theCharset
                     allowLossyConversion: (BOOL)lossy
{
#ifdef MACOSX
  // Use the CF decoding to get the data, bypassing Foundation...
  unsigned long enc;
  NSData *data;
  
  enc = [NSString encodingForCharset: [theCharset dataUsingEncoding: NSASCIIStringEncoding]
	     convertToNSStringEncoding: NO];
  data = (NSData *)CFStringCreateExternalRepresentation(NULL, (CFStringRef)self,
							(CFStringEncoding)enc, (lossy) ? '?' : 0);
  return [data autorelease];
#else
  return [self dataUsingEncoding: 
		[object_getClass(self) 
		    encodingForCharset: 
			[theCharset dataUsingEncoding: NSASCIIStringEncoding]]
	allowLossyConversion: lossy];
#endif
}


//
//
//
+ (NSString *) stringFromRecipients: (NSArray *) theRecipients
			       type: (PantomimeRecipientType) theRecipientType
{
  CWInternetAddress *anInternetAddress;
  NSMutableString *aMutableString;
  NSUInteger i, count;
  
  aMutableString = [[NSMutableString alloc] init];
  count = [theRecipients count];

  for (i = 0; i < count; i++)
    {
      anInternetAddress = [theRecipients objectAtIndex: i];
      
      if ([anInternetAddress type] == theRecipientType)
	{
	  [aMutableString appendFormat: @"%@, ", [anInternetAddress stringValue]];
	}
    }
  
  return AUTORELEASE(aMutableString); 
}

@end
