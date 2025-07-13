/*
  Project: VolMon

  Copyright (C) 2022 Free Software Foundation

  Author: ,,,

  Created: 2022-11-01 20:28:45 +0000 by pi

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

#import "MiniView.h"

#include <X11/Xlib.h>
#include <X11/X.h>

@implementation MiniView

- (id) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  tileImage = [NSImage imageNamed:@"common_Tile"];
  return self;
}

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

- (void) scrollWheel:(NSEvent *)event {
  id del = [NSApp delegate];

  if ([event buttonNumber] == 4) {
    [del performSelector:@selector(increaseVolume:) withObject:self];
  }
  else if ([event buttonNumber] == 5) {
    [del performSelector:@selector(decreaseVolume:) withObject:self];
  }
}

- (void) mouseDown:(NSEvent*) theEvent {
}

- (void) drawRect:(NSRect)r
{
  [tileImage compositeToPoint:NSMakePoint(0,0)
                     fromRect:NSMakeRect(0, 0, 64, 64)
                    operation:NSCompositeSourceAtop];

  [super drawRect:r];
}
@end
