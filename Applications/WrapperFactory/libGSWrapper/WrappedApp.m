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
#include "X11/Xutil.h"

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

- (void)_wrappedAppDidChangeStatus:(NSString*) state
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_wrappedAppDidChangeStatusCB:) object:nil];
  [self performSelector:@selector(_wrappedAppDidChangeStatusCB:) withObject:state afterDelay:0.1];
}

- (void)_wrappedAppDidChangeStatusCB:(NSString*) state
{
  NSTimeInterval td = ([[NSDate date] timeIntervalSinceReferenceDate] - lastActionTime);
  if (td < 1.0) {
    NSLog(@"too many evets, ignore");
    lastActionTime = [[NSDate date] timeIntervalSinceReferenceDate];
    return;    
  }

  if ([state isEqualToString:@"ACTIVE"]) {
    if (wrappedAppIsActive) return;
    wrappedAppIsActive = YES;
    [delegate wrappedAppDidBecomeActive];
  }
  else if ([state isEqualToString:@"DEACTIVE"]) {
    if (!wrappedAppIsActive) return;
    wrappedAppIsActive = NO;
    [delegate wrappedAppDidResignActive];
  }

  lastActionTime = [[NSDate date] timeIntervalSinceReferenceDate];
}

- (NSString*)wrappedAppClassName
{
  return wrappedAppClassName;
}

- (void) startObservingEvents
{
  [self performSelectorInBackground:@selector(processXWindowsEvents:) withObject:self];
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
          [self performSelectorOnMainThread:@selector(_wrappedAppDidChangeStatus:) withObject:@"ACTIVE" waitUntilDone:NO];
        }
        else {
          //NSLog(@"xxxx:%lx %s", win, hint.res_class);
          [self performSelectorOnMainThread:@selector(_wrappedAppDidChangeStatus:) withObject:@"DEACTIVE" waitUntilDone:NO];
        }

        XFree (data);
        XFree (hint.res_class);
        XFree (hint.res_name);
      }

    }
  }
}

@end
