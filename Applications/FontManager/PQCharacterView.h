/*
 * PQCharacterView.h - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 12/01/07
 * License: 3-Clause BSD license (see file COPYING)
 */


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface PQCharacterView : NSView
{
	NSString *fontName;
	float fontSize;

	NSColor *color;
	NSColor *guideColor;
	NSColor *backgroundColor;
	
	unichar character;
}

- (void) setFontSize: (float)newSize;
- (float) fontSize;
- (void) setFont: (NSString *)newFontName;
- (NSString *) font;
- (void) setCharacter: (unichar)newCharacter;
- (unichar) character;

@end
