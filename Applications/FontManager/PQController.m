/*
 * PQController.m - Font Manager
 *
 * Controller for installed font list & main window.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: 3-Clause BSD license (see file COPYING)
 */


#import "PQController.h"
#import "PQFontManager.h"
#import "PQFontDocument.h"
#import "PQCompat.h"


const float groupsBoxMinWidth = 100.0 + 16.0;
const float fontsBoxMinWidth = 100.0;
const float sampleBoxMinWidth = 220.0;


@implementation PQController

- (id) init
{
	[super init];
	
	/* Create an array of font families */
	PQFontManager *fontManager =
		(PQFontManager *)[PQFontManager sharedFontManager];
	NSArray *fontFamilyNames = [fontManager availableFontFamilies];
	
	fontFamilies = [[NSMutableArray alloc] init];
	
	NSEnumerator *familyNamesEnum = [fontFamilyNames objectEnumerator];
	NSString *currentName;

	while ((currentName = [familyNamesEnum nextObject]))
	{
		NSArray *members = [fontManager availableMembersOfFontFamily: currentName];

		NSMutableArray *newMembers = [[NSMutableArray alloc] init];
		NSArray *currentMember;
		NSEnumerator *membersEnum = [members objectEnumerator];

		while ((currentMember = [membersEnum nextObject]))
		{
			[newMembers addObject:[currentMember objectAtIndex:0]];
		}
		
		PQFontFamily *newFontFamily =
			[[PQFontFamily alloc] initWithName: currentName members: newMembers];
    [fontFamilies addObject:newFontFamily];
	}
	
	[fontFamilies sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	RETAIN(fontFamilies);

	return self;
}

- (void) awakeFromNib
{
	[self updateSample];


	/* Values that should be set in MainMenu.gorm, but aren't */
	NSTableColumn * fontListColumn = [[fontList tableColumns] objectAtIndex: 0];
	[[fontListColumn headerCell] setTitle: @"Fonts"];
	[fontListColumn setEditable: NO];
	[[[[groupList tableColumns] objectAtIndex: 0] headerCell]
		setTitle: @"Groups"];
	[splitView setDelegate: self];

	[fontList sizeLastColumnToFit];
	[groupList sizeLastColumnToFit];

	float windowMinWidth = (([splitView dividerThickness] * 2) +
	                        groupsBoxMinWidth + fontsBoxMinWidth +
													sampleBoxMinWidth);
	[window setMinSize: NSMakeSize(windowMinWidth, [window minSize].height)];

	int fontsCount = [fontFamilies count];

	if (fontsCount < 2)
	{
		[fontsInfoField setStringValue:
			[NSString stringWithFormat:@"%i %@", fontsCount,
			                           NSLocalizedString(@"family", nil)]];
	}
	else
	{
		[fontsInfoField setStringValue:
			[NSString stringWithFormat:@"%i %@", fontsCount,
			                           NSLocalizedString(@"families", nil)]];
	}
	
	[fontList setTarget: self];
	[fontList setDoubleAction: @selector(openSelected:)];
}

/* Split view data source */

- (float) splitView: (NSSplitView *)sender
	constrainMaxCoordinate: (float)proposedMax
        ofSubviewAt: (int)offset
{
	if (offset == 0)
	{
		/* FUTURE:
		if ([sender isSubviewCollapsed: sampleBox])
		{
			return ([sender frame].size.width - 128.0);
		}
		else
		{
			return ([sender frame].size.width - [sampleBox frame].size.width - 128.0);
		}
		*/
		/* NOW: */
		return ([sender frame].size.width - [sampleBox frame].size.width -
		        fontsBoxMinWidth - ([sender dividerThickness] * 2));
	}
	else if (offset == 1)
	{
		return ([sender frame].size.width - sampleBoxMinWidth -
		        [sender dividerThickness]);
	}
	/* Else */
	return proposedMax;
}

- (float) splitView: (NSSplitView *)sender
	constrainMinCoordinate: (float)proposedMin
        ofSubviewAt: (int)offset
{
	if (offset == 0)
	{
		return groupsBoxMinWidth;
	}
	else if (offset == 1)
	{
		return ([groupsBox frame].size.width + fontsBoxMinWidth +
		        [sender dividerThickness]);
	}
	/* Else */
	return proposedMin;
}

/* FUTURE:
- (BOOL) splitView: (NSSplitView *)sender canCollapseSubview: (NSView *)subview
{
	if (subview == sampleBox)
	{
		return YES;
	}
	/ * Else * /
	return NO;
}
*/

- (void) splitView: (NSSplitView *)sender
	resizeSubviewsWithOldSize: (NSSize)oldSize
{
	NSSize newSize = [splitView frame].size;
	float differance = newSize.width - oldSize.width;

	if (differance > 0)
	{
		[sampleBox setFrameSize:
			NSMakeSize(([sampleBox frame].size.width + differance), newSize.height)];
	}
	else if (differance < 0)
	{
		if (([sampleBox frame].size.width + differance) > sampleBoxMinWidth)
		{
			[sampleBox setFrameSize:
				NSMakeSize(([sampleBox frame].size.width + differance),
				           newSize.height)];
		}
		else
		{
			differance -= (sampleBoxMinWidth - [sampleBox frame].size.width);

			/* Split the rest between the remaining views */
			/* We assume that the window's minimum size is correct */

			float groupsBoxWidth = [groupsBox frame].size.width;
			float fontsBoxWidth = [fontsBox frame].size.width;

			float groupsBoxDifferance =
				(int)(differance * (groupsBoxWidth / (groupsBoxWidth + fontsBoxWidth)));
			float fontsBoxDifferance = (differance - groupsBoxDifferance);

			groupsBoxWidth += groupsBoxDifferance;
			fontsBoxWidth += fontsBoxDifferance;

			/* Avoid resizing to small if possible */
			if (fontsBoxWidth < fontsBoxMinWidth)
			{
				groupsBoxDifferance += (fontsBoxWidth - fontsBoxMinWidth);
				fontsBoxDifferance += (fontsBoxMinWidth - fontsBoxWidth);
				groupsBoxWidth += (fontsBoxWidth - fontsBoxMinWidth);
				fontsBoxWidth = fontsBoxMinWidth;
			}
			else if (groupsBoxWidth < groupsBoxMinWidth)
			{
				fontsBoxDifferance += (groupsBoxMinWidth - fontsBoxWidth);
				groupsBoxDifferance += (groupsBoxMinWidth - groupsBoxWidth);
				fontsBoxWidth += (groupsBoxWidth - groupsBoxMinWidth);
				groupsBoxWidth = groupsBoxMinWidth;
			}

			[groupsBox setFrameSize: NSMakeSize(groupsBoxWidth, newSize.height)];
			[fontsBox setFrame:
				NSMakeRect(([fontsBox frame].origin.x + groupsBoxDifferance),
									 [fontsBox frame].origin.y, fontsBoxWidth, newSize.height)];
			[sampleBox setFrame:
				NSMakeRect(([sampleBox frame].origin.x + differance),
									 [sampleBox frame].origin.y, sampleBoxMinWidth,
									 newSize.height)];
		}
	}
	else
	{
		[sampleBox setFrameSize: NSMakeSize([sampleBox frame].size.width,
	                                      newSize.height)];
	}


	[groupsBox setFrameSize: NSMakeSize([groupsBox frame].size.width,
	                                    newSize.height)];
	[fontsBox setFrameSize: NSMakeSize([fontsBox frame].size.width,
																		 newSize.height)];
}

/* Groups [table] view data source */

- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
	return 1; // TEMP
}

- (id) tableView: (NSTableView *)aTableView
	objectValueForTableColumn: (NSTableColumn *)aTableColumn
	           row: (int)rowIndex
{
	return @"All"; // TEMP
}

/* Fonts [outline] view data source */

- (id) outlineView: (NSOutlineView *)outlineView
	objectValueForTableColumn: (NSTableColumn *)tableColumn
	byItem: (id)item
{
	if ([item isKindOfClass:[PQFontFamily class]])
	{
		return [(PQFontFamily *)item name];
	}
	else if ([item isKindOfClass:[NSString class]])
	{
		NSString *familyName = [[NSFont fontWithName: item size: 0.0] familyName];
		NSArray *familyMembersInfo =
			[[PQFontManager sharedFontManager] availableMembersOfFontFamily: familyName];

		NSEnumerator *membersEnum = [familyMembersInfo objectEnumerator];
		NSArray *currentMember;

		while ((currentMember = [membersEnum nextObject]))
		{
			if ([[currentMember objectAtIndex: 0] isEqualToString: item])
			{
				return [currentMember objectAtIndex: 1];
			}
		}
	}
	
	/* Else: something is wrong */
	return nil;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	if (item == nil) /* Is this even necessary? */
	{
		return YES;
	}
	else if ([item isKindOfClass:[PQFontFamily class]])
	{
		return [item hasMultipleMembers];
	}
	/* else */
	return NO;
}

- (int) outlineView: (NSOutlineView *)outlineView
	numberOfChildrenOfItem: (id)item
{
	if (item == nil)
	{
		return [fontFamilies count];
	}
	else if ([item isKindOfClass:[PQFontFamily class]])
	{
		return [[item members] count];
	}
	/* else */
	return 0;
}

- (id) outlineView: (NSOutlineView *)outlineView
             child: (int)index
						ofItem: (id)item
{
	if (item == nil)
	{
		return [fontFamilies objectAtIndex:index];
	}
	else if ([item isKindOfClass:[PQFontFamily class]])
	{
		return [[item members] objectAtIndex:index];
	}
	
	/* Else: something is wrong */
	return nil;
}

/* Watch for selection changes */

- (void) tableViewSelectionDidChange: (NSNotification *)aNotification
{
	// TODO: Until we implement groups.
}

- (void) outlineViewSelectionDidChange: (NSNotification *)notification
{
	[self updateSample];
}

- (void) openSelected: (id)sender
{
	// TODO: This method's implementation is a quick hack based on -updateSample.
	//       Rewite needed.
	
	NSIndexSet *selectedRows = [fontList selectedRowIndexes];
	
	NSEnumerator *itemEnum = [fontFamilies objectEnumerator];
	PQFontFamily *currentItem;
	
	NSMutableArray *selectedItems = [[NSMutableArray alloc] init];
	
	while ((currentItem = [itemEnum nextObject]))
	{
    if ([selectedRows containsIndex:[fontList rowForItem:currentItem]])
		{
			[selectedItems addObjectsFromArray:[currentItem members]];
		}
		else
		{
			NSEnumerator *membersEnum = [[currentItem members] objectEnumerator];
			NSString *currentMember;
			
			while ((currentMember = [membersEnum nextObject]))
			{
				if ([selectedRows containsIndex:[fontList rowForItem:currentMember]])
				{
					[selectedItems addObject:currentMember];
				}
			}
		}
	}

	if ([sender clickedRow] > -1 && [selectedItems count] > 0)
	{
		/*
		PQFontDocument *document = [[NSDocumentController sharedDocumentController]
																openUntitledDocumentOfType: @"PQFontDocument"
																display: YES];
			
		[document setFont: [selectedItems objectAtIndex: 0]]; */
		
		PQFontDocument *document = [[NSDocumentController sharedDocumentController]
																makeUntitledDocumentOfType: @"PQFontDocument"];
		
		[document setFont: [selectedItems objectAtIndex: 0]];
		
		[[NSDocumentController sharedDocumentController] addDocument: document];
		
		[document makeWindowControllers];
		[document showWindows];
	}
}

- (void) updateSample
{
	// NOTE: This method probably could be better.
	NSIndexSet *selectedRows = [fontList selectedRowIndexes];
	
	NSEnumerator *itemEnum = [fontFamilies objectEnumerator];
	PQFontFamily *currentItem;
	
	NSMutableArray *selectedItems = [[NSMutableArray alloc] init];
	
	while ((currentItem = [itemEnum nextObject]))
	{
    if ([selectedRows containsIndex:[fontList rowForItem:currentItem]])
		{
			[selectedItems addObjectsFromArray:[currentItem members]];
		}
		else
		{
			NSEnumerator *membersEnum = [[currentItem members] objectEnumerator];
			NSString *currentMember;
			
			while ((currentMember = [membersEnum nextObject]))
			{
				if ([selectedRows containsIndex:[fontList rowForItem:currentMember]])
				{
					[selectedItems addObject:currentMember];
				}
			}
		}
		/* Else: something is wrong */
	}
	
	[sampleController setFonts:selectedItems];
}

- (void) dealloc
{
	RELEASE(fontFamilies);
	
	[super dealloc];
}

@end
