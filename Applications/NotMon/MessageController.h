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

#ifndef _MESSAGECONTROLLER_H_
#define _MESSAGECONTROLLER_H_

#import <AppKit/AppKit.h>

@interface MessageWindow : NSPanel
@end

@interface MessageController : NSObject
{
  IBOutlet NSPanel* panel;
  IBOutlet NSTextField* panelInfo;
  IBOutlet NSTextField* panelTitle;
  IBOutlet NSButton* closeAction;
  IBOutlet NSButton* openAction;

  NSString* command;
}

- (IBAction) actionButton:(id)sender;

- (void) setActionCommand:(NSString*) command;

- (NSPanel*) panel;
- (NSTextField*) panelTitle;
- (NSTextField*) panelInfo;

@end

#endif // _MESSAGECONTROLLER_H_

