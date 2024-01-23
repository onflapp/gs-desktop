/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "SaverWindow.h"
#include <X11/Xlib.h>
#include <GNUstepGUI/GSDisplayServer.h>

@implementation SaverWindow

- (void) makeOmnipresent
{
  GSDisplayServer *server = GSCurrentServer();
  Display *dpy = (Display *)[server serverDevice];
  void *winptr = [server windowDevice: [self windowNumber]];
  Window win = (Window)winptr;
  Atom atom = 0;
  long data = 1;
  
  atom = XInternAtom(dpy, "KWM_WIN_STICKY", False);
  
  if (atom != 0) {
    XChangeProperty(dpy, win, atom, atom, 32, 
		    PropModeReplace, (unsigned char *)&data, 1);
  }
  
  atom = XInternAtom(dpy, "WIN_STATE_STICKY", False);
  
  if (atom != 0) {  
    XChangeProperty(dpy, win, atom, atom, 32, 
		    PropModeReplace, (unsigned char *)&data, 1);
  }
}

- (void) makeFullscreen:(BOOL) fullscreen_flag
{
  GSDisplayServer *server = GSCurrentServer();
  Display *dpy = (Display *)[server serverDevice];
  void *winptr = [server windowDevice: [self windowNumber]];
  Window win = (Window)winptr;

  XEvent xev;

  Atom wm_state = XInternAtom(dpy, "_NET_WM_STATE", True);
  Atom fullscreen = XInternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", True);
  long mask = SubstructureNotifyMask;

  memset(&xev, 0, sizeof(xev));
  xev.type = ClientMessage;
  xev.xclient.display = dpy;
  xev.xclient.window = win;
  xev.xclient.message_type = wm_state;
  xev.xclient.format = 32;
  xev.xclient.data.l[0] = fullscreen_flag;
  xev.xclient.data.l[1] = fullscreen;

  if (!XSendEvent(dpy, DefaultRootWindow(dpy), False, mask, &xev)) {
    NSLog(@"Error: sending fullscreen event to xserver\n");
    return;
  }

  if (fullscreen_flag) {
    XGrabPointer(dpy, win, False,
                       PointerMotionMask | ButtonReleaseMask | ButtonPressMask,
                       GrabModeAsync, GrabModeAsync, win, None, CurrentTime);
  }
}

- (void) setAction: (SEL)a forTarget: (id)t
{
  action = a;
  target = t;
}

- (void) keyDown: (NSEvent *)theEvent
{
  if([self level] == NSScreenSaverWindowLevel)
    {
      [NSApp sendAction: action to: target from: self];
    }
}
- (void) keyUp: (NSEvent *)theEvent
{

}

- (void) mouseDown: (NSEvent *)theEvent
{
  if([self level] == NSScreenSaverWindowLevel)
    {
      [NSApp sendAction: action to: target from: self];
    }
}
- (void) mouseUp: (NSEvent *)theEvent
{

}

- (BOOL) canBecomeKeyWindow
{
  if([self level] != NSDesktopWindowLevel)
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

- (BOOL) canBecomeMainWindow
{
  if([self level] != NSDesktopWindowLevel)
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

- (void) hide: (id)sender
{
  // Don't react to hide.  This window cannot be hidden.
}

@end
