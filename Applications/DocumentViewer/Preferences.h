/*
   Project: DocumentViewer

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

#ifndef _PREFERENCES_H_
#define _PREFERENCES_H_

#import <AppKit/AppKit.h>

@interface Preferences : NSObject
{
  IBOutlet NSPanel* panel;
  IBOutlet NSButton* reuseDocumentButton;
}

+ (Preferences*) sharedInstance;
- (NSPanel*) panel;

@end

#endif // _PANEL_H_

