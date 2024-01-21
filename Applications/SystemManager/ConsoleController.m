/*
   Project: SystemManager

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

#import "ConsoleController.h"

@implementation ConsoleView

- (id) initWithFrame:(NSRect) frame {
  [super initWithFrame:frame];
  [defaults setScrollBackEnabled:YES];
  [defaults setWindowBackgroundColor:[NSColor blackColor]];
  [defaults setTextNormalColor:[NSColor grayColor]];
  [defaults setTextBoldColor:[NSColor greenColor]];
  [defaults setCursorColor:[NSColor redColor]];
  [defaults setScrollBottomOnInput:YES];
  [defaults setUseBoldTerminalFont:NO];

  //NSFont* font = [NSFont userFixedPitchFontOfSize:18];

  //[self setFont:font];
  //[self setBoldFont:font];
  [self setCursorStyle:[defaults cursorStyle]];
  [self setTermProgram:@"GNUstep_SystemManager"];

  [self setCursorStyle:[defaults cursorStyle]];
  [self updateColors:defaults];

  return self;
}

@end

@implementation ConsoleWindow
- (void) _initBackendWindow {
  [super _initBackendWindow];
}
@end

@implementation ConsoleController

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Console" owner:self];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(viewBecameIdle:)
           name:TerminalViewBecameIdleNotification
         object:console];

  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (NSWindow*) panel {
  return panel;
}

- (void) execCommand:(NSString*) cmd withArguments:(NSArray*) args {
  NSLog(@"exec:%@ args:%@", cmd, args);
  [console clearBuffer:self];
  [console runProgram:cmd
        withArguments:args
         initialInput:nil];

}

- (void) viewBecameIdle:(NSNotification*) n {
  //[panel performClose:self];
}

- (void) windowDidResignKey:(NSNotification *)notification {
  //[panel performClose:self];
}

- (void) windowWillClose:(NSNotification*) not {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:@"statusHasChanged" object:NSApp];
}

@end
