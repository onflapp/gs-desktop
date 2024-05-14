// ADVCFConverter.m (this is -*- ObjC -*-)
// 
// Authors: Björn Giesler <giesler@ira.uka.de>
//          Riccardo Mottola
// 
// Address Book Framework for GNUstep
// 



#import <GNUstepBase/GSMime.h>

#import "ADPerson.h"
#import "ADGlobals.h"
#import "ADImageLoading.h"
#import "ADMultiValue.h"
#import "ADVCFConverter.h"

@interface NSString(QuotedPrintable)
- (unsigned long) hexLongValue;
- (NSString*) stringByQuotedPrintableDecoding;
- (NSString*) stringByQuotedPrintableEncoding;
@end

@implementation NSString(QuotedPrintable)
- (unsigned long) hexLongValue
{
  unsigned long val;
  NSString *str;
  NSString *hexchars;
  int i;

  val = 0;
  str = [[self stringByTrimmingCharactersInSet:
		 [NSCharacterSet whitespaceCharacterSet]]
	  lowercaseString];
  hexchars = @"0123456789abcdef";

  for(i=0; i<[str length]; i++)
    {
      NSRange r;
      NSString *substr;

      r = NSMakeRange(i, 1);
      substr = [str substringWithRange: r];
      r = [hexchars rangeOfString: substr];
      if(r.location == NSNotFound)
	[NSException raise: NSGenericException
		     format: @"\"%@\"[%d] not a hex char", str, i];
      val <<= 4;
      val |= r.location;
    }

  return val;
}

- (NSString*) stringByQuotedPrintableDecoding
{
  int i;
  NSMutableString *str;
  NSMutableString *str2;
  
  // process \ escaped chars
  str = [NSMutableString stringWithString:self];
  [str replaceOccurrencesOfString:@"\\\\" 
                       withString:@"\\" 
                          options:0 
                            range:NSMakeRange(0, [str length])];

  [str replaceOccurrencesOfString:@"\\n" 
                       withString:@"\n" 
                          options:0 
                            range:NSMakeRange(0, [str length])];

  str2 = [NSMutableString stringWithCapacity: [str length]];
  for(i=0; i<[str length]; i++)
    {
      NSRange r;
      NSString *s;

      r = NSMakeRange(i, 1);
      s = [str substringWithRange: r];
      if([s isEqualToString: @"="] && i < [str length]-2)
	{
	  unsigned char c;
	  NSString *hex;
	  BOOL hexDecodeWorked;
	  
	  r = NSMakeRange(i+1, 2);
	  hex = [str substringWithRange: r];
	  
	  hexDecodeWorked = YES;
	  
	  NS_DURING
	    {
	      c = (unsigned char)[hex hexLongValue];
	    }
	  NS_HANDLER
	    {
	      hexDecodeWorked = NO;
	    }
	  NS_ENDHANDLER;
	  
	  if (hexDecodeWorked)
	    {
	      [str2 appendString: [NSString stringWithFormat: @"%c", c]];
	      i+=2;
	    }
	  else // hex decode failed!
	    {
	      /*
	       * Note: This is maybe not the true and plain VCard
	       * specification, but some Vcard files (e.g. when exported
	       * from the Apple Address Book) don't take care when encoding
	       * URLs (and possibly other fields). So we fall back to not
	       * interpreting the hex characters.
	       *
	       * The URL format in question is this:
	       * http://www.somesearchengine.com/query=blablabla
	       *                                      ^
	       *          This is not an escaped special character
	       *
	       * XXX: May produce problems with some URLS containing
	       *      valid alphanumerical hex numbers after the '='.
	       * FIX: No fix known.
	       */
	      [str2 appendString: s]; // note: s equals @"="
	    }
	}
      else
	[str2 appendString: s];
    }

  str2 = [NSString stringWithUTF8String: [str2 cString]];
  return str2;
}

- (NSString*) stringByQuotedPrintableEncoding
{
  int i;
  size_t len;
  const unsigned char *cstr;
  NSMutableString *str;

  cstr = (unsigned char *)[self UTF8String];  
  len = strlen((char *)cstr);
  str = [NSMutableString stringWithCapacity: len];
  for (i = 0; i < len; i++) {
      if (cstr[i] == ' ')
	[str appendString: @"=20"];
      else if(cstr[i] > 127)
	[str appendFormat: @"=%X", cstr[i]];
      else
	[str appendFormat: @"%c", cstr[i]];
  }
  return str;
}
@end

@interface NSArray(VCFKeys)
- (NSString*) restOfStringStartingWith: (NSString*) start;
@end

@implementation NSArray(VCFKeys)
- (NSString*) restOfStringStartingWith: (NSString*) start
{
  NSEnumerator *e;
  id obj;

  e = [self objectEnumerator];
  while((obj = [e nextObject]))
    {
      if(![obj isKindOfClass: [NSString class]])
	continue;
      if([obj length] < [start length])
	continue;
      if([[obj substringToIndex: [start length]]
	   isEqualToString: start])
	return [obj substringFromIndex: [start length]];
    }
  return nil;
}
@end

NSData *base64Decode(NSString* nsstr)
{
  return [GSMimeDocument decodeBase64:[nsstr dataUsingEncoding:NSUTF8StringEncoding]];
}

NSString *base64Encode(NSData* data)
{
  return AUTORELEASE([[NSString alloc] initWithData:[GSMimeDocument encodeBase64:data] encoding:NSUTF8StringEncoding]);
}  
  
      
@interface ADVCFConverter(Private)
- (BOOL) parseLine: (int) line
	 fromArray: (NSArray*) arr
	  upToLine: (int*) retLine
      intoKeyBlock: (NSArray**) k
	valueBlock: (NSArray**) v;
- (void) integrateKeyBlock: (NSArray*) k
		valueBlock: (NSArray*) v
		intoPerson: (ADPerson*) p;
- (void) appendStringForProperty: (NSString*) property
			inPerson: (ADPerson*) p;
- (void) appendStringWithHeader: (NSString*) header
			  value: (NSString*) value;
- (void) appendStringWithHeader: (NSString*) header
			  value: (NSString*) value
		binaryLinebreak: (BOOL) blb;
@end

static NSArray *knownItems;

@implementation ADVCFConverter
+ (void) initialize
{
  knownItems =
    [[NSArray alloc] initWithObjects: @"org", @"role", @"url", @"adr",
		     @"n", @"agent", @"logo", @"photo", @"label", @"fn",
		     @"title", @"sound", @"version", @"tel", @"email",
		     @"tz", @"geo", @"note", @"bday", @"rev", @"uid",
		     @"key", @"mailer", nil];
}

- (void) dealloc
{
  [_str release];
  [_out release];
  [super dealloc];
}

- initForInput
{
  _input = YES;
  _str = nil;
  _out = nil;
  return [super init];
}

- (BOOL) useString: (NSString*) str
{
  _str = [str copy];
  _idx = 0;

  return YES; 
}

- (ADRecord*) nextRecord
{
  int i = 0;
  NSString *str;
  NSArray *lines;
  ADPerson *person;

  person = [[[ADPerson alloc] init] autorelease];
  [person setValue: [NSDate date] forProperty: ADModificationDateProperty];
  [person setValue: [NSDate date] forProperty: ADCreationDateProperty];
  
  str = [_str substringFromIndex: _idx];

  lines = [str componentsSeparatedByString: @"\n"];
  
  while(i < [lines count])
    {
      NSArray *keyblock, *valueblock;
      BOOL retval;
      int oldIndex, newIndex;

      oldIndex = i;
      retval = [self parseLine: i
		     fromArray: lines
		     upToLine: &i
		     intoKeyBlock: &keyblock
		     valueBlock: &valueblock];
      newIndex = i;
      while(oldIndex < newIndex)
	_idx += [[lines objectAtIndex: oldIndex++] length] + 1;
      
      if(retval)
	{
	  if([keyblock containsObject: @"end"]) // done!
	    return person;
	     
	  if(![keyblock containsObject: @"begin"] &&
	     ![keyblock containsObject: @"end"] &&
	     ![keyblock containsObject: @"version"])
	    [self integrateKeyBlock: keyblock
		  valueBlock: valueblock
		  intoPerson: person];
	  }
      }
  
  return nil;
}

/* COutputConverting */
- initForOutput
{
  _str = nil;
  _input = NO;
  _idx = 0;
  _out = [[NSMutableString alloc] init];
  return self;
}

- (BOOL) canStoreMultipleRecords
{
  return YES;
}

- (void) storeRecord: (ADRecord*) record
{
  NSEnumerator *e; NSString *prop; NSString *name; id val;
  NSArray *myProps;

  if(![record isKindOfClass: [ADPerson class]])
    {
      NSLog(@"Can't store objects of class %@\n", [record className]);
      return;
    }
  
  myProps = [NSArray arrayWithObjects: ADLastNameProperty, ADFirstNameProperty,
	     ADMiddleNameProperty, ADTitleProperty, nil];

  [_out appendString: @"BEGIN:VCARD\r\n"];
  [_out appendString: @"VERSION:2.1\r\n"];
  [_out appendString: @"X-GENERATOR:Addresses for GNUstep pre-1.0\r\n"];

  // Create name ourselves
  name = @"";
  e = [myProps objectEnumerator];
  while((prop = [e nextObject]))
    {
      val = [record valueForProperty: prop];
      name = [name stringByAppendingFormat: @"%@;", val ? val : @""];
    }
  val = [record valueForProperty: ADSuffixProperty];
  name = [name stringByAppendingFormat: @"%@", val ? val : @""];
  [self appendStringWithHeader: @"N" value: name];
  
  e = [[[record class] properties] objectEnumerator];
  while((prop = [e nextObject]))
    {
      if(![myProps containsObject: prop] &&
	 ![prop isEqualToString: ADSuffixProperty])
	[self appendStringForProperty: prop inPerson: (ADPerson*) record];
    }

  [_out appendString: @"END:VCARD\r\n"];
}

- (NSString*) string
{
  return _out;
}
@end

@implementation ADVCFConverter (Private)
- (BOOL) parseLine: (int) line
	 fromArray: (NSArray*) arr
	  upToLine: (int*) retLine
      intoKeyBlock: (NSArray**) k
	valueBlock: (NSArray**) v
{
  NSString *str, *keyblock, *value;
  NSCharacterSet *wsp;
  NSRange r;
  BOOL lastLineWasReadable;

  wsp = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  *retLine = line;
  
  str = [[arr objectAtIndex: (*retLine)++]
	    stringByTrimmingCharactersInSet: wsp];

  if(![str length]) return NO;
  
  /*
   * Unfolding multi-line value fields conforming to RFC 2425
   */
  
  
  // While "there is a next line that begins with a space character"...
  lastLineWasReadable = YES;
  while(*retLine < [arr count] && lastLineWasReadable)
    {
      NSString* str2 = [arr objectAtIndex: *retLine];
      
      if ([str2 length] == 0)
	{
	  lastLineWasReadable = NO;
	}
      else
	{
	  NSString* firstCharacter =
	    [str2 substringWithRange: NSMakeRange(0,1)];
	  
	  if ([firstCharacter isEqualToString: @" "] || // Space
	      [firstCharacter isEqualToString: @"\t"]) // Tab
	    {
	      /*
	       * Ignore all spaces in front of the real data. IIRC not
	       * compliant to the VCard standard, but the Apple Address
	       * book does it this way, too. :-/
	       *
	       * Trim the first characters (usually the whitespace) and
	       * the last character(s) (the CRLF)!
	       */
	      str2 = [str2 stringByTrimmingCharactersInSet:wsp];
	      str = [str stringByAppendingString: str2];
	      // we parsed a line more, so increase the counter
	      (*retLine)++;
	    }
	  else
	    lastLineWasReadable = NO;
	}
    }
#ifdef DEBUGGING  
  NSLog(@"Input line : %@", str);
#endif
  r = [str rangeOfString: @":"];
  if(r.location == NSNotFound)
    {
      NSLog(@"Syntax error in line %d!\n", line);
      return NO;
    }
  
  keyblock = [str substringToIndex: r.location];
  *k = [[keyblock lowercaseString] componentsSeparatedByString: @";"];
  
  value = [str substringFromIndex: r.location+r.length];
  NSLog(@"value: %@", value);
  if([value isEqualToString: @"="]) // escape to next line
    {
      value = [[arr objectAtIndex: (*retLine)++]
		stringByTrimmingCharactersInSet: wsp];
		NSLog(@"value2: %@", value);
      *v = [[value stringByQuotedPrintableDecoding]
	     componentsSeparatedByString: @";"];
    }
  else
    *v = [[value stringByQuotedPrintableDecoding]
	   componentsSeparatedByString: @";"];
  NSLog(@"v: %@", *v);
  return YES;
}

- (void) integrateKeyBlock: (NSArray*) k
		valueBlock: (NSArray*) v
		intoPerson: (ADPerson*) p
{
  NSString* key;
  NSRange r;

  if(![k count])
    {
      NSLog(@"No keys in '%@':'%@'\n", k, v);
      return;
    }
  else if(![v count])
    {
      NSLog(@"No values in '%@':'%@'\n", k, v);
      return;
    }
  
  key = [k objectAtIndex: 0];
  /*
   * Strip any group from the key (ie item1.ADR)
   * See http://tools.ietf.org/search/rfc2426#section-4
   * and http://tools.ietf.org/search/rfc2425 which says :
   *
   * The group construct is used to group related attributes together.
   * The group name is a syntactic convention used to indicate that all
   * type names prefaced with the same group name SHOULD be grouped
   * together when displayed by an application. It has no other
   * significance.  Implementations that do not understand or support
   * grouping MAY simply strip off any text before a "." to the left of
   * the type name and present the types and values as normal.
   */
  r = [key rangeOfString: @"."];
  if (r.location != NSNotFound)
    key = [key substringFromIndex: r.location+1];

#if 0
  if(![knownItems containsObject: key])
    {
      NSLog(@"%@ not in knownItems\n", key);
      return;
    }
#endif

  if([key isEqualToString: @"n"])
    {
      if([v count] != 5)
	NSLog(@"Value for '%@':'%@' doesn't have enough entries!\n",
	      k, v);

      [p setValue: [v objectAtIndex: 0] forProperty: ADLastNameProperty];
      if([v count] > 1)
	[p setValue: [v objectAtIndex: 1] forProperty: ADFirstNameProperty];
      if([v count] > 2)
	[p setValue: [v objectAtIndex: 2] forProperty: ADMiddleNameProperty];
      if([v count] > 3)
	[p setValue: [v objectAtIndex: 3] forProperty: ADTitleProperty];
      if([v count] > 4)
	[p setValue: [v objectAtIndex: 4] forProperty: ADSuffixProperty];
    }

  else if([key isEqualToString: @"org"])
    [p setValue: [v objectAtIndex: 0] forProperty: ADOrganizationProperty];
  else if([key isEqualToString: @"title"])
    [p setValue: [v objectAtIndex: 0] forProperty: ADJobTitleProperty];
  else if([key isEqualToString: @"url"])
    [p setValue: [v objectAtIndex: 0] forProperty: ADHomePageProperty];
  else if([key isEqualToString: @"fn"])
    [p setValue: [v objectAtIndex: 0] forProperty: ADFormattedNameProperty];
  else if([key isEqualToString: @"bday"])
    {
      NSCalendarDate *d;

      d = [NSCalendarDate dateWithString: [v objectAtIndex: 0]
			  calendarFormat: @"%Y-%d-%m"];
      if(!d)
	d = [NSCalendarDate dateWithString: [v objectAtIndex: 0]
			    calendarFormat: @"%Y%d%m"];
      if(d) 
	[p setValue: d forProperty: ADBirthdayProperty];
      else
	NSLog(@"Can't convert %@ to date\n", [v objectAtIndex: 0]);
    }
  
  else if([key isEqualToString: @"note"])
    [p setValue: [v objectAtIndex: 0] forProperty: ADNoteProperty];

  // phone -- multi-string
  else if([key isEqualToString: @"tel"])
    {
      ADMutableMultiValue *mv;
      NSString *val;

      mv = [[[ADMutableMultiValue alloc]
	      initWithMultiValue: [p valueForProperty: ADPhoneProperty]]
	     autorelease];
      val = [v objectAtIndex: 0];
      if([k containsObject: @"fax"])
	{
	  if([k containsObject: @"home"])
	    [mv addValue: val withLabel: ADPhoneHomeFAXLabel];
	  else
	    [mv addValue: val withLabel: ADPhoneWorkFAXLabel];
	}
      else if([k containsObject: @"pager"])
	{
	  [mv addValue: val withLabel: ADPhonePagerLabel];
	}
      else // assume "voice" for everything else
	{
	  if([k containsObject: @"main"])
	    [mv addValue: val withLabel: ADPhoneMainLabel];
	  else if([k containsObject: @"cell"])
	    [mv addValue: val withLabel: ADPhoneMobileLabel];
	  else if([k containsObject: @"home"])
	    [mv addValue: val withLabel: ADPhoneHomeLabel];
	  else
	    [mv addValue: val withLabel: ADPhoneWorkLabel];
	}
      [p setValue: mv forProperty: ADPhoneProperty];
    }

  // email -- multi-string
  else if([key isEqualToString: @"email"])
    {
      ADMutableMultiValue *mv;

      mv = [[[ADMutableMultiValue alloc]
	      initWithMultiValue: [p valueForProperty: ADEmailProperty]]
	     autorelease];

      if([k containsObject: @"home"])
	[mv addValue: [v objectAtIndex: 0] withLabel: ADEmailHomeLabel];
      else
	[mv addValue: [v objectAtIndex: 0] withLabel: ADEmailWorkLabel];

      [p setValue: mv forProperty: ADEmailProperty];
    }

  else if([key isEqualToString: @"adr"])
    {
      ADMutableMultiValue *mv;

      NSMutableDictionary *dict;
      NSString *poBox, *extendedAddr, *street, *locality, *region,
	*postalCode, *countryName;

      mv = [[[ADMutableMultiValue alloc]
	      initWithMultiValue: [p valueForProperty: ADAddressProperty]]
	     autorelease];

      dict = [NSMutableDictionary dictionaryWithCapacity: 6];
      poBox        = [v objectAtIndex: 0];
      extendedAddr = [v objectAtIndex: 1];
      street       = [v objectAtIndex: 2];
      locality     = [v objectAtIndex: 3];
      region       = [v objectAtIndex: 4];
      postalCode   = [v objectAtIndex: 5];
      countryName  = [v objectAtIndex: 6];


      if(street && ![street isEqualToString: @""])
	[dict setObject: street forKey: ADAddressStreetKey];
      if(locality && ![locality isEqualToString: @""])
	[dict setObject: locality forKey: ADAddressCityKey];
      if(region && ![region isEqualToString: @""])
	[dict setObject: region forKey: ADAddressStateKey];
      if(postalCode && ![postalCode isEqualToString: @""])
	[dict setObject: postalCode forKey: ADAddressZIPKey];
      if(countryName && ![countryName isEqualToString: @""])
	[dict setObject: countryName forKey: ADAddressCountryKey];
      if(poBox && ![poBox isEqualToString: @""])
	[dict setObject: poBox forKey: ADAddressPOBoxKey];
      if(extendedAddr && ![extendedAddr isEqualToString: @""])
	[dict setObject: extendedAddr forKey: ADAddressExtendedAddressKey];
      
      if([k containsObject: @"home"])
	[mv addValue: dict withLabel: ADAddressHomeLabel];
      else
	[mv addValue: dict withLabel: ADAddressWorkLabel];

      [p setValue: mv forProperty: ADAddressProperty];
    }

  else if([key isEqualToString: @"photo"])
    {
      NSString *encoding;
      NSString *type;
      NSData *data;
      
      NSLog(@"Photo str found. Keys %@", k);
      
      encoding = [k restOfStringStartingWith: @"encoding="];
      if(![encoding isEqualToString: @"base64"] &&
	 ![encoding isEqualToString: @"b"] &&  // Evolution exports this way
	 ![k containsObject: @"base64"])
	{
	  NSLog(@"Cannot integrate image -- unknown "
		@"encoding '%@'\n", encoding);
	  return;
	}
      type = [k restOfStringStartingWith: @"type="];
      
      data = base64Decode([v objectAtIndex: 0]);
      
      // Let's hope NSImage handles this
      [p setImageData: data];
      if(type)
	[p setImageDataType: type];
      else
	[p setImageDataType: @"jpg"]; // FIXME: This is a fallback solution :-(
    }

  // FIXME: The following keys (specified in the vcard spec) aren't
  // handled by this converter yet, because they're not in the Apple
  // spec, but should perhaps be: 
  // @"label" -- free-form postal delivery label text
  // @"key"   -- public key
  // @"rev"   -- last revision in ISO8601 format, which NSDate can't
  //             parse (yet)
}

- (void) appendStringForProperty: (NSString*) prop
			inPerson: (ADPerson*) p
{
  id val; int i; NSString *label, *identifier, *vcfLabel, *hdr, *fmt;

  val = [p valueForProperty: prop];
  if(!val || ([val respondsToSelector: @selector(count)] && ![val count]))
    return;

  if([prop isEqualToString: ADOrganizationProperty])
    [self appendStringWithHeader: @"ORG" value: val];
  else if([prop isEqualToString: ADJobTitleProperty])
    [self appendStringWithHeader: @"TITLE" value: val];
  else if([prop isEqualToString: ADHomePageProperty])
    [self appendStringWithHeader: @"URL" value: val];
  else if([prop isEqualToString: ADNoteProperty])
    [self appendStringWithHeader: @"NOTE" value: val];
  else if([prop isEqualToString: ADPhoneProperty]) // multi-string
    {
      NSString *value;

      for(i=0; i<[val count]; i++)
	{
	  value = [val valueAtIndex: i];
	  identifier = [val identifierAtIndex: i];
	  label = [val labelAtIndex: i];
	  vcfLabel = @"";

	  if([label isEqualToString: ADPhoneWorkLabel] ||
	     [label isEqualToString: ADWorkLabel])
	    vcfLabel = @"WORK;VOICE;";
	  else if([label isEqualToString: ADPhoneHomeLabel] ||
		  [label isEqualToString: ADHomeLabel])
	    vcfLabel = @"HOME;VOICE;";
	  else if([label isEqualToString: ADPhoneMobileLabel])
	    vcfLabel = @"CELL;VOICE;";
	  else if([label isEqualToString: ADPhoneMainLabel])
	    vcfLabel = @"PREF;VOICE;";
	  else if([label isEqualToString: ADPhoneHomeFAXLabel])
	    vcfLabel = @"HOME;FAX;";
	  else if([label isEqualToString: ADPhoneWorkFAXLabel])
	    vcfLabel = @"WORK;FAX;";
	  else if([label isEqualToString: ADPhonePagerLabel])
	    vcfLabel = @"PAGER;";
	  else if([label isEqualToString: ADOtherLabel])
	    vcfLabel = @"OTHER;";

	  hdr = [NSString stringWithFormat: @"TEL;%@X-GNUSTEPLABEL=%@;"
			  @"X-GNUSTEPID=%@;%d", vcfLabel, label,
			  identifier, i+1];
	  [self appendStringWithHeader: hdr
		value: value];
	}
    }
  else if([prop isEqualToString: ADEmailProperty])
    {
      NSString *value;

      for(i=0; i<[val count]; i++)
	{
	  value = [val valueAtIndex: i];
	  identifier = [val identifierAtIndex: i];
	  label = [val labelAtIndex: i];
	  vcfLabel = @"";

	  if([label isEqualToString: ADEmailWorkLabel] ||
	     [label isEqualToString: ADWorkLabel])
	    vcfLabel = @"WORK;";
	  else if([label isEqualToString: ADEmailHomeLabel] ||
		  [label isEqualToString: ADHomeLabel])
	    vcfLabel = @"HOME;";
	  else if([label isEqualToString: ADOtherLabel])
	    vcfLabel = @"OTHER;";

	  hdr =
	    [NSString stringWithFormat: @"EMAIL;INTERNET;%@X-GNUSTEPLABEL=%@;"
		      @"X-GNUSTEPID=%@;%d", vcfLabel, label, identifier, i+1];
	  [self appendStringWithHeader: hdr
		value: value];
	}
    }
  else if([prop isEqualToString: ADAddressProperty])
    {
      NSDictionary *value;
      NSString *poBox, *extAddr, *street, *locality,
	*region, *postalCode, *country;

      for(i=0; i<[val count]; i++)
	{
	  value = [val valueAtIndex: i];
	  identifier = [val identifierAtIndex: i];
	  label = [val labelAtIndex: i];
	  vcfLabel = @"";

	  if([label isEqualToString: ADAddressWorkLabel] ||
	     [label isEqualToString: ADWorkLabel])
	    vcfLabel = @"WORK;";
	  else if([label isEqualToString: ADAddressHomeLabel] ||
		  [label isEqualToString: ADHomeLabel])
	    vcfLabel = @"HOME;";
	  else if([label isEqualToString: ADOtherLabel])
	    vcfLabel = @"OTHER;";

	  poBox = [value objectForKey: ADAddressPOBoxKey];
	  if(!poBox) poBox = @"";
	  extAddr = [value objectForKey: ADAddressExtendedAddressKey];
	  if(!extAddr) extAddr = @"";
	  street = [value objectForKey: ADAddressStreetKey];
	  if(!street) street = @"";
	  locality = [value objectForKey: ADAddressCityKey];
	  if(!locality) locality = @"";
	  region = [value objectForKey: ADAddressStateKey];
	  if(!region) region = @"";
	  postalCode = [value objectForKey: ADAddressZIPKey];
	  if(!postalCode) postalCode = @"";
	  country = [value objectForKey: ADAddressCountryKey];
	  if(!country) country = @"";

	  hdr = [NSString stringWithFormat: @"ADR;%@X-GNUSTEPLABEL=%@;"
			  @"X-GNUSTEPID=%@;%d", vcfLabel, label,
			  identifier, i+1];
	  fmt = [NSString stringWithFormat: @"%@;%@;%@;%@;%@;%@;%@",
			  poBox, extAddr, street, locality, region,
			  postalCode, country];
	  [self appendStringWithHeader: hdr value: fmt];
	}      
    }
  else if([prop isEqualToString: ADImageProperty])
    {
      if ([p valueForProperty: ADImageTypeProperty])
        hdr = [NSString stringWithFormat: @"PHOTO;TYPE=%@;ENCODING=BASE64",
		      [[p valueForProperty: ADImageTypeProperty]
			uppercaseString]];
      else
        hdr = [NSString stringWithFormat: @"PHOTO;ENCODING=BASE64"];
      [self appendStringWithHeader: hdr
	    value: base64Encode(val)
	    binaryLinebreak: YES];
    }
  else if([prop isEqualToString: ADBirthdayProperty])
    [self appendStringWithHeader: @"BDAY"
	  value: [val descriptionWithCalendarFormat: @"%Y-%d-%m"]];
  else
    NSLog(@"Warning: Unhandled property '%@' in conversion to vcard\n",
	  prop);
}

- (void) appendStringWithHeader: (NSString*) header
			  value: (NSString*) value
{
  return [self appendStringWithHeader: header
	       value: value
	       binaryLinebreak: NO];
}

- (void) appendStringWithHeader: (NSString*) header
			  value: (NSString*) value
		binaryLinebreak: (BOOL) blb
{
  const char *str1, *str2;

  str1 = [value lossyCString];
  str2 = [value UTF8String];
  if(strcmp(str1, str2) != 0)
    {
      value = [value stringByQuotedPrintableEncoding];
      header = [header stringByAppendingString:
			 @";ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8"];
    }

  if(!([value length] >= 76) || !blb)
    [_out appendFormat: @"%@:%@\r\n", header, value];
  else
    {
      int i;

      [_out appendFormat: @"%@:\r\n", header];
      for(i=0; i<[value length]; i+=76)
	{
	  NSString *substr;

	  substr = [value substringFromIndex: i];
	  if([substr length] > 76)
	    substr = [value substringWithRange: NSMakeRange(i, 76)];

	  [_out appendFormat: @" %@\r\n", substr];
	}
    }
}
@end
