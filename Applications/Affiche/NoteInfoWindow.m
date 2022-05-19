/*
**  NoteInfoWindow.m
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

#import "NoteInfoWindow.h"

#import "Constants.h"
#import "LabelWidget.h"

@implementation NoteInfoWindow

- (void) dealloc
{
  RELEASE(creationDateField);
  RELEASE(modificationDateField);
  
  RELEASE(titlePopUp);
  RELEASE(titleField);

  [super dealloc];
}

- (void) layoutWindow
{
  LabelWidget *creationDateLabel, *modificationDateLabel, *titleLabel;

  creationDateLabel = [LabelWidget labelWidgetWithFrame: NSMakeRect(10,70,110,25)
				   label: _(@"Creation date:")];
  [[self contentView] addSubview: creationDateLabel];
  
  creationDateField = [[NSTextField alloc] initWithFrame: NSMakeRect(120,70,190,25)];
  [creationDateField setEditable: NO];
  [[self contentView] addSubview: creationDateField];
  
  modificationDateLabel = [LabelWidget labelWidgetWithFrame: NSMakeRect(10,40,110,25)
				       label: _(@"Modification date:")];
  [[self contentView] addSubview: modificationDateLabel];
  
  modificationDateField = [[NSTextField alloc] initWithFrame: NSMakeRect(120,40,190,25)];
  [modificationDateField setEditable: NO];
  [[self contentView] addSubview: modificationDateField];

  titleLabel = [LabelWidget labelWidgetWithFrame: NSMakeRect(10,10,50,TextFieldHeight)
			    label: _(@"Title:")];
  [[self contentView] addSubview: titleLabel];
  
  titlePopUp = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(65,10,120,ButtonHeight)];
  [titlePopUp addItemWithTitle: _(@"No title")];
  [titlePopUp addItemWithTitle: _(@"First line of note")];
  [titlePopUp addItemWithTitle: _(@"Custom")];
  [titlePopUp setTarget: [self windowController]];
  [titlePopUp setAction: @selector(selectionOfTitleHasChanged:)];
  [[self contentView] addSubview: titlePopUp];

  titleField = [[NSTextField alloc] initWithFrame: NSMakeRect(190,12,120,TextFieldHeight)];
  [titleField setDelegate: [self windowController]];
  [[self contentView] addSubview: titleField];

}
 

//
// access/mutation methods
//
- (NSTextField *) creationDateField
{
  return creationDateField;
}

- (NSTextField *) modificationDateField
{
  return modificationDateField;
}

- (NSPopUpButton *) titlePopUp
{
  return titlePopUp;
}

- (NSTextField *) titleField
{
  return titleField;
}

@end
