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

#import "Note.h"

#import "Affiche.h"
#import "Constants.h"

static int currentVersion = 3;

@implementation Note

- (id) init
{
  self = [super init];
  
  [Note setVersion: currentVersion];
  
  [self setValue: nil];
  [self setBackgroundColor: [Affiche colorForCode: YELLOW]];
  [self setColorCode: YELLOW];
  [self setFrame: NSMakeRect(10,10,DEFAULT_NOTE_WIDTH,DEFAULT_NOTE_HEIGHT)];
  [self setCreationDate: nil];
  [self setModificationDate: nil];
  [self setTitle: NO_TITLE];
  [self setTitleValue: nil];

  return self;
}

- (id) initWithAttributedString: (NSAttributedString *) theAttributedString
                backgroundColor: (NSColor *) theColor	
{
  self = [self init];
  
  [self setValue: theAttributedString];
  [self setBackgroundColor: theColor];
  
  return self;
}

- (void) dealloc
{
  NSLog(@"Note: -dealloc");
  
  RELEASE(value);
  RELEASE(backgroundColor);
  RELEASE(titleValue);

  [super dealloc];
}

//
// coding protocol
//
- (void) encodeWithCoder: (NSCoder *) theCoder
{
  [Note setVersion: currentVersion];
  
  //NSLog(@"Encoding = |%@| color code = %d", [[self value] string], [self colorCode]);
  [theCoder encodeObject: [self value]];
  [theCoder encodeObject: [self backgroundColor]];
  [theCoder encodeObject: [NSNumber numberWithInt: [self colorCode]] ];
  
  // We encode our frame
  [theCoder encodeObject: [NSNumber numberWithFloat: frame.origin.x] ];
  [theCoder encodeObject: [NSNumber numberWithFloat: frame.origin.y] ];
  [theCoder encodeObject: [NSNumber numberWithFloat: frame.size.width] ];
  [theCoder encodeObject: [NSNumber numberWithFloat: frame.size.height] ];

  [theCoder encodeObject: [self creationDate]];
  [theCoder encodeObject: [self modificationDate]];

  [theCoder encodeObject: [NSNumber numberWithInt: [self title]] ];
  [theCoder encodeObject: [self titleValue]];
}

- (id) initWithCoder: (NSCoder *) theCoder
{
  int version;
  
  version = [theCoder versionForClassName: NSStringFromClass([self class])];;

  self = [self init];

  //NSLog(@"Version = %d", version);

  // Version 0 - Corresponds to Affiche v0.1.0
  if ( version == 0 )
    {
      NSAttributedString *anAttributedString;

      anAttributedString = [[NSAttributedString alloc] initWithString: [theCoder decodeObject]];
      [self setValue: anAttributedString];
      RELEASE(anAttributedString);

      // We discard our color (we keep the defaults used in -init)
      [theCoder decodeObject];
      
      // We decode our frame
      frame.origin.x = [[theCoder decodeObject] floatValue];
      frame.origin.y = [[theCoder decodeObject] floatValue];
      frame.size.width = [[theCoder decodeObject] floatValue];
      frame.size.height = [[theCoder decodeObject] floatValue];
      
      [self setCreationDate: [theCoder decodeObject]];
      [self setModificationDate: [theCoder decodeObject]];
    }
  // Version 1 - Corresponds to Affiche v0.2.0 and v0.3.0
  else if ( version == 1 )
    {
      [self setValue: [theCoder decodeObject]];
      
      // We discard our color (we keep the defaults used in -init)
      [theCoder decodeObject];
      
      // We decode our frame
      frame.origin.x = [[theCoder decodeObject] floatValue];
      frame.origin.y = [[theCoder decodeObject] floatValue];
      frame.size.width = [[theCoder decodeObject] floatValue];
      frame.size.height = [[theCoder decodeObject] floatValue];
      
      [self setCreationDate: [theCoder decodeObject]];
      [self setModificationDate: [theCoder decodeObject]];
    }
  // Version 2 - Corresponds to Affiche v0.4.0
  else if ( version == 2 )
    {
      [self setValue: [theCoder decodeObject]];
      
      [self setBackgroundColor: [theCoder decodeObject]];
      [self setColorCode: [[theCoder decodeObject] intValue]];
      
      // We decode our frame
      frame.origin.x = [[theCoder decodeObject] floatValue];
      frame.origin.y = [[theCoder decodeObject] floatValue];
      frame.size.width = [[theCoder decodeObject] floatValue];
      frame.size.height = [[theCoder decodeObject] floatValue];
      
      [self setCreationDate: [theCoder decodeObject]];
      [self setModificationDate: [theCoder decodeObject]];
    }
  // Version 3 - Corresponds to Affiche v0.5.0
  else
    {
      [self setValue: [theCoder decodeObject]];
      
      [self setBackgroundColor: [theCoder decodeObject]];
      [self setColorCode: [[theCoder decodeObject] intValue]];
      
      // We decode our frame
      frame.origin.x = [[theCoder decodeObject] floatValue];
      frame.origin.y = [[theCoder decodeObject] floatValue];
      frame.size.width = [[theCoder decodeObject] floatValue];
      frame.size.height = [[theCoder decodeObject] floatValue];
      
      [self setCreationDate: [theCoder decodeObject]];
      [self setModificationDate: [theCoder decodeObject]];

      [self setTitle: [[theCoder decodeObject] intValue]];
      [self setTitleValue: [theCoder decodeObject]];
    }
  
  return self;
}

//
// access / mutation methods
//
- (NSAttributedString *) value
{
  return value;
}

- (void) setValue: (NSAttributedString *) theValue
{
  if ( theValue )
    {
      RETAIN(theValue);
      RELEASE(value);
      value = theValue;
  
      //NSLog(@"value set to string = |%@|", [[self value] string]);
    }
  else
    {
      value = [[NSAttributedString alloc] initWithString: @""];
    }
}

- (NSColor *) backgroundColor
{
  return backgroundColor;
}

- (void) setBackgroundColor: (NSColor *) theColor
{
  if ( theColor) 
    {
      RETAIN(theColor);
      RELEASE(backgroundColor);
      backgroundColor = theColor;
    }
  else
    {
      RELEASE(backgroundColor);
      backgroundColor = [NSColor whiteColor];
      RETAIN(backgroundColor);
    }
}

- (int) colorCode
{
  return colorCode;
}

- (void) setColorCode: (int) theColorCode
{
  colorCode = theColorCode;
}

- (NSRect) frame
{
  return frame;
}

- (void) setFrame: (NSRect) theFrame
{
  //NSLog(@"Setting frame to: (%f,%f) (%f,%f)", theFrame.origin.x, theFrame.origin.y, 
  //theFrame.size.width, theFrame.size.height);
  frame = theFrame;
}

- (NSDate *) creationDate
{
  return creationDate;
}

- (void) setCreationDate: (NSDate *) theDate
{
  if ( theDate )
    {
      RETAIN(theDate);
      RELEASE(creationDate);
      creationDate = theDate;
    }
  else
    {
      RELEASE(creationDate);
      creationDate = [NSDate date];
      RETAIN(creationDate);
    }
}

- (NSDate *) modificationDate
{
  return modificationDate;
}

- (void) setModificationDate: (NSDate *) theDate
{
  if ( theDate )
    {
      RETAIN(theDate);
      RELEASE(modificationDate);
      modificationDate = theDate;
    }
  else
    {
      RELEASE(modificationDate);
      modificationDate = [NSDate date];
      RETAIN(modificationDate);
    }
}


- (int) title
{
  return title;
}

- (void) setTitle: (int) theTitle
{
  title = theTitle;
}

- (NSString *) titleValue
{
  return titleValue;
}

- (void) setTitleValue: (NSString *) theTitleValue
{
  if ( theTitleValue )
    {
      RETAIN(theTitleValue);
      RELEASE(titleValue);
      titleValue = theTitleValue;
    }
  else
    {
      RELEASE(titleValue);
      titleValue = nil;
    }
}


//
// class methods
//
+ (Note *) note
{
  return AUTORELEASE([[Note alloc] init]);                                     
}

@end
