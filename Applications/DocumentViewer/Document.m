/*
   Project: WebBrowser

   Copyright (C) 2020 Free Software Foundation

   Author: onflapp

   Created: 2020-07-22 12:41:08 +0300 by root

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "Document.h"

@implementation Document

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Document" owner:self];
  [window setFrameAutosaveName:@"document_window"];
  [window makeKeyAndOrderFront:self];
  
  [navScroll setBorderType:NSBezelBorder];
  [navScroll setHasHorizontalScroller:YES];
  [navScroll setHasVerticalScroller:NO];
    
  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (void) displayFile:(NSString*) path {
  [statusField setStringValue:@"loading pdf"];
  [pdfView loadFile:path];
  
  [self displayNavigation];
  [self displayPage:1];
}

- (void) displayPage:(NSInteger) page {
  if (isWorking) return;

  isWorking = YES;
  NSMatrix* matrix = [navScroll documentView];
  [matrix selectCellAtRow:0 column:page-1];
  currentPage = page;

  [self performSelector:@selector(refreshCurrentPage) withObject:nil afterDelay:0.1];
}

- (void) refreshCurrentPage {
  [pdfView displayPage:currentPage];
  isWorking = NO;
}

- (void) displayNavigation {
  NSButtonCell* cell = AUTORELEASE([NSButtonCell new]);
  [cell setButtonType:NSPushOnPushOffButton];
  [cell setImagePosition:NSImageOverlaps];
  NSMatrix* matrix = [[NSMatrix alloc] initWithFrame:NSZeroRect mode:NSRadioModeMatrix
                                           prototype:cell numberOfRows: 0 numberOfColumns: 0];

  [matrix setIntercellSpacing:NSZeroSize];
  [matrix setCellSize:NSMakeSize(26,[[navScroll contentView] bounds].size.height)];
  [matrix setAllowsEmptySelection:YES];
  [matrix setTarget:self];
  [matrix setAction: @selector(goToPage:)];
  [navScroll setDocumentView:matrix];
  
  NSString* imagePath = [[NSBundle mainBundle] pathForResource: @"page" ofType: @"tiff" inDirectory: nil];
  NSImage* miniPage = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];

  NSInteger npages = [pdfView countPages];
  for (NSInteger i = 0; i < npages; i++) {
    [matrix addColumn];
    cell = [matrix cellAtRow:0 column:i];
    if (i < 100) {
      [cell setFont: [NSFont systemFontOfSize: 10]];
    } 
    else {
      [cell setFont: [NSFont systemFontOfSize: 8]];
    }
    [cell setImage:miniPage];
    [cell setTitle:[NSString stringWithFormat: @"%i", i+1]];
  }
  [matrix sizeToCells];
}

- (IBAction) goToPage:(id) sender {
  NSInteger p = [sender selectedColumn] + 1;
  [self displayPage:p];
}

- (IBAction) nextPage:(id) sender {
  NSUInteger p = [pdfView displayedPage] + 1;
  if (p > [pdfView countPages]) p = [pdfView countPages];

  [self displayPage:p];
}

- (IBAction) previousPage:(id) sender {
  NSUInteger p = [pdfView displayedPage] - 1;
  if (p < 1) p = 1;
  
  [self displayPage:p];
}

@end
