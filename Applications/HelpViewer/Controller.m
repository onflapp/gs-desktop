/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003 Nicolas Roard (nicolas@roard.com)
                  2020 Riccardo Mottola <rm@gnu.org>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the
    Free Software Foundation, Inc.  
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
*/

#include <AppKit/AppKit.h>
#include "Controller.h"

@implementation Controller

- (void) initButtons 
{
    [search setTitle: _(@"Search")];
    [search setFont: [NSFont systemFontOfSize: 0]];
    [search setImagePosition: NSImageAbove];
    [search setImage: [NSImage imageNamed: @"Search.tiff"]];

    [index setTitle: _(@"Index")];
    [index setFont: [NSFont systemFontOfSize: 0]];
    [index setImagePosition: NSImageAbove];
    [index setImage: [NSImage imageNamed: @"Index.tiff"]];

    [back setTitle: _(@"Back")];
    [back setFont: [NSFont systemFontOfSize: 0]];
    [back setImagePosition: NSImageAbove];
    [back setImage: [NSImage imageNamed: @"Back.tiff"]];

    [bookshelf setTitle: _(@"Bookshelf")];
    [bookshelf setFont: [NSFont systemFontOfSize: 0]];
    [bookshelf setImagePosition: NSImageAbove];
    [bookshelf setImage: [NSImage imageNamed: @"Bookshelf.tiff"]];
}

- (void) awakeFromNib
{
    windowController = [[MainWindowController alloc] initWithTextView: textview
			    andBrowserView: tocview];
   
    [infoMenu setAction: @selector (orderFrontStandardInfoPanel:)];
    [helpMenu setAction: @selector (orderFrontHelpPanel:)];

    [self initButtons];

    [window setFrameAutosaveName:@"help_window"];
    [window setTitle: @"HelpViewer"];
    [windowController setWindow: window];

    [NSApp setDelegate: self];
}

- (void) applicationDidFinishLaunching: (NSNotification *) not {
    NSArray *args = [[NSProcessInfo processInfo] arguments];

    if ([args count] > 1)
    {
	if ([[NSFileManager defaultManager] fileExistsAtPath: [args objectAtIndex: 1]])
	{
	    [windowController loadFile: [args objectAtIndex: 1]];
	}
    }
}
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    return [windowController loadFile: filename];
}

- (void) dealloc 
{
  RELEASE (windowController);
  [super dealloc];
}

- (void) openFile: (id) sender
{
    NSInteger ret;
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection: NO];
    ret = [panel runModalForTypes: [NSArray arrayWithObjects: @"help", @"xlp", nil]];
    if (ret == NSOKButton)
    {
	[windowController loadFile: [[panel filenames] objectAtIndex: 0]];
    }
}

- (void) search: (id) sender
{
    NSLog (@"Search ...");
}

- (void) index: (id) sender 
{
    NSLog (@"Index ...");
}

- (void) back: (id) sender
{
    NSLog (@"Back ...");
}

- (void) bookshelf: (id) sender
{
    NSLog (@"Bookshelf ...");
}

- (void) print: (id) sender
{
	[windowController print: sender];
}

@end
