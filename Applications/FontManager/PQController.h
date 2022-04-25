/*
 * PQController.h - Font Manager
 *
 * Controller for installed font list & main window.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: Modified BSD license (see file COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PQSampleController.h"
#import "PQFontFamily.h"

@interface PQController : NSObject
{
	IBOutlet NSOutlineView *fontList;
	IBOutlet NSTextField *fontsInfoField;
	IBOutlet NSTableView *groupList;
	IBOutlet PQSampleController *sampleController;

	IBOutlet NSWindow *window;
	IBOutlet NSSplitView *splitView;
	IBOutlet NSBox *groupsBox;
	IBOutlet NSBox *fontsBox;
	IBOutlet NSBox *sampleBox;

	NSMutableArray *fontFamilies; /* All font families */
}

- (void) updateSample;

@end
