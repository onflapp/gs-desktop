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

#import "FigureCell.h"

@implementation FigureCell

- (id) initWithSize: (NSSize) size 
{
  if ((self = [super init]))
    {
      _size = size;
      _image = nil;
      _legends = nil;
      border = 12.0;
      spaceMargin = 20.0;
    }
  return self;    
}

- (void) setLegends: (NSArray*) legends
{
    ASSIGN (_legends, legends);
}

- (void) setImage:  (NSImage*) img
{
    ASSIGN (_image, img);
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
  CGFloat width = 0.0;
  CGFloat minimalHeight;
  CGFloat imageWidth = [_image size].width;
  CGFloat imageHeight = [_image size].height;   

  width = [textView bounds].size.width - -2*spaceMargin - 2*border;
    if (_legends)
    {
	      NSUInteger i;
	      CGFloat margin = (width - imageWidth)/2;

	      NSMutableParagraphStyle* paragraph = [NSMutableParagraphStyle new];
	      [paragraph setAlignment: NSLeftTextAlignment];
	      [paragraph setTailIndent: margin];
	      [paragraph setHeadIndent: 0.0];
	      [paragraph setFirstLineHeadIndent: 0.0];

	      NSDictionary* attributes = [NSDictionary dictionaryWithObject: paragraph 
		    forKey: NSParagraphStyleAttributeName];
	      [paragraph release];

	      NSMutableArray* preLeftLegends = [NSMutableArray array];
	      NSMutableArray* preRightLegends = [NSMutableArray array];
	      
	      for (i=0; i<[_legends count]; i++)
	      {
		  Legend* current = [_legends objectAtIndex: i];
		  [[current legend] addAttributes: attributes 
			range: NSMakeRange (0, [[current legend] length])];
		  NSSize s = [[current legend] size];

		  [current setHeight: s.height];
		  if ([current point].x > (imageWidth/2))
		  {
		    [current setRightPos]; // on range ˆ droite
		    [preRightLegends addObject: current];
		  }
		  else
		  {
		    [preLeftLegends addObject: current];
		  }        
	      }
		    
	      NSArray* leftLegends = [preLeftLegends sortedArrayUsingSelector: @selector (compareWith:)];
	      NSArray* rightLegends = [preRightLegends sortedArrayUsingSelector: @selector (compareWith:)];

	      CGFloat leftLegendsHeight = 0;
	      CGFloat rightLegendsHeight = 0;
	      
	      for (i=0; i < [leftLegends count]; i++)
		{
		  leftLegendsHeight += [[leftLegends objectAtIndex: i] height];
		}

	      for (i=0; i < [rightLegends count]; i++)
		{
		  rightLegendsHeight += [[rightLegends objectAtIndex: i] height];
		}
	      
	      CGFloat minimalInterspace = 8;

	      minimalHeight = leftLegendsHeight+([leftLegends count]+1)*minimalInterspace;

	      if (imageHeight < minimalHeight)
		imageHeight = minimalHeight;
    }

    _size = NSMakeSize (width, imageHeight);
}

- (void) drawLegends: (NSArray*) legends onRight: (BOOL) right 
    withInterspace: (CGFloat) interspace withAttributes: (NSDictionary*) attributes
    withFrame: (NSRect) cellFrame withBorder: (CGFloat) border withMargin: (CGFloat) Margin 
    withSpaceMargin: (CGFloat) spaceMargin withImageWidth: (CGFloat) imageWidth withPosImage: (CGFloat) posImage
{
      CGFloat posY = interspace;
      NSUInteger i;
      for (i=0; i < [legends count]; i++)
      {
	  NSRect r;
          NSPoint t, tp, p;
          Legend* current = [legends objectAtIndex: i];
          [[current legend] addAttributes: attributes 
                range: NSMakeRange (0, [[current legend] length])];
          NSSize s = [[current legend] size];
//	  NSSize s = [[current legend] sizeWithAttributes: attributes];

          if (!right)
          {
            r  = NSMakeRect (cellFrame.origin.x + border + (Margin-s.width) - 2, cellFrame.origin.y + posY - 2, s.width + 4, s.height + 4);
            t  = NSMakePoint (cellFrame.origin.x + border + (Margin-s.width), cellFrame.origin.y + posY);
            tp = NSMakePoint (cellFrame.origin.x + border + Margin + 2, cellFrame.origin.y + posY + s.height/2);
          }
          else
          {
            r  = NSMakeRect (cellFrame.origin.x + border + Margin + (2*spaceMargin) + imageWidth - 2, 
                    cellFrame.origin.y + posY - 2, s.width + 4, s.height + 4);
            t  = NSMakePoint (cellFrame.origin.x + border + Margin + (2*spaceMargin) + imageWidth,
                    cellFrame.origin.y + posY);
            tp = NSMakePoint (cellFrame.origin.x + border + Margin + (2*spaceMargin) + imageWidth - 2, 
                    cellFrame.origin.y + posY + s.height/2);
          }
          
          p  = NSMakePoint (cellFrame.origin.x + border + Margin + spaceMargin + [current point].x,
		  cellFrame.origin.y + [current point].y + posImage);
          
         // [[NSBezierPath bezierPathWithRect: r] stroke];
	[[NSColor colorWithCalibratedRed: 0.81 green: 0.84 blue: 0.88 alpha:1.0] set];
	NSBezierPath* path = [[NSBezierPath alloc] init];

	CGFloat radius = 8;

	NSPoint p1 = NSMakePoint (r.origin.x, r.origin.y + radius);
	NSPoint p2 = NSMakePoint (r.origin.x, r.origin.y + r.size.height - radius);
	NSPoint p4 = NSMakePoint (r.origin.x + r.size.width - radius, r.origin.y + r.size.height);
	NSPoint p6 = NSMakePoint (r.origin.x + r.size.width, r.origin.y + radius);
	NSPoint p8 = NSMakePoint (r.origin.x + radius, r.origin.y);

	NSPoint pr1 = NSMakePoint (r.origin.x + radius, r.origin.y + r.size.height - radius);
	NSPoint pr2 = NSMakePoint (r.origin.x + r.size.width - radius, r.origin.y + r.size.height - radius);
	NSPoint pr3 = NSMakePoint (r.origin.x + r.size.width - radius, r.origin.y + radius);
	NSPoint pr4 = NSMakePoint (r.origin.x + radius, r.origin.y + radius);

	[path moveToPoint: p1];
	[path lineToPoint: p2];
	[path appendBezierPathWithArcWithCenter: pr1 radius: radius startAngle: 180 endAngle: 90 clockwise: YES];
	[path lineToPoint: p4];
	[path appendBezierPathWithArcWithCenter: pr2 radius: radius startAngle: 90 endAngle: 0 clockwise: YES];
	[path lineToPoint: p6];
	[path appendBezierPathWithArcWithCenter: pr3 radius: radius startAngle: 0 endAngle: 270 clockwise: YES];
	[path lineToPoint: p8];
	//[path appendBezierPathWithArcFromPoint: p8 toPoint: p1 radius: radius];
	[path appendBezierPathWithArcWithCenter: pr4 radius: radius startAngle: 270 endAngle: 180 clockwise: YES];
	[path fill];
	[path release];

//          [[current legend] drawAtPoint: t withAttributes: attributes];            
          [[current legend] drawAtPoint: t];
	  NSBezierPath* path2 = [NSBezierPath bezierPath];
          
          [path2 moveToPoint: tp];                        
	  [path2 lineToPoint: p];
	  [path2 stroke];          
          
          posY += s.height + interspace;          
      }
}


- (void) drawWithFrame: (NSRect) cellFrame
    inView: (NSView*) controlView
{
  if (![controlView window])
    return;

	[[NSColor whiteColor] set];
	NSRectFill (cellFrame);

      //NSLog (@"drawInteriorWithFrame de FigureCell ... ");
      //NSLog (@"image : %@", _image);
      //NSLog (@"cellframe origin x : %.2f origin y : %.2f", cellFrame.origin.x, cellFrame.origin.y);
      NSLog (@"cellFrame height : %.2f", cellFrame.size.height);

	if (_legends)
	{
		  
	      NSUInteger i;
	      CGFloat interspace = 20.0;
	      CGFloat imageWidth = [_image size].width;
	      CGFloat imageHeight = [_image size].height;   
	      CGFloat margin = (cellFrame.size.width - imageWidth - 2*spaceMargin - 2*border)/2;

	      CGFloat posImage = 0.0;
	      if (imageHeight < cellFrame.size.height)
	      {
	      	posImage = (cellFrame.size.height - imageHeight)/2;
	      }
	      NSPoint imageOrigin = NSMakePoint (cellFrame.origin.x + border + margin + spaceMargin,
		      cellFrame.origin.y + imageHeight + posImage);
	      [_image compositeToPoint: imageOrigin operation: NSCompositeSourceAtop];
	      
	      NSMutableParagraphStyle* paragraph = [NSMutableParagraphStyle new];
	      [paragraph setAlignment: NSLeftTextAlignment];
	      [paragraph setTailIndent: margin];
	      [paragraph setHeadIndent: 0.0];
	      [paragraph setFirstLineHeadIndent: 0.0];
	      
	      NSDictionary* attributes = [NSDictionary dictionaryWithObject: paragraph 
		    forKey: NSParagraphStyleAttributeName];
	      [paragraph release];

	      NSMutableArray* preLeftLegends = [NSMutableArray array];
	      NSMutableArray* preRightLegends = [NSMutableArray array];
	      
	      for (i=0; i<[_legends count]; i++)
	      {
		  Legend* current = [_legends objectAtIndex: i];
		  [[current legend] addAttributes: attributes 
			range: NSMakeRange (0, [[current legend] length])];
		  NSSize s = [[current legend] size];

		  [current setHeight: s.height];
		  if ([current point].x > (imageWidth/2))
		  {
		    [current setRightPos]; // on range ˆ droite
		    [preRightLegends addObject: current];
		  }
		  else
		  {
		    [preLeftLegends addObject: current];
		  }        
	      }
		    
	      NSArray* leftLegends = [preLeftLegends sortedArrayUsingSelector: @selector (compareWith:)];
	      NSArray* rightLegends = [preRightLegends sortedArrayUsingSelector: @selector (compareWith:)];

	      CGFloat leftLegendsHeight = 0.0;
	      CGFloat rightLegendsHeight = 0.0;
	      
	      for (i=0; i < [leftLegends count]; i++)
		{
		  leftLegendsHeight += [[leftLegends objectAtIndex: i] height];
		}

	      for (i=0; i < [rightLegends count]; i++)
		{
		  rightLegendsHeight += [[rightLegends objectAtIndex: i] height];
		}
	      
	      interspace = (cellFrame.size.height - leftLegendsHeight)/ ([leftLegends count]+1);      

	      [self drawLegends: leftLegends onRight: NO withInterspace: interspace
		    withAttributes: attributes withFrame: cellFrame withBorder: border
		    withMargin: margin withSpaceMargin: spaceMargin withImageWidth: imageWidth
		    withPosImage: posImage];

	      interspace = (cellFrame.size.height - rightLegendsHeight)/ ([rightLegends count]+1);      
	      [self drawLegends: rightLegends onRight: YES withInterspace: interspace
		    withAttributes: attributes withFrame: cellFrame withBorder: border
		    withMargin: margin withSpaceMargin: spaceMargin withImageWidth: imageWidth
		    withPosImage: posImage];

	}
}

@end
