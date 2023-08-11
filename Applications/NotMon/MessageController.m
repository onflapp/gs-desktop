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

@implementation MessageController

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Message" owner:self];

  return self;
}

- (void) dealloc {
  [super dealloc];
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
  [panel close];
}

@end
