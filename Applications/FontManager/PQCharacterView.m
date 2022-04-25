/*
 * PQCharacterView.m - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 12/01/07
 * License: 3-Clause BSD license (see file COPYING)
 */


#ifdef GNUSTEP
#import <GNUstepGUI/GSTheme.h>
#endif
#import <stdlib.h>
#import <math.h>
#import "PQCharacterView.h"
#import "PQCompat.h"


#define invf(f) ((f > 0.0) ? (f - (f * 2.0)) : fabs(f))


@implementation PQCharacterView

- (id) initWithFrame: (NSRect)frame
{
	[super initWithFrame: frame];

	fontName = [[NSFont userFontOfSize: 144.0] fontName];
	fontSize = 144.0;
	
	color = [NSColor blackColor];
	guideColor = [NSColor redColor];
	backgroundColor = [NSColor whiteColor];
	
	character = 0;
	
	RETAIN(fontName);
	RETAIN(color);
	RETAIN(guideColor);
	RETAIN(backgroundColor);

	return self;
}

- (void) dealloc
{
	RELEASE(fontName);
	RELEASE(color);
	RELEASE(guideColor);
	RELEASE(backgroundColor);
	
	[super dealloc];
}

- (void) setFontSize: (float)newSize
{
	fontSize = newSize;
	
	[self setNeedsDisplay: YES];
}

- (float) fontSize
{
	return fontSize;
}

- (void) setFont: (NSString *)newFontName
{
	ASSIGN(fontName, newFontName);
	
	[self setNeedsDisplay: YES];
}

- (NSString *) font
{
	return fontName;
}

- (void) setCharacter: (unichar)newCharacter
{
	character = newCharacter;
	
	[self setNeedsDisplay: YES];
}

- (unichar) character
{
	return character;
}


/* Drawing */

- (void) drawRect: (NSRect)rect
{
	NSFont *font = [NSFont fontWithName: [self font] size: [self fontSize]];
	NSBezierPath *path = [[NSBezierPath alloc] init];
	
#ifndef GNUSTEP
	NSCharacterSet *fontCharacterSet = [font coveredCharacterSet];
#endif
	
	/* Text system components */
	NSTextStorage *textStorage;
	NSLayoutManager *layoutManager;

	/* Set up text system */
	textStorage = [[NSTextStorage alloc] initWithString:
		[NSString stringWithCharacters: &character length: 1]];
	[textStorage addAttribute: NSFontAttributeName
											value: font
											range: NSMakeRange(0, [textStorage length])];
	[textStorage addAttribute: NSForegroundColorAttributeName
											value: color
											range: NSMakeRange(0, [textStorage length])];
	layoutManager = [[NSLayoutManager alloc] init];
	[textStorage addLayoutManager: layoutManager];
	RELEASE(layoutManager); /* Retained by textStorage */
	
	[backgroundColor set];
	[NSBezierPath fillRect: rect];

	float advancement =
		[font advancementForGlyph: [layoutManager glyphAtIndex: 0]].width;

#ifndef GNUSTEP
	if ([layoutManager numberOfGlyphs] > 0 && advancement > 0.0 &&
	    [fontCharacterSet characterIsMember: character])
#else
	if ([layoutManager numberOfGlyphs] > 0 && advancement > 0.0)
#endif
	{
		float ascent = [font ascender];
		float descent = [font descender];
		float xHeight = [font xHeight];
		float italicAngle = [font italicAngle];
		float yOffset = (rect.size.height - [textStorage size].height) / 2.0;
    float baseline = yOffset + abs(descent);
		float xOffset = NSMidX(rect) - (advancement / 2.0);
				
    [guideColor set];

		[path moveToPoint: NSMakePoint(0.0, baseline)];
		[path lineToPoint: NSMakePoint(rect.size.width, baseline)];

		[path stroke];

		[path removeAllPoints];

		float pattern[] = {1.0, 2.0};
		[path setLineDash: pattern count: 2 phase: 0.0];

		[path moveToPoint: NSMakePoint(xOffset, 0.0)];
		[path lineToPoint: NSMakePoint(xOffset, rect.size.height)];

		[path moveToPoint: NSMakePoint(xOffset + advancement, 0.0)];
		[path lineToPoint: NSMakePoint(xOffset + advancement,
		                               rect.size.height)];

		[path moveToPoint: NSMakePoint(0.0, baseline + descent)];
		[path lineToPoint: NSMakePoint(rect.size.width, baseline + descent)];

		[path moveToPoint: NSMakePoint(0.0, baseline + ascent)];
		[path lineToPoint: NSMakePoint(rect.size.width, baseline + ascent)];

		[path moveToPoint: NSMakePoint(0.0, baseline + xHeight)];
		[path lineToPoint: NSMakePoint(rect.size.width, baseline + xHeight)];

		// NOTE: Mac OS X version 10.3 seems to return a bogus italic angle.
		if (italicAngle != 0.0)
		{
			float top = ([self frame].size.height / 2.0);
			float bottom = ([self frame].size.height / 2.0);
			float tangent = tan(invf(italicAngle) * (3.141592 / 180.0));

			[path moveToPoint:
				NSMakePoint(xOffset + (tangent * top),
										[self frame].size.height)];
			[path lineToPoint:
				NSMakePoint(xOffset - (tangent * bottom), 0.0)];

			[path moveToPoint:
				NSMakePoint(xOffset + advancement + (tangent * top),
										[self frame].size.height)];
			[path lineToPoint:
				NSMakePoint((xOffset + advancement) - (tangent * bottom), 0.0)];
		}

		[path stroke];

		[textStorage drawAtPoint: NSMakePoint(xOffset, yOffset)];       
	}
	
#ifdef GNUSTEP
	[[GSTheme theme] drawGrayBezel: NSMakeRect(0.0, 0.0,
	                                           [self frame].size.width,
																						 [self frame].size.height)
												withClip: rect];
#else
	[[NSColor lightGrayColor] set];
	[NSBezierPath strokeRect:NSInsetRect(NSMakeRect(0.0, 0.0,
																									[self frame].size.width,
																									[self frame].size.height),
																			 0.5, 0.5)];
#endif
}

@end
