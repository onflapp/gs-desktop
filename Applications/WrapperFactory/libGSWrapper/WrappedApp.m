/* Copyright (C) 2024 OnFlApp
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * $Id: WrapperDelegate.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/libGSWrapper/WrapperDelegate.m $
 */

#import <AppKit/AppKit.h>
#import "WrappedApp.h"
#import "NSApplication+AppName.h"
#import "NSMenu+Suppress.h"
#import "AppIconView.h"

Window *winlist (Display *disp, unsigned long *len) {
    Atom prop = XInternAtom(disp,"_NET_CLIENT_LIST",False), type;
    int form;
    unsigned long remain;
    unsigned char *list;
 
    errno = 0;
    if (XGetWindowProperty(disp, XDefaultRootWindow(disp), prop, 0, 1024, False, XA_WINDOW,
                &type, &form, len, &remain, &list) != Success) {
        return 0;
    }
     
    return (Window*)list;
}

char *wintitle (Display *disp, Window win) {
    Atom prop = XInternAtom(disp,"_NET_WM_NAME",False), type;
    Atom utf8Atom = XInternAtom(disp,"UTF8_STRING",false);

    int form;
    unsigned long remain, len;
    unsigned char *list;
 
    errno = 0;
    if (XGetWindowProperty(disp, win, prop, 0, 1024, False, utf8Atom,
                &type, &form, &len, &remain, &list) != Success) {
        return NULL;
    }
 
    return (char*)list;
}

@implementation WrappedApp

- (id)initWithClassName:(NSString*) cname;
{
    self = [super init];
    ASSIGN(wrappedAppClassName, cname);

    return self;
}

- (void)dealloc
{
  RELEASE(delegate);
  RELEASE(wrappedAppClassName);
  [super dealloc];
}

- (void)setDelegate:(id)del
{
  ASSIGN(delegate, del);
}

- (BOOL)isActive
{
  return wrappedAppIsActive;
}

- (void)_wrappedAppDidChangeStatus:(NSNotification*)not
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_wrappedAppDidChangeStatusCB:) object:nil];
  [self performSelector:@selector(_wrappedAppDidChangeStatusCB:) withObject:not afterDelay:0.1];
}

- (void)_wrappedAppDidChangeStatusCB:(NSNotification*)not
{
  NSString* state = [not name];
  NSTimeInterval td = ([[NSDate date] timeIntervalSinceReferenceDate] - lastActionTime);
  if (td < 1.0) {
    NSLog(@"too many evets, ignore");
    lastActionTime = [[NSDate date] timeIntervalSinceReferenceDate];
    return;    
  }

  [self updateWindowList];

  if ([state isEqualToString:@"ACTIVE"]) {
    if (wrappedAppIsActive) return;
    wrappedAppIsActive = YES;
    Window win = [[not object]integerValue];
    
    [NSApp setKeyWindow:[self wrappedWindowForID:win]];
    [delegate wrappedAppDidBecomeActive];
  }
  else if ([state isEqualToString:@"DEACTIVE"]) {
    if (!wrappedAppIsActive) return;
    wrappedAppIsActive = NO;

    [NSApp setKeyWindow:nil];
    [delegate wrappedAppDidResignActive];
  }


  lastActionTime = [[NSDate date] timeIntervalSinceReferenceDate];
}

- (NSString*)wrappedAppClassName
{
  return wrappedAppClassName;
}

- (WrappedWin*) wrappedWindowForID:(Window) wid
{
  for (NSWindow* win in [NSApp windows]) {
    if ([win isKindOfClass:[WrappedWin class]] && [win windowID] == wid) {
      return win;
    }
  }

  return nil;
}

- (void) startObservingEvents
{
  [self performSelectorInBackground:@selector(processXWindowsEvents:) withObject:self];
}

- (void) updateWindowList
{
  const char* wmclass = [wrappedAppClassName cString];
  Display *dpy = XOpenDisplay(NULL);
  XClassHint whints;
  NSMenu *windowsMenu = [NSApp windowsMenu];
  NSMutableArray *toadd = [NSMutableArray array];
  NSMutableArray *torem = [NSMutableArray array];

  unsigned long len;
  Window *list;
  char *name;
  int rv;
 
  list = (Window*)winlist(dpy, &len);
 
  for (int i = 0; i < (int)len ; i++) {
    Window win = list[i];
    rv = XGetClassHint(dpy, win, &whints);
    if (!rv) continue;
    if (strcmp(whints.res_class, wmclass) != 0) continue;

    name = wintitle(dpy, win);
    if (name) {
      WrappedWin* wwin = [self wrappedWindowForID:win];
      if (!wwin) {
        wwin = [[WrappedWin alloc] initWithWindowID:win];
      }
      [toadd addObject:wwin];
      [wwin setTitle:[NSString stringWithFormat:@"%s", name]];
      NSLog(@">>> %lx %s %s\n", win, whints.res_class, name);
      XFree(name);
    }
  }
  
  for (WrappedWin* wwin in toadd) {
    [NSApp addWindowsItem:wwin
		    title:[wwin title]
	         filename:NO];
  }

  for (NSWindow* win in [NSApp windows]) {
    if ([win isKindOfClass:[WrappedWin class]] && [toadd containsObject:win] == NO) {
      [torem addObject:win];
    } 
  }

  for (NSWindow* win in torem) {
    [NSApp removeWindowsItem:win];
  }

  XFree(list);
}

- (void) processXWindowsEvents:(id)sender 
{
  const char* wrapper = [[sender wrappedAppClassName] cString];
  if (!wrapper) return;

  XInitThreads();

  Display *d;
  XEvent e;
 
  d = XOpenDisplay(NULL);

  Atom naw = XInternAtom(d, "_NET_ACTIVE_WINDOW", False);

  Window root = XDefaultRootWindow(d);
  XSelectInput(d, root, PropertyChangeMask);

  while (1) {
    XNextEvent(d, &e);
    if (e.xproperty.atom == naw) {
      unsigned char *data = NULL;
      int format;
      Atom real;
      unsigned long extra, n;

      XGetWindowProperty(d, root, naw, 0, ~0, False,
                         AnyPropertyType, &real, &format, &n, &extra, &data);

      if (data) {
        Window win = *(unsigned long *) data;
        XClassHint hint;
        XGetClassHint(d, win, &hint);

        if (strcmp(hint.res_class, wrapper) == 0) {
          NSNotification* not = [NSNotification notificationWithName:@"ACTIVE" object:[NSNumber numberWithInteger:win]];
          [self performSelectorOnMainThread:@selector(_wrappedAppDidChangeStatus:) withObject:not waitUntilDone:NO];
        }
        else {
          //NSLog(@"xxxx:%lx %s", win, hint.res_class);
          NSNotification* not = [NSNotification notificationWithName:@"DEACTIVE" object:[NSNumber numberWithInteger:win]];
          [self performSelectorOnMainThread:@selector(_wrappedAppDidChangeStatus:) withObject:not waitUntilDone:NO];
        }

        XFree (data);
        XFree (hint.res_class);
        XFree (hint.res_name);
      }

    }
  }
}

@end
