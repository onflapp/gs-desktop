/*
   Project: DocumentViewer

   Copyright (C) 2022 Free Software Foundation

   Author: Ondrej Florian,,,

   Created: 2022-10-22 16:59:28 +0200 by oflorian

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

#import "Preferences.h"

@implementation Preferences

static Preferences* __sharedinstance;

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Preferences" owner:self];
  [panel setFrameAutosaveName:@"preferences_window"]; 

  return self;
}

+ (Preferences*) sharedInstance {
  if (!__sharedinstance) {
    __sharedinstance = [[Preferences alloc] init];
  }
  return __sharedinstance;
}

- (NSPanel*) panel {
  return panel;
}

@end
