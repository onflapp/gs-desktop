/* Include for nxworkspace tools
   Copyright (C) 2020 Free Software Foundation, Inc.

   Written by:  onflapp
   Created: September 2020

   This file is part of the GNUstep Project

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   You should have received a copy of the GNU General Public
   License along with this program; see the file COPYING.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

   */

#import "ShellUITask.h"

@interface ShellUIProxy : NSObject {
   NSMutableDictionary* controls;
   NSMutableDictionary* context;
   ShellUITask* delegate;

   IBOutlet NSView* iconView;
   IBOutlet NSWindow* window;
   NSMenu* menu;
}

- (id) init;
- (void) updateValue:(NSString*) val forControl:(NSString*) name;
- (void) handleActions:(id) del;

- (NSView*) iconView;
- (NSWindow*) window;
- (NSMenu*) menu;
@end
