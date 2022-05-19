/*
**  NoteWindow.m
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

#import "NoteWindow.h"

#import "Constants.h"
#import "NoteView.h"

@implementation NoteWindow

- (void) dealloc
{
  //NSLog(@"NoteWindow: -dealloc");
  RELEASE(noteView);

  RELEASE(textView);
  RELEASE(scrollView);
  
  [super dealloc];
}

- (void) layoutWindow
{
  noteView = [[NoteView alloc] init];
  [noteView setFrame: NSMakeRect(0,0,DEFAULT_NOTE_WIDTH,DEFAULT_NOTE_HEIGHT)];
  [noteView setAutoresizingMask: (NSViewWidthSizable|NSViewHeightSizable)];
  [noteView setWindow: self];
  
  scrollView = [[NSScrollView alloc] initWithFrame: NSMakeRect(3,8,DEFAULT_NOTE_WIDTH-6,DEFAULT_NOTE_HEIGHT - 19)];
  
  textView = [[NSTextView alloc] initWithFrame: [[scrollView contentView] frame]];
  //[textView setTextContainerInset: NSMakeSize(5,5)];
  [textView setBackgroundColor: [NSColor whiteColor]];
  [textView setDrawsBackground: YES];
  [textView setRichText: YES];
  [textView setUsesFontPanel: YES];
  [textView setHorizontallyResizable: NO];
  [textView setVerticallyResizable: YES];
  [textView setMinSize: NSMakeSize (0, 0)];
  [textView setMaxSize: NSMakeSize (1E7, 1E7)];
  [textView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
  [[textView textContainer] setContainerSize: NSMakeSize([[scrollView contentView] frame].size.width, 
  							 1E7)];
  [[textView textContainer] setWidthTracksTextView: YES];
  [textView setEditable: YES];
  [textView setDelegate: [self windowController]];

  [scrollView setDocumentView: textView];
  [scrollView setHasHorizontalScroller: NO];
  [scrollView setHasVerticalScroller: NO];
  [scrollView setBorderType: NSNoBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable|NSViewHeightSizable)];
  
  [[self contentView] addSubview: noteView];
  [[self contentView] addSubview: scrollView];
}


- (BOOL) canBecomeKeyWindow
{
  return YES;
}

//
// access/mutation methods
//

- (NSSize) maxSize
{
  NSRect aRect;
  
  aRect = [[NSScreen mainScreen] frame];
  
  return NSMakeSize(aRect.size.width - 140, aRect.size.height - 140);
}

- (NSSize) minSize
{
  return NSMakeSize(100,50);
}

- (NoteView *) noteView
{
  return noteView;
}

- (NSTextView *) textView
{
  return textView;
}

@end
