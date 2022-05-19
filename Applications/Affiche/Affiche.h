/*
**  Affiche.h
**
**  Copyright (c) 2001
**
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

@class Note;
@class PreferencesPanelController;

@interface Affiche : NSObject
{
  // Outlets
  IBOutlet NSMenu *menu;
  IBOutlet NSMenu *info;
  IBOutlet NSMenu *file;
  IBOutlet NSMenu *edit;
  IBOutlet NSMenu *note;
  IBOutlet NSMenu *color;
  IBOutlet NSMenu *windows;
  IBOutlet NSMenu *services;
  IBOutlet NSMenu *format;

  IBOutlet NSMenuItem *blueMenuItem;
  IBOutlet NSMenuItem *grayMenuItem;
  IBOutlet NSMenuItem *greenMenuItem;
  IBOutlet NSMenuItem *purpleMenuItem;
  IBOutlet NSMenuItem *yellowMenuItem;
  
  // ivars
  NSMutableArray *allNotes;
}

- (id) init;
- (void) dealloc;

//
// action methods
//
- (IBAction) closeNote: (id) sender;

- (IBAction) exportText: (id) sender;
- (IBAction) importText: (id) sender;

- (IBAction) newNote: (id) sender;
- (IBAction) quitApplication: (id) sender;
- (IBAction) showPreferencesPanel: (id) sender;
- (IBAction) saveAllNotes: (id) sender;
- (IBAction) setNoteColor: (id) sender;
- (IBAction) showNoteInfo: (id) sender;


//
// delegate methods
//
- (void) applicationDidFinishLaunching: (NSNotification *) not;
- (void) applicationWillFinishLaunching: (NSNotification *) not;


//
// other methods
//
- (void) deleteNote: (Note *) theNote;
- (void) showNote: (Note *) theNote;
- (BOOL) synchronize;

- (PreferencesPanelController *) preferencesPanelController;


//
// static methods
//

+ (NSColor *) colorForCode: (int) theCode;

@end

@interface Affiche (Private)

- (void) _showNewNote: (Note *) theNote;

@end
