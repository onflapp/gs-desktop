/*
   Project: WebBrowser

   Copyright (C) 2020 Free Software Foundation

   Author: onflapp

   Created: 2020-07-22 12:41:08 +0300 by root

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

#import "FullScreenWindow.h"
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <GNUstepGUI/GSDisplayServer.h>

@implementation FullScreenWindow
- (IBAction) toggleFullScreen:(id) sender {
  GSDisplayServer *server = GSCurrentServer();
  Display *dpy = (Display *)[server serverDevice];
  Window wid = (Window)[self windowRef];
  XEvent xev;

  Atom wm_state = XInternAtom(dpy, "_NET_WM_STATE", True);
  Atom fullscreen = XInternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", True);
  long mask = SubstructureNotifyMask;

  memset(&xev, 0, sizeof(xev));
  xev.type = ClientMessage;
  xev.xclient.display = dpy;
  xev.xclient.window = wid;
  xev.xclient.message_type = wm_state;
  xev.xclient.format = 32;
  xev.xclient.data.l[1] = fullscreen;

  if (fullScreenDisplay) {
    xev.xclient.data.l[0] = False;
    fullScreenDisplay = NO;
    _styleMask = lastStyle;
  }
  else {
    xev.xclient.data.l[0] = True;
    fullScreenDisplay = YES;
    lastStyle = _styleMask;
    _styleMask = 0;
  }

  if (!XSendEvent(dpy, DefaultRootWindow(dpy), False, mask, &xev)) {
    fprintf(stderr, "Error: sending fullscreen event to xserver\n");
  }
}

@end
