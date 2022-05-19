/*
**  NoteView.m
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

#import "NoteView.h"

#import "Constants.h"

@implementation NoteView

- (id) init
{
  self = [super init];
  
  buttons = nil;
  resize = nil;
  titleBarColor = nil;
  noteColor = nil;
  
  [self setColorCode: YELLOW];
  
  return self;
}

- (void) dealloc
{
  RELEASE(buttons);
  RELEASE(resize);
  RELEASE(titleBarColor);
  RELEASE(noteColor);

  [super dealloc];
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (BOOL) acceptsFirstMouse: (NSEvent *) theEvent
{
  return YES;
}


- (void) drawRect: (NSRect) theRect
{
  NSMutableAttributedString *title;
  NSFont *aFont;

  // We fill our rect with the color of our title bar's image for the buttons
  [titleBarColor set];
  NSRectFill(theRect);
  
  // Our top image is 36x11
  [buttons compositeToPoint: NSMakePoint(theRect.size.width - 36, theRect.size.height - 11)
  	   operation: NSCompositeSourceAtop];
  
  
  // We now fill it with the color of the content of the note
  [noteColor set];
  NSRectFill( NSMakeRect(0,0,theRect.size.width, theRect.size.height - 11) );

  // Our bottom image is 8x8
  [resize compositeToPoint: NSMakePoint(theRect.size.width - 8, 0)
	  operation: NSCompositeSourceAtop];

  // We draw the title
  aFont = [NSFont boldSystemFontOfSize: 8];
  title = [[NSMutableAttributedString alloc]
	    initWithString: [window title]];
  
  [title addAttribute: NSFontAttributeName
	 value: aFont
	 range: NSMakeRange(0, [[title string] length])];

  // FIXME - more intelligent replace
  if ( [title size].width > (theRect.size.width - 50) )
    {
      [title replaceCharactersInRange: NSMakeRange(10, [[title string] length] - 10)
	     withString: @"..."];
    }

#ifdef MACOSX
  [title drawAtPoint: NSMakePoint(10, theRect.size.height - 10)];
#else
  [title drawAtPoint: NSMakePoint(10, theRect.size.height)];
#endif
}


- (void) mouseDown: (NSEvent *) theEvent
{
  NSRect windowRect, resizeRect;
  NSPoint bottomRightOrigin;
  
  NSEvent *nextEvent;
  BOOL resizing;

  lastLocationOfWindow = [theEvent locationInWindow];

  windowRect = [window frame];

  // We get the point corresponding to the origin of our bottom right corner
  bottomRightOrigin = [window convertBaseToScreen: lastLocationOfWindow];

  //NSLog(@"%@", NSStringFromRect(windowRect));

  resizeRect = NSMakeRect(windowRect.size.width - 8, 0, 8, 8);
  resizing = NSMouseInRect(lastLocationOfWindow, resizeRect, NO);

  //NSLog(@"Resizing = %d", resizing);

  while (YES) 
    {
      nextEvent = [window nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
     
      if ( [nextEvent type] == NSLeftMouseUp )
	{
	  [self mouseUp: theEvent];
	  break;
	}
      else if ( [nextEvent type] == NSLeftMouseDragged )
	{
	  NSPoint aPoint;
	  
	  aPoint = [window mouseLocationOutsideOfEventStream];

	  if (! resizing )
	    {
	      NSPoint origin;
	      
	      
	      origin = [window frame].origin;
	      origin.x += (aPoint.x - lastLocationOfWindow.x);
	      origin.y += (aPoint.y - lastLocationOfWindow.y);
	      
	      [window setFrameOrigin: origin];
	    }
	  else
	    {
	      NSRect aRect;
	      float dx, dy;

	      aPoint = [window convertBaseToScreen: aPoint];
	  
	      dx = (aPoint.x - bottomRightOrigin.x);
	      dy = (aPoint.y - bottomRightOrigin.y);
		
	      aRect = NSMakeRect(windowRect.origin.x,
				 windowRect.origin.y + dy,
				 windowRect.size.width + dx,
				 windowRect.size.height - dy);
	      
	      // We don't resize if we reached our minimum size...
	      if (aRect.size.width < [window minSize].width)
		{
		  aRect.size.width = [window minSize].width;
		}

	      if (aRect.size.height < [window minSize].height)
		{
		  aRect.origin.y -= [window minSize].height - aRect.size.height;
		  aRect.size.height = [window minSize].height;
		}

	      if ( aRect.size.width >= [window minSize].width &&
		   aRect.size.height >= [window minSize].height )
		{
		  [window setFrame: aRect
			  display: YES];
		}
	    }
	}
    }
}


//
// Method used to detect when the user release the left mouse button 
// in order to know if we must minimize, maximize or close the window.
//
- (void) mouseUp: (NSEvent *) theEvent
{
  NSRect minimizeRect, maximizeRect, closeRect, windowRect;
  NSPoint aPoint;

  aPoint = [theEvent locationInWindow];
  windowRect = [window frame];
 
  minimizeRect = NSMakeRect(windowRect.size.width - 33, windowRect.size.height - 10, 7, 7);
  maximizeRect = NSMakeRect(windowRect.size.width - 21, windowRect.size.height - 10, 7, 7);
  closeRect = NSMakeRect(windowRect.size.width - 8, windowRect.size.height - 10, 7, 7);
  
  //NSLog(@"Location = %f %f", aPoint.x, aPoint.y);
  
  // We verify if we must minimize, maximize or close the window
  if ( NSMouseInRect(aPoint, minimizeRect, NO) )
    {
      [window setFrame: NSMakeRect([window frame].origin.x,
				   [window frame].origin.y,
				   [window minSize].width,
				   [window minSize].height)
	      display: YES];
    }
  else if (NSMouseInRect(aPoint, maximizeRect, NO) )
    {      
      [window setFrame: NSMakeRect(70,
				   70,
				   [window maxSize].width,
				   [window maxSize].height)
	      display: YES];
    }
  else if (NSMouseInRect(aPoint, closeRect, NO) )
    {
      if ( [[window windowController] windowShouldClose: nil] )
	{
	  [window close];
	}
    }
}

//
// access/mutation methods
//

- (void) setColorCode: (int) theColorCode
{
  TEST_RELEASE(buttons);
  TEST_RELEASE(resize);
  TEST_RELEASE(titleBarColor);
  TEST_RELEASE(noteColor);
  
  //NSLog(@"Setting color code = %d", theColorCode);

  switch (theColorCode)
    {
    case BLUE:
      buttons = [NSImage imageNamed: @"buttons_blue.tiff"];
      resize = [NSImage imageNamed: @"resize_blue.tiff"];
      titleBarColor = [NSColor colorWithDeviceRed: 0.24
			       green: 0.90
			       blue: 1.0
			       alpha: 1.0];
      noteColor = [NSColor colorWithDeviceRed: 0.44
			   green: 1.0
			   blue: 1.0
			   alpha: 1.0];
      break;

    case GRAY:
      buttons = [NSImage imageNamed: @"buttons_gray.tiff"];
      resize = [NSImage imageNamed: @"resize_gray.tiff"];
      titleBarColor = [NSColor colorWithDeviceRed: 0.83
			       green: 0.83
			       blue: 0.83
			       alpha: 1.0];
      noteColor = [NSColor colorWithDeviceRed: 0.93
			   green: 0.93
			   blue: 0.93
			   alpha: 1.0];
      break;

    case GREEN:
      buttons = [NSImage imageNamed: @"buttons_green.tiff"];
      resize = [NSImage imageNamed: @"resize_green.tiff"];
      titleBarColor = [NSColor colorWithDeviceRed: 0.58
			       green: 1.0
			       blue: 0.58
			       alpha: 1.0];
      noteColor = [NSColor colorWithDeviceRed: 0.70
			   green: 1.0
			   blue: 0.63
			   alpha: 1.0];
      break;
      
    case PURPLE:
      buttons = [NSImage imageNamed: @"buttons_purple.tiff"];
      resize = [NSImage imageNamed: @"resize_purple.tiff"];
      titleBarColor = [NSColor colorWithDeviceRed: 0.57
			       green: 0.72
			       blue: 1.0
			       alpha: 1.0];
      noteColor = [NSColor colorWithDeviceRed: 0.70
			   green: 0.78
			   blue: 1.0
			   alpha: 1.0];
      break;
      
    case YELLOW:
    default:
      buttons = [NSImage imageNamed: @"buttons_yellow.tiff"];
      resize = [NSImage imageNamed: @"resize_yellow.tiff"];
      titleBarColor = [NSColor colorWithDeviceRed: 1.0
			       green: 0.9
			       blue: 0.24
			       alpha: 1.0];
      noteColor = [NSColor colorWithDeviceRed: 1.0
			   green: 1.0
			   blue: 0.63
			   alpha: 1.0];
    }
  
  RETAIN(buttons);
  RETAIN(resize);
  RETAIN(titleBarColor);
  RETAIN(noteColor);
  
  [self setNeedsDisplay: YES];
}

- (void) setWindow: (NSWindow *) theWindow
{
  window = theWindow;
}


@end
