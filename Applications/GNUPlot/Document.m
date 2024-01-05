/*
   Project: VimGS

   Copyright (C) 2020 Free Software Foundation

   Author: onflapp

   Created: 2020-07-22 12:41:08 +0300 by root

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "Document.h"

static NSWindow* _lastMainWindow;

@implementation Document

+ (Document*) lastActiveDocument {
  return (Document*)[_lastMainWindow delegate];
}

- (id) initWithFile:(NSString*) path {
  self = [super init];
  [NSBundle loadNibNamed:@"Document" owner:self];

  Defaults* defs = [[Defaults alloc] init];
  [defs setScrollBackEnabled:NO];

  [terminalView updateColors:defs];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(updateTitleBar:)
           name:TerminalViewTitleDidChangeNotification
         object:terminalView];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(viewBecameIdle:)
           name:TerminalViewBecameIdleNotification
         object:terminalView];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(preferencesDidChange:)
           name:TerminalPreferencesDidChangeNotification
         object:[NSApp delegate]];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(updateFileName:)
           name:@"TerminalFileNameNotification"
         object:terminalView];

  ASSIGN(fileName, path);
         
  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter]
    removeObserver:self];

  RELEASE(fileName);

  [super dealloc];
}

- (NSString*) fileName {
  return fileName;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
  NSLog(@"xxxxxxxxxxxx");
  [plotView resizeXWindow];
}

- (void) showWindow {
  if ([window isVisible]) {
    [window makeKeyAndOrderFront:self];
  }
  else {
    [window makeFirstResponder:terminalView];

    if (!_lastMainWindow) _lastMainWindow = [[NSApp orderedWindows] lastObject];
    if (_lastMainWindow) {
      NSRect r = [_lastMainWindow frame];
      r.origin.x += 24;

      [window setFrame:r display:NO];
    }
    else {
      [window setFrameUsingName:@"document_window"];
      [window setFrameAutosaveName:@"document_window"];
    }

    [window makeKeyAndOrderFront:self];
  }
  if (!initialized) {
    [self initializeCommandView];
  }
}

- (void) initializeCommandView {
  NSString* xid = [plotView createPlotWindow]; 
  
  [terminalView runWithFile:fileName windowID:xid];
  initialized = YES;
}

- (void) viewBecameIdle:(NSNotification*) n {
  [terminalView closeProgram];
  [window close];
}

- (void) preferencesDidChange:(NSNotification *)notif {
  Defaults* prefs = [[Defaults alloc] init];

  NSFont* font = [prefs terminalFont];
  if (font) {
    [terminalView setFont:font];
    if ([prefs useBoldTerminalFont] == YES)
      [terminalView setBoldFont:[Defaults boldTerminalFontForFont:font]];
    else
      [terminalView setBoldFont:font];
  }
  [terminalView setCursorStyle:[prefs cursorStyle]];
  [terminalView updateColors:prefs];

  [terminalView setNeedsDisplayInRect:[terminalView frame]];
  [[terminalView superview] setFrame:[[terminalView superview] frame]];
}

- (NSWindow*) window {
  return window;
}

- (void) updateTitleBar:(NSNotification*) n {
  NSString* title = [terminalView xtermTitle];
  if (!title) title = @"untitled";

  [window setTitle:title];
}

- (void) updateFileName:(NSNotification*) n {
  NSString* fn = [[n userInfo] valueForKey:@"path"];
  if ([fn length] == 0) fn = nil;

  ASSIGN(fileName, fn);
}

- (void) windowDidBecomeMain:(NSNotification *)notification {
  _lastMainWindow = [self window];
}

- (void) windowWillClose:(NSNotification *)notification {
  NSWindow* win = [self window];
  [terminalView quit:self];

  if (_lastMainWindow == win) _lastMainWindow = nil;

  ASSIGN(fileName, nil);
  [win setDelegate: nil];
  [self release];
}

@end
