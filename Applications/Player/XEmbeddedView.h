/*
   Project: WebBrowser

   Copyright (C) 2020 Free Software Foundation

   Author: root

   Created: 2020-08-08 14:25:54 +0300 by root

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

#ifndef _XEMBEDDEDVIEW_H_
#define _XEMBEDDEDVIEW_H_

#import <AppKit/AppKit.h>
#include <X11/Xlib.h>

@interface XEmbeddedView : NSView
{
  Display* xdisplay;
  Window xwindowid;
  BOOL isactive;
  BOOL isvisible;

  KeySym filterModL;
  KeySym filterModR;
  int filterMod;
}

- (void) createXWindowID;
- (void) windowWillClose:(NSNotification*) note;
- (void) destroyXWindow;
- (void) activateXWindow;
- (void) deactivateXWindow:(NSNotification*) note;

- (Window) embededXWindowID;
- (NSRect) convertToNativeWindowRect;

@end

#endif // _XEMBEDDEDVIEW_H_

