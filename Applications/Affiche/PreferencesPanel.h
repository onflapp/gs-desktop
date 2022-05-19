/*
**  PreferencesPanel.h
**
**  Copyright (c) 2002
**
**  Author: Jonathan B. Leffert <jonathan@leffert.net>
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import <AppKit/AppKit.h>

@interface PreferencesPanel : NSPanel
{
  NSTextField *fontField;

  NSPopUpButton *colorPopUp;
  NSBox *titleBarColorBox, *noteContentColorBox;

  NSButton *topLeft;
  NSButton *topRight;
  NSButton *bottomLeft;
  NSButton *bottomRight;
  NSButton *center;

  NSPopUpButton *titlePopUp;
  NSTextField *titleField;
}

- (void) layoutPanel;

//
// access/mutation methods
//

- (NSTextField *) fontField;


- (NSPopUpButton *) colorPopUp;
- (NSBox *) titleBarColorBox;
- (NSBox *) noteContentColorBox;

- (NSButton *) topLeft;
- (NSButton *) topRight;
- (NSButton *) bottomLeft;
- (NSButton *) bottomRight;
- (NSButton *) center;

- (NSPopUpButton *) titlePopUp;
- (NSTextField *) titleField;

@end
