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
}

- (void) awakeFromNib
{
    windowController = [[MainWindowController alloc] initWithTextView: textview
			    andBrowserView: tocview];
   
    [infoMenu setAction: @selector (orderFrontStandardInfoPanel:)];
    [helpMenu setAction: @selector (orderFrontHelpPanel:)];

    [self initButtons];

    [window setFrameAutosaveName:@"help_window"];
    [window setTitle: @"Help Viewer"];
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
    [windowController search: sender];
}

- (void) index: (id) sender 
{
    NSLog (@"Index ...");
}

- (void) back: (id) sender
{
    [windowController back: sender];
}

- (void) forward: (id) sender
{
    [windowController forward: sender];
}

- (void) bookshelf: (id) sender
{
    NSString* bfile = [[NSUserDefaults standardUserDefaults] valueForKey:@"bookshelf_file"];
    if (bfile) {
      [windowController loadFile: bfile];
    }
    else {
      NSLog (@"no bookshelf_file defined");
    }
}

- (void) print: (id) sender
{
    [windowController print: sender];
}

@end
