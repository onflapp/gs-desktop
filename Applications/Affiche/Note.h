/*
**  Note.m
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

@interface Note : NSObject
{
  NSAttributedString *value; 
  
  NSDate *creationDate;
  NSDate *modificationDate;
  
  NSColor *backgroundColor;
  int colorCode;
  
  NSRect frame;

  int title;
  NSString *titleValue;
}

- (id) initWithAttributedString: (NSAttributedString *) theAttributedString
                backgroundColor: (NSColor *) theColor;	

- (void) dealloc;

//
// coding protocol
//
- (void) encodeWithCoder: (NSCoder *) theCoder;
- (id) initWithCoder: (NSCoder *) theCoder;

//
// access / mutation methods
//
- (NSAttributedString *) value;
- (void) setValue: (NSAttributedString *) theValue;

- (NSColor *) backgroundColor;
- (void) setBackgroundColor: (NSColor *) theColor;

- (int) colorCode;
- (void) setColorCode: (int) theColorCode;

- (NSRect) frame;
- (void) setFrame: (NSRect) theFrame;

- (NSDate *) creationDate;
- (void) setCreationDate: (NSDate *) theDate;

- (NSDate *) modificationDate;
- (void) setModificationDate: (NSDate *) theDate;

- (int) title;
- (void) setTitle: (int) theTitle;

- (NSString *) titleValue;
- (void) setTitleValue: (NSString *) theTitleValue;

//
// class methods
//
+ (Note *) note;

@end
