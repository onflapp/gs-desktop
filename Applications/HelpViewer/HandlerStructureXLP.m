/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003 Nicolas Roard (nicolas@roard.com)
                  2020 Riccardo Mottola <rm@gnu.org>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the
    Free Software Foundation, Inc.  
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
*/

#include "HandlerStructureXLP.h"

#define HAVING(str) ([[elementName lowercaseString] isEqualToString: str])

@implementation HandlerStructureXLP

- (id) init
{
  if ((self = [super init]))
    {
      _firstSection = [[Section alloc] initWithHeader: @"document"];
      _currentSection = _firstSection;
      _document = NO;
      content = nil;
    }
  return self;
}

- (id) initWithSection: (Section*) section
{
  if ((self = [super init]))
    {
      ASSIGN (_firstSection, section);
      _currentSection = _firstSection;
      _currentContent = [section text];
      _document = YES;
      content = nil;
    }
  return self;
}

- (void) dealloc
{
  RELEASE (_firstSection);
  [super dealloc];
}

- (void) startElement: (NSString*) elementName attributes: (NSMutableDictionary*) elementAttributes {
    //NSLog (@"startElement : <%@>", elementName);
    NSString* name = nil;
    NSString* src = nil;

    if ([elementAttributes objectForKey: @"name"] != nil)
    {
	name = [NSString stringWithString: [elementAttributes objectForKey: @"name"]];
    }

    if ([elementAttributes objectForKey: @"src"] != nil)
    {
	src = [NSString stringWithString: [elementAttributes objectForKey: @"src"]];
    }

    if HAVING (@"document") 
    { 
    	_document = YES; 
    }

    if (_document)
    {
	if (
		HAVING (@"section")
		|| HAVING (@"chapter")
		|| HAVING (@"part")
		|| HAVING (@"plain")
	   )
	{
		//NSLog (@"<section>name=%@", name);
		Section* newSection = [[Section alloc] initWithHeader: name];
		if (src != nil)
		{
			[newSection setPath: src];
		}

		if HAVING (@"chapter") [newSection setType: SECTION_TYPE_CHAPTER];
		if HAVING (@"part") [newSection setType: SECTION_TYPE_PART];
		if HAVING (@"plain") [newSection setType: SECTION_TYPE_PLAIN];

		[_currentSection setLoaded: YES];
		[_currentSection addSub: newSection];
		_currentSection = newSection;
		_currentContent = [newSection text];
		[_currentSection retain];
		[_currentContent retain];
	}
	else
	{
		id tag = [[NSString alloc] initWithFormat: @"<%@", elementName];
		id str = [[NSMutableAttributedString alloc] initWithString: tag];

		[tag release];
		
		NSEnumerator *enumerator = [elementAttributes keyEnumerator];
		id key;
	
		while ((key = [enumerator nextObject])) 
		{
			id strelem = [[NSString alloc] initWithFormat: @" %@=%@",
				key, [elementAttributes objectForKey: key]];
			id astrelem = [[NSMutableAttributedString alloc] initWithString: strelem];
			[str appendAttributedString: astrelem];
			[astrelem release];
			[strelem release];
	    	}
		id strend = [[NSMutableAttributedString alloc] initWithString: @">"];

		[_currentContent appendAttributedString: str];
		[_currentContent appendAttributedString: strend];
		//[self addCurrentProgression: ([str length] + 1)];

		[str release];
		[strend release];
	}
    }
}

- (void) endElement: (NSString*) elementName {
    //NSLog (@"endElement : <%@>", elementName);

    if HAVING (@"document") 
    { 
    	_document = NO; 
    }

    if (_document)
    {
	if (
		HAVING (@"section")
		|| HAVING (@"chapter")
		|| HAVING (@"part")
		|| HAVING (@"plain")
	   )
	{
		//NSLog (@"characters (attr) : %@", _currentContent);
		//NSLog (@"</section>");

		if ([[_currentSection text] length] > 0)
		{
			[_currentSection setLoaded: YES];
		}
		
		Section* parent = [_currentSection parent];
		if (parent != nil)
		{	
			ASSIGN (_currentSection, parent);
			ASSIGN (_currentContent, [parent text]);
		}
	}
	else
	{
		id tag = [[NSString alloc] initWithFormat: @"</%@>", elementName];
		id str = [[NSMutableAttributedString alloc] initWithString: tag];
		[_currentContent appendAttributedString: str];
		//[self addCurrentProgression: [str length]];
		[str release];
		[tag release];
		//NSLog (@"</%@>",elementName);
	}
    }

}

- (void) characters: (NSString*) name {
    if (_document)
    {
    	//NSLog (@"characters : %@", name);
	NSString* str;

	if ([name isEqualToString: @"<"])
	  str = @"&lt;";
	else if ([name isEqualToString: @">"])
          str = @"&gt;";
	else
	  str = [NSString trimString: name];
	
    	NSMutableAttributedString* astr = [[NSMutableAttributedString alloc] initWithString: str];
	[_currentContent appendAttributedString: astr];
	//[self addCurrentProgression: [astr length]];
	[astr release];
    }
}

- (void) addCurrentProgression: (int) add
{
	current += add;
	NSLog (@"Lu (%d) : %.2f / %.2f (%.2f%)", add, current, max, current*100/max);
}

- (Section*) sections {
	return _firstSection;
}
- (void) setPath: (NSString*) p {
	if (p != nil)
	{
		ASSIGN (path, p);
		//NSLog (@"Handler setPath: %@", p);
		content = [[NSData alloc] initWithContentsOfFile: path];
	}
}
- (void) parse {
	NSLog (@"HandlerStructureXLP parse");
	//[Parser parserWithHandler: self withData: content];
	max = (float) [content length];
	[[GSHTMLParser parserWithSAXHandler: self withData: content] parse];
	current = max;
}

- (void) setTextView: (NSTextView*) textview {
//    textView = textview;
}

@end
