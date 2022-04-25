/*
 * PQSamplerController.m - Font Manager
 *
 * Controller for font sampler.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: Modified BSD license (see file COPYING)
 */


#import "PQSampleController.h"
#import "PQCompat.h"


@interface PQSampleController (FontManagerPrivate)
- (void) PQAddSampleTextToHistory: (NSString *)someText;
@end


@implementation PQSampleController

- (id) init
{
	[super init];

	fonts = [[NSArray alloc] init];
	
	defaultSampleText = [[NSArray alloc] init];
			
	sampleTextHistory = [[NSMutableArray alloc] init];


	sizes = [NSArray arrayWithObjects: [NSNumber numberWithInt:9],
		[NSNumber numberWithInt:10], [NSNumber numberWithInt:11],
		[NSNumber numberWithInt:12], [NSNumber numberWithInt:13],
		[NSNumber numberWithInt:14], [NSNumber numberWithInt:18],
		[NSNumber numberWithInt:24], [NSNumber numberWithInt:36],
		[NSNumber numberWithInt:48], [NSNumber numberWithInt:64],
		[NSNumber numberWithInt:72], [NSNumber numberWithInt:96],
		[NSNumber numberWithInt:144], [NSNumber numberWithInt:288], nil];

	fontsNeedUpdate = YES;
	isCustom = NO;

	RETAIN(fonts);
	RETAIN(defaultSampleText);
	RETAIN(sampleTextHistory);
	RETAIN(sizes);

	return self;
}

- (void) awakeFromNib
{
	if ([sampleView isKindOfClass: [PQFontSampleView class]])
	{
		RELEASE(defaultSampleText);
		defaultSampleText =
			[NSArray arrayWithObjects: NSLocalizedString(@"PQPangram", nil), nil];
		RETAIN(defaultSampleText);
	}
	else if ([sampleView isKindOfClass: [NSTextView class]])
	{
		RELEASE(defaultSampleText);
		defaultSampleText =
			[NSArray arrayWithObjects:NSLocalizedString(@"PQParagraph", nil),
			                          NSLocalizedString(@"PQAlphabet", nil), nil];
		RETAIN(defaultSampleText);
		
		[sampleTextHistory addObject: @""];
	}
	
	
	if ([sampleView isKindOfClass: [PQFontSampleView class]])
	{
		[sampleView setAutoSize: YES];
		[sampleView setFontSize: 24];
		[sampleView setSampleText: NSLocalizedString(@"PQPangram", nil)];
	
		/* Couldn't set "Uses data source" in gorm */
#ifdef GNUSTEP
		[sampleField setUsesDataSource: YES];
		[sampleField setDataSource: self];
#endif
	}
	else if ([sampleView isKindOfClass: [NSTextView class]])
	{
		[sampleView setString: NSLocalizedString(@"PQParagraph", nil)];
	}
	
	/* Couldn't set "Uses data source" in gorm */
#ifdef GNUSTEP
	[sizeField setUsesDataSource: YES];
	[sizeField setDataSource: self];
#endif

	[self updateControls];
}

- (void) dealloc
{
	RELEASE(fonts);
	RELEASE(defaultSampleText);
	RELEASE(sampleTextHistory);
	RELEASE(sizes);

	[super dealloc];
}

- (void) setFonts: (NSArray *)someFonts
{
	ASSIGN(fonts, someFonts);
	
	if ([sampleView isKindOfClass: [PQFontSampleView class]])
	{
		fontsNeedUpdate = YES;
		[sampleView setNeedsDisplay: YES];
	}
	else if ([sampleView isKindOfClass: [NSTextView class]])
	{
		if ([fonts count] > 0)
		{
			[sampleView setFont: [NSFont fontWithName: [fonts objectAtIndex: 0]
			                                     size: [sizeSlider intValue]]];
			[self updateControls];
		}
	}
}

- (NSArray *) fonts
{
	return fonts;
}

- (void) setSampleTextHistory: (NSArray *)aHistory
{
	ASSIGN(sampleTextHistory, [aHistory mutableCopy]);
}

- (NSArray *) sampleTextHistory
{
	return sampleTextHistory;
}


/* Combo box data source */

- (id) comboBox: (NSComboBox *)aComboBox objectValueForItemAtIndex: (int)index
{
	if (aComboBox == sizeField)
	{
		return [sizes objectAtIndex:index];
	}
	else if (aComboBox == sampleField)
	{
		return [[defaultSampleText
			arrayByAddingObjectsFromArray: sampleTextHistory] objectAtIndex: index];
	}

	/* Else: something is wrong */
	return nil;
}

- (int) numberOfItemsInComboBox: (NSComboBox *)aComboBox
{
	if (aComboBox == sizeField)
	{
		return [sizes count];
	}
	else if (aComboBox == sampleField)
	{
		return [[defaultSampleText
			arrayByAddingObjectsFromArray: sampleTextHistory] count];
	}

	/* Else: something is wrong */
	return 0;
}


/* Font sample view data source */

- (int) numberOfFontsInFontSampleView: (PQFontSampleView *)aFontSampleView
{
	return [fonts count];
}

- (NSString *) fontSampleView: (PQFontSampleView *)aFontSampleView
									fontAtIndex: (int)rowIndex
{
	return [fonts objectAtIndex: rowIndex];
}

- (BOOL) fontsShouldChangeInFontSampleView: (PQFontSampleView *)aFontSampleView
{
	if (fontsNeedUpdate == YES)
	{
		fontsNeedUpdate = NO;
		return YES;
	}
	return NO;
}


/* Text view delegate */

- (BOOL) textView: (NSTextView *)aTextView
	shouldChangeTextInRange: (NSRange)affectedCharRange
	replacementString: (NSString *)replacementString
{
	isCustom = YES;
	
	[samplePopUpButton selectItemAtIndex: 2];
	
	return YES;
}


/* Keep controls updated */

- (void) updateControls
{
	if ([sampleView isKindOfClass: [PQFontSampleView class]])
	{
		[sampleField setStringValue: [sampleView sampleText]];
		[sizeField setIntValue: [sampleView fontSize]];
		[sizeSlider setIntValue: [sampleView fontSize]];
		[sampleField reloadData];
	}
	else if ([sampleView isKindOfClass: [NSTextView class]])
	{
		if ([fonts count] > 0)
		{
			[sizeField setIntValue: [[sampleView font] pointSize]];
			[sizeSlider setIntValue: [[sampleView font] pointSize]];
		}
	}
}

- (void) changeSize: (id)sender
{
	if ([sampleView isKindOfClass: [PQFontSampleView class]])
	{
		[sampleView setFontSize: [sender intValue]];
	}
	else if ([sampleView isKindOfClass: [NSTextView class]])
	{
		if ([fonts count] > 0)
		{
			[sampleView setFont: [NSFont fontWithName: [fonts objectAtIndex: 0]
			                                     size: [sender intValue]]];
		}
	}
	[self updateControls];
}

- (void) changeColor: (id)sender
{
	if ([sampleView isKindOfClass: [PQFontSampleView class]])
	{
		[sampleView setForegroundColor: [foregroundColorWell color]];
		[sampleView setBackgroundColor: [backgroundColorWell color]];
	}
	else if ([sampleView isKindOfClass: [NSTextView class]])
	{
		[sampleView setTextColor: [foregroundColorWell color]];
		[sampleView setBackgroundColor: [backgroundColorWell color]];
	}
}

- (void) changeSampleText: (id)sender
{
	NSString *newSampleText = nil;
	
	if ([sender isKindOfClass: [NSComboBox class]])
	{
		newSampleText = [sampleField stringValue];
	}
	else if ([sender isKindOfClass: [NSPopUpButton class]])
	{
		int count = [defaultSampleText count];
		
		if (isCustom == YES && [sampleView isKindOfClass: [NSTextView class]])
		{
			[sampleTextHistory replaceObjectAtIndex: 0
									withObject: [NSString stringWithString: [sampleView string]]];
		}
		
		if ([sender indexOfSelectedItem] < count)
		{
			newSampleText =
				[defaultSampleText objectAtIndex: [sender indexOfSelectedItem]];
				
			isCustom = NO;
		}
		else
		{
			newSampleText =
				[sampleTextHistory objectAtIndex: [sender indexOfSelectedItem] - count];
				
			isCustom = YES;
		}
	}
	
	if ([sampleView isKindOfClass: [PQFontSampleView class]])
	{
		[sampleView setSampleText: newSampleText];
		[self PQAddSampleTextToHistory: newSampleText];
	}
	else if ([sampleView isKindOfClass: [NSTextView class]])
	{
		[sampleView setString: newSampleText];
	}
	
	[self updateControls];
}

@end


@implementation PQSampleController (FontManagerPrivate)

- (void) PQAddSampleTextToHistory: (NSString *)someText
{
	if ([defaultSampleText containsObject: someText] == NO)
	{
		NSInteger index = [sampleTextHistory indexOfObject: someText];

		if (index != NSNotFound)
		{
			[sampleTextHistory removeObjectAtIndex: index];
		}

		[sampleTextHistory insertObject: someText atIndex: 0];
	}

	if ([sampleTextHistory count] > 10)
	{
		NSRange trimRange = NSMakeRange(10, ([sampleTextHistory count] - 10));

		[sampleTextHistory removeObjectsInRange:trimRange];
	}
}

@end
