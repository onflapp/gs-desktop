/*
	Defaults.m

	Controller class for this Preferences module

	Copyright (C) 2002 Fabien VALLON <fabien.vallon@fr.alcove.com>
	Copyright (C) 2003 Dusk to Dawn Computing, Inc.
	Portions Copyright (C) Philippe C. D. Robert

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation; either version 2 of
	the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA
*/
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSView.h>

#include "Domains.h"


@interface Domains (Private)

- (void) nukeDomain: (NSString *)dom;
- (void) unimplemented: (id)sender title: (NSString *)aTitle;

@end

@implementation Domains

- (id) init
{
	self = [super init];

	if (![NSBundle loadNibNamed: @"Domains" owner: self]) {
		NSLog (@"Defaults: Could not load nib \"Domains\", aborting.");
		return nil;
	}

	defs = [NSUserDefaults standardUserDefaults];

	// do any initialization that can't be done in Gorm yet
	[defaultsBrowser setMaxVisibleColumns: 2];

	[editTextView setHorizontallyResizable: NO];
	[editTextView setVerticallyResizable: YES];
	[editTextView setAutoresizingMask: NSViewHeightSizable];

	[editTextView setTextContainerInset: NSMakeSize(2, 2)];
	[[editTextView textContainer] setHeightTracksTextView: NO];
	[[editTextView textContainer] setWidthTracksTextView: YES];

	[detailsButton setHidden:YES];

	[window setFrameAutosaveName:@"domains_window"];

	return self;
}

- (void) showPanel:(id) sender 
{
	[defaultsBrowser loadColumnZero];
	[window makeKeyAndOrderFront:sender];	
}

- (void) nukeDomain: (NSString *)dom
{
	if (![dom length])
		return;

	[defs removePersistentDomainForName: dom];
	[defs synchronize];
	[defaultsBrowser loadColumnZero];
}

- (void) unimplemented: (id)sender title: (NSString *)aTitle
{
	NSRunInformationalAlertPanel(aTitle,
					@"Not implemented yet. Sorry.", @"OK", nil, nil);
	return;
}

/*
	Browser delegate methods
*/
- (int) browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column
{
	if (sender != defaultsBrowser)
		return 0;
	switch (column) {
		case 0:
			return [[defs persistentDomainNames] count];

		case 1: {
			NSString	*nm;

			nm = [[defaultsBrowser selectedCellInColumn:0] stringValue];
			return [[defs persistentDomainForName: nm] count];
		}

		default:
			return 0;
	}
}

- (void) browser: (NSBrowser *)sender willDisplayCell: (id)cell
		   atRow: (int)row column: (int)column
{
	if (sender != defaultsBrowser)
		return;

	switch (column) {
		case 0:
			[cell setStringValue: [[[[defs persistentDomainNames] sortedArrayUsingSelector: @selector(compare:)] objectAtIndex: row] description]];
			break;

		case 1: {
			NSString *nm = [[defaultsBrowser selectedCellInColumn: 0] stringValue];
			NSArray *keys = [[[defs persistentDomainForName: nm] allKeys] sortedArrayUsingSelector: @selector(compare:)];
			NSString *_title = [keys objectAtIndex: row];

			[cell setLeaf: YES];
			[cell setStringValue: _title];
			return;
		}
		default:
			return;
	}
}

- (BOOL) browser: (NSBrowser *)sender isColumnValid: (int)column
{
	if (sender != defaultsBrowser)
		return NO;

	// should actually do something here
	return YES;
}


- (NSString *) browser: (NSBrowser *)sender titleOfColumn: (int)column
{
	if (sender != defaultsBrowser)
		return @"";

	switch (column) {
		case 0:
			return @"Domains";
		case 1:
			return [[defaultsBrowser selectedCellInColumn: 0] stringValue];
		default:
			NSDebugLog (@"[Defaults -defaultsBrowser:titleOfColumn:]: column range error");
			return @"";
	}
}

- (BOOL) browser: (NSBrowser *)sender selectCellWithString: (NSString *)title
		inColumn: (int)column
{
	if (sender != defaultsBrowser)
		return NO;

	return YES;
}

// Browser action 
- (IBAction) browserSelectedSomething: (id)sender
{
	if (sender != defaultsBrowser)
		return;

	if ([[sender selectedCell] isLeaf]) {
		NSString *selectedKey = [[sender selectedCell] stringValue];
		NSString *domain = [[sender selectedCellInColumn:0] stringValue];
		id selectedValue = [[defs persistentDomainForName: domain] objectForKey: selectedKey];
		if (selectedValue) {
			[editTextView setString: [selectedValue description]];
			[editTextView setNeedsDisplay: YES];
		}
    	}
	else {
		NSString *selectedKey = [[sender selectedCell] stringValue];
		if ([selectedKey isEqualToString:@"NSGlobalDomain"]) {
			[detailsButton setHidden:NO];
		}
		else {
			[detailsButton setHidden:YES];
		}

	}
}

/*
	Action methods
*/
- (IBAction) removeDomain: (id)sender
{
	NSString	*dom = [[defaultsBrowser selectedCellInColumn: 0] stringValue];

	if (![dom length]) {
		NSRunAlertPanel(@"Alert",
						@"Please select a domain to remove.", @"OK", nil, nil);
		return;
	}

	if (NSRunAlertPanel (@"Remove Domain",
						 @"Do you really want to remove the \"%@\" domain?",
						 @"Remove", @"Cancel", nil,
						 dom) == NS_ALERTDEFAULT) {
		[self nukeDomain: dom];
		return;
	}
}

- (IBAction) removeDefault: (id)sender
{
	NSString	*dom = [[defaultsBrowser selectedCellInColumn: 0] stringValue];
	NSString	*def = [[defaultsBrowser selectedCellInColumn: 1] stringValue];

	if (![dom length]) {
		NSRunAlertPanel(@"Alert",
						@"Please select a domain from which to remove defaults.", @"OK", nil, nil);
		return;
	}

	if (![def length]) {
		if (NSRunAlertPanel (@"Remove Default",
							 @"Do you really want to remove all defaults from the \"%@\" domain?\n(The domain itself will be removed as well)",
							 @"Remove", @"Cancel", nil,
							 dom) == NS_ALERTDEFAULT) {
			[self nukeDomain: dom];
			return;
		}
		return;
	}

	if (NSRunAlertPanel (@"Remove Default",
						 @"Do you really want to remove the \"%@\" default?",
						 @"Remove", @"Cancel", nil,
						 def) == NS_ALERTDEFAULT) {
		NSMutableDictionary	*domain = [[[defs persistentDomainForName: dom] mutableCopy] autorelease];

		[domain removeObjectForKey: def];
		[defs setPersistentDomain: domain forName: dom];
		[defs synchronize];
		[defaultsBrowser reloadColumn: 1];

		return;
	}
}

- (IBAction) createDomain: (id)sender
{
	[self unimplemented: sender title: @"Add Domain"];
}

- (IBAction) createDefault: (id)sender
{
	[self unimplemented: sender title: @"Add Default"];
}

- (void) saveDefault: (id)sender
{
	NSString			*domainName;
	NSString			*keyName;
	NSMutableDictionary	*domain;

	if (![defaultsBrowser selectedCellInColumn: 1])
		return;

	domainName = [[defaultsBrowser selectedCellInColumn: 0] stringValue];
 	keyName = [[defaultsBrowser selectedCellInColumn: 1] stringValue];
	domain = [[[defs persistentDomainForName: domainName] mutableCopy] autorelease];

	[domain setObject: [[[editTextView string] copy] autorelease] forKey: keyName];
	[defs setPersistentDomain: domain forName: domainName];
	[defs synchronize];
}

- (void) discardDefault: (id)sender
{
	NSString		*keyName = [[defaultsBrowser selectedCellInColumn: 1] stringValue];
	NSString		*domainName = [[defaultsBrowser selectedCellInColumn: 0] stringValue];
	NSDictionary	*domain = [defs persistentDomainForName: domainName];

	if (![defaultsBrowser selectedCellInColumn: 1])
		return;

	[editTextView setString: [domain objectForKey: keyName]];
	[editTextView setNeedsDisplay: YES];
}

/*
	This only exists to get the Domain and Default menu items to auto-activate.
*/
- (void) dummy: (id)sender
{
}

@end
