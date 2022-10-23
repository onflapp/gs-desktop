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
#import "Inspector.h"

@implementation Document

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Document" owner:self];
  [window setFrameAutosaveName:@"document_window"];
  
  [window makeKeyAndOrderFront:self];

  books = [[Books alloc] init];

  [resultsView setHeaderView:nil];
  [resultsView setDelegate:self];
  [resultsView setDataSource:self];

  return self;
}

- (void) dealloc {
  RELEASE(filePath);
  RELEASE(books);

  [self release];
  [super dealloc];
}

- (void) openFile:(NSString*) file {
  [books openFile: file];
  ASSIGN(filePath, file);
}

- (void) inspect:(id) sender {
  [[[Inspector sharedInstance] window] orderFront:sender];
}

- (void) search:(id) sender {
}

- (void) saveDocument:(id) sender {
  if (filePath) {
    [books saveFile:filePath];
  }
  else {
    [self saveDocumentAs: sender];
  }
}

- (void) saveDocumentAs:(id) sender {
  NSSavePanel* panel = [NSSavePanel savePanel];
  [panel setAllowedFileTypes:[NSArray arrayWithObject:@"books"]];

  if ([panel runModal] == NSOKButton) {
    NSString* fileName = [panel filename];
    [books saveFile:fileName];
    [books openFile:fileName];
    ASSIGN(filePath, fileName);
  }
}

- (void) windowDidBecomeKey:(NSWindow*) win {
  [[Inspector sharedInstance] inspectBooks:books];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView*) table {
  return 2;
}

- (id) tableView:(NSTableView*) table objectValueForTableColumn:(NSTableColumn*) col row:(NSInteger) row {
  return @"hello";
}

@end
