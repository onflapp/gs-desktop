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
#import "WrappedWin.h"
#import "NSApplication+AppName.h"
#import "NSMenu+Suppress.h"
#import "AppIconView.h"

@implementation WrappedWin

- (id)initWithWindowID:(Window) wid {
  self = [super init];
  winid = wid;

  return self;
}

- (Window) windowID {
  return winid;
}

- (void) dealloc {
  [super dealloc];
}

- (id) firstResponder {
  return self;
}

/*
- (BOOL)respondsToSelector:(SEL) aSelector {
  NSString* sel = NSStringFromSelector(aSelector);
  NSLog(@">>>%@", sel);
  return YES;
}
*/

- (void) makeKeyAndOrderFront:(id)sender {
  [self orderFront:sender];
}

- (void) performClose:(id) sender {
  NSString* val = [NSString stringWithFormat:@"%lx", winid];
  [[NSApp delegate] performShellUISelector:@selector(dowindowclose:) withObject:val];
}

- (void) arrangeInFront:(id) sender {
}

- (void) performMiniaturize:(id) sender {
  NSString* val = [NSString stringWithFormat:@"%lx", winid];
  [[NSApp delegate] performShellUISelector:@selector(dowindowminimize:) withObject:val];
}

- (void) orderFront:(id)sender {
  NSString* val = [NSString stringWithFormat:@"%lx", winid];
  [[NSApp delegate] performShellUISelector:@selector(dowindowactivate:) withObject:val];
}

- (void) copy:(id)sender {
  NSString* val = [NSString stringWithFormat:@"%lx", winid];
  [[NSApp delegate] performShellUISelector:@selector(docopy:) withObject:val];
}

- (void) cut:(id)sender {
  NSString* val = [NSString stringWithFormat:@"%lx", winid];
  [[NSApp delegate] performShellUISelector:@selector(docut:) withObject:val];
}

- (void) paste:(id)sender {
  NSString* val = [NSString stringWithFormat:@"%lx", winid];
  [[NSApp delegate] performShellUISelector:@selector(dopaste:) withObject:val];
}

- (void) selectAll:(id)sender {
  NSString* val = [NSString stringWithFormat:@"%lx", winid];
  [[NSApp delegate] performShellUISelector:@selector(doselectall:) withObject:val];
}

- (id) validRequestorForSendType:(NSString *)st
                      returnType:(NSString *)rt {
  if ([st isEqual:NSStringPboardType])
    return self;
  else
    return nil;
}

- (BOOL) writeSelectionToPasteboard:(NSPasteboard *)pb
                              types:(NSArray *)types {
  NSString *sel = [[NSPasteboard pasteboardWithName:@"Selection"] stringForType:NSStringPboardType];

  if (sel) {
    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pb setString:sel forType:NSStringPboardType];
    return YES;
  }
  else {
    return NO;
  }
}
@end
