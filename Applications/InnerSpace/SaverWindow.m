/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "SaverWindow.h"
# include <GNUstepGUI/GSDisplayServer.h>

// I need to put defines here to make it not tied to X, 
// nor any backend..  this is temporary.
#ifdef HAVE_OMNIPRESENT
#include <X11/Xlib.h>
#endif

@implementation SaverWindow

- (void) makeOmnipresent
{
#ifdef HAVE_OMNIPRESENT
  GSDisplayServer *server = GSCurrentServer();
  Display *dpy = (Display *)[server serverDevice];
  void *winptr = [server windowDevice: [self windowNumber]];
  Window win = *(Window *)winptr;
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
#endif
}

- (void) setAction: (SEL)a forTarget: (id)t
{
  action = a;
  target = t;
}

- (void) keyDown: (NSEvent *)theEvent
{
  if([self level] != NSDesktopWindowLevel)
    {
      [NSApp sendAction: action to: target from: self];
    }
}

- (void) mouseUp: (NSEvent *)theEvent
{
  if([self level] != NSDesktopWindowLevel)
    {
      [NSApp sendAction: action to: target from: self];
    }
}

- (BOOL) canBecomeKeyWindow
{
  return YES;
}

- (BOOL) canBecomeMainWindow
{
  return YES;
}

- (void) hide: (id)sender
{
  // Don't react to hide.  This window cannot be hidden.
}

@end
