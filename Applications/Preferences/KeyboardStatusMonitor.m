#import "KeyboardStatusMonitor.h"
#include "X11/Xutil.h"

@implementation KeyboardStatusMonitor

- (id)init
{
  if (!(self = [super init])) {
    return nil;
  }

  return self;
}

- (void) processXWindowsEvents:(id) sender {
  CREATE_AUTORELEASE_POOL(pool);
  Display *d;
  XEvent e;
  Window r;
  Time lasttime = 0;
  int s;

  d = XOpenDisplay(NULL);
  s = DefaultScreen(d);
  r = XDefaultRootWindow(d);

  /* this is a hack which hopefully works
   * I observed that _XKB_RULES_NAMES will change after display wakes up
   * use this to trigger update
   */
  Atom atom = XInternAtom(d, "_XKB_RULES_NAMES", True);

  XSelectInput(d, r, PropertyChangeMask);
  while (1) {
    XNextEvent(d, &e);

    if (e.type == PropertyNotify) {
      if (e.xproperty.atom == atom) {
        Time d = e.xproperty.time - lasttime;
        if (d > 30000) { //let's assume the display doesn't get turned on and off too frequetly
          [sender performSelectorOnMainThread:@selector(wakeUpAfterSleep) 
                                  withObject:nil 
                               waitUntilDone:NO];
        }
        lasttime = e.xproperty.time;
      }
    }
  }
  [self release];
  RELEASE(pool);
}

@end
