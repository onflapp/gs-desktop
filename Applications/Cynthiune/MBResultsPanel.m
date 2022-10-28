/* MBResultsPanel.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#import <AppKit/NSApplication.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSTextFieldCell.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>

#import <Cynthiune/NSCellExtensions.h>
#import <Cynthiune/NSColorExtensions.h>
#import <Cynthiune/NSViewExtensions.h>
#import <Cynthiune/utils.h>

#import "CynthiuneTextCell.h"
#import "MBResultsPanel.h"

#define LOCALIZED(X) NSLocalizedString (X, nil)

#define panelContentRect NSMakeRect (100, 100, 420, 205)
#define panelContentSize NSMakeSize (420, 185)

@implementation MBResultsPanel : NSPanel

+ (MBResultsPanel *) resultsPanel
{
  static MBResultsPanel *resultsPanel = nil;
  if (!resultsPanel)
    resultsPanel = [self new];

  return resultsPanel;
}

- (void) _setDefaults
{
  [tableView deselectAll: self];
  [okButton setEnabled: NO];
  [self setTitle: LOCALIZED (@"Please select the correct information...")];
  [self setHidesOnDeactivate: YES];
  [self setInitialFirstResponder: okButton];
  [self setContentSize: panelContentSize];
}

- (NSTableColumn *) _tableColumnWithIdentifier: (NSString *) identifier
                                      andTitle: (NSString *) title
{
  NSTableColumn *column;
  CynthiuneTextCell *dataCell;

  dataCell = [CynthiuneTextCell new];
  [dataCell autorelease];

  column = [[NSTableColumn alloc] initWithIdentifier: identifier];
  [column autorelease];
  [column setResizable: NO];
  [column setEditable: NO];
  [[column headerCell] setStringValue: title];
  [dataCell setHighlightColor: [NSColor rowsHighlightColor]];
  [dataCell setDrawsBackground: YES];
  [column setDataCell: dataCell];

  return column;
}

- (void) _createInfoText: (NSView *) contentView
{
  NSTextField *infoText;
  NSFont *infoFont;

#ifdef GNUSTEP
  infoFont = [NSFont controlContentFontOfSize: [NSFont systemFontSize]];
#else
  infoFont = [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]];
#endif

  infoText = [[NSTextField alloc]
               initWithFrame: NSMakeRect (10, 155, 400, 40)];
  [infoText setFont: infoFont];
  [infoText setBezeled: NO];
  [infoText setBordered: NO];
  [infoText setDrawsBackground: NO];
  [infoText setSelectable: NO];
  [infoText setEditable: NO];
  [infoText setAutoresizingMask: NSViewMinYMargin | NSViewWidthSizable];
  [infoText setStringValue:
              LOCALIZED (@"The request to the MusicBrainz server returned"
                         @" more than one result.\nPlease select the line"
                         @" in the following table that is the most"
                         @" accurate.")];
  [[infoText cell] setWraps: YES];

  [contentView addSubview: infoText];
}

- (void) _createTableView: (NSView *) contentView
{
  NSScrollView *scrollView;
  NSTableColumn *column;

  tableView = [NSTableView new];

  column = [self _tableColumnWithIdentifier: @"title"
                 andTitle: LOCALIZED (@"Title")];
  [tableView addTableColumn: column];
  column = [self _tableColumnWithIdentifier: @"album"
                 andTitle: LOCALIZED (@"Album")];
  [tableView addTableColumn: column];
  column = [self _tableColumnWithIdentifier: @"trackNumber"
                 andTitle: LOCALIZED (@"Track")];
  [tableView addTableColumn: column];
  column = [self _tableColumnWithIdentifier: @"artist"
                 andTitle: LOCALIZED (@"Artist")];
  [tableView addTableColumn: column];
  column = [self _tableColumnWithIdentifier: @"year"
                 andTitle: LOCALIZED (@"Year")];
  [[column dataCell] setAlignment: NSRightTextAlignment];
  [tableView addTableColumn: column];

  [tableView setDrawsGrid: NO];
  [tableView setDataSource: self];
  [tableView setIntercellSpacing: NSMakeSize (0.0, 0.0)];
  [tableView setAllowsEmptySelection: YES];
  [tableView setAllowsMultipleSelection: NO];
  [tableView setAllowsColumnSelection: NO];
  [tableView setAutoresizesAllColumnsToFit: NO];
  [tableView setAutoresizingMask: NSViewNotSizable];
  [tableView setDoubleAction: @selector (_doubleClick:)];
  [tableView setTarget: self];
  [tableView setDelegate: self];

  scrollView =
    [[NSScrollView alloc]
      initWithFrame: NSMakeRect (10, 45, 400, 100)];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setDocumentView: tableView];
  [scrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [scrollView setAutoresizesSubviews: YES];

  [contentView addSubview: scrollView];
}

- (void) _createButtons: (NSView *) contentView
{
  NSRect frame;
  NSFont *labelFont;

#ifdef GNUSTEP
  labelFont = [NSFont controlContentFontOfSize: [NSFont labelFontSize]];
#else
  labelFont = [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]];
#endif

  frame = NSMakeRect (10, 10, 10, 10);
  okButton = [[NSButton alloc] initWithFrame: frame];
  [okButton setTitle: LOCALIZED (@"OK")];
  [okButton setFont: labelFont];
#ifdef GNUSTEP
  [okButton setImagePosition: NSImageRight]; 
  [okButton setImage: [NSImage imageNamed: @"common_ret"]];
  [okButton setAlternateImage: [NSImage imageNamed: @"common_retH"]];
#endif
  [okButton setAutoresizingMask: NSViewMinXMargin];
  [okButton setTarget: self];
  [okButton setAction: @selector (_ok:)];
  [okButton setButtonType: NSMomentaryPushButton];
  [okButton setBezelStyle: NSRoundedBezelStyle];
  [okButton sizeToFit];
  frame = [okButton frame];
  frame.origin.x = 420 - 10 - frame.size.width;
  [okButton setFrame: frame];

  cancelButton = [[NSButton alloc] initWithFrame: frame];
  [cancelButton setTitle: LOCALIZED (@"Cancel")];
  [cancelButton setFont: labelFont];
  [cancelButton setAutoresizingMask: NSViewMinXMargin];
  [cancelButton setTarget: self];
  [cancelButton setAction: @selector (_cancel:)];
  [cancelButton setButtonType: NSMomentaryPushButton];
  [cancelButton setBezelStyle: NSRoundedBezelStyle];
  [cancelButton sizeToFit];

  [contentView addSubview: okButton];
  [contentView addSubview: cancelButton];
  [cancelButton arrangeViewLeftTo: okButton];

  [okButton setNextKeyView: cancelButton];
  [cancelButton setNextKeyView: okButton];
}

- (id) init
{
  NSView *contentView;

  if ((self = [super initWithContentRect: panelContentRect
                     styleMask: (NSTitledWindowMask | NSResizableWindowMask) 
                     backing: NSBackingStoreBuffered
                     defer: NO]))
    {
      trackInfos = nil;

      [self setMinSize: [self frame].size];
      contentView = [self contentView];
      [self _createInfoText: contentView];
      [self _createTableView: contentView];
      [self _createButtons: contentView];
      [self setHidesOnDeactivate: YES];
      [self setInitialFirstResponder: okButton];
    }

  return self;
}

- (void) _updateColumnWidth: (NSTableColumn *) column
{
  float newWidth, strWidth;
  NSEnumerator *trackEnum;
  NSDictionary *track;
  NSString *value;
  NSCell *cell;

  cell = [column headerCell];
  newWidth = [cell widthOfText: [cell stringValue]] + 20.0;
  trackEnum = [trackInfos objectEnumerator];

  cell = [column dataCell];
  track = [trackEnum nextObject];
  while (track)
    {
      value = [track objectForKey: [column identifier]];
      strWidth = [cell widthOfText: value];
      if (newWidth < strWidth)
        newWidth = strWidth;
      track = [trackEnum nextObject];
    }

  [column setWidth: newWidth];
}

- (void) _updateColumnsWidth
{
  NSEnumerator *columns;
  NSTableColumn *column;

  columns = [[tableView tableColumns] objectEnumerator];
  column = [columns nextObject];
  while (column)
    {
      [self _updateColumnWidth: column];
      column = [columns nextObject];
    }
}

- (void) showPanelForTrackInfos: (NSArray *) allTrackInfos
                    aboveWindow: (NSWindow *) window
                         target: (id) caller
                       selector: (SEL) action
{
  trackInfos = allTrackInfos;
  [trackInfos retain];

  [tableView reloadData];

  target = caller;
  actionSelector = action;

  [self _updateColumnsWidth];
  [self _setDefaults];

  [self center];
  [self orderWindow: NSWindowAbove
        relativeTo: [window windowNumber]];
  [self makeKeyAndOrderFront: self];
  [self setLevel: NSModalPanelWindowLevel];
}

- (void) _cancel: (id) sender
{
  [trackInfos release];
  trackInfos = nil;
  [self close];
}

- (void) _ok: (id) sender
{
  int selectedRow;

  selectedRow = [tableView selectedRow];
  [target performSelector: actionSelector
          withObject: [trackInfos objectAtIndex: selectedRow]];
  [trackInfos release];
  trackInfos = nil;
  [self close];
}

- (void) _doubleClick: (id) sender
{
  if ([tableView clickedRow] > -1)
    [self _ok: sender];
}

/* Datasource protocol */
- (NSInteger) numberOfRowsInTableView: (NSTableView *) tableView
{
  return [trackInfos count];
}

-            (id) tableView: (NSTableView *) tableView
  objectValueForTableColumn: (NSTableColumn *) tableColumn
                        row: (NSInteger) rowIndex
{
  NSDictionary *trackInfo;

  trackInfo = [trackInfos objectAtIndex: rowIndex];

  return [trackInfo objectForKey: [tableColumn identifier]];
}

/* tableview delegate */
- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
  [okButton setEnabled: ([tableView numberOfSelectedRows] != 0)];
}

- (void) tableView: (NSTableView *) tv
   willDisplayCell: (id) cell
    forTableColumn: (NSTableColumn *) tableColumn
               row: (NSInteger) rowIndex
{
#ifdef GNUSTEP
  /* GNUSTEP is buggy so we work-around */
  [cell setHighlighted: [tv isRowSelected: rowIndex]];
#endif
  [cell setBackgroundColor: ((rowIndex % 2 == 0)
                             ? [NSColor evenRowsBackgroundColor]
                             : [NSColor oddRowsBackgroundColor])];
}

@end
