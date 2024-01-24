/*
   Project: Librarian

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

static NSWindow* _lastMainWindow;

NSString* make_title(NSString* path) {
  return [[path lastPathComponent] stringByDeletingPathExtension];
}

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
  [[NSNotificationCenter defaultCenter]
    removeObserver:self];

  RELEASE(filePath);
  RELEASE(books);

  [self release];
  [super dealloc];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (Document*) lastActiveDocument {
  return (Document*)[_lastMainWindow delegate];
}

- (void) awakeFromNib {
  NSInteger t = [[[NSUserDefaults standardUserDefaults] valueForKey:@"default_search_type"] integerValue];
  [queryTypeButton selectItemWithTag:t];
}

- (void) showWindow {
  if ([books status] == -1) {
    [statusField setStringValue:@"create new index first"];
  }

  if ([window isVisible]) {
    [window makeKeyAndOrderFront:self];
  }
  else {
    if (!_lastMainWindow) _lastMainWindow = [[NSApp orderedWindows] lastObject];
    if (filePath) {
      NSString* n = [NSString stringWithFormat:@"document_window_%lx", [filePath hash]];
      [window setFrameUsingName:n];
      [window setFrameAutosaveName:n];
    }
    else if (_lastMainWindow) {
      NSRect r = [_lastMainWindow frame];
      r.origin.x += 24;

      [window setFrame:r display:NO];
    }

    [window makeKeyAndOrderFront:self];
  }
}

- (NSString*) fileName {
  return filePath;
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

  [window setTitle:make_title(file)];
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

- (void) searchText:(NSString*) text {
  [self showWindow];
  [queryField setStringValue:text];
  [self search:self];
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
  [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:type] forKey:@"default_search_type"];

  NSLog(@"search[%@]", txt);
  [books search:txt type:type];
  [resultsView reloadData];
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
  if ([[NSUserDefaults standardUserDefaults] valueForKey:@"DEFAULT_BOOK"] == nil && filePath) {
    [[NSUserDefaults standardUserDefaults] setValue:filePath forKey:@"DEFAULT_BOOK"];
  }

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

    [window setTitle:make_title(fileName)];
  }
}

- (void) rebuild:(id) sender {
  [books rebuild];
}

- (void) windowWillClose: (NSNotification*)aNotification {
  if ([window frameAutosaveName] == nil) {
    NSString* n = [NSString stringWithFormat:@"document_window_%lx", [filePath hash]];
    [window setFrameAutosaveName:n];
  }

  Inspector* ip = [Inspector sharedInstance];
  [ip inspectBooks:nil];
  [[ip window] orderOut:self];

  if (_lastMainWindow == window) _lastMainWindow = nil;

  [window setDelegate:nil];
  [books close];
}

- (void) windowDidBecomeKey:(NSNotification*) not {
  NSInteger t = [[[NSUserDefaults standardUserDefaults] valueForKey:@"hide_on_deactivate"] integerValue];
  [window setHidesOnDeactivate:t];

  [[Inspector sharedInstance] inspectBooks:books];
  _lastMainWindow = window;
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
