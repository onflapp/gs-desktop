/*
**  Affiche.m
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

#import "Affiche.h"

#import "Constants.h"
#import "Note.h"
#import "NoteInfoWindowController.h"
#import "NoteView.h"
#import "NoteWindowController.h"
#import "PreferencesPanelController.h"

NSString *PathToNotes()
{
  return [NSString stringWithFormat: @"%@/%@",
                   AfficheUserLibraryPath(), @"Notes"];
}

static PreferencesPanelController *preferencesPanelController;

@implementation Affiche

//
//
//
- (id) init
{
  self = [super init];
  
  return self;
}

- (void) dealloc
{
  RELEASE(allNotes);

  [super dealloc];
}

//
// action methods
//

- (IBAction) closeNote: (id) sender
{
  if ( [NoteWindowController lastNoteWindowOnTop] )
    {
      if ( [[[NoteWindowController lastNoteWindowOnTop] 
	      windowController] windowShouldClose: nil] )
	{
	  [[NoteWindowController lastNoteWindowOnTop] close];
	}
    }
  else
    {
      NSBeep();
    }
}

- (IBAction) exportText: (id) sender
{
  if ( [NoteWindowController lastNoteWindowOnTop] )
    {
      NoteWindowController *noteWindowController;
      NSSavePanel *aSavePanel;
      int aChoice;
      
      noteWindowController = [[NoteWindowController lastNoteWindowOnTop] delegate];
      
      aSavePanel = [NSSavePanel savePanel];
      [aSavePanel setAccessoryView: nil];
      [aSavePanel setRequiredFileType: @""];
      
      aChoice = [aSavePanel runModalForDirectory: NSHomeDirectory()
			    file: @"note.txt"];
      
      /* if successful, save file under designated name */
      if (aChoice == NSOKButton)
	{
	  if (! [[[noteWindowController textView] string] writeToFile: [aSavePanel filename]
							  atomically: YES] )
	    {
	      NSBeep();
	    }
	}
    }
  else
    {
      NSBeep();
    }
}

- (IBAction) importText: (id) sender
{
  NSArray *fileToOpen;
  NSOpenPanel *oPanel;
  int count, result;
  
  oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:NO];
  result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil types:nil];
  
  if (result == NSOKButton)
    {
      fileToOpen = [oPanel filenames];
      count = [fileToOpen count];
      
      if (count > 0)
	{
	  NSAttributedString *anAttributedString;
	  NSString *fileName;
	  Note *aNote;
	  
	  fileName = [fileToOpen objectAtIndex: 0];
	  
	  aNote = AUTORELEASE([[Note alloc] init]);
	  anAttributedString = [[NSAttributedString alloc] initWithString: [NSString stringWithContentsOfFile: fileName]];
	  [aNote setValue: anAttributedString];
	  RELEASE(anAttributedString);

	  [allNotes addObject: aNote];
	  [self synchronize];

	  [self _showNewNote: aNote];
	}
    }
}

- (IBAction) newNote: (id) sender
{
  Note *aNote;
  
  aNote = AUTORELEASE([[Note alloc] init]);
  [allNotes addObject: aNote];
  
  [self _showNewNote: aNote];

  // We sync for saving that new note right now
  [self synchronize];
}


//
// Our Affiche service!
//
- (void) newNote: (NSPasteboard *) pboard
	userData: (NSString *) userData
	   error: (NSString **) error
{
  NSString *aString;
  NSArray *allTypes;
  Note *aNote;

  allTypes = [pboard types];
  
  if ( ![allTypes containsObject: NSStringPboardType])
    {
      *error = @"No string type supplied on pasteboard";
      return;
    }
  
  aString = [pboard stringForType: NSStringPboardType];
  
  if (aString == nil)
    {
      *error = @"No string value supplied on pasteboard";
      return;
    }
  
  aNote = AUTORELEASE([[Note alloc] init]);
  [aNote setValue: AUTORELEASE([[NSAttributedString alloc] initWithString: aString]) ];
  
  [allNotes addObject: aNote];
  [self synchronize];
  
  [self _showNewNote: aNote];
}

- (IBAction) quitApplication: (id) sender
{
  [self synchronize];
  
  [NSApp terminate: self];  
}

- (IBAction) showPreferencesPanel: (id) sender
{
  [[self preferencesPanelController] showWindow: self];
}

- (IBAction) saveAllNotes: (id) sender
{
  [self synchronize];
}

- (IBAction) setNoteColor: (id) sender
{
  if ( [NoteWindowController lastNoteWindowOnTop] )
    {
      NoteWindowController *aNoteWindowController;
      NSColor *aColor;
      int colorCode;
      
      aNoteWindowController = [[NoteWindowController lastNoteWindowOnTop] delegate];
      
      if (sender == blueMenuItem)
	{
	  colorCode = BLUE;
	}
      else if (sender == grayMenuItem)
	{
	  colorCode = GRAY;
	}
      else if (sender == greenMenuItem)
	{
	  colorCode = GREEN;
	}
      else if (sender == purpleMenuItem)
	{
	  colorCode = PURPLE;
	} 
      // The default color is always yellow.
      else
	{
	  colorCode = YELLOW;
	}
      
      aColor = [Affiche colorForCode: colorCode];
      
      [[aNoteWindowController note] setBackgroundColor: aColor];
      [[aNoteWindowController note] setColorCode: colorCode];
      
      [[aNoteWindowController textView] setBackgroundColor: aColor];
      [[aNoteWindowController noteView] setColorCode: colorCode];
      [[aNoteWindowController textView] setNeedsDisplay: YES];
    }
  else
    {
      NSBeep();
    }
}

- (IBAction) showNoteInfo: (id) sender
{
  if ( [NoteWindowController lastNoteWindowOnTop] )
    {
      NoteInfoWindowController *aNoteInfoWindowController;    
      Note *aNote;

      aNote = [(NoteWindowController *)[[NoteWindowController lastNoteWindowOnTop] delegate] note];
      aNoteInfoWindowController = [NoteInfoWindowController singleInstance];
      [aNoteInfoWindowController setNote: aNote];
      [aNoteInfoWindowController showWindow: self];
    }
}

//
// delegate methods
//
- (void) applicationDidFinishLaunching: (NSNotification *) not
{
  NSFileManager *fileManager;
  BOOL isDir;
  int i;
  
  fileManager = [NSFileManager defaultManager];
  
  if ( [fileManager fileExistsAtPath: (NSString *)AfficheUserLibraryPath()
                    isDirectory: &isDir] )
    {
      if ( ! isDir )
        {
          NSLog(@"%@ exists but it is a file not a directory.",
                AfficheUserLibraryPath());
          exit(1);
        }
    }
  else    {
    if ( ! [fileManager createDirectoryAtPath: (NSString *)AfficheUserLibraryPath()
			attributes: nil] )
      {
	// directory creation failed.  quit.
	NSLog(@"Could not create directory: %@", AfficheUserLibraryPath());
	exit(1);
      }
    else
        {
          NSLog(@"Created directory: %@", AfficheUserLibraryPath());
        }
  }
    
  // We verify if our archived NSMutableArray exists, if not,
  // we create. If yes, we decode it.
  if ( [fileManager fileExistsAtPath: PathToNotes()] )
    {
      allNotes = [NSUnarchiver unarchiveObjectWithFile: PathToNotes()];
      RETAIN(allNotes);
    }
  else
    {
      allNotes = [[NSMutableArray alloc] init];
      [self synchronize];
    }
  
  // For all notes, we show their window.
  for (i = 0; i < [allNotes count]; i++)
    {
      [self showNote: [allNotes objectAtIndex: i]];
    }

  // We register our service
  [NSApp setServicesProvider: self];
}

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
  // Local variable
#ifndef MACOSX  
  SEL action = NULL;
#endif

  // We begin by setting our NSApp's logo
  [NSApp setApplicationIconImage: [NSImage imageNamed: @"Affiche.tiff"]];

    // We continue by creating our NSMenu
#ifndef MACOSX
  menu = [[NSMenu alloc] init];
  
  [menu addItemWithTitle:_(@"Info") action: action keyEquivalent: @""];
  [menu addItemWithTitle:_(@"File") action: action  keyEquivalent: @""];
  [menu addItemWithTitle:_(@"Edit") action: action  keyEquivalent: @""];
  [menu addItemWithTitle:_(@"Note") action: action  keyEquivalent: @""];
  [menu addItemWithTitle:_(@"Color") action: action  keyEquivalent: @"h"];
  [menu addItemWithTitle:_(@"Windows") action: action keyEquivalent: @"p"];
  [menu addItemWithTitle:_(@"Print") action: action keyEquivalent: @"p"];
  [menu addItemWithTitle:_(@"Services") action: action keyEquivalent: @""];
  [menu addItemWithTitle:_(@"Hide") action: @selector (hide:) keyEquivalent: @"h"];
  [menu addItemWithTitle:_(@"Quit") action:@selector(quitApplication:) keyEquivalent: @"q"];

  // Our Info menu / submenus
  info = [[NSMenu alloc] init];
  [menu setSubmenu:info forItem:[menu itemWithTitle:_(@"Info")]];
  [info addItemWithTitle:_(@"Info Panel...")
        action: @selector(orderFrontStandardInfoPanel:)   
        keyEquivalent:@""];
  [info addItemWithTitle:_(@"Preferences...")
        action: @selector(showPreferencesPanel:)
        keyEquivalent:@""];
  [info addItemWithTitle:_(@"Help...")
        action: action
        keyEquivalent:@"?"];
  RELEASE(info);

  // Our File menu / submenus
  file = [[NSMenu alloc] init];
  [menu setSubmenu:file forItem:[menu itemWithTitle:_(@"File")]];
  [file addItemWithTitle: _(@"New Note")
	action: @selector(newNote:) 
	keyEquivalent: @"n"];
  [file addItemWithTitle: _(@"Close")
	action: @selector(closeNote:)
	keyEquivalent: @""];
  [file addItemWithTitle: _(@"Save All")
	action: @selector(saveAllNotes:)
	keyEquivalent: @""];
  [file addItemWithTitle: _(@"Import Text")
	action: @selector(importText:)
	keyEquivalent: @""];
  [file addItemWithTitle: _(@"Export Text")
	action: @selector(exportText:)
	keyEquivalent: @""];
  RELEASE(file);

   // Our Edit menu / submenus
  edit = [[NSMenu alloc] init];
  [menu setSubmenu:edit forItem:[menu itemWithTitle:_(@"Edit")]];
  [edit addItemWithTitle: _(@"Cut")
	action: @selector(cut:)
	keyEquivalent: @"x"];
  [edit addItemWithTitle: _(@"Copy")
	action: @selector(copy:)
	keyEquivalent: @"c"];
  [edit addItemWithTitle: _(@"Paste")
	action: @selector(paste:)
	keyEquivalent: @"v"];
  [edit addItemWithTitle: _(@"Delete")
	action: @selector(delete:)
	keyEquivalent: @""];
  [edit addItemWithTitle: _(@"Select All")
	action: @selector(selectAll:)
	keyEquivalent: @"a"];
  RELEASE(edit);

  // Our Edit menu / submenus
  note = [[NSMenu alloc] init];
  [menu setSubmenu: note 
	forItem: [menu itemWithTitle:_(@"Note")]];
  [note addItemWithTitle: _(@"Format")
	action: action
	keyEquivalent: @""];
  format = [[NSFontManager sharedFontManager] fontMenu: YES];
  [note setSubmenu: format
	forItem: [note itemWithTitle: _(@"Format")]];
  RELEASE(format);
  [note addItemWithTitle: _(@"Note Info")
	action: @selector(showNoteInfo:)
	keyEquivalent: @""];
  RELEASE(note);

  // Our Color menu / submenus
  color = [[NSMenu alloc] init];
  [menu setSubmenu:color forItem:[menu itemWithTitle:_(@"Color")]];
  RELEASE(color);

  blueMenuItem = [[NSMenuItem alloc] init];
  [blueMenuItem setTitle: _(@"Blue")];
  [blueMenuItem setAction: @selector(setNoteColor:)];
  [blueMenuItem setKeyEquivalent: @""];
  [color addItem: blueMenuItem];
  RELEASE(blueMenuItem);

  grayMenuItem = [[NSMenuItem alloc] init];
  [grayMenuItem setTitle: _(@"Gray")];
  [grayMenuItem setAction: @selector(setNoteColor:)];
  [grayMenuItem setKeyEquivalent: @""];
  [color addItem: grayMenuItem];
  RELEASE(grayMenuItem);
  
  greenMenuItem = [[NSMenuItem alloc] init];
  [greenMenuItem setTitle: _(@"Green")];
  [greenMenuItem setAction: @selector(setNoteColor:)];
  [greenMenuItem setKeyEquivalent: @""];
  [color addItem: greenMenuItem];
  RELEASE(greenMenuItem);

  purpleMenuItem = [[NSMenuItem alloc] init];
  [purpleMenuItem setTitle: _(@"Purple")];
  [purpleMenuItem setAction: @selector(setNoteColor:)];
  [purpleMenuItem setKeyEquivalent: @""];
  [color addItem: purpleMenuItem];
  RELEASE(purpleMenuItem);

  yellowMenuItem = [[NSMenuItem alloc] init];
  [yellowMenuItem setTitle: _(@"Yellow")];
  [yellowMenuItem setAction: @selector(setNoteColor:)];
  [yellowMenuItem setKeyEquivalent: @""];
  [color addItem: yellowMenuItem];
  RELEASE(yellowMenuItem);

  // Our Windows menu
  windows = [[NSMenu alloc] init];
  [menu setSubmenu:windows forItem: [menu itemWithTitle:_(@"Windows")]];

  // Our Services menu
  services = [[NSMenu alloc] init];
  [menu setSubmenu: services forItem: [menu itemWithTitle: _(@"Services")]];

  [NSApp setMainMenu: menu];
  [NSApp setServicesMenu: services];
  [NSApp setWindowsMenu: windows];

  RELEASE(services);
  RELEASE(windows);
  RELEASE(menu);
#endif
}


//
// other methods
//

- (void) deleteNote: (Note *) theNote
{
  if ( theNote )
    {
      [allNotes removeObject: theNote];
    }
}

- (void) showNote: (Note *) theNote
{
  if ( theNote )
    {
      NoteWindowController *noteWindowController;
  
      noteWindowController = [[NoteWindowController alloc]
			       initWithWindowNibName: @"NoteWindow"];
      [noteWindowController setNote: theNote];
      [[noteWindowController window] orderFrontRegardless];
    }
}
 
- (BOOL) synchronize
{
  return [NSArchiver archiveRootObject: allNotes 
                                toFile: PathToNotes()];
}

- (PreferencesPanelController *) preferencesPanelController
{
  if ( ! preferencesPanelController )
    {
      preferencesPanelController = 
	[[PreferencesPanelController alloc] 
	  initWithWindowNibName: @"PreferencesPanel"];
    }
  return preferencesPanelController;
}


//
// static methods
//

+ (NSColor *) colorForCode: (int) theCode
{
  switch (theCode)
    {
    case BLUE:
      return  [NSColor colorWithDeviceRed: 0.44
		       green: 1.0
		       blue: 1.0
		       alpha: 1.0];
      
    case GRAY:
      return [NSColor colorWithDeviceRed: 0.93
		      green: 0.93
		      blue: 0.93
		      alpha: 1.0];
      
    case GREEN:
      return [NSColor colorWithDeviceRed: 0.70
		      green: 1.0
		      blue: 0.63
		      alpha: 1.0];
      
    case PURPLE:
      return[NSColor colorWithDeviceRed: 0.70
	    green: 0.78
	    blue: 1.0
	    alpha: 1.0];
      
    case YELLOW:
    default:
      return [NSColor colorWithDeviceRed: 1.0
		      green: 1.0
		      blue: 0.63
		      alpha: 1.0];
    }
}


@end


//
// Private interface
//
@implementation Affiche (Private)

- (void) _showNewNote: (Note *) theNote
{
  NoteWindowController *noteWindowController;
  NSRect aRect;
  int position;

  // We set our default note color
  if ( [[NSUserDefaults standardUserDefaults] objectForKey: @"COLOR"] )
    {
      int colorCode;
      
      colorCode = [[NSUserDefaults standardUserDefaults] integerForKey: @"COLOR"] + 1;
      [theNote setColorCode: colorCode];
      [theNote setBackgroundColor: [Affiche colorForCode: colorCode]];
    }

  // We set our note's title
  if ( [[NSUserDefaults standardUserDefaults] objectForKey: @"TITLE"] )
    {
      [theNote setTitle: ([[NSUserDefaults standardUserDefaults] integerForKey: @"TITLE"] + 1)];
      [theNote setTitleValue: [[NSUserDefaults standardUserDefaults] objectForKey: @"TITLE_VALUE"]];
    }


  // We create our note window's controller in order to set the rest of the attributes
  noteWindowController = [[NoteWindowController alloc]
			   initWithWindowNibName: @"NoteWindow"];
  
  [noteWindowController setNote: theNote];

  
  // We set the font
  if ( [[NSUserDefaults standardUserDefaults] objectForKey: @"FONT_NAME"] )
    {
      [[noteWindowController textView] setFont: [NSFont fontWithName: [[NSUserDefaults standardUserDefaults] stringForKey: @"FONT_NAME"]
							size: [[NSUserDefaults standardUserDefaults] floatForKey: @"FONT_SIZE"]] ];
    }
 
  
  // We set the note position
  if ( [[NSUserDefaults standardUserDefaults] objectForKey: @"POSITION"] )
    {     
      position = [[NSUserDefaults standardUserDefaults] integerForKey: @"POSITION"];
    }
  else
    {
      position = CENTER;
    }

  // We get our screen's frame  
  aRect = [[NSScreen mainScreen] frame];

  switch ( position )
    {
    case TOP_LEFT:
      [[noteWindowController window] setFrameTopLeftPoint: NSMakePoint(70, aRect.size.height - 70)];
      break;

    case BOTTOM_LEFT:
      [[noteWindowController window] setFrameTopLeftPoint: NSMakePoint(70, 70 + DEFAULT_NOTE_HEIGHT)];
      break;
      
    case TOP_RIGHT:
      [[noteWindowController window] setFrameTopLeftPoint:
				       NSMakePoint(aRect.size.width - 70 - DEFAULT_NOTE_WIDTH,
						   aRect.size.height - 70)];
      break;

    case BOTTOM_RIGHT:
      [[noteWindowController window] setFrameTopLeftPoint:
				       NSMakePoint(aRect.size.width - 70 - DEFAULT_NOTE_WIDTH,
						   70 + DEFAULT_NOTE_HEIGHT)];
      break;

    case CENTER:
    default:
      [[noteWindowController window] center];
    }
  
  // We finally put the new note on the screen!
  [[noteWindowController window] orderFrontRegardless];
}

@end


//
// Starting point of Affiche
//
int main(int argc, const char *argv[], char *env[])
{     
  Affiche *affiche;
  
  CREATE_AUTORELEASE_POOL(pool);

  affiche = [[Affiche alloc] init];
  
  [NSApplication sharedApplication];
  [NSApp setDelegate: affiche];

  NSApplicationMain(argc, argv); 
  
  RELEASE(affiche);
  RELEASE(pool);
  
  return 0;
}
