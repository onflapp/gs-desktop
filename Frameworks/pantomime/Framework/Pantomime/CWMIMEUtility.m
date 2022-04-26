/*
**  CWMIMEUtility.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2014-2018 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
**          Sebastian Reitenbach
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

#import <Pantomime/CWMIMEUtility.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWMessage.h>
#import <Pantomime/CWMIMEMultipart.h>
#import <Pantomime/NSString+Extensions.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/CWPart.h>
#import <Pantomime/CWMD5.h>
#import <Pantomime/CWUUFile.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSValue.h>

#include <ctype.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

//
// C functions
//
char ent(char **ref);
char *striphtml(char *s, int encoding);
NSString *unique_id();

static const char *hexDigit = "0123456789ABCDEF";
static unsigned seed_count = 1;

@implementation CWMIMEUtility

//
// See RFC2047.
// It supports:
// 
// Abcd =?ISO-8859-1?Q?=E8fgh?=
// =?iso-8859-1?Q?ab=E7de?= =?iso-8859-1?Q?_?= =?iso-8859-1?Q?oo=F4oo?=
// Abd =?ISO-8859-1?Q?=E8?= fghijklmn
//
//
+ (NSString *) decodeHeader: (NSData *) theData
		    charset: (NSString *) theCharset
{
  NSMutableString *aMutableString;
  NSData *charset, *encoded_text;
  NSString *aString;
  
  NSUInteger i, length, start, i_charset, i_encoding, end; 
  const char *bytes;
 
  BOOL ignore_span;
  char encoding;

  // We first verify for a nil value
  if (theData == nil || (length = [theData length]) == 0)
    {
      return @"";
    }
  
  // We check for the ISO-2022-JP announcer sequence
  if ([theData hasCPrefix: "\e$B"])
    {
      return AUTORELEASE([[NSString alloc] initWithData: theData  encoding: NSISO2022JPStringEncoding]);
    }

  bytes = [theData bytes];
  
  aMutableString = [[NSMutableString alloc] initWithCapacity: length];
  
  start = i = 0;
  ignore_span = NO;
  
  while (i < (length - 1))
    {
      if (bytes[i] != '=' || bytes[i+1] != '?')
	{
	  if (bytes[i] > 32)
	    {
	      ignore_span = NO;
	    }
	  
	  i++;
	  continue;
	}
      
      if (i != start && !ignore_span)
	{
	  aString = nil;

	  if (theCharset)
	    {  
	      aString = [NSString stringWithData: [NSData dataWithBytes: bytes+start  length: i-start]
				  charset: [theCharset dataUsingEncoding: NSASCIIStringEncoding]];
	      RETAIN(aString);
	    }
	  
	  if (!aString)
	    {
	      aString = [[NSString alloc] initWithCString: bytes+start  length: i-start];
	    }

	  [aMutableString appendString: aString];
	  DESTROY(aString);
	}
      
      start = i;
      
      // skip the =? and one character (or it isn't valid)
      i += 3; 
      while (i < length && bytes[i] != '?') 
	{
	  i++;
	}
      
      if ( i == length) 
	{
	  break;
	}
      
      i_charset = i;
      
      // encoding is a single character
      if (i+2 >= length)
	{
	  break;
	}
      
      encoding = bytes[i+1];
      
      if (bytes[i+2] != '?')
	{
	  break;
	}
      
      i += 3;
      i_encoding = i;
      
      while (i <length && bytes[i] != '?')
	{
	  i++;
	}
      
      if (i+1 >= length)
	{
	  break;
	}
      
      if (bytes[i+1] != '=')
	{
	  break;
	}

      end = i;
      i += 2;
      
      if (theCharset)
	{
	  charset = [theCharset dataUsingEncoding: NSASCIIStringEncoding];
	}
      else
	{
          NSRange charsetRange;
          charsetRange = NSMakeRange(start+2,i_charset-start-2);
	  charset = [theData subdataWithRange: charsetRange];
	}
      
      encoded_text = [theData subdataWithRange: NSMakeRange(i_encoding,end-i_encoding)];
      
      if (encoding == 'q' || encoding == 'Q')
	{
	  aString = [NSString stringWithData: [encoded_text decodeQuotedPrintableInHeader: YES]
			      charset: charset];
	}
      else if (encoding == 'b' || encoding== 'B')
	{
          NSData *decodedData;
        
          decodedData = [encoded_text decodeBase64];
	  aString = [NSString stringWithData: decodedData
			      charset: charset];
	}
      else
	{
	  continue;
	}

      if (aString)
	{
          [aMutableString appendString: aString];
        }
      aString = nil;
      start = i;
      ignore_span = YES;
    }
  
  // always append end of string, even if there was a space
  i = length;
  if (i > start)
    {
      aString = nil;

      if (theCharset)
      	{  
	  aString = [NSString stringWithData: [NSData dataWithBytes: bytes+start  length: i-start]
			      charset: [theCharset dataUsingEncoding: NSASCIIStringEncoding]];
	  RETAIN(aString);
      	}
      
      if (!aString)
	{
	  aString = [[NSString alloc] initWithCString: bytes+start  length: i-start];
      	}
      
      [aMutableString appendString: aString];
      DESTROY(aString);
    }
  
  return AUTORELEASE(aMutableString);
}


//
//
//
+ (NSData *) globallyUniqueBoundary
{
  NSMutableData *aMutableData;
  
  aMutableData = [[NSMutableData alloc] init];
  [aMutableData appendBytes: "=_"  length: 2];
  [aMutableData appendCFormat: @"%@", unique_id()];

  return AUTORELEASE(aMutableData);
}


//
// Instead of using [[NSHost currentHost] name],
// we use gethostname(). This is due to the fact
// that NSHost's -name method will block for a good
// amount of time if DNS resolutions can't be made.
//
+ (NSData *) globallyUniqueID
{
  NSMutableData *aMutableData;
  char s[65];
  
 
  aMutableData = [[NSMutableData alloc] init];
  [aMutableData appendCFormat: @"%@", unique_id()];
 
  memset(s, 0, sizeof(s));
  gethostname(s, sizeof(s)-1);
  [aMutableData appendCFormat: @"@%s", s];

  return AUTORELEASE(aMutableData);
}


//
// FIXME: Should we really use NSUTF8StringEncoding in base64?
//
+ (NSData *) encodeHeader: (NSString *) theText
		  charset: (NSString *) theCharset
		 encoding: (PantomimeEncoding) theEncoding
{
  NSData *aData;
  
  // Initial verification
  if (!theText || [theText length] == 0)
    {
      return [NSData data];
    }
  
  aData = [theText dataUsingEncoding: [NSString encodingForCharset:
						  [theCharset dataUsingEncoding: NSASCIIStringEncoding]]];
  
  if (theEncoding == PantomimeEncodingQuotedPrintable)
    {
      return [aData encodeQuotedPrintableWithLineLength: 0  inHeader: YES];
    }
  else if (theEncoding == PantomimeEncodingBase64)
    {
      return [aData encodeBase64WithLineLength: 0];
    }
  //
  // FIXME: What should we do here, should we just return the 'aData' w/o 
  //        encoding it or should we generate an exception?
  else
    {
      return aData; 
    }
}


//
// The format returned is for example:
//
// =?ISO-8859-1?B?....?=
// 
// This format is known as an encoded-word defined in RFC2047.
// If the word doesn't need to be encoded, it's just returned as is.
//
// FIXME: We should verify that the length doesn't exceed 75 chars.
//
#warning remove/combine or leave and document
+ (NSData *) encodeWordUsingBase64: (NSString *) theWord
		      prefixLength: (int) thePrefixLength
{
  // Initial verification
  if (!theWord || [theWord length] == 0)
    {
      return [NSData data];
    }
  else if ([theWord is7bitSafe])
    {
      return [theWord dataUsingEncoding: NSASCIIStringEncoding];
    }
  else
    {
      NSMutableData *aMutableData;
      NSString *aCharset;

      aMutableData = [[NSMutableData alloc] init];
      aCharset = [theWord charset];

      [aMutableData appendCFormat: @"=?%@?b?", aCharset];
      [aMutableData appendData: [CWMIMEUtility encodeHeader: theWord
					       charset: aCharset
					       encoding: PantomimeEncodingBase64]];
      [aMutableData appendCString: "?="];

      return AUTORELEASE(aMutableData);
    }

  // Never reached.
  return nil;
}


//
// The format returned is for example:
//
// =?ISO-8859-1?Q?=E8fgh?=
//
// This format is known as an encoded-word defined in RFC2047.
// If the word doesn't need to be encoded, it's just returned as it.
//
// The string returned will NOT be more than 75 characters long
// for each folded part of the original string.
//
#warning remove/combine or leave and document
+ (NSData *) encodeWordUsingQuotedPrintable: (NSString *) theWord
			       prefixLength: (NSUInteger) thePrefixLength
{  
  NSMutableString *aMutableString;
  NSMutableArray *aMutableArray;
  NSString *aCharset, *aString;
  NSMutableData *aMutableData;
  NSScanner *aScanner;
  
  NSUInteger i, count;
  NSUInteger previousLocation, currentLocation;
  BOOL mustUseEncoding;

  if (!theWord || [theWord length] == 0 )
    {
      return [NSData data];
    } 

  // If it's not an ASCII string, we must use the encoding!
  mustUseEncoding = ![theWord is7bitSafe];
  
  aCharset = nil;
  
  if (mustUseEncoding)
    {
      aCharset = [theWord charset];
    }
  
  aMutableString = [[NSMutableString alloc] init];
  
  aMutableArray = [[NSMutableArray alloc] init];
  AUTORELEASE(aMutableArray);
  
  // We initialize our scanner with the content of our word
  aScanner = [[NSScanner alloc] initWithString: theWord];
  
  previousLocation = 0;
  
  while ([aScanner scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]  intoString: NULL])
    {
      NSUInteger length;
      
      currentLocation = [aScanner scanLocation]; 
	  
      // aString contains the substring WITH the spaces present BEFORE the word and AFTER the last aString.
      // 
      // For example, the result of "this is a test" will be
      //
      // aString = "this"
      // aString = " is"
      // aString = " a"
      // aString = " test"
      //
      aString = [theWord substringWithRange: NSMakeRange(previousLocation, currentLocation - previousLocation)];

      if (mustUseEncoding)
	{
	  // Our 'initial' length contains =?iso-8859-x?q? and ?=
	  length = 18;
	  length += [[CWMIMEUtility encodeHeader: [NSString stringWithFormat: @"%@%@", aMutableString, aString]
				    charset: aCharset
				    encoding: PantomimeEncodingQuotedPrintable] length];
	}
      else
	{
	  length = [aMutableString length] + [aString length];
	}

      // If we are on the first line, we must consider the prefix length.
      // For example, the prefix length might be the length of the string "Subject: "
      if ([aMutableArray count] == 0)
	{
	  length += thePrefixLength;
	}

      if (length > 75)
	{
	  [aMutableArray addObject: aMutableString];

	  RELEASE(aMutableString);
	  aMutableString = [[NSMutableString alloc] init];
	}
      
      [aMutableString appendString: aString];
      previousLocation = currentLocation;
    }
  
  // We add our last string to the array.
  [aMutableArray addObject: aMutableString];
  RELEASE(aMutableString);
  
  RELEASE(aScanner);
      
  aMutableData = [[NSMutableData alloc] init];
  
  count = [aMutableArray count];
  for (i = 0; i < count; i++)
    {
      aString = [aMutableArray objectAtIndex: i];

      // We must append a space (' ') before each folded line.
      if (i > 0)
	{
	  [aMutableData appendCString: " "];
	}
	  
      if (mustUseEncoding)
	{
	  [aMutableData appendCFormat: @"=?%@?q?", aCharset];
	  [aMutableData appendData: [CWMIMEUtility encodeHeader: aString
						   charset: aCharset
						   encoding: PantomimeEncodingQuotedPrintable] ];
	  [aMutableData appendCString: "?="];
	}
      else
	{
	  [aMutableData appendData: [aString dataUsingEncoding: NSASCIIStringEncoding]];
	}
      
      // We if it is our last string, we must NOT append the \n
      if (!(i == (count-1)))
	{
	  [aMutableData appendCString: "\n"];
	}
    }

  return AUTORELEASE(aMutableData);
}
  

//
//
//
+ (CWMessage *) compositeMessageContentFromRawSource: (NSData *) theData
{
  return AUTORELEASE([[CWMessage alloc] initWithData: theData]);
}


//
// FIXME: whitespace after boundary markers
// 
+ (CWMIMEMultipart *) compositeMultipartContentFromRawSource: (NSData *) theData
						    boundary: (NSData *) theBoundary
{
  CWMIMEMultipart *aMimeMultipart;
  
  NSMutableData *aMutableData;
  NSArray *allParts;
  NSRange aRange;
  NSUInteger i, count;
  
  aMimeMultipart = [[CWMIMEMultipart alloc] init];

  aMutableData = [[NSMutableData alloc] init];
  [aMutableData appendBytes: "--"  length: 2];
  [aMutableData appendData: theBoundary];

  // We first skip everything before the first boundary
  aRange = [theData rangeOfData: aMutableData];
   
  if (aRange.length && aRange.location)
    {
      theData = [theData subdataFromIndex: (aRange.location + aRange.length)];
    }
  
  [aMutableData setLength: 0];
  [aMutableData appendBytes: "\n--"  length: 3];
  [aMutableData appendData: theBoundary];
  
  // Add terminating 0 so we can use it as a C string below
  [aMutableData appendBytes: "\0" length: 1];

  // We split this mime body part into multiple parts since we have various representations
  // of the actual body part.
  allParts = [theData componentsSeparatedByCString: [aMutableData bytes]];
  count = [allParts count];
  RELEASE(aMutableData);

  for (i = 0; i < count; i++)
    {
      CWPart *aPart;
      NSData *aData;

      aData = [allParts objectAtIndex: i];
      
      if (aData && [aData length] > 0)
	{
	  // This is the last part. Ignore everything past the end marker
	  if ([aData hasCPrefix: "--\n"] ||
	      ([aData length] == 2 && [aData hasCPrefix: "--"]))
	    {
	      break;
	    }
	  
	  // We then skip the first character since it's a \n (the one at the end of the boundary)
	  if ([aData hasCPrefix: "\n"])
	    {
	      aData = [aData subdataFromIndex: 1];
	    }
	
	  aPart = [[CWPart alloc] initWithData: aData];
	  [aPart setSize: [aData length]];
	  [aMimeMultipart addPart: aPart];
	  RELEASE(aPart);
	}
    }

  return AUTORELEASE(aMimeMultipart);
}


//
//
// 
+ (id) discreteContentFromRawSource: (NSData *) theData
			   encoding: (PantomimeEncoding) theEncoding
{
  if (theEncoding == PantomimeEncodingQuotedPrintable)
    {
      return [theData decodeQuotedPrintableInHeader: NO];
    }
  else if (theEncoding == PantomimeEncodingBase64)
    {
      return [[theData dataByRemovingLineFeedCharacters] decodeBase64];
    }
  
  return theData;
}


//
//
//
+ (void) setContentFromRawSource: (NSData *) theData
                          inPart: (CWPart *) thePart
{
  NSAutoreleasePool *pool;
 
  // We create a temporary autorelease pool since this method can be
  // memory consuming on our default autorelease pool.
  pool = [[NSAutoreleasePool alloc] init];

  //
  // Composite types (message/multipart).
  //
  if ([thePart isMIMEType: @"message"  subType: @"rfc822"])
    {
      NSData *aData;

      aData = theData;

      // We verify the Content-Transfer-Encoding, this part could be base64 encoded.
      if ([thePart contentTransferEncoding] == PantomimeEncodingBase64)
	{
	  NSMutableData *aMutableData;

	  aData = [[theData dataByRemovingLineFeedCharacters] decodeBase64];
	  
	  aMutableData = [NSMutableData dataWithData: aData];
	  [aMutableData replaceCRLFWithLF];
	  aData = aMutableData;
	}

      [thePart setContent: [CWMIMEUtility compositeMessageContentFromRawSource: aData]];
    }
  else if ([thePart isMIMEType: @"multipart"  subType: @"*"])
    {
      [thePart setContent: [CWMIMEUtility compositeMultipartContentFromRawSource: theData
					  boundary: [thePart boundary]]];
    }
  // 
  // Discrete types (text/application/audio/image/video) or any "unsupported Content-Type:s"
  //
  // text/*
  // image/*
  // application/*
  // audio/*
  // video/*
  //
  // We also treat those composite type as discrete types:
  //
#warning test extensively those
  // message/delivery-status
  // message/disposition-notification
  //
  else
    {
      [thePart setContent: [CWMIMEUtility discreteContentFromRawSource: theData
					  encoding: [thePart contentTransferEncoding]]];
    }
  
  RELEASE(pool);
}


//
//
//
+ (NSData *) plainTextContentFromPart: (CWPart *) thePart
{
  NSData *aContent;

  aContent = (NSData *)[thePart content];

  //
  // If it's a text/html part, we must remove all the formatting codes and 
  // keep only the 'real' text contained in that part. We should do the
  // same for text/rtf or text/enriched parts.
  //
  if ([thePart isMIMEType: @"text"  subType: @"html"])
    {
      char *buf, *bytes;
 
      buf = (char *)malloc(([aContent length]+1)*sizeof(char));
      memset(buf, 0, [aContent length]+1);
      memcpy(buf, [aContent bytes], [aContent length]);

      bytes = striphtml(buf, [NSString encodingForPart: thePart]);
      free(buf);

      aContent = [NSData dataWithBytesNoCopy: bytes  length: strlen(bytes)  freeWhenDone: YES];
    }
  
  return aContent;
}

@end


//
// This C function has been written by Abhijit Menon-Sen <ams@wiw.org>
// This code is in the public domain.
//
char *striphtml(char *s, int encoding)
{
  char c, *t, *text;

  if ((t = text = malloc(strlen(s)+1)) == NULL)
    {
      return NULL;
    }

  while ((c = *s++))
    {
      if (c == '<')
        {
          /*
           * Ignore everything to the end of this tag or sgml comment.
           */
          if (s[0] == '!' && s[1] == '-' && s[2] == '-')
            {
              s += 3;
              while ((c = *s++))
                {
                  if (c == '-' && s[0] == '-' && s[1] == '>')
                    {
                      s += 2;
                      break;
                    }
                }
            }
          else
            {
              while ((c = *s++))
                {
                  if (c == '>')
                    {
                      break;
                    }
                }
            }
        }
      else if (c == '&')
        {
	  NSString *aString;

	  c = ent(&s);
	  aString = AUTORELEASE([[NSString alloc] initWithBytes: &c  length: 1  encoding: NSISOLatin1StringEncoding]);

	  if ([aString length])
	    {
	      NSData *aData;

	      aData = [aString dataUsingEncoding: encoding];
	      
	      if (aData)
		{
		  char *bytes;
		  NSUInteger len;
		  
		  bytes = (char *)[aData bytes];
		  len = [aData length];
		  
		  while (len--)
		    {
		      *t++ = *bytes;
		      bytes++;
		    }
		}
	    }
	}
      else
        {
          *t++ = c;
        }
    }

  *t = '\0';

  return text;
}


//
// This C function has been written by Abhijit Menon-Sen <ams@wiw.org>
// This code is in the public domain.
//
char ent(char **ref)
{
  unsigned i;
  char c = ' ', *s = *ref, *t = s;
  
  struct {
    char *name;
    char chr;
  } refs[] = {
    { "lt"    , '<'       },
    { "gt"    , '>'       },
    { "amp"   , '&'       },
    { "quot"  , '"'       },
    { "nbsp"  , (char)160 },
    { "iexcl" , (char)161 },
    { "cent"  , (char)162 },
    { "pound" , (char)163 },
    { "curren", (char)164 },
    { "yen"   , (char)165 },
    { "brvbar", (char)166 },
    { "sect"  , (char)167 },
    { "uml"   , (char)168 },
    { "copy"  , (char)169 },
    { "ordf"  , (char)170 },
    { "laquo" , (char)171 },
    { "not"   , (char)172 },
    { "shy"   , (char)173 },
    { "reg"   , (char)174 },
    { "macr"  , (char)175 },
    { "deg"   , (char)176 },
    { "plusmn", (char)177 },
    { "sup2"  , (char)178 },
    { "sup3"  , (char)179 },
    { "acute" , (char)180 },
    { "micro" , (char)181 },
    { "para"  , (char)182 },
    { "middot", (char)183 },
    { "cedil" , (char)184 },
    { "sup1"  , (char)185 },
    { "ordm"  , (char)186 },
    { "raquo" , (char)187 },
    { "frac14", (char)188 },
    { "frac12", (char)189 },
    { "frac34", (char)190 },
    { "iquest", (char)191 },
    { "Agrave", (char)192 },
    { "Aacute", (char)193 },
    { "Acirc" , (char)194 },
    { "Atilde", (char)195 },
    { "Auml"  , (char)196 },
    { "Aring" , (char)197 },
    { "AElig" , (char)198 },
    { "Ccedil", (char)199 },
    { "Egrave", (char)200 },
    { "Eacute", (char)201 },
    { "Ecirc" , (char)202 },
    { "Euml"  , (char)203 },
    { "Igrave", (char)204 },
    { "Iacute", (char)205 },
    { "Icirc" , (char)206 },
    { "Iuml"  , (char)207 },
    { "ETH"   , (char)208 },
    { "Ntilde", (char)209 },
    { "Ograve", (char)210 },
    { "Oacute", (char)211 },
    { "Ocirc" , (char)212 },
    { "Otilde", (char)213 },
    { "Ouml"  , (char)214 },
    { "times" , (char)215 },
    { "Oslash", (char)216 },
    { "Ugrave", (char)217 },
    { "Uacute", (char)218 },
    { "Ucirc" , (char)219 },
    { "Uuml"  , (char)220 },
    { "Yacute", (char)221 },
    { "THORN" , (char)222 },
    { "szlig" , (char)223 },
    { "agrave", (char)224 },
    { "aacute", (char)225 },
    { "acirc" , (char)226 },
    { "atilde", (char)227 },
    { "auml"  , (char)228 },
    { "aring" , (char)229 },
    { "aelig" , (char)230 },
    { "ccedil", (char)231 },
    { "egrave", (char)232 },
    { "eacute", (char)233 },
    { "ecirc" , (char)234 },
    { "euml"  , (char)235 },
    { "igrave", (char)236 },
    { "iacute", (char)237 },
    { "icirc" , (char)238 },
    { "iuml"  , (char)239 },
    { "eth"   , (char)240 },
    { "ntilde", (char)241 },
    { "ograve", (char)242 },
    { "oacute", (char)243 },
    { "ocirc" , (char)244 },
    { "otilde", (char)245 },
    { "ouml"  , (char)246 },
    { "divide", (char)247 },
    { "oslash", (char)248 },
    { "ugrave", (char)249 },
    { "uacute", (char)250 },
    { "ucirc" , (char)251 },
    { "uuml"  , (char)252 },
    { "yacute", (char)253 },
    { "thorn" , (char)254 },
    { "yuml"  , (char)255 }
  };
  
  while (isalpha((int)(unsigned char)*s) || isdigit((int)(unsigned char)*s) || *s == '#')
    s++;
  
  for (i = 0; i < sizeof(refs)/sizeof(refs[0]); i++) {
    if (strncmp(refs[i].name, t, s-t) == 0) {
      c = refs[i].chr;
      break;
    }
  }
  
  if (*s == ';')
    s++;
  
  *ref = s;
  return c;
}


//
//
//
NSString *unique_id()
{
  NSMutableData *aMutableData;
  CWMD5 *aMD5;
  
  char random_data[9];
  time_t curtime;
  int i, pid;
  
  pid = getpid();
  time(&curtime);
  
  for (i = 0; i < 8; i++)
    {
      srand(seed_count++);
      random_data[i] = hexDigit[rand()&0xf];
    }
  random_data[8] = '\0';
  
  aMutableData = [[NSMutableData alloc] init];
  [aMutableData appendCFormat: @"%d.%ld%s", pid, (long)curtime, random_data];
  aMD5 = [[CWMD5 alloc] initWithData: aMutableData];
  RELEASE(aMutableData);
  AUTORELEASE(aMD5);
  
  [aMD5 computeDigest];
  
  return [aMD5 digestAsString];
}
