/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003      Nicolas Roard (nicolas@roard.com)
                  2020-2021 Riccardo Mottola <rm@gnu.org>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the
    Free Software Foundation, Inc.  
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
*/

#include "NoteCell.h"

@implementation NoteCell

- (id) initWithTextView: (NSTextView*) textview 
{
  if ((self = [super init]))
    {
      _image = nil;
      _note = nil;
      _color = nil;
      imageBorder = 4.0;
      leadingMargin = 8.0;
      trailingMargin = 4.0;
      [self resizeWithTextView: textview];
    }
  return self;    
}

- (void) setText: (NSMutableAttributedString*) text
{
    ASSIGN (_note, text);

    NSMutableParagraphStyle* paragraph = [NSMutableParagraphStyle new];
    [paragraph setAlignment: NSLeftTextAlignment];
    [paragraph setHeadIndent: leadingMargin];
    [paragraph setFirstLineHeadIndent: leadingMargin];
    [paragraph setTailIndent: -trailingMargin];
      
    NSDictionary* attributes = [NSDictionary dictionaryWithObject: paragraph 
							   forKey: NSParagraphStyleAttributeName];
    [paragraph release];
	  
    [_note addAttributes: attributes range: NSMakeRange (0, [_note length])];
}

- (void) setImage:  (NSImage*) img
{
    ASSIGN (_image, img);
}

- (void) setColor: (NSColor*) color
{
    ASSIGN (_color, color);
}

- (NSSize) cellSize 
{
    return _size;
}

- (void) resize: (id) sender
{
	[self resizeWithTextView: [sender object]];
}

- (void) resizeWithTextView: (NSTextView*) textView
{
    CGFloat height = 0.0;
    CGFloat width = 0.0;
    CGFloat textHeight = 0.0;
    CGFloat imageWidth = 0.0;

    if (_image)
      {
	imageWidth = [_image size].width;
	height = [_image size].height;
	width = imageWidth;
      }
    
    if (_note)
      {
	NSSize size;

	size.width = [textView bounds].size.width - width;
	size.width -= leadingMargin; // Take in account of the text margins inside the view
	size.width -= leadingMargin*2;
	size.height = 9999.0;
	if (size.width <= 0)
	  size.width = [textView bounds].size.width;
        noteSize = [_note boundingRectWithSize:size options:0].size;
	NSLog(@"input %@ output %@", NSStringFromSize(size), NSStringFromSize(noteSize));
	textHeight = noteSize.height;
	if (textHeight > height)
	  height = textHeight;
	width += size.width;
      }
   
    NSLog (@"NoteCell: width : %.2f height : %.2f", width, height);

    _size = NSMakeSize (width, height);
}

- (void) drawWithFrame: (NSRect) cellFrame
    inView: (NSView*) controlView
{
  [super drawWithFrame: cellFrame inView: controlView];
}

- (void) drawInteriorWithFrame: (NSRect) cellFrame
    inView: (NSView*) controlView
{
  if (![controlView window])
    return;
  NSLog(@"draw width: %f", cellFrame.size.width);
  [_color set];

  NSBezierPath* path = [[NSBezierPath alloc] init];

  CGFloat radius = 8;

  NSPoint p1 = NSMakePoint (cellFrame.origin.x, cellFrame.origin.y + radius);
  NSPoint p2 = NSMakePoint (cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height - radius);
  NSPoint p4 = NSMakePoint (cellFrame.origin.x + cellFrame.size.width - radius, cellFrame.origin.y + cellFrame.size.height);
  NSPoint p6 = NSMakePoint (cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + radius);
  NSPoint p8 = NSMakePoint (cellFrame.origin.x + radius, cellFrame.origin.y);

  NSPoint pr1 = NSMakePoint (cellFrame.origin.x + radius, cellFrame.origin.y + cellFrame.size.height - radius);
  NSPoint pr2 = NSMakePoint (cellFrame.origin.x + cellFrame.size.width - radius, cellFrame.origin.y + cellFrame.size.height - radius);
  NSPoint pr3 = NSMakePoint (cellFrame.origin.x + cellFrame.size.width - radius, cellFrame.origin.y + radius);
  NSPoint pr4 = NSMakePoint (cellFrame.origin.x + radius, cellFrame.origin.y + radius);

  [path moveToPoint: p1];
  [path lineToPoint: p2];
  [path appendBezierPathWithArcWithCenter: pr1 radius: radius startAngle: 180 endAngle: 90 clockwise: YES];
  [path lineToPoint: p4];
  [path appendBezierPathWithArcWithCenter: pr2 radius: radius startAngle: 90 endAngle: 0 clockwise: YES];
  [path lineToPoint: p6];
  [path appendBezierPathWithArcWithCenter: pr3 radius: radius startAngle: 0 endAngle: 270 clockwise: YES];
  [path lineToPoint: p8];
  [path appendBezierPathWithArcWithCenter: pr4 radius: radius startAngle: 270 endAngle: 180 clockwise: YES];
  [path fill];
  [path release];

  if (_note)
    {
      CGFloat imageWidth = 0.0;
      CGFloat imageHeight = 0.0;
      NSPoint imageOrigin = NSZeroPoint;
      NSPoint noteOrigin = NSZeroPoint;
      NSRect noteRect;

      if (_image)
	{
	  imageWidth = [_image size].width;
	  imageHeight = [_image size].height;

	  imageOrigin.x = cellFrame.origin.x;
	  imageOrigin.y = cellFrame.origin.y + cellFrame.size.height - (cellFrame.size.height - imageHeight)/2;
	  [_image compositeToPoint: imageOrigin operation: NSCompositeSourceAtop];
	}

      noteOrigin.x = cellFrame.origin.x + imageWidth;
      noteOrigin.y = cellFrame.origin.y + (cellFrame.size.height - noteSize.height)/2;

      noteRect.origin = noteOrigin;
      noteRect.size = noteSize;

      [_note drawInRect: noteRect];
    }
}

@end
