/*
**  PreferencesPanelController.h
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

@interface PreferencesPanelController : NSWindowController
{
  IBOutlet NSTextField *fontField;

  IBOutlet NSPopUpButton *colorPopUp;
  IBOutlet NSBox *titleBarColorBox;
  IBOutlet NSBox *noteContentColorBox;

  IBOutlet NSButton *topLeft;
  IBOutlet NSButton *topRight;
  IBOutlet NSButton *bottomLeft;
  IBOutlet NSButton *bottomRight;
  IBOutlet NSButton *center;

  IBOutlet NSPopUpButton *titlePopUp;
  IBOutlet NSTextField *titleField;

  // ivars
  int position;
}

- (id) initWithWindowNibName: (NSString *) theNibName;
- (void) dealloc;

- (void) initializeFromDefaults;


//
// action methods
//

- (IBAction) chooseFont: (id) sender;
- (IBAction) selectionOfColorHasChanged: (id) sender;
- (IBAction) selectionOfPositionHasChanged: (id) sender;
- (IBAction) selectionOfTitleHasChanged: (id) sender;

@end

@interface PreferencesPanelController (Private)

- (void) _updatePositionSelection;

@end
