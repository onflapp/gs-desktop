/*
**  PreferencesPanelController.m
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

#import "PreferencesPanelController.h"

#import "ColorView.h"
#import "Constants.h"
#import "PreferencesPanel.h"

@implementation PreferencesPanelController

- (id) initWithWindowNibName: (NSString *) theNibName
{
#ifdef MACOSX
  self = [super initWithWindowNibName: theNibName];
#else
  PreferencesPanel *thePanel;
  
  thePanel = [[PreferencesPanel alloc] initWithContentRect:NSMakeRect(100,100,355,270)
				       styleMask: (NSClosableWindowMask)
				       backing: NSBackingStoreBuffered
				       defer: NO];

  self = [super initWithWindow: thePanel];
  
  [thePanel layoutPanel];
  [thePanel setDelegate: self];

  // We link our outlets
  fontField = [thePanel fontField];

  colorPopUp = [thePanel colorPopUp];
  titleBarColorBox = [thePanel titleBarColorBox];
  noteContentColorBox = [thePanel noteContentColorBox];

  topLeft = [thePanel topLeft];
  topRight = [thePanel topRight];
  bottomLeft = [thePanel bottomLeft];
  bottomRight = [thePanel bottomRight];
  center = [thePanel center];

  titlePopUp = [thePanel titlePopUp];
  titleField = [thePanel titleField];

  RELEASE(thePanel);
#endif

  // We set our title
  [[self window] setTitle: _(@"Preferences...")];
  
#ifdef MACOSX
  [titleBarColorBox setContentView: [ColorView colorView]];
  [noteContentColorBox setContentView: [ColorView colorView]];
#endif
  
  // We get our defaults for this panel
  [self initializeFromDefaults];

  return self;
}

- (void) dealloc
{
  [super dealloc];
}


//
//
//
- (void) initializeFromDefaults
{
  if ( [[NSUserDefaults standardUserDefaults] stringForKey: @"FONT_NAME"] )
    {
      [fontField setFont: [NSFont fontWithName: [[NSUserDefaults standardUserDefaults] stringForKey: @"FONT_NAME"]
				  size: [[NSUserDefaults standardUserDefaults] floatForKey: @"FONT_SIZE"]]];
    }

  // We set the value of our textfield
  [fontField setStringValue: [NSString stringWithFormat: @"%@ - %.1f PT",
				       [[fontField font] fontName],
				       [[fontField font] pointSize]] ];
  
  // We select and update our selected color
  if ( [[NSUserDefaults standardUserDefaults] objectForKey: @"COLOR"] )
    {
      [colorPopUp selectItemAtIndex: [[NSUserDefaults standardUserDefaults] integerForKey: @"COLOR"] ];
    }
  else
    {
      [colorPopUp selectItemAtIndex: (YELLOW - 1)];
    }
  
  [self selectionOfColorHasChanged: nil];


  // We select our position
  if ( [[NSUserDefaults standardUserDefaults] objectForKey: @"POSITION"] )
    {
      position = [[NSUserDefaults standardUserDefaults] integerForKey: @"POSITION"];
    }
  else
    {
      position = CENTER;
    }
  [self _updatePositionSelection];


  // We select our title 
  [titlePopUp selectItemAtIndex: [[NSUserDefaults standardUserDefaults] integerForKey: @"TITLE"]];
  
  if ( [titlePopUp indexOfSelectedItem] == (CUSTOM - 1) )
    {
      [titleField setEditable: YES];
    }
  else
    {
      [titleField setEditable: NO];
    }

  if ( [[NSUserDefaults standardUserDefaults] objectForKey: @"TITLE_VALUE"] )
    {
      [titleField setStringValue: [[NSUserDefaults standardUserDefaults] objectForKey: @"TITLE_VALUE"]];
    }
  else
    {
      [titleField setStringValue: @""];
    }
}


//
// delegate methods
// 

- (void) changeFont: (id) sender
{
  NSFontManager *aFontManager;
  NSFont *aFont;
  
  //NSLog(@"font changed!");

  aFontManager = sender;
  
  aFont = [aFontManager convertFont: [fontField font]];
  [fontField setFont: aFont];

  // We set the value of our textfield
  [fontField setStringValue: [NSString stringWithFormat: @"%@ - %.1f PT",
				       [[fontField font] fontName],
				       [[fontField font] pointSize]] ];
}


- (void) windowWillClose: (id) sender
{
  NSLog(@"Closing the panel... - we save the preferences.");
  
  [[NSUserDefaults standardUserDefaults] setObject: [[fontField font] fontName]
					 forKey: @"FONT_NAME"];
  [[NSUserDefaults standardUserDefaults] setFloat: [[fontField font] pointSize]
					 forKey: @"FONT_SIZE"];
  
  [[NSUserDefaults standardUserDefaults] setInteger: [colorPopUp indexOfSelectedItem]
					 forKey: @"COLOR"];

  [[NSUserDefaults standardUserDefaults] setInteger: position
					 forKey: @"POSITION"];

  [[NSUserDefaults standardUserDefaults] setInteger: [titlePopUp indexOfSelectedItem]
					 forKey: @"TITLE"];

  [[NSUserDefaults standardUserDefaults] setObject: [titleField stringValue]
					 forKey: @"TITLE_VALUE"];
  
  [[NSUserDefaults standardUserDefaults] synchronize];
}

//
// action methods
//

- (IBAction) chooseFont: (id) sender
{
  NSFontPanel *aFontPanel;
  
  //NSLog(@"Choosing font!");

  aFontPanel = [NSFontPanel sharedFontPanel];
  [[NSFontManager sharedFontManager] setSelectedFont: [fontField font]
				     isMultiple: NO];
  
  [aFontPanel orderFront: nil];
}


- (IBAction) selectionOfColorHasChanged: (id) sender
{
  ColorView *titleBarColorView, *noteContentColorView;

  titleBarColorView = (ColorView *)[titleBarColorBox contentView];
  noteContentColorView = (ColorView *)[noteContentColorBox contentView];
  
  [colorPopUp synchronizeTitleAndSelectedItem];

  switch ( [colorPopUp indexOfSelectedItem] )
    {
    case 0:
      [titleBarColorView setColor: [NSColor colorWithDeviceRed: 0.24
					    green: 0.9
					    blue: 1.0
					    alpha: 1.0]];
      [noteContentColorView setColor: [NSColor colorWithDeviceRed: 0.44
					       green: 1.0
					       blue: 1.0
					       alpha: 1.0]];
      break;

    case 1:
      [titleBarColorView setColor: [NSColor colorWithDeviceRed: 0.83
					    green: 0.83
					    blue: 0.83
					    alpha: 1.0]];
      [noteContentColorView setColor: [NSColor colorWithDeviceRed: 0.93
					       green: 0.93
					       blue: 0.93
					       alpha: 1.0]];
      break;
    
    case 2:
      [titleBarColorView setColor: [NSColor colorWithDeviceRed: 0.58
					    green: 1.0
					    blue: 0.58
					    alpha: 1.0]];
      [noteContentColorView setColor: [NSColor colorWithDeviceRed: 0.70
					       green: 1.0
					       blue: 0.63
					       alpha: 1.0]];
      break;
      
    case 3:
      [titleBarColorView setColor: [NSColor colorWithDeviceRed: 0.57
					    green: 0.72
					    blue: 1.0
					    alpha: 1.0]];
      [noteContentColorView setColor: [NSColor colorWithDeviceRed: 0.70
					       green: 0.78
					       blue: 1.0
					       alpha: 1.0]];
      break;

    case 4:
    default:
      [titleBarColorView setColor: [NSColor colorWithDeviceRed: 1.0
					    green: 0.90
					    blue: 0.24
					    alpha: 1.0]];
      [noteContentColorView setColor: [NSColor colorWithDeviceRed: 1.0
					       green: 1.0
					       blue: 0.63
					       alpha: 1.0]];
    }

  [titleBarColorView setNeedsDisplay: YES];
  [noteContentColorView setNeedsDisplay: YES];
}


//
//
//
- (IBAction) selectionOfPositionHasChanged: (id) sender
{
  if ( sender == topLeft )
    {
      position = TOP_LEFT;
    }
  else if ( sender == bottomLeft )
    {
      position = BOTTOM_LEFT;
    }
  else if ( sender == topRight )
    {
      position = TOP_RIGHT;
    }
  else if ( sender == bottomRight )
    {
      position = BOTTOM_RIGHT;
    }
  // Center
  else
    {
      position = CENTER;
    }

  [self _updatePositionSelection];
}


//
//
//
- (IBAction) selectionOfTitleHasChanged: (id) sender
{
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
}

@end

@implementation PreferencesPanelController (Private)

- (void) _updatePositionSelection
{
  switch ( position )
    {
    case TOP_LEFT:
      [topLeft setState: NSOnState];
      [bottomLeft setState: NSOffState];
      [topRight setState: NSOffState];
      [bottomRight setState: NSOffState];
      [center setState: NSOffState];
      break;
      
    case BOTTOM_LEFT:
      [topLeft setState: NSOffState];
      [bottomLeft setState: NSOnState];
      [topRight setState: NSOffState];
      [bottomRight setState: NSOffState];
      [center setState: NSOffState];
      break;
      
    case TOP_RIGHT:
      [topLeft setState: NSOffState];
      [bottomLeft setState: NSOffState];
      [topRight setState: NSOnState];
      [bottomRight setState: NSOffState];
      [center setState: NSOffState];
      break;
      
    case BOTTOM_RIGHT:
      [topLeft setState: NSOffState];
      [bottomLeft setState: NSOffState];
      [topRight setState: NSOffState];
      [bottomRight setState: NSOnState];
      [center setState: NSOffState];
      break;
      
    case CENTER:
    default:
      [topLeft setState: NSOffState];
      [bottomLeft setState: NSOffState];
      [topRight setState: NSOffState];
      [bottomRight setState: NSOffState];
      [center setState: NSOnState];
    }
}

@end
