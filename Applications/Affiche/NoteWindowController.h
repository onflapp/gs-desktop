/*
**  NoteWindowController.m
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
@class NoteView;

@interface NoteWindowController : NSWindowController
{
  // Outlets
  IBOutlet NSTextView *textView;
  
  // Other ivar
  Note *note;
}

- (id) initWithWindowNibName: (NSString *) theNibName;
- (void) dealloc;

- (void) updateWindowTitle;

//
// delegate methods
//

- (void) textDidChange: (NSNotification *) aNotification;
- (void) windowDidBecomeKey: (NSNotification *) aNotification;
- (void) windowDidLoad;
- (void) windowDidMove: (NSNotification *) aNotification;
- (void) windowDidResize: (NSNotification *) aNotification;
- (BOOL) windowShouldClose: (id) sender;
- (void) windowWillClose: (NSNotification *) theNotification;


//
// access / mutation
//

+ (id) lastNoteWindowOnTop;
- (Note *) note;
- (void) setNote: (Note *) theNote;
- (NSTextView *) textView;
- (NoteView *) noteView;

@end

//
// private methods
//
@interface NoteWindowController (Private)

- (void) _updateWindowFrame;

@end
