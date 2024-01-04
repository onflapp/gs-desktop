/*
   Project: MountUp

   Copyright (C) 2022 Free Software Foundation

   Author: Parallels

   Created: 2022-11-02 17:46:05 +0000 by parallels

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

#import "PasswordPanel.h"

@implementation PasswordPanel
- (id) init {
  self = [super init];

  [NSBundle loadNibNamed:@"PasswordPanel" owner:self];

  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (NSString*) askForPasswordWithMessage:(NSString*) msg {
  [panel center];
  [password setStringValue:@""];
  [message setStringValue:msg];

  NSInteger rv = [NSApp runModalForWindow:panel];
  if (rv) {
    NSString* val = [password stringValue];
    [password setStringValue:@""];
    return val;
  }
  else {
    [password setStringValue:@""];
    return nil;
  }
}

- (IBAction) ok:(id) sender {
  [panel orderOut:sender];
  [NSApp stopModalWithCode:1];
}

- (IBAction) cancel:(id) sender {
  [panel orderOut:sender];
  [NSApp stopModalWithCode:0];
}

@end
