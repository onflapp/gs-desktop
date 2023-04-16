/*
   Project: DocViewer

   Copyright (C) 2023 Free Software Foundation

   Author: Parallels

   Created: 2023-04-16 13:41:14 +0200 by parallels

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

#import "HtmlView.h"

@implementation HtmlView

- (id) init {
  self = [super init];

  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (void) awakeFromNib {
  [self setMaintainsBackForwardList:YES];
}

- (BOOL) canHandleClickOnLink:(NSURL*) url {
  if ([[url scheme] isEqualToString:@"file"]) {
    return YES;
  }
  else {
    [[NSWorkspace sharedWorkspace] openURL:url];
    return NO;
  }
}

@end
