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

#import "MessageController.h"

@implementation MessageWindow
@end

@implementation MessageController

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Message" owner:self];
  [openAction setHidden:YES];

  return self;
}

- (void) dealloc {
  RELEASE(command);
  [super dealloc];
}

- (void) setActionCommand:(NSString*) cmd {
  ASSIGN(command, cmd);
  [openAction setHidden:NO];
}

- (NSPanel*) panel {
  return panel;
}

- (NSTextField*) panelTitle {
  return panelTitle;
}

- (NSTextField*) panelInfo {
  return panelInfo;
}

- (void) windowWillClose:(NSNotification*) not {
  [[NSApp delegate] performSelector:@selector(removeMessageController:) withObject:self];
  [self release];
}

- (IBAction) actionButton:(id)sender {
  if (sender == openAction) {
    if (command) {
      NSTask* task = [[[NSTask alloc] init] autorelease];
      [task setLaunchPath:@"/bin/sh"];
      [task setArguments:[NSArray arrayWithObjects:@"-c", command, nil]];
      [task launch];
    }
    [panel close];
  }
  else {
    [panel close];
  }
}

@end
