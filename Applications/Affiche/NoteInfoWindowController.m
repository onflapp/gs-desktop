/*
**  NoteInfoWindowController.m
**
**  Copyright (c) 2001, 2002
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

#import "NoteInfoWindowController.h"

#import "Constants.h"
#import "Note.h"
#import "NoteView.h"
#import "NoteWindowController.h"

#ifndef MACOSX
#import "NoteInfoWindow.h"
#endif

static NoteInfoWindowController *singleInstance;

@implementation NoteInfoWindowController

- (id) initWithWindowNibName: (NSString *) theNibName
{
#ifdef MACOSX
  self = [super initWithWindowNibName: theNibName];
#else
  NoteInfoWindow *noteInfoWindow;
  
  noteInfoWindow = [[NoteInfoWindow alloc] initWithContentRect:NSMakeRect(100,100,320,110)
                                      styleMask: (NSClosableWindowMask|NSResizableWindowMask)
                                      backing: NSBackingStoreBuffered
                                      defer: NO];

  self = [super initWithWindow: noteInfoWindow];
  
  [noteInfoWindow layoutWindow];
  [noteInfoWindow setDelegate: self];

  // We link our outlets
  creationDateField = [noteInfoWindow creationDateField];
  modificationDateField = [noteInfoWindow modificationDateField];

  titlePopUp = [noteInfoWindow titlePopUp];
  titleField = [noteInfoWindow titleField];
#endif
  
  // We set the title to an empty string
  [[self window] setTitle: _(@"Note Information")];
  
  return self;
}

- (void) dealloc
{
  singleInstance = nil;
  
  [super dealloc];
}

//
// delegate methods
//
- (void) controlTextDidChange: (NSNotification *) aNotification
{
  //NSLog(@"Changing text...");
  
  if ( [self note] && [NoteWindowController lastNoteWindowOnTop])
    {
      NoteWindowController *aNoteWindowController;
      
      // We update our value
      [[self note] setTitleValue: [titleField stringValue]];
      
      // We refresh the UI
      aNoteWindowController = [[NoteWindowController lastNoteWindowOnTop] windowController];
      [aNoteWindowController updateWindowTitle];
      [[aNoteWindowController noteView] setNeedsDisplay: YES];
    }
}

- (void) windowDidLoad
{
  [super windowDidLoad];
}

- (void) windowWillClose: (NSNotification *) theNotification
{
  AUTORELEASE(self);
}


//
// action methods
//
- (IBAction) selectionOfTitleHasChanged: (id) sender
{
  //NSLog(@"Changing note title...");

  [titlePopUp synchronizeTitleAndSelectedItem];

  switch ( [titlePopUp indexOfSelectedItem] )
    {
    case 2:
      [titleField setEditable: YES];
      break;
      
    case 0:
    case 1:
    default:
      [titleField setEditable: NO];
    }

  if ( [self note] && [NoteWindowController lastNoteWindowOnTop])
    {
      NoteWindowController *aNoteWindowController;
      
      // We set our new values
      [[self note] setTitle: ([titlePopUp indexOfSelectedItem] + 1)];
      [[self note] setTitleValue: [titleField stringValue]];

      // We refresh the UI
      aNoteWindowController = [[NoteWindowController lastNoteWindowOnTop] windowController];
      [aNoteWindowController updateWindowTitle];
      [[aNoteWindowController noteView] setNeedsDisplay: YES];
    }
  else
    {
      NSBeep();
    }
}


//
// access / mutation
//

- (Note *) note
{
  return note;
}

- (void) setNote: (Note *) theNote
{
  if (! singleInstance )
    {
      return;
    }

  if ( theNote )
    {
      note = theNote;
      
      [creationDateField setStringValue: [[note creationDate] description] ];
      [modificationDateField setStringValue: [[note modificationDate] description] ];
      
      [titlePopUp selectItemAtIndex: ([note title] - 1)];
      [titleField setStringValue: ([note titleValue] ? [note titleValue] : @"")];
    }
  else
    {
      note = nil;
    }
}

//
// single instance
//

+ (id) singleInstance
{
  if (!singleInstance)
    {
      singleInstance = [[NoteInfoWindowController alloc] initWithWindowNibName: @"NoteInfoWindow"];
    }
    
  return singleInstance;
}

@end
