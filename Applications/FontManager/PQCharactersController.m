/*
 * PQCharactersController.m - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 12/02/07
 * License: 3-Clause BSD license (see file COPYING)
 */


#import "PQCharactersController.h"
#import "PQCompat.h"


@implementation PQCharactersController

- (id) init
{
	[super init];
	
	fontName = [[NSString alloc] init];
	
	unicodeBlocks =
		[NSDictionary dictionaryWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource: @"UnicodeBlocks"
																			ofType: @"plist"]];
	
	characterRange = NSMakeRange(0, 128);
	
	RETAIN(unicodeBlocks);
	RETAIN(fontName);
	
	return self;
}

- (void) dealloc
{
	RELEASE(unicodeBlocks);
	RELEASE(fontName);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	[unicodeBlockPopUpButton removeAllItems];

	NSArray *unicodeBlockNames =
		[NSArray arrayWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource: @"UnicodeBlockNames"
																			ofType: @"plist"]];

	[unicodeBlockPopUpButton addItemsWithTitles: unicodeBlockNames];

	/*
	[unicodeBlockPopUpButton addItemsWithTitles:
		[[unicodeBlocks allKeys]
			sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];
	*/
	
	[unicodeBlockPopUpButton selectItemWithTitle: @"Basic Latin"];

	[charsView setSelectedIndex: 65];
}

- (void) changeCharSize: (id)sender
{
  [charView setFontSize: [sender intValue]];
}

- (void) changeUnicodeBlock: (id)sender
{
	NSArray *unicodeBlock =
		[unicodeBlocks objectForKey: [sender titleOfSelectedItem]];
	
	unsigned int lowerBound = [[unicodeBlock objectAtIndex: 0] intValue];
	unsigned int upperBound = [[unicodeBlock objectAtIndex: 1] intValue];
	
	characterRange = NSMakeRange(lowerBound, (upperBound - lowerBound));
	
	[charsView setSelectedIndex: 0];
	[charsView setNeedsDisplay: YES];
}

- (void) setFont: (NSString *)newFontName
{
	ASSIGN(fontName, newFontName);
	
	[charView setFont: fontName];
	
	[charsView setFont: [NSFont fontWithName: fontName size: 24.0]];
}

- (NSString *) font
{
	return fontName;
}

- (int) numberOfCharactersInCharactersView: (PQCharactersView *)aCharactersView
{
	return characterRange.length;
}

- (unichar) charactersView: (PQCharactersView *)aCharactersView
					characterAtIndex: (int)index
{
	return index + characterRange.location;
}

- (void) selectionDidChangeInCharactersView: (PQCharactersView *)charactersView
{
	[charView setCharacter: characterRange.location + [charsView selectedIndex]];
}

@end
