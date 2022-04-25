/*
 * PQCharactersView.h - Font Manager
 *
 * Copyright 2008 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 02/29/08
 * License: 3-Clause BSD license (see file COPYING)
 */


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface PQCharactersView : NSView
{
	id dataSource;
	id delegate;
	
	NSFont *font;
	
	unsigned int length;
	unsigned int columns;
	unsigned int rows;
	unsigned int selectedIndex;
	float width;
	float height;
}

- (void) setDataSource: (id)anObject;
- (id) dataSource;

- (void) setDelegate: (id)anObject;
- (id) delegate;

- (void) setFont: (NSFont *)newFont;
- (NSFont *) font;

- (void) setSelectedIndex: (unsigned int)newSelectedIndex;
- (unsigned int) selectedIndex;

@end


@interface NSObject (PQCharactersDataSource)

- (int) numberOfCharactersInCharactersView: (PQCharactersView *)aCharactersView;
- (unichar) charactersView: (PQCharactersView *)aCharactersView
					characterAtIndex: (int)index;

@end


@interface NSObject (PQCharactersDelegate)

- (void) selectionDidChangeInCharactersView: (PQCharactersView *)charactersView;

@end
