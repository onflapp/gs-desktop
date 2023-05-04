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
  
  books = [[Books alloc] init];

  [resultsView setHeaderView:nil];
  [resultsView setDelegate:self];
  [resultsView setDataSource:self];
  [resultsView setDoubleAction:@selector(selectFile:)];
  [[resultsView tableColumnWithIdentifier:@"icon"] setEditable:NO];
  [[resultsView tableColumnWithIdentifier:@"title"] setEditable:NO];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
      selector:@selector(searchHasEnded:) 
      name:@"searchHasEnded"
      object:books];

  [nc addObserver:self
      selector:@selector(statusHasChanged:) 
      name:@"statusHasChanged"
      object:books];

  return self;
}

- (void) dealloc {
  RELEASE(filePath);
  RELEASE(books);

  [self release];
  [super dealloc];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) showWindow {
  [window setFrameAutosaveName:@"document_window"];
  [window makeKeyAndOrderFront:self];

  if ([books status] == -1) {
    [statusField setStringValue:@"create new index first"];
  }
}

- (void) searchHasEnded:(NSNotification*) not {
  [resultsView reloadData];
  
  NSInteger c = [[books searchResults] count];
  [statusField setStringValue:[NSString stringWithFormat:@"%ld results found", c]];
}

- (void) statusHasChanged:(NSNotification*) not {
  if ([books status] == 0) {
    [statusField setStringValue:@"ready"];
  }
  else if ([books status] == 1) {
    [statusField setStringValue:@"building index..."];
  }
  else {
    [statusField setStringValue:@"working..."];
  }
}

- (void) openFile:(NSString*) file {
  [books openFile: file];
  ASSIGN(filePath, file);
}

- (void) selectFile:(id) sender {
  ResultItem* item = [[books searchResults] objectAtIndex:[resultsView selectedRow]];
  NSWorkspace* wk = [NSWorkspace sharedWorkspace];

  if ([item type] != 1) {
    NSString* path = [item path];

    if ([path hasPrefix:@"/"]) {
      [wk openFile:path];
    }
    else {
      NSURL* uu = [NSURL URLWithString:path];
      if (uu) {
        [wk openURL:uu];
      }
    }
  }
}

- (void) displayErrorMessage:(NSString*) msg info:(NSString*) info {
  NSAlert* alert = [NSAlert alertWithMessageText:msg
                                  defaultButton:@"OK" 
                                alternateButton:nil 
                                    otherButton:nil 
                      informativeTextWithFormat:info];
  [alert runModal];
}

- (void) inspect:(id) sender {
  Inspector* ip = [Inspector sharedInstance];
  [ip inspectBooks:books];
  [[ip window] orderFront:sender];
}

- (void) search:(id) sender {
  if ([books status] == -1) {
    [self displayErrorMessage:@"Index has not been built yet" 
                         info:@"Use the inspector to configure and build the index"];
    return;
  }
  else if ([books status] > 0) {
    return;
  }

  NSString* txt = [queryField stringValue];
  NSInteger type = [[queryTypeButton selectedItem] tag];


  [statusField setStringValue:@"searching..."];

  NSLog(@"search[%@]", txt);
  [books search:txt type:type];
}

- (void) list:(id) sender {
  if ([books status] == -1) {
    [self displayErrorMessage:@"Index has not been built yet" 
                         info:@"Use the inspector to configure and build the index"];
    return;
  }
  else if ([books status] > 0) {
    return;
  }

  [statusField setStringValue:@"listing..."];

  [books list];
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

- (void) rebuild:(id) sender {
  [books rebuild];
}

- (void) windowWillClose: (NSNotification*)aNotification {
  Inspector* ip = [Inspector sharedInstance];
  [ip inspectBooks:nil];
  [[ip window] orderOut:self];

  [books close];
}

- (void) windowDidBecomeKey:(NSWindow*) win {
  [[Inspector sharedInstance] inspectBooks:books];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView*) table {
  return [[books searchResults] count];
}

- (void) tableView:(NSTableView*)table willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)col row: (NSInteger)row {
  ResultItem* item = [[books searchResults] objectAtIndex:row];
  if ([[col identifier] isEqualToString:@"title"]) {
    if ([item type] == 1) {
      [cell setTextColor:[NSColor grayColor]];
      [cell setFont:[NSFont boldSystemFontOfSize:12]];
      [cell setAlignment:NSCenterTextAlignment];
    }
    else {
      [cell setTextColor:[NSColor textColor]];
      [cell setFont:[NSFont labelFontOfSize:12]];
      [cell setAlignment:NSLeftTextAlignment];
    }
  }
}

- (id) tableView:(NSTableView*) table objectValueForTableColumn:(NSTableColumn*) col row:(NSInteger) row {
  ResultItem* item = [[books searchResults] objectAtIndex:row];
  if ([[col identifier] isEqualToString:@"icon"]) {
    if ([item type] == 1) return nil;
    else                  return [NSImage imageNamed:@"chapter"];
  }
  else {
    if ([item type] == 1) return [NSString stringWithFormat:@"--- %@ ---", [item title]];
    else                  return [NSString stringWithFormat:@"%@", [item title]];
  }
}

@end
