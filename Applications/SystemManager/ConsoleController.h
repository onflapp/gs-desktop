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

#ifndef _CONSOLECONTROLLER_H_
#define _CONSOLECONTROLLER_H_

#import <AppKit/AppKit.h>
#import <TerminalKit/TerminalKit.h>

@interface ConsoleView : TerminalView
@end

@interface ConsoleWindow : NSWindow
@end

@interface ConsoleController : NSObject
{
  IBOutlet NSWindow* panel;
  IBOutlet ConsoleView* console;
}

- (NSWindow*) panel;
- (void) execCommand:(NSString*) cmd withArguments:(NSArray*) args;

@end

#endif // _CONSOLECONTROLLER_H_

