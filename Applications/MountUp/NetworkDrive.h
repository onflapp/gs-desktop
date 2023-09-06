/*
   Project: MountUp

   Copyright (C) 2022 Free Software Foundation

   Author: Parallels

   Created: 2022-11-02 17:46:05 +0000 by parallels

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

#ifndef _NETWORKDRIVE_H_
#define _NETWORKDRIVE_H_

#import <AppKit/AppKit.h>
#import "NetworkDrive.h"

@interface NetworkDrive : NSObject
{
   IBOutlet NSPanel* panel;
   IBOutlet NSPopUpButton* type;
   IBOutlet NSTextField* location;
   IBOutlet NSTextField* user;
   IBOutlet NSTextField* password;
}
- (IBAction) connect:(id) sender;

- (void) showPanel;
- (void) closePanel;
@end

#endif // _NETWORKDRIVE_H_

