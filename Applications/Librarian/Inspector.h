/*
   Project: Librarian

   Copyright (C) 2022 Free Software Foundation

   Author: Ondrej Florian,,,

   Created: 2022-10-22 16:59:28 +0200 by oflorian

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

#ifndef _INSPECTOR_H_
#define _INSPECTOR_H_

#import <AppKit/AppKit.h>
#import "Books.h"

@interface Inspector : NSObject
{
  IBOutlet NSWindow* window;
  IBOutlet NSTableView* pathsTable;
  IBOutlet NSTextField* filterField;
  IBOutlet NSTextField* statusField;

  Books* currentBooks;
}
- (void) inspectBooks:(Books*) b;
- (IBAction) rebuild:(id) sender;
- (IBAction) addFolder:(id) sender;
- (IBAction) removeFolder:(id) sender;

+ (Inspector*) sharedInstance;
- (NSWindow*) window;

@end

#endif // _INSPECTOR_H_

