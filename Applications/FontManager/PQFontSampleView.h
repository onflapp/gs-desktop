/*
 * PQFontSampleView.h - Font Manager
 *
 * A font sampling view.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/28/07
 * License: Modified BSD license (see file COPYING)
 */


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface PQFontSampleView : NSView
{
	id dataSource;
	
	NSString *sampleText;
	int fontSize;
	
	NSColor *foregroundColor;
	NSColor *backgroundColor;

	/* Text system components */
	NSTextStorage *textStorage;
	NSLayoutManager *layoutManager;
	NSTextContainer *textContainer;

	BOOL fontAttributesNeedUpdate;

	BOOL autoSize;
}

- (void) setDataSource: (id)anObject;
- (id) dataSource;

- (void) setSampleText: (NSString *)someText;
- (NSString *) sampleText;
- (void) setFontSize: (int)aSize;
- (int) fontSize;

- (void) setAutoSize: (BOOL)flag;
- (BOOL) autoSize;
- (void) setConstrainedFrameSize: (NSSize)aSize;

- (void) setForegroundColor: (NSColor *)aColor;
- (NSColor *) foregroundColor;
- (void) setBackgroundColor: (NSColor *)aColor;
- (NSColor *) backgroundColor;

@end


@interface NSObject (PQFontSampleDataSource)

- (int) numberOfFontsInFontSampleView: (PQFontSampleView *)aFontSampleView;
- (NSString *) fontSampleView: (PQFontSampleView *)aFontSampleView
									fontAtIndex: (int)rowIndex;
- (BOOL) fontsShouldChangeInFontSampleView: (PQFontSampleView *)aFontSampleView;

@end
