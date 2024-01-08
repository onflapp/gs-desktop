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

#import "XEmbeddedView.h"
#import <GNUstepGUI/GSDisplayServer.h>
#include "X11/Xutil.h"
#include "X11/keysymdef.h"

@implementation XEmbeddedView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];
  xwindowid = 0;
  xdisplay = NULL;

  return self;
}

- (void) dealloc {
  NSLog(@"dealloc");
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (xwindowid != 0) {
    [self unmapXWindow];
    [self destroyXWindow];
  }

  [super dealloc];
}

- (void) windowWillClose:(NSNotification*) note {
  if ([note object] == [self window]) {
    [self destroyXWindow];
  }
}

- (void) viewDidMoveToWindow {
  if ([self window]) {
    isvisible = YES;
  }
  else {
    isvisible = NO;
    if (xwindowid != 0) {
      [self unmapXWindow];
      [self destroyXWindow];
    }
  }
}

- (void) destroyXWindow {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (xdisplay && xwindowid) {
    NSLog(@"aaa");
    XDestroyWindow(xdisplay, xwindowid);
    XFlush(xdisplay);

    xdisplay = NULL;
    xwindowid = 0;
    NSLog(@"DESTROY");
  }
}

- (void) activateXWindow {
  NSWindow* win = [self window];
  if (!win) return;

  if ([NSApp isActive] == NO) {
    [NSApp activateIgnoringOtherApps:YES];
    [win makeKeyAndOrderFront:self];
  }
  else {
    [win makeFirstResponder:self];
    [win makeKeyAndOrderFront:self];
  }
}

- (void) deactivateXWindow:(NSNotification*) note {
  isactive = NO;
}

- (BOOL) acceptsFirstResponder {
  return YES;
}

- (BOOL) becomeFirstResponder {
  if (!isactive) {
    isactive = YES;
    NSLog(@"FOCUS %x", self);

    /*
    [NSApp delayDeactivation];
    sendclientmsg(xdisplay, root, ignore_focus, 1);
    XSetInputFocus(xdisplay, xwindowid, RevertToParent, CurrentTime);
    XFlush(xdisplay);
    */
  }
  return YES;
}

- (BOOL) resignFirstResponder {
  isactive = NO;
  NSWindow* win = [self window];
  if ([win isKeyWindow]) {
    [GSServerForWindow(win) setinputfocus:[win windowNumber]];
  }
  return YES;
}

- (void) resizeWithOldSuperviewSize:(NSSize) sz {
  [super resizeWithOldSuperviewSize:sz];
  [self resizeXWindow];
}

- (void) resizeXWindow {
  if (!xwindowid || !xdisplay) return;
  if (![self window]) return;

  XMapWindow(xdisplay, xwindowid); 
  
  NSRect r = [self convertToNativeWindowRect];
  
  XMoveResizeWindow(xdisplay, xwindowid, r.origin.x, r.origin.y, r.size.width, r.size.height);
  XFlush(xdisplay);
  NSLog(@"resized");
}

- (Window) embededXWindowID {
  return xwindowid;
}

- (NSRect) convertToNativeWindowRect {
  NSRect r = [self convertRect: [self bounds] toView:nil];

  NSInteger x = (NSInteger)r.origin.x - 1;
  NSInteger y = (NSInteger)r.origin.y;
  NSInteger w = (NSInteger)r.size.width;
  NSInteger h = (NSInteger)r.size.height;

  NSInteger vh = (NSInteger)[[[self window] contentView] frame].size.height;
  y = vh - h - y + 8;

  return NSMakeRect(x, y, w, h);
}

- (void) unmapXWindow {
}

- (void) initModFilter {
  NSString* cmdkey = [[NSUserDefaults standardUserDefaults] valueForKey:@"GSFirstCommandKey"];
  if ([cmdkey isEqualToString:@"Super_L"]) {
    filterModL = XK_Super_L;
    filterModR = XK_Super_R;
    filterMod = Mod4Mask;
  }
  else if ([cmdkey isEqualToString:@"Alt_L"]) {
    filterModL = XK_Alt_L;
    filterModR = XK_Alt_L;
    filterMod = Mod1Mask;
  }
  else if ([cmdkey isEqualToString:@"Meta_L"]) {
    filterModL = XK_Meta_L;
    filterModR = XK_Meta_R;
    filterMod = Mod2Mask;
  }
  else {
    filterModL = XK_Control_L;
    filterModR = XK_Control_R;
    filterMod = ControlMask;
  }
}

- (void) createXWindowID {
  xdisplay = XOpenDisplay(NULL);
  int screen = DefaultScreen(xdisplay);

  unsigned long white_pixel = WhitePixel(xdisplay, screen);
  unsigned long black_pixel = BlackPixel(xdisplay, screen);

  int x=0, y=100, w=300, h=400;

  Window xid = XCreateSimpleWindow(xdisplay,
                                  DefaultRootWindow(xdisplay),
                                  x,y,  // top left corner
                                  w,h,  // width and height
                                  0,    // border width
                                  black_pixel,
                                  white_pixel);

  NSLog(@"got window %x", xid);

  XMapWindow(xdisplay, xid);
  XSync(xdisplay, False);
  
  [self reparentXWindowID:xid];
}

- (void) reparentXWindowID:(Window)xwinid {
  if (xwindowid != 0) return;
  if (!isvisible) return;

  Window myxwindowid = (Window)[[self window]windowRef];
  xdisplay = XOpenDisplay(NULL);
  xwindowid = xwinid;
  int screen = DefaultScreen(xdisplay);

  NSLog(@"reparent %x", xwindowid);

  XReparentWindow(xdisplay, xwindowid, myxwindowid, 0, 0);
  XSync(xdisplay, False);
  XMapWindow(xdisplay, xwindowid);

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self 
         selector:@selector(deactivateXWindow:) 
	     name:NSApplicationWillResignActiveNotification
	   object:NSApp];

  [nc addObserver:self 
         selector:@selector(deactivateXWindow:) 
	     name:NSWindowDidResignKeyNotification
	   object:[self window]];

  [nc addObserver:self 
	 selector:@selector(windowWillClose:) 
	     name:NSWindowWillCloseNotification
	   object:[self window]];

  [self initModFilter];

  [self performSelector:@selector(resizeXWindow) withObject:nil afterDelay:0.1];
  [self performSelectorInBackground:@selector(processXWindowsEvents:) withObject:self];
  
  [self setNeedsDisplay:YES];
}

- (void) processXWindowsEvents:(id) sender {
  XInitThreads();

  Window ws = (Window)[[sender window]windowRef];
  Window we = (Window)[sender embededXWindowID];
  Window wf = None;
  Display *d;
  XEvent e;
  int wr;
 
  d = XOpenDisplay(NULL);

  //Window root = XDefaultRootWindow(d);
  //Atom ignore_focus = XInternAtom(d, WM_IGNORE_FOCUS_EVENTS, True);
  XSelectInput(d, we, EnterWindowMask | LeaveWindowMask | StructureNotifyMask);

  BOOL grabbing_mouse = NO;

  while (1) {
    XNextEvent(d, &e);

    if (e.type == EnterNotify) {
      XGetInputFocus(d, &wf, &wr);
      if (wf != None && wf != we) {
        NSLog(@"M - GRAB");
        XGrabButton(d, AnyButton, AnyModifier, we, 1, ButtonPressMask, GrabModeSync, GrabModeAsync, None, None);
        XFlush(d);
        grabbing_mouse = YES;
      }
    }
    else if (e.type == LeaveNotify) {
      if (grabbing_mouse) {
        NSLog(@"M - UN GRAB");
        XUngrabButton(d, AnyButton, AnyModifier, we);
        XFlush(d);
        grabbing_mouse = NO;
      }
    }
    else if (e.type == ButtonPress) {
      if (e.xbutton.button == Button1 || [NSApp isActive]) {
        if (grabbing_mouse) {
          NSLog(@"M - UN GRAB");
          XUngrabButton(d, AnyButton, AnyModifier, we);
          XSync(xdisplay, True);
          grabbing_mouse = NO;
        }

        [sender performSelectorOnMainThread:@selector(activateXWindow) withObject:nil waitUntilDone:NO];
      }
      XAllowEvents(d, ReplayPointer, e.xbutton.time);
    }
    else if (e.type == DestroyNotify) {
      NSLog(@"bbbbbbbbbbbb");
      break;
    }
    else {
      NSLog(@"EEEE %d", e.type);
    }
  }

  XUngrabButton(d, AnyButton, AnyModifier, we);
  NSLog(@"we are done here");

  xwindowid = 0;
}


@end
