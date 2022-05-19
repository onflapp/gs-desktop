/*
**  PreferencesPanel.m
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

#import "PreferencesPanel.h"

#import "ColorView.h"
#import "Constants.h"
#import "LabelWidget.h"

@implementation PreferencesPanel

- (void) dealloc
{
  NSLog(@"PreferencesPanel: -dealloc");

  RELEASE(fontField);
  
  RELEASE(colorPopUp);
  RELEASE(titleBarColorBox);
  RELEASE(noteContentColorBox);

  RELEASE(topLeft);
  RELEASE(topRight);
  RELEASE(bottomLeft);
  RELEASE(bottomRight);
  RELEASE(center);
  
  [super dealloc];
}

- (void) layoutPanel
{
  LabelWidget *label, *colorLabel, *positionLabel, *fontLabel, *titleLabel;  
  NSButton *chooseFont;

  // Default Font
  fontLabel = [LabelWidget labelWidgetWithFrame: NSMakeRect(10,193,50,TextFieldHeight)
			     label: _(@"Font:")];
  [[self contentView] addSubview: fontLabel];

  fontField = [[NSTextField alloc] initWithFrame: NSMakeRect(65,185,240,40)];
  [fontField setEditable: NO];
  [fontField setSelectable: NO];
  [fontField setStringValue: @""];
  [fontField setBezeled: NO];
  [fontField setBordered: YES];
  [[self contentView] addSubview: fontField];

  chooseFont = [[NSButton alloc] initWithFrame: NSMakeRect(310,185,35,22)];
  [chooseFont setTitle: _(@"Set...")];
  [chooseFont setTarget: [self windowController]];
  [chooseFont setAction: @selector(chooseFont:)];
  [[self contentView] addSubview: chooseFont];


  // Default color
  colorLabel = [LabelWidget labelWidgetWithFrame: NSMakeRect(10,129,50,TextFieldHeight)
			    label: _(@"Color:")];
  [[self contentView] addSubview: colorLabel];
  
  colorPopUp = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(65,127,110,ButtonHeight)];
  [colorPopUp addItemWithTitle: _(@"Blue")];
  [colorPopUp addItemWithTitle: _(@"Gray")];
  [colorPopUp addItemWithTitle: _(@"Green")];
  [colorPopUp addItemWithTitle: _(@"Purple")];
  [colorPopUp addItemWithTitle: _(@"Yellow")];
  [colorPopUp setTarget: [self windowController]];
  [colorPopUp setAction: @selector(selectionOfColorHasChanged:)];
  [[self contentView] addSubview: colorPopUp];

  titleBarColorBox = [[NSBox alloc] initWithFrame: NSMakeRect(180,125,80,50)];
  [titleBarColorBox setTitlePosition: NSAboveTop];
  [titleBarColorBox setTitle: _(@"Title bar")];
  [titleBarColorBox setContentViewMargins: NSMakeSize(1,1)];
  [titleBarColorBox setContentView: [ColorView colorView]];
  [[self contentView] addSubview: titleBarColorBox];

  noteContentColorBox = [[NSBox alloc] initWithFrame: NSMakeRect(265,125,80,50)];
  [noteContentColorBox setTitlePosition: NSAboveTop];
  [noteContentColorBox setTitle: _(@"Note content")];
  [noteContentColorBox setContentViewMargins: NSMakeSize(1,1)];
  [noteContentColorBox setContentView: [ColorView colorView]];
  [[self contentView] addSubview: noteContentColorBox];


  // Default position
  positionLabel = [LabelWidget labelWidgetWithFrame: NSMakeRect(10,72,100,TextFieldHeight)
			       label: _(@"Position:")];
  [[self contentView] addSubview: positionLabel];

  topLeft = [[NSButton alloc] initWithFrame: NSMakeRect(65,90,20,20)];
  [topLeft setTitle: @""];
  [topLeft setButtonType: NSPushOnPushOffButton];
  [topLeft setTarget: [self windowController]];
  [topLeft setAction: @selector(selectionOfPositionHasChanged:)];
  [[self contentView] addSubview: topLeft];
  
  center = [[NSButton alloc] initWithFrame: NSMakeRect(85,70,20,20)];
  [center setTitle: @""];
  [center setButtonType: NSPushOnPushOffButton];
  [center setTarget: [self windowController]];
  [center setAction: @selector(selectionOfPositionHasChanged:)];
  [[self contentView] addSubview: center];

  topRight = [[NSButton alloc] initWithFrame: NSMakeRect(105,90,20,20)];
  [topRight setTitle: @""];
  [topRight setButtonType: NSPushOnPushOffButton];
  [topRight setTarget: [self windowController]];
  [topRight setAction: @selector(selectionOfPositionHasChanged:)];
  [[self contentView] addSubview: topRight];
  
  bottomLeft = [[NSButton alloc] initWithFrame: NSMakeRect(65,50,20,20)];
  [bottomLeft setTitle: @""];
  [bottomLeft setButtonType: NSPushOnPushOffButton];
  [bottomLeft setTarget: [self windowController]];
  [bottomLeft setAction: @selector(selectionOfPositionHasChanged:)];
  [[self contentView] addSubview: bottomLeft];
  
  bottomRight = [[NSButton alloc] initWithFrame: NSMakeRect(105,50,20,20)];
  [bottomRight setTitle: @""];
  [bottomRight setButtonType: NSPushOnPushOffButton];
  [bottomRight setTarget: [self windowController]];
  [bottomRight setAction: @selector(selectionOfPositionHasChanged:)];
  [[self contentView] addSubview: bottomRight];


  // Default title
  titleLabel = [LabelWidget labelWidgetWithFrame: NSMakeRect(10,12,50,TextFieldHeight)
			    label: _(@"Title:")];
  [[self contentView] addSubview: titleLabel];
  
  titlePopUp = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(65,10,120,ButtonHeight)];
  [titlePopUp addItemWithTitle: _(@"No title")];
  [titlePopUp addItemWithTitle: _(@"First line of note")];
  [titlePopUp addItemWithTitle: _(@"Custom")];
  [titlePopUp setTarget: [self windowController]];
  [titlePopUp setAction: @selector(selectionOfTitleHasChanged:)];
  [[self contentView] addSubview: titlePopUp];

  titleField = [[NSTextField alloc] initWithFrame: NSMakeRect(190,12,155,TextFieldHeight)];
  [[self contentView] addSubview: titleField];

  label = [LabelWidget labelWidgetWithFrame: NSMakeRect(10,235,250,TextFieldHeight)
		       label: _(@"Defaults used when creating a new note:")];
  [[self contentView] addSubview: label];
}
 

//
// access/mutation methods
//

- (NSTextField *) fontField
{
  return fontField;
}

- (NSPopUpButton *) colorPopUp
{
  return colorPopUp;
}

- (NSBox *) titleBarColorBox
{
  return titleBarColorBox;
}

- (NSBox *) noteContentColorBox
{
  return noteContentColorBox;
}

- (NSButton *) topLeft
{
  return topLeft;
}

- (NSButton *) topRight
{
  return topRight;
}

- (NSButton *) bottomLeft
{
  return bottomLeft;
}

- (NSButton *) bottomRight
{
  return bottomRight;
}

- (NSButton *) center
{
  return center;
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
