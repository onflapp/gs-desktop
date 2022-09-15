/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003      Nicolas Roard (nicolas@roard.com)
                  2020-2021 Riccardo Mottola <rm@gnu.org>

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

#include "TextFormatterXLP.h"

#define HAVING(str) ([[elementName lowercaseString] isEqualToString: str])

@implementation TextFormatterXLP

- (id) init
{
  if ((self = [super init]))
    {
      _firstSection = [[Section alloc] initWithHeader: @"document"];
      _listCounter = [[NSMutableArray alloc] init];
      legends = nil;
      _currentSection = _firstSection;
      _document = NO;
      Bundle = nil;
      content = nil;
    }
  return self;
}

- (void) startElement: (NSString*) elementName attributes: (NSMutableDictionary*) elementAttributes {
    if (_pre)
    {
    	// verbatim mode
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

	[str release];
	[strend release];
    }
    else
    {
    	if HAVING (@"b")
    	{
		_bold = YES;
    	}
	else if HAVING (@"i")
	{
		_italic = YES;
	}
	else if HAVING (@"sc")
	{
		_smallcaps = YES;
	}
	else if HAVING (@"code")
	{
		_code = YES;
	}
	else if HAVING (@"pre")
	{
		_pre = YES;
		_code = YES;
	}
	else if HAVING (@"url")
	{
		_url = YES;
	}
	else if HAVING (@"br")
	{
		id str = [[NSMutableAttributedString alloc] initWithString: @"\n"];
		if ((_legendfig) || (_note) || (_caution) || (_listing) || (_information))
		{
			[_string appendAttributedString: str];
		}
		else
		{
			[_currentContent appendAttributedString: str];
		}
		[str release];
	}
        else if HAVING (@"ol") { _ol = YES; _listLevel ++;
            [_listCounter addObject: [NSDecimalNumber one]];
        }
        else if HAVING (@"ul") { _ul = YES; _listLevel ++;
            [_listCounter addObject: [NSDecimalNumber one]];
        }
        else if HAVING (@"li") {
            NSMutableString* add = [NSMutableString string];
            NSMutableParagraphStyle* paragraphStyle = [NSMutableParagraphStyle
            new];
            //defaultParagraphStyle];
            NSMutableAttributedString* AS;
            int i = 0;

            [add appendString: @"\n"];
            //NSLog (@"on a li, listlevel : %d", _listLevel);

            if (_listLevel > 0)
            {
                for (i = 0; i< _listLevel; i++)
                {
                    [add appendString: @"  "];
                }
                if (_ol)
                {
                    NSDecimalNumber* counter = [_listCounter lastObject];
                    [add appendString: [counter stringValue]];
                    counter = [counter decimalNumberByAdding: [NSDecimalNumber one]];
                    [_listCounter replaceObjectAtIndex: [_listCounter count] -1 withObject: counter];
                    [add appendString: @". "];
                }
                else if (_ul)
                {
                    [add appendString: @" "];
                }
            }
            _li = YES;
            //printf ("on ajoute la chaine : <%s>\n", [add cString]);
            AS = [[NSMutableAttributedString alloc] initWithString: add];
            NSMutableAttributedString* space = [[NSMutableAttributedString alloc] initWithString: @" "];
	    if (_listLevel > 0) [self addImage: [NSImage imageNamed: @"Point2.tiff"] onString: AS];
	    [AS appendAttributedString: space];
	    [space release];
            //[paragraphStyle setAlignment: NSLeftTextAlignment];
            [paragraphStyle setHeadIndent: 16.0];
            //[paragraphStyle setTailIndent: 100.0];
            [AS addAttribute: NSParagraphStyleAttributeName
                value: paragraphStyle
                range: NSMakeRange(0,[AS length])];
	    [paragraphStyle release];
	    [_currentContent appendAttributedString: AS];
            RELEASE (AS);
        }
        else if HAVING (@"img") {
            NSString* src = nil;
            if ([elementAttributes objectForKey: @"src"] != nil)
            {
                src = [NSString stringWithString: [elementAttributes objectForKey: @"src"]];
                //NSLog (@"src : %@", src);
                [self addImage: [Bundle pathForResource: [src stringByDeletingPathExtension] ofType: [src pathExtension]]];
            }
        }
        else if HAVING (@"legendfig") {
            _legendfig = YES; 
            RELEASE (legends);
            legends = [[NSMutableArray alloc] init];

            RELEASE (imgSource);
            if ([elementAttributes objectForKey: @"src"] != nil)
            {
                imgSource = [[NSString alloc] initWithString: [elementAttributes objectForKey: @"src"]];
                //NSLog (@"src : %@", imgSource);
            }
        }
        else if HAVING (@"legend") {
            int x, y;
            x = y = 0;
            _preString = _string;
            _string = [[NSMutableAttributedString alloc] init];
         
            if ([elementAttributes objectForKey: @"x"] != nil)
            {
                x = [[elementAttributes objectForKey: @"x"] intValue];
            }

            if ([elementAttributes objectForKey: @"y"] != nil)
            {
                y = [[elementAttributes objectForKey: @"y"] intValue];
            }

            legendX = x;
            legendY = y;
        }
	else if HAVING (@"note") {
		_note = YES;
		_preString = _string;
		_string = [[NSMutableAttributedString alloc] init];
	}
	else if HAVING (@"listing") {
		_listing = YES;
		_preString = _string;
		_string = [[NSMutableAttributedString alloc] init];
	}
	else if HAVING (@"caution") {
		_caution = YES;
		_preString = _string;
		_string = [[NSMutableAttributedString alloc] init];
	}
	else if HAVING (@"information") {
		_information = YES;
		_preString = _string;
		_string = [[NSMutableAttributedString alloc] init];
	}
    }
}

- (void) endElement: (NSString*) elementName {

	if HAVING (@"pre")
	{
		_pre = NO;
		_code = NO;
	}
	if (_pre)
	{
		id tag = [[NSString alloc] initWithFormat: @"</%@>", elementName];
		id str = [[NSMutableAttributedString alloc] initWithString: tag];
		[_currentContent appendAttributedString: str];
		[str release];
		[tag release];
	}
	else 
	{
		if HAVING (@"b")
		{
			_bold = NO;
		}
		else if HAVING (@"i")
		{
			_italic = NO;
		}
		else if HAVING (@"sc")
		{
			_smallcaps = NO;
		}
		else if HAVING (@"code")
		{
			_code = NO;
		}
		else if HAVING (@"url")
		{
			_url = NO;
		}
		else if HAVING (@"ol") {
		    _ol = NO;
		    _listLevel --;
		    [_listCounter removeObjectAtIndex: [_listCounter count] -1];
		}
		else if HAVING (@"ul") {
		    _ul = NO;
		    _listLevel --;
		}
		else if HAVING (@"li") _li = NO;
		else if HAVING (@"legendfig") {
		    _legendfig = NO;
		    [self addLegendFig: imgSource withLegends: legends];
		}
		else if HAVING (@"legend") {
		    Legend* current = [Legend legendWithString: _string andPoint: NSMakePoint (legendX, legendY)];
		    RELEASE (_string);
		    _string = _preString;
		    [legends addObject: current];
		}
		else if HAVING (@"note") {
			[self addNote: _string 
				withImage: [NSImage imageNamed: @"note.png"]
				withColor: [NSColor colorWithCalibratedRed: 0.81 green: 0.84 blue: 0.88 alpha:1.0]];
			RELEASE (_string);
			_string = _preString;
			_note = NO;
		}
		else if HAVING (@"listing") {
			[self addNote: _string 
				withImage: [NSImage imageNamed: @"listing.png"]
				withColor: [NSColor colorWithCalibratedRed: 0.88 green: 0.88 blue: 0.88 alpha:1.0]];
			RELEASE (_string);
			_string = _preString;
			_listing = NO;
		}
		else if HAVING (@"caution") {
			[self addNote: _string 
				withImage: [NSImage imageNamed: @"caution.png"]
				withColor: [NSColor colorWithCalibratedRed: 0.88 green: 0.78 blue: 0.78 alpha:1.0]];
			RELEASE (_string);
			_string = _preString;
			_caution = NO;
		}
		else if HAVING (@"information") {
			[self addNote: _string 
				withImage: [NSImage imageNamed: @"information.png"]
				withColor: [NSColor colorWithCalibratedRed: 0.79 green: 0.89 blue: 0.78 alpha:1.0]];
			RELEASE (_string);
			_string = _preString;
			_information = NO;
		}
	}
}

- (void) characters: (NSString*) name {
    NSMutableDictionary* attr = [NSMutableDictionary dictionaryWithCapacity: 2];
    NSFont* font = nil;
    NSFontTraitMask FontMask = 0;
    int FontSize = 12;

        if (_bold) FontMask = NSBoldFontMask | FontMask;
	if (_italic) FontMask = NSItalicFontMask | FontMask;
	if (_smallcaps) FontMask = NSSmallCapsFontMask | FontMask;
	if (_code || _url) font = [NSFont userFixedPitchFontOfSize: FontSize];
	else font = [NSFont userFontOfSize: FontSize];

        font = [[NSFontManager sharedFontManager]
                    convertFont: font
                    toHaveTrait: FontMask];

        //[attr setObject: paragraphStyle forKey: NSParagraphStyleAttributeName];
        [attr setObject: font forKey: NSFontAttributeName];
        
	id str = [[NSMutableAttributedString alloc] initWithString: name attributes: attr];

	if ((_legendfig) || (_note) || (_caution) || (_listing) || (_information))
	{
		[_string appendAttributedString: str];
	}
	else
	{
		[_currentContent appendAttributedString: str];
	}

	[str release];
}

- (void) setBundle: (NSBundle*) bundle {
	ASSIGN (Bundle, bundle);
}

- (NSMutableAttributedString*) renderHeader: (NSString*) header withLevel: (int) level
{
    NSMutableDictionary* attr = [NSMutableDictionary dictionaryWithCapacity: 2];
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    NSFont* font;
    NSFontTraitMask FontMask = 0;

    [paragraphStyle setAlignment: NSLeftTextAlignment];

    CGFloat fontSize = 12.0;
    int ruleHeight = 0;

    switch (level)
    {
	case 0: 
		fontSize = 24; 
		FontMask = NSBoldFontMask | FontMask;
		ruleHeight = 3;
		break;
	case 1: 
		fontSize = 20; 
		FontMask = NSBoldFontMask | FontMask;
		ruleHeight = 1;
		break;
	case 2: 
		fontSize = 16; 
		FontMask = NSBoldFontMask | FontMask;
		ruleHeight = 1;
		break;
	default:
		fontSize = 12;
		FontMask = NSBoldFontMask | FontMask;
    }

    font = [[NSFontManager sharedFontManager]
                convertFont: [NSFont userFontOfSize: fontSize]
                toHaveTrait: FontMask];

    //[attr setObject: paragraphStyle forKey: NSParagraphStyleAttributeName];
    [attr setObject: font forKey: NSFontAttributeName];

    [paragraphStyle release];

    NSMutableAttributedString* ret = [[NSMutableAttributedString alloc] init];
    NSMutableAttributedString* astring = [[NSMutableAttributedString alloc] initWithString: @"\n"];
    if (level) {
    	[ret appendAttributedString: astring];
    	[ret appendAttributedString: astring];
    }
    NSMutableAttributedString* ahead = [[NSMutableAttributedString alloc] initWithString: header attributes: attr];
    [ret appendAttributedString: ahead];
    [ahead release];
    if (ruleHeight) 
    {	
	[self addRuleTo: ret withHeight: ruleHeight];
    }
    [ret appendAttributedString: astring];
    [astring release];

    return AUTORELEASE(ret);
}

- (void) addRuleTo: (NSMutableAttributedString*) string withHeight: (CGFloat) height {
    if (height> 0)
    {
	    NSTextAttachment* BR = [[NSTextAttachment alloc] init];
    	    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];

	    BRCell* attachCell = [BRCell sharedBRCell];
	    [BR setAttachmentCell: attachCell];

	    NSMutableAttributedString* attStr = [[NSMutableAttributedString alloc] init];
	    [attStr appendAttributedString: [NSAttributedString attributedStringWithAttachment: BR]];
    	    
	    NSFont* font = [[NSFontManager sharedFontManager]
                convertFont: [NSFont userFontOfSize: 1]
                toHaveTrait: 0];

	
    	    //[attStr addAttribute: NSFontAttributeName value: font range: NSMakeRange (0, [attSStr length])];
	    [paragraphStyle setMaximumLineHeight: (CGFloat) height];
    	    [attStr addAttribute: NSParagraphStyleAttributeName value: paragraphStyle range: NSMakeRange (0, [attStr length])];
	    [paragraphStyle release];
    	    //[attStr addAttribute: NSBackgroundColorAttributeName value: [NSColor redColor] range: NSMakeRange (0, [attStr length])];
	    [attStr addAttribute: @"BRCellHeight" value: [NSNumber numberWithInt: height] range: NSMakeRange (0,[attStr length])];
    	    NSMutableAttributedString* astring = [[NSMutableAttributedString alloc] initWithString: @"\n"];

	    [string appendAttributedString: astring];
	    [string appendAttributedString: attStr];
	    [attStr release];
	    //[string appendAttributedString: astring];
    	    [astring release];
	    RELEASE (BR);
    }
}

- (NSMutableAttributedString*) renderText: (NSMutableAttributedString*) text
{
	RELEASE (_currentContent);
	_currentContent = [[NSMutableAttributedString alloc] init];
	//[Parser parserWithHandler: self withData:
	[[GSHTMLParser parserWithSAXHandler: self withData: 
		[[text string] dataUsingEncoding:  NSISOLatin1StringEncoding
		allowLossyConversion: YES]]
		parse];
	return _currentContent;
}

- (void) setTextView: (NSTextView*) textview {
    textView = textview;
}

- (void) addImage: (NSImage*) img onString: (NSMutableAttributedString*) astring {
        NSTextAttachmentCell* attachCell = [[NSTextAttachmentCell alloc] initImageCell: img];

        NSTextAttachment* tAttachment = [[NSTextAttachment alloc] init];
        [tAttachment setAttachmentCell: attachCell];

        NSMutableAttributedString* t = [[NSMutableAttributedString alloc] init];
	[t appendAttributedString: [NSMutableAttributedString attributedStringWithAttachment: tAttachment]];
        //[t setAlignment: NSCenterTextAlignment range: NSMakeRange (0, [t length])];

    	[astring appendAttributedString: t];
	[t release];
        RELEASE (attachCell);
        RELEASE (tAttachment);
}


- (void) addImage: (NSString*) pathname {

    NSString* file;
    NSTextAttachment* textAttachment;

    NSLog (@"addImage : %@", pathname);

    if ([path length] == 0)
        file = pathname;
    else
        file = [NSString stringWithFormat: @"%@/%@", path, pathname];

    if ([[NSFileManager defaultManager] fileExistsAtPath: file])
    {
        //NSLog (@"on lit l'image: >%@<", file);

        NSImage* img = [[NSImage alloc] initWithContentsOfFile: file];
        NSFileWrapper* wrapper = [[NSFileWrapper alloc] initWithPath: file];
        NSTextAttachmentCell* attachCell = [[NSTextAttachmentCell alloc] initImageCell: img];

        [wrapper setIcon: [NSImage imageNamed: @"Search.tiff"]];

        textAttachment = [[NSTextAttachment alloc] initWithFileWrapper: wrapper];
        [textAttachment setAttachmentCell: attachCell];

        NSMutableAttributedString* t = [[NSMutableAttributedString alloc] init];
	[t appendAttributedString: [NSMutableAttributedString attributedStringWithAttachment: textAttachment]];
        //[t setAlignment: NSCenterTextAlignment range: NSMakeRange (0, [t length])];

    	[_currentContent appendAttributedString: t];
	[t release];
        RELEASE (img);
        RELEASE (wrapper);
        RELEASE (attachCell);
        RELEASE (textAttachment);
    }
    else
    {
        NSLog (@"l'image >%@< n'existe pas !", file);
    }
}

- (void) addNote: (NSMutableAttributedString*) string withImage: (NSImage*) img withColor: (NSColor*) color
{
    NSTextAttachment* textAttach = [[NSTextAttachment alloc] init];
    NoteCell* attachCell = [[NoteCell alloc] initWithTextView: textView];

    [attachCell setImage: img];
    [attachCell setColor: color];
    [attachCell setText: string];
    [attachCell resizeWithTextView: textView];

    [[NSNotificationCenter defaultCenter] addObserver: attachCell
					     selector: @selector (resize:)
						 name: @"NSViewFrameDidChangeNotification"
					       object: textView];

    [textAttach setAttachmentCell: attachCell];
    NSMutableAttributedString* attStr = [[NSMutableAttributedString alloc] init];
    [attStr appendAttributedString: [NSMutableAttributedString attributedStringWithAttachment: textAttach]];
    //[attStr setAlignment: NSCenterTextAlignment range: NSMakeRange (0, [attStr length])];
    NSMutableAttributedString* astring = [[NSMutableAttributedString alloc] initWithString: @"\n"];

    [_currentContent appendAttributedString: astring];
    [astring release];

    [_currentContent appendAttributedString: attStr];
    [attStr release];
    RELEASE (textAttach);
    RELEASE (attachCell);
}

- (void) addLegendFig: (NSString*) imgpath withLegends: (NSArray*) plegends
{
    NSImage* img = [[NSImage alloc] initWithContentsOfFile: 
    	[Bundle pathForResource: [imgpath stringByDeletingPathExtension] 
	ofType: [imgpath pathExtension]]];

    //NSLog (@"addLegendFig: %@ legends : %@", imgpath, plegends);

    NSTextAttachment* textAttach = [[NSTextAttachment alloc] init];
    FigureCell* attachCell = [[FigureCell alloc] initWithSize:
        NSMakeSize ([textView bounds].size.width, [img size].height)];

    [[NSNotificationCenter defaultCenter] addObserver: attachCell
        selector: @selector (resize:)
        name: @"NSViewFrameDidChangeNotification"
        object: textView];

    [attachCell setImage: img];
    [attachCell setLegends: plegends];
    [attachCell resizeWithTextView: textView];
    [textAttach setAttachmentCell: attachCell];

    NSMutableAttributedString* attStr = [[NSMutableAttributedString alloc] init];
    [attStr appendAttributedString: [NSMutableAttributedString attributedStringWithAttachment: textAttach]];
    [attStr setAlignment: NSCenterTextAlignment range: NSMakeRange (0, [attStr length])];

    [_currentContent appendAttributedString: attStr];
    [attStr release];
    RELEASE (textAttach);
    RELEASE (attachCell);
    RELEASE (img);
}



@end
