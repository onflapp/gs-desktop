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

- (void) mouseDown:(NSEvent*) theEvent {
}

/* 
 * I tried to simulate mouse events for WM to get UseWindowMakerIcons working
 * this doesn't work as something grabs the pointer and prevents WM from taking over
 *

  Display* dpy = XOpenDisplay(NULL);
  Window win = [[NSApp iconWindow]windowRef];
  Window root;
  Window parent;
  Window *children;
  unsigned int nchildren;

  int result = XQueryTree(dpy, win, &root, &parent, &children, &nchildren);
  if (result) {
    XEvent xevent;

    ///
    memset (&xevent, 0, sizeof (xevent));

    xevent.xany.type = ButtonRelease;
    xevent.xany.display = dpy;
    xevent.xbutton.button = Button1;
    xevent.xbutton.same_screen = True;			
    xevent.xbutton.window = win;

    XSendEvent(dpy, win, False, ButtonPressMask, &xevent);
    XFlush(dpy);

    ///
    memset (&xevent, 0, sizeof (xevent));

    XQueryPointer(dpy, win,
                  &xevent.xbutton.root, &xevent.xbutton.subwindow,
                  &xevent.xbutton.x_root, &xevent.xbutton.y_root,
                  &xevent.xbutton.x, &xevent.xbutton.y,
                  &xevent.xbutton.state);

    xevent.xany.type = ButtonPress;
    xevent.xany.display = dpy;
    xevent.xbutton.button = Button1;
    xevent.xbutton.same_screen = True;			
    xevent.xbutton.window = parent;

    XSendEvent(dpy, parent, False, ButtonPressMask, &xevent);
    XFlush(dpy);

    XFree(children);
  }
*/

- (void) drawRect:(NSRect)r
{
  [tileImage compositeToPoint:NSMakePoint(0,0)
                     fromRect:NSMakeRect(0, 0, 64, 64)
                    operation:NSCompositeSourceAtop];

  [super drawRect:r];
}
@end
