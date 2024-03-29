/*
   Project: Player

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

#import "VideoDocument.h"

@implementation VideoDocument
- (id) init {
  self = [super init];

  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (NSString*) playerExec {
  return @"playerview/start_video.sh";
}

- (NSArray*) playerArguments {
  Window win = [videoView embededXWindowID];

  if (mediaFile) {
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:win], mediaFile, nil];
  }
  else {
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:win], nil];
  }
}

- (void) makeWindow {
  [NSBundle loadNibNamed:@"VideoDocument" owner:self];
  [window setFrameAutosaveName:@"video_window"];
  
  [window makeKeyAndOrderFront:self];
}

@end
