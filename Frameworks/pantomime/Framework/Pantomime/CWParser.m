/*
**  CWParser.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2013-2020 The GNUstep Team
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
**          Sebastian Reitenbach
**          German Arias
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

#import <Pantomime/CWParser.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWFlags.h>
#import <Pantomime/CWInternetAddress.h>
#import <Pantomime/CWMessage.h>
#import <Pantomime/CWMIMEUtility.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/NSString+Extensions.h>

#include <stdlib.h>
#include <string.h>  // For NULL on OS X
#include <ctype.h>
#include <stdio.h>
//#include <Pantomime/elm_defs.h>

#import <Foundation/NSBundle.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>

//
//
//
static char *month_name[12] = {"jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"};

static struct _timezone {
  char *name;          /* time zone name */
  int offset;         /* offset, in minutes, EAST of GMT */
} timezone_info[] = {
  
  /* the following are from RFC-822 */
  { "ut", 0 },
  { "gmt", 0 },
  { "est", -5*3600 },   { "edt", -4*3600 },       /* USA eastern standard */
  { "cst", -6*3600 },   { "cdt", -5*3600 },       /* USA central standard */
  { "mst", -7*3600 },   { "mdt", -6*3600 },       /* USA mountain standard */
  { "pst", -8*3600 },   { "pdt", -7*3600 },       /* USA pacific standard */
  { "z", 0 }, /* zulu time (the rest of the military codes are bogus) */
  
  /* popular European timezones */
  { "wet", 0*3600 },                            /* western european */
  { "met", 1*3600 },                            /* middle european */
  { "eet", 2*3600 },                            /* eastern european */
  { "bst", 1*3600 },                            /* ??? british summer time */
  
  /* Canadian timezones */
  { "ast", -4*3600 },   { "adt", -3*3600 },       /* atlantic */
	{ "nst", -3*1800 },{ "ndt", -2*1800 },          /* newfoundland */
  { "yst", -9*3600 },   { "ydt", -8*3600 },       /* yukon */
	{ "hst", -10*3600 },                            /* hawaii (not really canada) */
  
  /* Asian timezones */
  { "jst", 9*3600 },                            /* japan */
  { "sst", 8*3600 },                            /* singapore */
  
  /* South-Pacific timezones */
  { "nzst", 12*3600 },  { "nzdt", 13*3600 },      /* new zealand */
  { "wst", 8*3600 },    { "wdt", 9*3600 },        /* western australia */
  
  /*
   * Daylight savings modifiers.  These are not real timezones.
   * They are used for things like "met dst".  The "met" timezone
   * is 1*3600, and applying the "dst" modifier makes it 2*3600.
   */
  { "dst", 1*3600 },
  { "dt", 1*3600 },
  { "st", 1*3600 }
};

//
//
//
int next_word(unsigned char *buf, NSUInteger start, NSUInteger len, unsigned char *word)
{
  unsigned char *p;
  NSUInteger i;

  for (p = buf+start, i = start; (isspace(*p) || *p == ','); ++p, ++i);
  
  if (start >= len) return -1;

  while (i < len && !(isspace(*p) || *p == ','))
    {
      *word++ = *p++;
      i++;
    }
  
  *word = '\0';

  return (int)((NSUInteger)(p-buf)-start);
}

//
// private methods
//
@interface CWParser (Private)
+ (id) _parameterValueUsingLine: (NSData *) theLine
			  range: (NSRange) theRange
			 decode: (BOOL) theBOOL
			charset: (NSString *) theCharset;
@end


//
//
//
@implementation CWParser

+ (void) parseContentDescription: (NSData *) theLine
                          inPart: (CWPart *) thePart
{
  NSData *aData;

  aData = [[theLine subdataFromIndex: 20] dataByTrimmingWhiteSpaces];

  if (aData && [aData length])
    {
      [thePart setContentDescription: [[aData dataFromQuotedData] asciiString] ];
    }
}


//
//
//
+ (void) parseContentDisposition: (NSData *) theLine
                          inPart: (CWPart *) thePart
{  
  if ([theLine length] > 21)
    {
      NSData *aData;
      NSRange aRange;

      aData = [theLine subdataFromIndex: 21];
      aRange = [aData rangeOfCString: ";"];
      
      if (aRange.length > 0)
	{
	  NSRange filenameRange;
	  
	  // We set the content disposition to this part
	  [thePart setContentDisposition: ([[[aData subdataWithRange: NSMakeRange(0, aRange.location)] asciiString] caseInsensitiveCompare: @"inline"] == NSOrderedSame ? PantomimeInlineDisposition : PantomimeAttachmentDisposition)];
	  
	  // We now decode our filename
	  filenameRange = [aData rangeOfCString: "filename"];

	  if (filenameRange.length > 0)
	    {
	      [thePart setFilename: [CWParser _parameterValueUsingLine: aData  range: filenameRange  decode: YES  charset: [thePart defaultCharset]]];
	    }
	}
      else
	{
	  [thePart setContentDisposition: ([[[aData dataByTrimmingWhiteSpaces] asciiString] caseInsensitiveCompare: @"inline"] == NSOrderedSame ? PantomimeInlineDisposition : PantomimeAttachmentDisposition)];
	}
    }
  else
    {
      [thePart setContentDisposition: PantomimeAttachmentDisposition];
    }
}


//
//
//
+ (void) parseContentID: (NSData *) theLine
		 inPart: (CWPart *) thePart
{
  if ([theLine length] > 12)
    {
      NSData *aData;
      
      aData = [theLine subdataFromIndex: 12];
      
      if ([aData hasCPrefix: "<"] && [aData hasCSuffix: ">"])
	{
	  [thePart setContentID: [[aData subdataWithRange: NSMakeRange(1, [aData length]-2)] asciiString]];
	}
      else
	{
	  [thePart setContentID: [aData asciiString]];
	}
    }
  else
    {
      [thePart setContentID: @""];
    }
}


//
//
//
+ (void) parseContentTransferEncoding: (NSData *) theLine
                               inPart: (CWPart *) thePart
{
  if ([theLine length] > 26)
    {
      NSData *aData;
      
      aData = [[theLine subdataFromIndex: 26] dataByTrimmingWhiteSpaces];
      
      if ([aData caseInsensitiveCCompare: "quoted-printable"] == NSOrderedSame)
	{
	  [thePart setContentTransferEncoding: PantomimeEncodingQuotedPrintable];
	}
      else if ([aData caseInsensitiveCCompare: "base64"] == NSOrderedSame)
	{
	  [thePart setContentTransferEncoding: PantomimeEncodingBase64];
	}
      else if ([aData caseInsensitiveCCompare: "8bit"] == NSOrderedSame)
	{
	  [thePart setContentTransferEncoding: PantomimeEncoding8bit];
	}
      else if ([aData caseInsensitiveCCompare: "binary"] == NSOrderedSame)
	{
	  [thePart setContentTransferEncoding: PantomimeEncodingBinary];
	}
      else
	{
	  [thePart setContentTransferEncoding: PantomimeEncodingNone];
	}
    }
  else
    {
      [thePart setContentTransferEncoding: PantomimeEncodingNone];
    }
}


//
//
//
+ (void) parseContentType: (NSData *) theLine
		   inPart: (CWPart *) thePart
{
  NSRange aRange;
  NSData *aData;
  NSUInteger x;

  if ([theLine length] <= 14)
    {
      [thePart setContentType: @"text/plain"];
      return;
    }

  aData = [[theLine subdataFromIndex: 13] dataByTrimmingWhiteSpaces];
  if (aData == nil || [aData length] == 0)
    {
      [thePart setContentType: @"text/plain"];
      return;
    }

  // We first skip the parameters, if we need to
  x = [aData indexOfCharacter: ';'];
  if (x != NSNotFound && x > 0)
    {
      aData = [aData subdataToIndex: x];
    } 
  
  // We see if there's a subtype specified for text, if none was specified, we append "/plain"
  x = [aData indexOfCharacter: '/'];

  if (x == NSNotFound && [aData hasCaseInsensitiveCPrefix: "text"])
    {
      [thePart setContentType: [[[aData asciiString] stringByAppendingString: @"/plain"] lowercaseString]];
    }
  else
    {
      [thePart setContentType: [[aData asciiString] lowercaseString]];
    }

  //
  // We decode our boundary (if we need to)
  //
  aRange = [theLine rangeOfCString: "boundary"  options: NSCaseInsensitiveSearch];
  
  if (aRange.length > 0)
    {
      [thePart setBoundary: [CWParser _parameterValueUsingLine: theLine  range: aRange  decode: NO  charset: nil]];
    }

  //
  // We decode our charset (if we need to)
  //
  aRange = [theLine rangeOfCString: "charset"  options: NSCaseInsensitiveSearch];
  
  if (aRange.length > 0)
    {
      [thePart setCharset: [[CWParser _parameterValueUsingLine: theLine  range: aRange  decode: NO  charset: nil] asciiString]];
    }
  
  //
  // We decode our format (if we need to). See RFC2646.
  //
  aRange = [theLine rangeOfCString: "format"  options: NSCaseInsensitiveSearch];
  
  if (aRange.length > 0)
    {
      NSData *aFormat;
      
      aFormat = [CWParser _parameterValueUsingLine: theLine  range: aRange  decode: NO  charset: nil];
      
      if ([aFormat caseInsensitiveCCompare: "flowed"] == NSOrderedSame)
	{
	  [thePart setFormat: PantomimeFormatFlowed];
	}
      else
	{
	  [thePart setFormat: PantomimeFormatUnknown];
	}
    }
  else
    {
      [thePart setFormat: PantomimeFormatUnknown];
    }

  //
  // We decode the parameter "name" iif the thePart is an instance of Part
  //
  if ([thePart isKindOfClass: [CWPart class]])
  {
    aRange = [theLine rangeOfCString: "name"  options: NSCaseInsensitiveSearch];

    if (aRange.length > 0)
      {
	[thePart setFilename: [CWParser _parameterValueUsingLine: theLine  range: aRange  decode: YES  charset: [thePart defaultCharset]]];
      }
  }
}


//
//
//
+ (void) parseDate: (NSData *) theLine
	 inMessage: (CWMessage *) theMessage
{
  if ([theLine length] > 6)
    {
      NSData *aData;
      NSUInteger tot;
      int month, day, year, hours, mins, secs, tz;
      int len, s;
      unsigned i, j;
      unsigned char *bytes, *word;

      aData = [theLine subdataFromIndex: 6];
      word = malloc(256);

      bytes = (unsigned char*)[aData bytes];
      tot = [aData length];
      i = 0;
      s = 0;
      tz = 0;

      // date-time       =       [ day-of-week "," ] date FWS time [CFWS]
      // day-of-week     =       ([FWS] day-name) / obs-day-of-week
      // day-name        =       "Mon" / "Tue" / "Wed" / "Thu" /
      //                         "Fri" / "Sat" / "Sun"
      // date            =       day month year
      // year            =       4*DIGIT / obs-year
      // month           =       (FWS month-name FWS) / obs-month
      // month-name      =       "Jan" / "Feb" / "Mar" / "Apr" /
      //                         "May" / "Jun" / "Jul" / "Aug" /
      //                         "Sep" / "Oct" / "Nov" / "Dec"
      //
      // day             =       ([FWS] 1*2DIGIT) / obs-day
      // time            =       time-of-day FWS zone
      // time-of-day     =       hour ":" minute [ ":" second ]
      // hour            =       2DIGIT / obs-hour
      // minute          =       2DIGIT / obs-minute
      // second          =       2DIGIT / obs-second
      // zone            =       (( "+" / "-" ) 4DIGIT) / obs-zone
      //
      // We need to handle RFC2822 and UNIX time:
      //
      // Date: Wed, 02 Jan 2002 09:07:19 -0700
      // Date: 02 Jan 2002 19:57:49 +0000
      //
      // And broken dates such as:
      //
      // Date: Thu, 03 Jan 2002 16:40:30 GMT
      // Date: Wed, 2 Jan 2002 08:56:18 -0700 (MST)
      // Date: Wed, 9 Jan 2002 10:04:23 -0500 (Eastern Standard Time)
      // Date: 11-Jan-02
      // Date: Tue, 15 Jan 2002 15:45:53 -0801
      // Date: Thu, 17 Jan 2002 11:54:11 -0900<br>
      //
      //while (i < tot && isspace(*bytes))
      //	{
      //	  i++; bytes++;
      //	}
      
      len = next_word(bytes, i, tot, word); if (len <= 0) { free(word); return; }

      if (isalpha(*word))
	{
	  //NSLog(@"UNIX DATE");
	  
	  // We skip the first word, no need for it.
	  i += (unsigned)len+1; len = next_word(bytes, i, tot, word); if (len <= 0) { free(word); return; }
	}

      
      month = -1;
      
      // We got a RFC 822 date. The syntax is:
      // day month year hh:mm:ss zone
      // For example: 03 Apr 2003 17:27:06 +0200
      //NSLog(@"RFC-822 time");
      day = atoi((const char*)word);
      
      //printf("len = %d |%s| day = %d\n", len, word, day);
      
      // We get the month name and we convert it.
      i += (unsigned)len+1; len = next_word(bytes, i, tot, word); if (len <= 0) { free(word); return; }
      
      for (j = 0; j < 12; j++)
	{
	  if (strncasecmp((const char*)word, month_name[j], 3) == 0)
	    {
	      month = (int)j+1;
	    }
	}
      
      if (month < 0) { free(word); return; }
      
      //printf("len = %d |%s| month = %d\n", len, word, month);
      
      // We get the year.
      i += (unsigned)len+1; len = next_word(bytes, i, tot, word); if (len <= 0) { free(word); return; }
      year = atoi((const char*)word);
      
      if (year < 70) year += 2000;
      if (year < 100) year += 1900;
      
      //printf("len = %d |%s| year = %d\n", len, word, year);
      
      // We parse the time using the hh:mm:ss format.
      i += (unsigned)len+1; len = next_word(bytes, i, tot, word); if (len <= 0) { free(word); return; }
      sscanf((const char*)word, "%d:%d:%d", &hours, &mins, &secs);
      //printf("len = %d |%s| %d:%d:%d\n", len, word, hours, mins, secs);
      
      // We parse the timezone.
      i += (unsigned)len+1; len = next_word(bytes, i, tot, word);
      
      if (len <= 0)
	{
	  tz = 0;
	}
      else
	{
	  unsigned char *p;
	  
	  p = word;
	  
	  if (*p == '-' || *p == '+')
	    {
	      s = (*p == '-' ? -1 : 1);
	      p++;
	    }
	  
	  len = (int)strlen((const char*)p);
	  
	  if (isdigit(*p))
	    {
	      if (len == 2)
		{
		  tz = (*(p)-48)*36000+*((p+1)-48)*3600;
		}
	      else
		{
		  tz = (*(p)-48)*36000+(*(p+1)-48)*3600+(*(p+2)-48)*10+(*(p+3)-48);
		}
	    }
	  else
	    {
	      for (j = 0; j < sizeof(timezone_info)/sizeof(timezone_info[0]); j++)
		{
		  if (strncasecmp((const char*)p, timezone_info[j].name, len) == 0)
		    {
		      tz = timezone_info[j].offset;
		    }
		}
	    }
	  tz = s*tz;
	}
      
      [theMessage setReceivedDate: [NSCalendarDate dateWithYear: year
						   month: (NSUInteger) month
						   day: (NSUInteger)day
						   hour: (NSUInteger) hours
						   minute: (NSUInteger) mins
						   second: (NSUInteger) secs
						   timeZone: [NSTimeZone timeZoneForSecondsFromGMT: tz]]];
      free(word);
    }
}

//
//
//
+ (NSData *) parseDestination: (NSData *) theLine
		      forType: (PantomimeRecipientType) theType
		    inMessage: (CWMessage *) theMessage
			quick: (BOOL) theBOOL
{  
  CWInternetAddress *anInternetAddress;
  NSData *aData;

  NSUInteger i, len, x;
  unsigned char *bytes;
  BOOL b;

  if (theBOOL)
    {
      aData = theLine;
    }
  else
    {
      switch (theType)
	{
	case PantomimeBccRecipient:
	  len = 5;
	  break;

	case PantomimeCcRecipient:
	case PantomimeToRecipient:
	  len = 4;
	  break;
	  
	case PantomimeResentBccRecipient:
	  len = 12;
	  break;

	case PantomimeResentCcRecipient:
	case PantomimeResentToRecipient:
	  len = 11;
	  break;
        default:
          NSDebugLog(@"CWParser parseDestination: forType: unknown type!");
          len = 0;
          break;
	}

      // We skip over emtpy headers.
      if (len >= [theLine length]) return [NSData data];
      
      aData = [theLine subdataFromIndex: len];
    }

  bytes = (unsigned char*)[aData bytes];
  len = [aData length];
  b = NO; x = 0;

  for (i = 0; i < len; i++)
    {
      if (*bytes == '"')
	{
	  b = !b;
	}

      if (*bytes == ',' || i == len-1)
	{
          NSData *headerData;
          NSRange headerRange;
        
	  if (b)
	    {
	      bytes++;
	      continue;
	    }

	  // We strip the trailing comma for all but the last entries.
	  if (i == len-1)
            headerRange = NSMakeRange(x, i-x+1);
          else
            headerRange = NSMakeRange(x, i-x);
          
          headerData = [aData subdataWithRange: headerRange];
          headerData = [headerData dataByTrimmingWhiteSpaces];
	  anInternetAddress = [[CWInternetAddress alloc]
				initWithString: [CWMIMEUtility decodeHeader: headerData
							       charset: [theMessage defaultCharset]]];
 
	  if (anInternetAddress != nil)
            {
              [anInternetAddress setType: theType];
	      [theMessage addRecipient: anInternetAddress];
	      RELEASE(anInternetAddress);
            }
	  x = i+1;
	}
      
      bytes++;
    }

  return aData;
}

//
//
//
+ (NSData *) parseFrom: (NSData *) theLine
	     inMessage: (CWMessage *) theMessage
		 quick: (BOOL) theBOOL;
{
  CWInternetAddress *anInternetAddress;
  NSData *aData;
  
  if (!theBOOL && !([theLine length] > 6))
    {
      return [NSData data];
    }
 
  if (theBOOL)
    {
      aData = theLine;
    }
  else
    {
      aData = [theLine subdataFromIndex: 6];
    }

  anInternetAddress = [[CWInternetAddress alloc] initWithString: [CWMIMEUtility decodeHeader: aData charset: [theMessage defaultCharset]]];

  [theMessage setFrom: anInternetAddress];
  RELEASE(anInternetAddress);

  return aData;
}


//
// This method is used to parse the In-Reply-To: header value.
//
+ (NSData *) parseInReplyTo: (NSData *) theLine
		  inMessage: (CWMessage *) theMessage
		      quick: (BOOL) theBOOL
{
  NSData *aData;
  NSUInteger x, y;
  
  if (theBOOL)
    {
      aData = theLine;
    }
  else if ([theLine length] > 13)
    {
      aData = [theLine subdataFromIndex: 13];
    }
  else
    {
      return [NSData data];
    }

  // We check for lame headers like that:
  //
  // In-Reply-To: <4575197F.7020602@de.ibm.com> (Markus Deuling's message of "Tue, 05 Dec 2006 08:02:23 +0100")
  // In-Reply-To: <MABBJIJNAFCGBJJJOEBHEEFGKIAA.reldred@viablelinks.com>; from reldred@viablelinks.com on Wed, Mar 26, 2003 at 11:23:37AM -0800
  //
  x = [aData indexOfCharacter: ';'];
  y = [aData indexOfCharacter: ' '];

  if (x != NSNotFound && x > 0 && x < y)
    {
      aData = [aData subdataToIndex: x];
    }
  else if (y != NSNotFound && y > 0)
    {
      aData = [aData subdataToIndex: y];
    }

  [theMessage setInReplyTo: [aData asciiString]];

  return aData;
}


//
//
//
+ (NSData *) parseMessageID: (NSData *) theLine
		  inMessage: (CWMessage *) theMessage
		      quick: (BOOL) theBOOL
{
  NSData *aData;
  
  if (!theBOOL && !([theLine length] > 12))
    {
      return [NSData data];
    }
  
  if (theBOOL) aData = theLine;
  else aData = [theLine subdataFromIndex: 12];
  
  [theMessage setMessageID: [[aData dataByTrimmingWhiteSpaces] asciiString]];
  return aData;
}


//
//
//
+ (void) parseMIMEVersion: (NSData *) theLine
		inMessage: (CWMessage *) theMessage
{
  if ([theLine length] > 14)
    {
      [theMessage setMIMEVersion: [[theLine subdataFromIndex: 14] asciiString]];
    }
}


//
//
//
+ (NSData *) parseReferences: (NSData *) theLine
		   inMessage: (CWMessage *) theMessage
		       quick: (BOOL) theBOOL
{
  NSData *aData;

  aData = nil;

  if (theBOOL)
    {
      aData = theLine;
    }
  else if ([theLine length] > 12)
    {
      aData = [theLine subdataFromIndex: 12];
    }
  
  if (aData && [aData length])
    {
      NSMutableArray *aMutableArray;
      NSArray *allReferences;
      NSData *aReference;
      NSString *aString;
      NSUInteger i, count;
      
      allReferences = [aData componentsSeparatedByCString: " "];
      count = [allReferences count];

      aMutableArray = [[NSMutableArray alloc] initWithCapacity: count];
      
      for (i = 0; i < count; i++)
	{
	  aReference = [allReferences objectAtIndex: i];
	  aString = [aReference asciiString];
	  
	  // We protect ourself against values that could hold 8-bit characters.
	  if (aString)
	    {
	      [aMutableArray addObject: aString];
	    }
	}
      
      [theMessage setReferences: aMutableArray];
      RELEASE(aMutableArray);
      
      return aData;
    }
  
  return [NSData data];
}


//
//
//
+ (void) parseReplyTo: (NSData *) theLine
	    inMessage: (CWMessage *) theMessage
{
  if ([theLine length] > 10)
    {
      CWInternetAddress *anInternetAddress;
      NSMutableArray *aMutableArray;
      NSData *aData;

      unsigned char *bytes;
      NSUInteger i, len;
      int s_len, x, y;
      BOOL b;
      
      aMutableArray = [[NSMutableArray alloc] init];
      aData = [theLine subdataFromIndex: 10];
      bytes = (unsigned char*)[aData bytes];
      len = [aData length];
      b = NO; x = 0;
      
      for (i = 0; i < len; i++)
	{
	  if (*bytes == '"')
	    {
	      b = !b;
	    }
	  
	  if (*bytes == ',' || i == len-1)
	    {
	      if (b)
		{
		  bytes++;
		  continue;
		}
	      
	      y = i;
	      
	      // We strip the trailing comma for all but the last entries.
	      s_len = y-x;
	      if (i == len-1) s_len++;

	      anInternetAddress = [[CWInternetAddress alloc]
				    initWithString: [CWMIMEUtility decodeHeader: [[aData subdataWithRange: NSMakeRange(x, s_len)] dataByTrimmingWhiteSpaces]
								   charset: [theMessage defaultCharset]]];
	      if (anInternetAddress != nil)
                {
	          [aMutableArray addObject: anInternetAddress];
	          RELEASE(anInternetAddress);
                }
	      x = y+1;
	    }
	  
	  bytes++;
	}

      if ([aMutableArray count])
	{
	  [theMessage setReplyTo: aMutableArray];
	}

      RELEASE(aMutableArray);
    }
}


//
//
//
+ (void) parseResentFrom: (NSData *) theLine
	 inMessage: (CWMessage *) theMessage
{
  if ([theLine length] > 13)
    {
      CWInternetAddress *anInternetAddress;
      
      anInternetAddress = [[CWInternetAddress alloc] initWithString: [CWMIMEUtility decodeHeader:
										      [theLine subdataFromIndex: 13]
										    charset: [theMessage defaultCharset]]];
      
      [theMessage setResentFrom: anInternetAddress];
      RELEASE(anInternetAddress);
    }
}


//
//
//
+ (void) parseStatus: (NSData *) theLine
	   inMessage: (CWMessage *) theMessage
{
  if ([theLine length] > 8)
    {
      NSData *aData;
      
      aData = [theLine subdataFromIndex: 8];
      [[theMessage flags] addFlagsFromData: aData  format: PantomimeFormatMbox];
      [theMessage addHeader: @"Status"  withValue: [aData asciiString]];
    }
}


//
//
//
+ (void) parseXStatus: (NSData *) theLine
	    inMessage: (CWMessage *) theMessage
{
  if ([theLine length] > 10)
    {
      NSData *aData;

      aData = [theLine subdataFromIndex: 10];
      [[theMessage flags] addFlagsFromData: aData  format: PantomimeFormatMbox];
      [theMessage addHeader: @"X-Status"  withValue: [aData asciiString]];
    }
}


//
//
//
+ (NSData *) parseSubject: (NSData *) theLine
		inMessage: (CWMessage *) theMessage
		    quick: (BOOL) theBOOL
{
  NSData *aData;

  if (theBOOL)
    {
      aData = theLine;
    }
  else if ([theLine length] > 9)
    {
      aData = [[theLine subdataFromIndex: 8] dataByTrimmingWhiteSpaces];
    }
  else
    {
      return [NSData data];
    }

  [theMessage setSubject: [CWMIMEUtility decodeHeader: aData  charset: [theMessage defaultCharset]]];
  
  return aData;
}


//
//
//
+ (void) parseUnknownHeader: (NSData *) theLine
		  inMessage: (CWMessage *) theMessage
{
  NSData *aName, *aValue;
  NSRange range;

  range = [theLine rangeOfCString: ":"];
  
  if (range.location != NSNotFound)
    {
      aName = [theLine subdataWithRange: NSMakeRange(0, range.location)];
      
      // we keep only the headers that have a value
      if (([theLine length]-range.location-1) > 0)
	{
	  aValue = [theLine subdataWithRange: NSMakeRange(range.location + 2, [theLine length]-range.location-2)];
	  
	  [theMessage addHeader: [aName asciiString]  withValue: [aValue asciiString]];
	}
    }
}


//
//
//
+ (void) parseOrganization: (NSData *) theLine
		 inMessage: (CWMessage *) theMessage
{
  NSString *organization;

  if ([theLine length] > 14)
    {
      organization = [CWMIMEUtility decodeHeader: [[theLine subdataFromIndex: 13] dataByTrimmingWhiteSpaces]
				    charset: [theMessage defaultCharset]];
    }
  else
    {
      organization = @"";
    }
  
  [theMessage setOrganization: organization];    
}

@end


//
// private methods
//
@implementation CWParser (Private)

+ (id) _parameterValueUsingLine: (NSData *) theLine
			  range: (NSRange) theRange
			 decode: (BOOL) theBOOL
			charset: (NSString *) theCharset
{
  NSMutableData *aMutableData;
  NSRange r1, r2;
  
  int value_start, value_end, parameters_count,len;
  BOOL is_rfc2231, has_charset;

  is_rfc2231 = has_charset = NO;
  len = [theLine length];
  
  //
  // Look for the first occurrence of '=' before the end of the line within
  // our range. That marke the beginning of the value. If we don't find one,
  // we set the beggining right after the end of the key tag
  //
  r1 = [theLine rangeOfCString: "="
		options: 0
		range: NSMakeRange(NSMaxRange(theRange), len-NSMaxRange(theRange))];

  if (r1.length > 0)
    {
      // If "=" was found, but after ";", something is very broken
      // and we just return nil. That can happen if we have a Content-Type like:
      //
      // Content-Type: text/x-patch; name=mpg321-format-string.diff; charset=ISO-8859-1
      //
      // "format" is part of the _name_ parameter. It has nothing to do with format=flowed.
      //
#warning FIXME - consider format= when passing the parameter range
#if 0
      if (r1.location > value_end)
	{
	  return nil;
	}
#endif
      
      value_start = r1.location+r1.length;
    }
  else
    {
      value_start = theRange.location+theRange.length;
    }  

  // The parameter can be quoted or not like this (for example, with a charset):
  // charset="us-ascii"
  // charset = "us-ascii"
  // charset=us-ascii
  // charset = us-ascii
  // It can be terminated by ';' or end of line.
  
  // Look for the first occurrence of ';'.
  // That marks the end of this key value pair.
  // If we don't find one, we set it to the end of the line.
  r1 = [theLine rangeOfCString: ";"
		options: 0
		range: NSMakeRange(NSMaxRange(theRange), len-NSMaxRange(theRange))];
		
  if (r1.length > 0)
    {
      value_end = r1.location-1;
    }
  else
    {
      value_end = len-1;
    }
  
  // We now have a range that should contain our value.
  // Build a NSRange out of it.
  if (value_end - value_start + 1 > 0)
    {
      r1 = NSMakeRange(value_start, value_end-value_start+1);
    }
  else
    {
      r1 = NSMakeRange(value_start, 0);
    }
  
  aMutableData = AUTORELEASE([[NSMutableData alloc] initWithData: [[[theLine subdataWithRange: r1] dataByTrimmingWhiteSpaces] dataFromQuotedData]]);

  //
  // VERY IMPORTANT:
  //
  // We check if something was encoded using RFC2231. We need to adjust
  // value_end if we find a multi-line parameter. We also proceed
  // with data substitution while we loop for parameter values unfolding.
  //
  if ([theLine characterAtIndex: NSMaxRange(theRange)] == '*')
    { 
      is_rfc2231 = YES;
      
      // We consider parameter value continuations (Section 3. of the RFC)
      // in order the set the appropriate end boundary.
      if ([theLine characterAtIndex: NSMaxRange(theRange)+1] == '0')
	{
	  // int end;
	  
	  // We check if we have a charset, in case of a multiline value.
	  if ([theLine characterAtIndex: NSMaxRange(theRange)+2] == '*')
	    {
	      has_charset = YES;
	    }
	  
	  r1.location = theRange.location;
	  r1.length = theRange.length;
	  parameters_count = 1;
	  
	  while (YES)
	    {
	      // end = NSMaxRange(r1);
	      r1 = [theLine rangeOfCString: [[NSString stringWithFormat: @"%s*%i", 
						       [[theLine subdataWithRange: theRange] cString],
						       parameters_count] UTF8String]
			    options: 0
			    range: NSMakeRange(NSMaxRange(r1), len-NSMaxRange(r1))];
	      parameters_count++;

	      if (r1.location != NSNotFound)
		{
		  value_start = NSMaxRange(r1);

		  // now we may need to skip *=, when data is encoded like
		  // filename*1*=%56%67;
		  // else it is like
		  // filename*1="xxxxx";
		  if ([theLine characterAtIndex: value_start] == '*')
			value_start += 2;
		  else
			value_start	+= 1;


		  r2 = [theLine rangeOfCString: ";"  options: 0  range: NSMakeRange(NSMaxRange(r1), len-NSMaxRange(r1))];
		  
		  if (r2.length > 0)
		    {
		      value_end = r2.location;
		    }
		  else
		    {
		      value_end = len;
		    }

		  [aMutableData appendData: [[[theLine subdataWithRange: NSMakeRange(value_start,value_end-value_start)]
					       dataFromSemicolonTerminatedData] dataFromQuotedData]];
		}
	      else
		{
		  break;
		}
	    }
	}
      else if ([theLine characterAtIndex: NSMaxRange(theRange)+1] == '=')
	{
	  has_charset = YES;
	}
    }
  
  if (is_rfc2231)
    {
      if (has_charset)
	{
	  BOOL lang = NO;
	  NSData *aCharset;
	  
          aCharset = nil;
	  r1 = [aMutableData rangeOfCString: "'"];

	  if (r1.location != NSNotFound)
	    {
	      lang = YES;
	      // We check for a language
	      r2 = [aMutableData rangeOfCString: "'"  options: 0
					  range: NSMakeRange(NSMaxRange(r1),
							     [aMutableData length]-NSMaxRange(r1))];
	  
	      if (r2.length && r2.location > r1.location+1)
		{
		  NSLog(@"WE'VE GOT A LANGUAGE!");
		}

	      aCharset = [aMutableData subdataToIndex: r1.location];

	      // We strip the charset and the language information from our data
	      [aMutableData replaceBytesInRange: NSMakeRange(0, NSMaxRange(r2))
				      withBytes: NULL
					 length: 0];
	    }

	  if (theBOOL)
	    {
	      NSString *aString;

	      aString = AUTORELEASE([[NSString alloc] initWithData: aMutableData  encoding: NSASCIIStringEncoding]);
	      
	      if (lang)
		{
		  return [aString stringByReplacingPercentEscapesUsingEncoding:
						  [NSString encodingForCharset: aCharset]];
		}
	      else
		{
		  return aString;
		}
	    }
	}
      else
        {
          NSString *aString;
        
          aString = AUTORELEASE([[NSString alloc] initWithData: aMutableData  encoding: NSASCIIStringEncoding]);
          
          return aString;
        }
    } 
  else
    {
      if (theBOOL)
	{
	  return [CWMIMEUtility decodeHeader: aMutableData  charset: theCharset];
	}
    }

  return aMutableData;
}

@end
