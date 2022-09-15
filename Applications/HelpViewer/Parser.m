/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003 Nicolas Roard (nicolas@roard.com)

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

#include "Parser.h"

/*
   I rewrote this very simple SAX-inspired Parser ...
   Very basic, but for HelpViewer needs it's enough 
*/

#define RESET(str) [str release]; str = [[NSMutableString alloc] init];

@implementation Parser

+ (void) parserWithHandler: (id) handler
    withData: (NSData*) data
{
    //NSString* file = [NSString stringWithContentsOfFile: filename];
    NSString* file = [[NSString alloc] initWithData: data encoding: NSISOLatin1StringEncoding];
    NSMutableString* current = [[NSMutableString alloc] init];

    //NSLog (@"on a chargé le fichier %@", filename);

    if (file != nil)
    {
	int i;
	BOOL Tag = NO;
	BOOL EndingTag = NO;
	BOOL AttributeStarted = NO;
	NSString* TagName = nil;
	NSString* KeyAttribute = nil;
	NSMutableDictionary* TagAttributes = nil;

	NSLog (@"file length : %d", [file length]);

	for (i=0; i < [file length]; i++)
	{
	    unichar c = [file characterAtIndex: i];

	    if (i %1000 == 0) NSLog (@"caractères lus : %d", i);

	    if ((!Tag) && (c == '<'))
	    {
		// We have a tag ...
		Tag = YES;

		// We send the previous characters to the handler
		[handler characters: current];
		
		// We recreate a current string
		RESET (current);
	    }
	    else if ((Tag) && (c == '>')) 
	    {
		// We close a tag ...
		Tag = NO;

		// We send the tag to the handler
		if (EndingTag)
		{
		    NSLog (@"end tag name : %@", current);
		    [handler endElement: current];
		    EndingTag = NO;
		}
		else
		{
		    if (TagName == nil)
		    {
			// If no tag name, current == tag name ...
			NSLog (@"no tag name : %@", current);
			[handler startElement: current attributes: nil];
		    }
		    else
		    {
			NSLog (@"tag name : %@", TagName);
			NSLog (@"attributes : %@", TagAttributes);
			[handler startElement: TagName attributes: TagAttributes];
		    }
		    [TagName release]; TagName = nil;
		    [KeyAttribute release]; KeyAttribute = nil;
		    [TagAttributes release]; TagAttributes = nil;
		}
		RESET (current);
	    }
	    else 
	    {
		// other character ...

		if (Tag)
		{
		    if (c == '/')
		    {
			// We have a closing tag
			// FIXME : this approach is not optimal and could be wrong
			EndingTag = YES;
		    }
		    else if (c == ' ')
		    {
			if (TagName == nil)
			{
			    // We set the tag name
			    TagName = [[NSString alloc] initWithString: current];
			    RESET (current);
			}
		    }
		    else if (c == '=')
		    {
			KeyAttribute = [NSString stringWithString: current];
		        KeyAttribute = RETAIN ([NSString trimString: KeyAttribute]);
			//KeyAttribute = [[NSString alloc] init];

			RESET (current);
			if (TagAttributes == nil) 
			{
			    TagAttributes = [[NSMutableDictionary alloc] init];
			}
			AttributeStarted = NO;
		    }
		    else if (c == '"') 
		    {
			if (AttributeStarted)
			{
			    [TagAttributes setObject: current forKey: KeyAttribute];
			    [KeyAttribute release]; KeyAttribute = nil;
			    RESET (current);
			}
			else 
			{
			    AttributeStarted = YES;
			    RESET (current);
			}
		    }
		    else
		    [current appendString : [NSString stringWithCharacters: &c length: 1]];
		}
		else
		[current appendString : [NSString stringWithCharacters: &c length: 1]];
	    }
	}

	NSLog (@"Parse terminé !");

	[file release];
	[current release];
	[TagName release]; 
	[KeyAttribute release]; 
	[TagAttributes release]; 
    }
}

@end
