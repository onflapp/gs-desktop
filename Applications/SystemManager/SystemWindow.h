/*
   Project: SystemManager

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

#ifndef _SYSTEMWINDOW_H_
#define _SYSTEMWINDOW_H_

#import <AppKit/AppKit.h>

@interface SystemWindow : NSObject {
  IBOutlet NSWindow* window;
  IBOutlet NSTextView* processInfo;
  IBOutlet NSTableView* processList;
  IBOutlet NSTextField* filterText;

  IBOutlet NSButton* devicesSwitch;
  IBOutlet NSButton* mountsSwitch;
  IBOutlet NSButton* pathsSwitch;
  IBOutlet NSButton* socketsSwitch;
  IBOutlet NSButton* slicesSwitch;
  IBOutlet NSButton* timersSwitch;
  IBOutlet NSButton* targetsSwitch;
  IBOutlet NSButton* servicesSwitch;
  IBOutlet NSButton* swapsSwitch;
  IBOutlet NSButton* scopesSwitch;

  IBOutlet NSPopUpButton* statusPopUp;

  NSMutableData* buff;
  NSFileHandle* fh;
  NSTask* task;
  NSInteger status;

  NSMutableArray* processItems;
  NSMutableString* processDetails;
}

- (id) init;
- (NSWindow*) window;
- (void) showWindow;

- (IBAction) refresh:(id)sender;
- (IBAction) execute:(id)sender;
- (IBAction) select:(id) sender;
- (IBAction) toggleSwitch:(id)sender;
- (IBAction) toggleStatus:(id)sender;

@end

#endif // _SYSTEMWINDOW_H_

