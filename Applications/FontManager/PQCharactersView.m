/*
 * PQCharactersView.m - Font Manager
 *
 * Copyright 2008 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 02/29/08
 * License: 3-Clause BSD license (see file COPYING)
 */


#import "PQCharactersView.h"
#import "PQCompat.h"
#import <math.h>


#define rectForIndex(x) NSMakeRect((((x < columns) ? \
                                   x : (x % columns)) * width), \
			                           (floorf((float)x / (float)columns)) * height, \
		                               width, height)
																	 

@implementation PQCharactersView

- (id) initWithFrame: (NSRect)frame
{
	[super initWithFrame: frame];

	font = [NSFont userFontOfSize: 24.0];

	length = 0;
	columns = 0;
	rows = 0;
	selectedIndex = 0;
	width = 0.0;
	height = 0.0;

	RETAIN(font);

	return self;
}

- (void) dealloc
{
	RELEASE(font);
	
	[super dealloc];
}

/* Data source */

- (void) setDataSource: (id)anObject
{
	if ([anObject
		respondsToSelector:@selector(numberOfCharactersInCharactersView:)] == NO)
	{
			[NSException raise: NSInternalInconsistencyException 
			            format: @"Data source does not respond to "
			                    @"numberOfCharactersInCharactersView:"];
	}
	else if ([anObject
		respondsToSelector:@selector(charactersView:characterAtIndex:)] == NO)
	{
			[NSException raise: NSInternalInconsistencyException 
			            format: @"Data source does not respond to "
			                    @"charactersView:characterAtIndex:"];
	}

	dataSource = anObject;

	[self setNeedsDisplay: YES];
}

- (id) dataSource
{
	return dataSource;
}


- (void) setDelegate: (id)anObject
{
	delegate = anObject;
}

- (id) delegate
{
	return delegate;
}


- (void) setFont: (NSFont *)newFont
{
	ASSIGN(font, newFont);
	
	[self setNeedsDisplay: YES];
}

- (NSFont *) font
{
	return font;
}

- (void) setSelectedIndex: (unsigned int)newSelectedIndex
{
	if (selectedIndex != newSelectedIndex &&
	    newSelectedIndex < [dataSource numberOfCharactersInCharactersView: self])
	{
		if (length > 0)
		{
			[self setNeedsDisplayInRect: rectForIndex(selectedIndex)];
			[self setNeedsDisplayInRect: rectForIndex(newSelectedIndex)];
		}
		else
		{
			[self setNeedsDisplay: YES];
		}
	
		selectedIndex = newSelectedIndex;
	}
	
	if ([delegate
		respondsToSelector:@selector(selectionDidChangeInCharactersView:)] == YES)
	{
		[delegate selectionDidChangeInCharactersView: self];
	}
}

- (unsigned int) selectedIndex
{
	return selectedIndex;
}


/* Mouse Events */

- (void) mouseDown: (NSEvent *)theEvent
{
	NSPoint point =
		[self convertPoint: [theEvent locationInWindow] fromView: nil];
	
	unsigned int newSelectedIndex =
		((unsigned int)floorf(point.y / height) * columns) +
			(unsigned int)floorf(point.x / width);
	
	[self setSelectedIndex: newSelectedIndex];
}

/* Drawing */

- (BOOL) isFlipped
{
	return YES;
}

- (void) drawRect: (NSRect)rect
{
	length = [dataSource numberOfCharactersInCharactersView: self];
	
	width = [font defaultLineHeightForFont];
		/*[font maximumAdvancement].width*/
	columns = (int)floorf([self frame].size.width / width);
	width = [self frame].size.width / columns;
	height = [font defaultLineHeightForFont];
	rows = (int)ceilf((float)length / (float)columns);
	
	if ((rows * height) != [self frame].size.height)
	{
		[self setFrameSize: NSMakeSize([self frame].size.width, rows * height)];
	}

	int i = 1;
	
	[[NSColor whiteColor] set];
	
	[NSBezierPath fillRect: rect];
	
	[[NSColor selectedTextBackgroundColor] set];
	
	[NSBezierPath fillRect: rectForIndex(selectedIndex)];
	
	/*NSBezierPath *path = [[NSBezierPath alloc] init];
	
	[[NSColor gridColor] set];
	
	while (i < columns)
	{
		[path moveToPoint: NSMakePoint(i * width, 0.0)];
		[path lineToPoint: NSMakePoint(i * width, [self frame].size.height)];
		
		++i;
	}
	
	i = 1;
	
	while (i < rows)
	{
		[path moveToPoint: NSMakePoint(0.0, i * height)];
		[path lineToPoint: NSMakePoint([self frame].size.width, i * height)];
		
		++i;
	}
	
	[path stroke];*/
	
#ifndef GNUSTEP
	NSCharacterSet *fontCharacterSet = [font coveredCharacterSet];
#endif
	
	/* Text system components */
	NSTextStorage *textStorage;
	NSLayoutManager *layoutManager;

	/* Set up text system */
	textStorage = [[NSTextStorage alloc] init];
	layoutManager = [[NSLayoutManager alloc] init];
	[textStorage addLayoutManager: layoutManager];
	RELEASE(layoutManager); /* Retained by textStorage */
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObject: font
	                                                 forKey: NSFontAttributeName];
	
	i = 0;
	
	while (i < length)
	{
		NSRect charRect =
			NSInsetRect(rectForIndex(i), width - (width * 2), height - (height * 2));
	
		if (NSContainsRect(rect, charRect) || NSIntersectsRect(charRect, rect) ||
		    NSContainsRect(charRect, rect))
		{
			unichar character = [dataSource charactersView: self characterAtIndex: i];
		
			NSAttributedString *string =
				[[NSAttributedString alloc]
					initWithString: [NSString stringWithCharacters: &character length: 1]
					attributes: attributes];

			[textStorage setAttributedString: string];

			float glyphWidth =
				[font advancementForGlyph: [layoutManager glyphAtIndex: 0]].width;

#ifndef GNUSTEP
			if ((!(glyphWidth > 0.0)) ||
			      (![fontCharacterSet characterIsMember: character]))
#else /* GNUstep's NSFont -coveredCharacterSet or NSCharacterSet is broken */
			if (!(glyphWidth > 0.0))
#endif
			{
				[textStorage setAttributedString:
					[[NSAttributedString alloc] initWithString: @"?"
					                                attributes: attributes]];
			
				[textStorage addAttribute: NSForegroundColorAttributeName
														value: [NSColor lightGrayColor]
														range: NSMakeRange(0, [textStorage length])];

				glyphWidth =
					[font advancementForGlyph: [layoutManager glyphAtIndex: 0]].width;
			}
			
			NSPoint point =
				NSMakePoint((((i < columns) ? i : (i % columns)) * width) +
												((width - glyphWidth) / 2.0),
										((floorf((float)i / (float)columns)) * height) /*+
										 (([font capHeight] - height) / 2.0)*/);

			[textStorage drawAtPoint: point];
		}
		
		++i;
	}
}

@end
