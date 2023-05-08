/*
   Project: CloudManager

   Copyright (C) 2023 Free Software Foundation

   Author: Parallels

   Created: 2023-05-08 13:10:39 +0000 by parallels

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

#ifndef _RCLONESETUP_H_
#define _RCLONESETUP_H_

#import <AppKit/AppKit.h>
#import <TerminalKit/TerminalKit.h>

@interface RCloneTerminalView : TerminalView
- (void) runSetup;
@end

@interface RCloneSetup : NSObject
{
   IBOutlet RCloneTerminalView* terminalView;
   IBOutlet NSPanel* panel;
}

- (NSPanel*) panel;
- (void) showPanelAndRunSetup:(id)sender;

@end

#endif // _RCLONESETUP_H_

