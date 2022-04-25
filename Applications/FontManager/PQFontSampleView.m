/*
 * PQFontSampleView.m - Font Manager
 *
 * A font sampling view.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/28/07
 * License: Modified BSD license (see file COPYING)
 */


#import "PQFontSampleView.h"
#import "PQCompat.h"


@implementation PQFontSampleView

- (id) initWithFrame: (NSRect)frame
{
	[super initWithFrame: frame];

	sampleText = [[NSString alloc] init];
	fontSize = 24;

	foregroundColor = [NSColor blackColor];
	backgroundColor = [NSColor whiteColor];

	/* Set up text system */
	textStorage = [[NSTextStorage alloc] init];
	layoutManager = [[NSLayoutManager alloc] init];
	textContainer = [[NSTextContainer alloc] init];
	[layoutManager addTextContainer: textContainer];
	[textStorage addLayoutManager: layoutManager];

	fontAttributesNeedUpdate = YES;

	autoSize = NO;

	RETAIN(sampleText);
	RETAIN(foregroundColor);
	RETAIN(backgroundColor);

	return self;
}

- (void) dealloc
{
	RELEASE(sampleText);
	RELEASE(foregroundColor);
	RELEASE(backgroundColor);
	
	[super dealloc];
}


/* Data source */

- (void) setDataSource: (id)anObject
{
	if ([anObject
		respondsToSelector:@selector(numberOfFontsInFontSampleView:)] == NO)
	{
			[NSException raise: NSInternalInconsistencyException 
			            format: @"Data source does not respond to "
			                    @"numberOfFontsInFontSampleView:"];
	}
	else if ([anObject
		respondsToSelector:@selector(fontSampleView:fontAtIndex:)] == NO)
	{
			[NSException raise: NSInternalInconsistencyException 
			            format: @"Data source does not respond to "
			                    @"fontSampleView:fontAtIndex:"];
	}

	dataSource = anObject;

	[self setNeedsDisplay: YES];
}

- (id) dataSource
{
	return dataSource;
}


/* View properties */

- (void) setSampleText: (NSString *)someText
{
	ASSIGN(sampleText, someText);
	fontAttributesNeedUpdate = YES;
	[self setNeedsDisplay: YES];
}

- (NSString *) sampleText
{
	return sampleText;
}

- (void) setFontSize: (int)aSize
{
	fontSize = aSize;
	fontAttributesNeedUpdate = YES;
	[self setNeedsDisplay: YES];
}

- (int) fontSize
{
	return fontSize;
}


/* Foreground and background colors */

- (void) setForegroundColor: (NSColor *)aColor
{
	ASSIGN(foregroundColor, aColor);
	[self setNeedsDisplay: YES];
}

- (NSColor *) foregroundColor
{
	return foregroundColor;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
	ASSIGN(backgroundColor, aColor);
	[self setNeedsDisplay: YES];
}

- (NSColor *) backgroundColor
{
	return backgroundColor;
}


/* Resizing */

- (void) setAutoSize: (BOOL)flag
{
	autoSize = flag;
}

- (BOOL) autoSize
{
	return autoSize;
}

- (void) setConstrainedFrameSize: (NSSize)aSize
{
	// FIXME: Shouldn't take some things for granted. (See the comments)
	id superview = [self superview];
	NSSize currentSize = [self frame].size;
	NSSize newSize = NSZeroSize;

	if ([superview isKindOfClass: [NSClipView class]] == YES)
	{
		if ([superview documentView] == self)
		{
			newSize = [superview bounds].size;
		}
	}

	/* If should resize horizontally */
	/* Fun stuff */
	/* Else */ newSize.width = currentSize.width;

	/* If should resize vertically */
	if (newSize.height < aSize.height)
	{
		newSize.height = aSize.height;
	}

	[self setFrameSize: newSize];
}


/* Drawing */

- (BOOL) isFlipped
{
	return YES;
}

- (void) drawRect: (NSRect)rect
{
	BOOL shouldUnlockFocus = NO;
	BOOL sampleChanged = NO;

	/* Set up text system */
	[textContainer setContainerSize: NSMakeSize([self frame].size.width, 50000)];


	/* Create font sample */
	if ([dataSource fontsShouldChangeInFontSampleView: self] == YES
			|| fontAttributesNeedUpdate == YES)
	{
		sampleChanged = YES;
		int fontsCount = [[self dataSource] numberOfFontsInFontSampleView: self];
		int index = 0;

		/* Font sample components */
		NSString *currentFontName;
		NSString *displayName;
		NSFont *currentFont;
		NSString *currentLabel;
		NSMutableDictionary *currentAttributes = [[NSMutableDictionary alloc] init];

		fontAttributesNeedUpdate = NO;

		[textStorage deleteCharactersInRange: NSMakeRange(0, [textStorage length])];

		while (index < fontsCount)
		{
			/* Find next font */
			currentFontName = [dataSource fontSampleView: self fontAtIndex: index];

			currentFont =
				[NSFont fontWithName: currentFontName size: [self fontSize]];

			/* Add label to text storage */
			[currentAttributes setValue: [NSFont labelFontOfSize: 0]
													 forKey: NSFontAttributeName];

			displayName = nil; /* So we know if we've found it yet. */

#ifdef GNUSTEP
			/* GNUsteps -displayName returns the post script name instead of a human
			   friendly name, so we get our own here. */

			NSString *familyName = [currentFont familyName];
			NSArray *familyMembersInfo = [[NSFontManager sharedFontManager]
				availableMembersOfFontFamily: familyName];

			NSEnumerator *membersEnum = [familyMembersInfo objectEnumerator];
			NSArray *currentMember;

			while ((currentMember = [membersEnum nextObject]))
			{
				if ([[currentMember objectAtIndex: 0] isEqualToString: currentFontName])
				{
					displayName = [NSString stringWithFormat: @"%@ %@",
					                                          familyName,
																							[currentMember objectAtIndex: 1]];
				}
			}

			if (displayName == nil) /* We haven't found it yet. */
			{
				displayName = familyName;
			}

#else
			/* If were not using GNUstep, it's probably safe to assume that
			   -displayName returns what we want */

			displayName = [currentFont displayName];

#endif

			if (index == 0)
			{
				currentLabel =
					[NSString stringWithFormat: @"%@:\n", displayName];
			}
			else
			{
				currentLabel =
					[NSString stringWithFormat: @"\n\n%@:\n", displayName];
			}

			[textStorage appendAttributedString:
				[[NSAttributedString alloc] initWithString: currentLabel
														          attributes: currentAttributes]];

			/* Add font sample to text storage */
			[currentAttributes setValue: currentFont forKey: NSFontAttributeName];

			[textStorage appendAttributedString:
				[[NSAttributedString alloc] initWithString: [self sampleText]
																				attributes: currentAttributes]];

			++index;
		}
	}

	if (autoSize == YES)
	{
		(void) [layoutManager glyphRangeForTextContainer: textContainer];

		[self setConstrainedFrameSize:
			[layoutManager usedRectForTextContainer: textContainer].size];

		/* Fix a drawing bug caused by resize. */
		rect = [self visibleRect];

		[self lockFocus];

		shouldUnlockFocus = YES;
	}

	/* Add color */
	[textStorage addAttribute: NSForegroundColorAttributeName
											value: [self foregroundColor]
											range: NSMakeRange(0, [textStorage length])];

	[[self backgroundColor] set];
	[NSBezierPath fillRect: rect];

	/* Draw font sample */
  NSRange rangeNeedsDrawing = [layoutManager glyphRangeForBoundingRect: rect
	                             inTextContainer: textContainer];

	[layoutManager drawGlyphsForGlyphRange: rangeNeedsDrawing
																 atPoint: NSMakePoint(0, 0)];

	if (shouldUnlockFocus == YES)
	{
		[self unlockFocus];
	}
}

@end
