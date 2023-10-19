/*
   Project: NotMon

   Copyright (C) 2023 Free Software Foundation

   Created: 2023-08-08 21:03:45 +0000 by oflorian

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

#include <X11/X.h>
#include <X11/Xutil.h>
#import "ConsoleController.h"

@implementation ConsoleView

- (id) initWithFrame:(NSRect) frame {
  [super initWithFrame:frame];

  Defaults* prefs = [[Defaults alloc] init];
  [prefs setScrollBackEnabled:NO];
  [prefs setWindowBackgroundColor:[NSColor whiteColor]];
  //[prefs setTextNormalColor:[NSColor blackColor]];
  //[prefs setTextBoldColor:[NSColor greenColor]];
  //[prefs setUseBoldTerminalFont:NO];
  //[prefs setCursorColor:[NSColor redColor]];
  [prefs setScrollBottomOnInput:NO];

  [self setCursorStyle:[prefs cursorStyle]];

  return self;
}

@end

@implementation ConsoleWindow
- (void) _initBackendWindow {
  [super _initBackendWindow];

  Window xwindowid = (Window)[self windowRef];
  Display* xdisplay = XOpenDisplay(NULL);
  XClassHint* xhint = XAllocClassHint();
  xhint->res_name = "Console_NotMon";
  xhint->res_class = "GNUstep";

  XSetClassHint(xdisplay, xwindowid, xhint);
  XFree(xhint);
  XSync(xdisplay, False);
}
@end

@implementation ConsoleController

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Console" owner:self];

  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (NSWindow*) panel {
  return panel;
}

- (void) execCommand:(NSString*) cmd {
  NSMutableArray* args = [NSMutableArray array];
  [console clearBuffer:self];
  [console runProgram:cmd
        withArguments:args
         initialInput:nil];
}

- (void) windowWillClose:(NSNotification*) not {
}

@end
