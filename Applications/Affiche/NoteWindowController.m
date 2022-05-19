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

#import "NoteWindowController.h"

#import "Affiche.h"
#import "Constants.h"
#import "Note.h"
#import "NoteInfoWindowController.h"
#import "NoteView.h"
#import "NoteWindow.h"

static id lastNoteWindowOnTop = nil;

@implementation NoteWindowController

- (id) initWithWindowNibName: (NSString *) theNibName
{
  NoteWindow *noteWindow;
  
  noteWindow = [[NoteWindow alloc] initWithContentRect:NSMakeRect(10,10,DEFAULT_NOTE_WIDTH,DEFAULT_NOTE_HEIGHT)
                                   //styleMask: NSTitledWindowMask
				   styleMask: NSBorderlessWindowMask
                                   backing: NSBackingStoreBuffered
                                   defer: NO];

  self = [super initWithWindow: noteWindow];
  
  [noteWindow layoutWindow];
  [noteWindow setDelegate: self];

  // We link our outlets
  textView = [noteWindow textView];
  
  // We set the title to an empty string
  [[self window] setTitle: @""];
  
  RELEASE(noteWindow);

  return self;
}

- (void) dealloc
{
  //NSLog(@"NoteWindowController: -dealloc");

  lastNoteWindowOnTop = nil;
  
  RELEASE(note);
  
  [super dealloc];
}

- (void) updateWindowTitle
{
  if ( [[self note] title] == NO_TITLE )
    {
      [[self window] setTitle: @""];
    }
  else if ( [[self note] title] == FIRST_LINE_OF_NOTE )
    {
      NSArray *allLines;
      
      allLines = [[textView string] componentsSeparatedByString: @"\n"];
      
      if ( [allLines count] > 0 )
	{
	  [[self window] setTitle: [allLines objectAtIndex: 0]];
	}
    }
  else
    {
      [[self window] setTitle: [[self note] titleValue]];
    }
}


//
// delegate methods
//

- (void) textDidChange: (NSNotification *) aNotification
{
  NSAttributedString *anAttributedString;
  
  anAttributedString = [[NSAttributedString alloc] initWithAttributedString: [textView textStorage]];
  [[self note] setValue: anAttributedString];

  [self updateWindowTitle];
  [[self noteView] setNeedsDisplay: YES];

  // We update the modification date of our note
  [[self note] setModificationDate: [NSDate date]];

  RELEASE(anAttributedString);
}

- (void) windowDidBecomeKey: (NSNotification *) aNotification
{
  lastNoteWindowOnTop = [self window];
  [[NoteInfoWindowController singleInstance] setNote: [self note]];
}

- (void) windowDidLoad
{
  lastNoteWindowOnTop = [self window];
  
  [super windowDidLoad];
}


- (void) windowDidMove: (NSNotification *) aNotification
{
  [self _updateWindowFrame];
}


- (void) windowDidResize: (NSNotification *) aNotification
{
  [self _updateWindowFrame];
}

- (BOOL) windowShouldClose: (id) sender
{
  int choice;

  choice = NSRunAlertPanel(_(@"Closing a note..."),
			   _(@"Would you like to save this note (%@...)\nto a file?"),
			   _(@"Cancel"), // default
			   _(@"Yes"),    // alternate
			   _(@"No"),     // other return
			   [[self window] title]);    
  
  if (choice == NSAlertDefaultReturn)
    {
      return NO;
    }
  else if ( choice == NSAlertAlternateReturn )
    {
      NSSavePanel *aSavePanel;
      int aChoice;
      
      aSavePanel = [NSSavePanel savePanel];
      [aSavePanel setAccessoryView: nil];
      [aSavePanel setRequiredFileType: @""];
      
      aChoice = [aSavePanel runModalForDirectory:NSHomeDirectory() file: @"note.txt"];
      
      /* if successful, save file under designated name */
      if (aChoice == NSOKButton)
	{
	  if (! [[textView string] writeToFile: [aSavePanel filename]
				   atomically: YES] )
	    {
	      NSBeep();
	    }
	}
    }
  
  [(Affiche *)[NSApp delegate] deleteNote: [self note]];
  [(Affiche *)[NSApp delegate] synchronize];

  return YES;
}

- (void) windowWillClose: (NSNotification *) theNotification
{
  AUTORELEASE(self);
}


//
// access / mutation
//

+ (id) lastNoteWindowOnTop
{
  return lastNoteWindowOnTop;
}

- (Note *) note
{
  return note;
}

- (void) setNote: (Note *) theNote
{
  if ( theNote )
    {
      RETAIN(theNote);
      RELEASE(note);
      note = theNote;
      
      [[textView textStorage] setAttributedString: [note value]];
      [textView setBackgroundColor: [note backgroundColor]];
      [[self noteView] setColorCode: [note colorCode]];
      [[self window] setFrame: [note frame]
		     display: NO];

      [self updateWindowTitle];
      [textView setNeedsDisplay: YES];
      [[self noteView] setNeedsDisplay: YES];
    }
  else
    {
      RELEASE(note);
      note = nil;
    }
}

- (NSTextView *) textView
{
  return textView;
}

- (NoteView *) noteView
{
  return [(NoteWindow *)[self window] noteView];
}

@end


//
// private methods
//
@implementation NoteWindowController (Private)

- (void) _updateWindowFrame
{
  if ( [self note] )
    {
      [[self note] setFrame: [[self window] frame]];
    }
}


@end
