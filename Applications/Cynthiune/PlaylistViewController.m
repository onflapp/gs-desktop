/* PlaylistViewController.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2005  Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <wolfgang@contre.com>
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

#import <AppKit/NSImage.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableHeaderView.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>

#import <Cynthiune/NSCellExtensions.h>
#import <Cynthiune/NSColorExtensions.h>
#import <Cynthiune/NSNumberExtensions.h>
#import <Cynthiune/utils.h>

#import "CynthiuneHeaderCell.h"
#import "CynthiuneTextCell.h"
#import "CynthiuneSongTitleCell.h"
#import "Playlist.h"
#import "PlaylistController.h"
#import "PlaylistViewController.h"
#import "PlaylistView.h"
#import "Song.h"
#import "FormatTester.h"

#define LOCALIZED(X) NSLocalizedString (X, nil)

static NSString *CynthiunePlaylistDragType = @"CynthiunePlaylistDragType";

@implementation PlaylistViewController : NSObject

- (id) init
{ 
  if ((self = [super init]))
    {
      currentPlayerSong = nil;
      sortColumn = @"";
      sortDirection = NSOrderedSame;
    }

  return self;
}

- (void) setCurrentPlayerSong: (Song *) newSong
{
  currentPlayerSong = newSong;
  [self updateView];
}

/* nib and gui init stuff... */

- (float) _timeColumnWidth
{
  NSTableColumn *column;
  float labelWidth, zeroesWidth;

  column = [playlistView tableColumnWithIdentifier: @"time"];
  labelWidth = [[column headerCell] widthOfText: LOCALIZED (@"Time")];
  zeroesWidth = [[column dataCell] widthOfText: @"00:00"];

  return ((labelWidth > zeroesWidth) ? labelWidth : zeroesWidth);
}

- (void) _deleteAllColumns
{
  NSArray *columns;
  int count, max;

  columns = [playlistView tableColumns];
  max = [playlistView numberOfColumns];
  for (count = 0; count < max; count++)
    {
#ifdef __MACOSX__
      [playlistView removeTableColumn: [columns objectAtIndex: 0]];
#else
      [playlistView removeTableColumn: [columns objectAtIndex: count]];
#endif /* __MACOSX__ */
    }
}

- (NSTableColumn *) _tableColumnWithIdentifier: (NSString *) identifier
                                      andTitle: (NSString *) title
                                titleAlignment: (NSTextAlignment) alignment
                                     resizable: (BOOL) resizable
{
  NSTableColumn *column;
  CynthiuneHeaderCell *headerCell;

  column = [[NSTableColumn alloc] initWithIdentifier: identifier];
  [column retain];
  headerCell = [CynthiuneHeaderCell new];
  [column setHeaderCell: headerCell];
  [column setEditable: NO];
  [column setResizable: resizable];
  [headerCell setStringValue: title];
  [headerCell setAlignment: alignment];
  if ([sortColumn isEqualToString: identifier])
    [headerCell setComparisonResult: sortDirection];
  [column sizeToFit];

  return column;
}

- (void) _addNeededColumns
{
  NSTableColumn *column;
  CynthiuneTextCell *songTimeCell;
  CynthiuneSongTitleCell *songTitleCell;
  NSColor *highlightColor;

  highlightColor = [NSColor rowsHighlightColor];

  songTitleCell = [CynthiuneSongTitleCell new];
  [songTitleCell setDrawsBackground: YES];
  [songTitleCell setHighlightColor: highlightColor];
  [songTitleCell setPointerImage: [NSImage imageNamed: @"song-pointer"]];

  songTimeCell = [CynthiuneTextCell new];
  [songTimeCell setDrawsBackground: YES];
  [songTimeCell setHighlightColor: highlightColor];
  [songTimeCell setAlignment: NSRightTextAlignment];

  column = [self _tableColumnWithIdentifier: @"song"
                 andTitle: LOCALIZED (@"Song")
                 titleAlignment: NSCenterTextAlignment
                 resizable: YES];
  [column setDataCell: songTitleCell];
  [playlistView addTableColumn: column];

  column = [self _tableColumnWithIdentifier: @"time"
                 andTitle: LOCALIZED (@"Time")
                 titleAlignment: NSLeftTextAlignment
                 resizable: NO];
  [column setDataCell: songTimeCell];
  [playlistView addTableColumn: column];
}

- (void) _updateColumnHeaders
{
  NSTableColumn *column;
  NSEnumerator *columnEnumerator;
  id headerCell;

  columnEnumerator = [[playlistView tableColumns] objectEnumerator];
  column = [columnEnumerator nextObject];
  while (column)
    {
      headerCell = [column headerCell];
      if ([[column identifier] isEqualToString: sortColumn])
        [headerCell setComparisonResult: sortDirection];
      else
        [headerCell setComparisonResult: NSOrderedSame];
      column = [columnEnumerator nextObject];
    }
  [[playlistView headerView] setNeedsDisplay: YES];
}

- (void) _restoreSortOrder
{
  NSUserDefaults *defaults;

  defaults = [NSUserDefaults standardUserDefaults];
  sortColumn = [defaults stringForKey: @"PlaylistSortColumn"];
  [sortColumn retain];
  sortDirection = [defaults integerForKey: @"PlaylistSortDirection"] - 1;
}

- (void) _saveSortOrder
{
  NSUserDefaults *defaults;

  defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject: sortColumn forKey: @"PlaylistSortColumn"];
  [defaults setInteger: (sortDirection + 1) forKey: @"PlaylistSortDirection"];
}

- (void) invalidateSortedColumn
{
  SET (sortColumn, @"");
  [self _saveSortOrder];
  [self _updateColumnHeaders];
}

- (void) awakeFromNib
{
  [self _restoreSortOrder];
  [self _deleteAllColumns];
  [self _addNeededColumns];

  [[playlistView window] setInitialFirstResponder: playlistView];

  [playlistView setIntercellSpacing: NSMakeSize (0.0, 0.0)];
  [playlistView setAllowsColumnResizing: NO];
  [playlistView setAutoresizesAllColumnsToFit: NO];
  [playlistView setAllowsEmptySelection: YES];
  [playlistView setAllowsMultipleSelection: YES];
  [playlistView setAllowsColumnSelection: NO];
  [playlistView setVerticalMotionCanBeginDrag: YES];
  [playlistView registerForDraggedTypes:
                  [NSArray arrayWithObjects: NSFilenamesPboardType,
                           CynthiunePlaylistDragType, nil]];
  [playlistView setDataSource: self];
  [playlistView setTarget: self];
  [playlistView setDelegate: self];
  [playlistView setDoubleAction: @selector(doubleClick:)];
  [playlistView sizeToFit];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(scrollViewDidResize:)
    name: NSViewFrameDidChangeNotification
    object: [[playlistView superview] superview]];
}

- (void) setPlaylistController: (PlaylistController *) controller
{
  playlistController = controller;
}

- (void) doubleClick: (id) sender
{
  int clickedRow;

  clickedRow = [playlistView clickedRow];
  if (clickedRow > -1)
    [playlistController tableDoubleClick: clickedRow];
}

/* FIXME: this method should be removed and the logic behind it rearranged so
   that we deal directly with the selection in the PlaylistView class */
- (void) selectSongsInArray: (NSArray *) array
{
  unsigned int count, max;
  Song *currentSong;

  max = [array count];
  for (count = 0; count < max; count++)
    {
      currentSong = [array objectAtIndex: count];
      [playlistView selectRow: [playlist indexOfSong: currentSong]
                    byExtendingSelection: YES];
    }
}

- (void) _sortPlaylist
{
  NSArray *selectedSongs;

  selectedSongs = [self getSelectedSongs];
  [playlistView deselectAll: self];

  if ([sortColumn isEqualToString: @"song"])
    [playlist
      sortByPlaylistRepresentation: (sortDirection == NSOrderedDescending)];
  else if ([sortColumn isEqualToString: @"time"])
    [playlist sortByDuration: (sortDirection == NSOrderedDescending)];

  [self selectSongsInArray: selectedSongs];
  [self _saveSortOrder];
  [self _updateColumnHeaders];
}

-               (void) tableView: (NSTableView *) tableView
  mouseDownInHeaderOfTableColumn: (NSTableColumn *) tableColumn;
{
  NSString *colId;

  if ([playlist numberOfSongs] > 1)
    {
      colId = [tableColumn identifier];
      if ([colId isEqualToString: sortColumn])
        {
          if (sortDirection == NSOrderedAscending)
            sortDirection = NSOrderedDescending;
          else
            sortDirection = NSOrderedAscending;
        }
      else
        {
          SET (sortColumn, colId);
          sortDirection = NSOrderedAscending;
        }

      [self _sortPlaylist];
    }
}

- (void) playlistViewActivateSelection: (PlaylistView *) view
{
  [playlistController playlistViewActivateSelection: view];
}

- (void) playlistViewDeleteSelection: (PlaylistView *) view
{
  [playlistController removeSelectedSongs: view];
}

/* datasource protocol */
- (NSInteger) numberOfRowsInTableView: (NSTableView *) tableView
{
  return [playlist numberOfSongs];
}

- (NSString *) _bestFit: (NSString *) string
              forColumn: (NSTableColumn *) column
{
  NSMutableString *newString;
  NSCell *dataCell;
  CGFloat stringWidth, width;
  NSUInteger length;

  newString = [NSMutableString stringWithString: string];
  dataCell = [column dataCell];

  width = [column width];
  stringWidth = [dataCell widthOfText: newString];
  length = [newString length];

  while (length > 3
         && (stringWidth > width || [newString hasSuffix: @" ..."]))
    {
      [newString replaceCharactersInRange: NSMakeRange (length - 4, 4)
                 withString: @"..."];
      stringWidth = [dataCell widthOfText: newString];
      length = [newString length];
    }

  return newString;
}

-            (id) tableView: (NSTableView *) tableView
  objectValueForTableColumn: (NSTableColumn *) tableColumn
                        row: (NSInteger) rowIndex
{
  NSString *cellContent, *colId;
  Song *song;

  cellContent = @"";
  colId = [tableColumn identifier];

  if (colId)
    {
      song = [playlist songAtIndex: rowIndex];
      if (!song)
        NSLog (@"no song at index %ld", rowIndex);

      if ([colId isEqualToString: @"song"])
        cellContent = [self _bestFit: [song playlistRepresentation]
                            forColumn: tableColumn];
      else if ([colId isEqualToString: @"time"])
        cellContent = [[song duration] timeStringValue];
      else
        NSLog (@"unexpected column id: %@", colId);
    }

  return cellContent;
}

- (void) tableView: (NSTableView *) tableView
   willDisplayCell: (id) cell
    forTableColumn: (NSTableColumn *) tableColumn
               row: (NSInteger) rowIndex
{
  Song *rowSong;

  rowSong = [playlist songAtIndex: rowIndex];
#ifdef GNUSTEP
  /* GNUSTEP is buggy so we work-around */
  [cell setHighlighted: [tableView isRowSelected: rowIndex]];
#endif
  [cell setBackgroundColor: ((rowIndex % 2 == 0)
                             ? [NSColor evenRowsBackgroundColor]
                             : [NSColor oddRowsBackgroundColor])];
  [cell setTextColor: (([rowSong status] == SongOK)
                       ? [NSColor controlTextColor]
                       : [NSColor disabledControlTextColor])];
  if ([[tableColumn identifier] isEqualToString: @"song"])
    [cell setShowImage: (currentPlayerSong
                         && currentPlayerSong == rowSong)];
}

- (BOOL) tableView: (NSTableView *) tableView
	 writeRows: (NSArray *) rows
      toPasteboard: (NSPasteboard*) pboard
{
  NSArray *types;
  BOOL accept;
  unsigned int count;

  count = [rows count];

  if (count > 0)
    {
      accept = YES;
      types = [NSArray arrayWithObjects: CynthiunePlaylistDragType,
                       NSFilenamesPboardType, nil];
      [pboard declareTypes: types owner: self];
      [pboard setPropertyList: rows forType: CynthiunePlaylistDragType];
    }
  else
    accept = NO;

  return accept;
}

- (void) pasteboard: (NSPasteboard *) pboard
 provideDataForType: (NSString *) type
{
  if ([type isEqualToString: NSFilenamesPboardType])
    [pboard setPropertyList: [self getSelectedSongsAsFilenames]
            forType: NSFilenamesPboardType];
  else
    NSLog (@"unexpected type: %@", type);
}

/* drag and drop */
- (BOOL) _acceptFilesInPasteboard: (NSPasteboard *) pboard
{
  NSArray *filesList;
  NSString *filename;
  FormatTester *formatTester;
  BOOL accept;
  unsigned int count, max;

  filesList = [pboard propertyListForType: NSFilenamesPboardType];

  accept = NO;
  count = 0;
  max = [filesList count];
  formatTester = [FormatTester formatTester];

  while (count < max && !accept)
    {
      filename = [filesList objectAtIndex: count];
      accept = (!fileIsAReadableDirectory (filename)
                && [formatTester formatNumberForFile: filename] > -1);
      count++;
    }

  return accept;
}

- (NSDragOperation) tableView: (NSTableView *) tableView
		 validateDrop: (id <NSDraggingInfo>) info
		  proposedRow: (NSInteger) row
	proposedDropOperation: (NSTableViewDropOperation) dropOperation
{
  NSString *availableType, *requiredType;
  NSPasteboard *pboard;
  NSDragOperation dragOperation;
  NSUInteger mask;

  pboard = [info draggingPasteboard];
  
  if ([info draggingSource] == playlistView)
    {
      requiredType = CynthiunePlaylistDragType;
      mask = [info draggingSourceOperationMask];
      if ((mask & NSDragOperationMove)
          == NSDragOperationMove)
        dragOperation = NSDragOperationMove;
      else if ((mask & NSDragOperationGeneric)
               == NSDragOperationGeneric)
        dragOperation = NSDragOperationGeneric;
      else
        dragOperation = NSDragOperationNone;
    }
  else
    {
      requiredType = NSFilenamesPboardType;
      dragOperation = NSDragOperationCopy;
    }

  availableType =
    [pboard availableTypeFromArray: [NSArray arrayWithObject: requiredType]];

  if (availableType && [availableType isEqualToString: requiredType])
    [tableView setDropRow: row dropOperation: NSTableViewDropAbove];
  else
    dragOperation = NSDragOperationNone;

  return dragOperation;
}

- (void) _acceptDroppedFiles: (NSArray *) filenames
                       atRow: (int) row
{
  [playlistController tableFilenamesDropped: filenames];
}

- (void) _acceptDroppedRows: (NSArray *) aRowsList
                      atRow: (int) row
                   withMask: (unsigned int) mask
{
  unsigned int firstRow, max, count;

  if (mask & NSDragOperationMove)
    {
      firstRow = [playlist moveSongsAtIndexes: aRowsList toIndex: row];
      [playlistView selectRow: firstRow byExtendingSelection: NO];
      max = [aRowsList count];
      for (count = 1; count < max; count++)
        [playlistView selectRow: (firstRow + count)
                      byExtendingSelection: YES];
    }
  else if (mask & NSDragOperationGeneric)
    NSLog (@"operation %d not currently supported", mask);
  else
    NSLog (@"invalid operation '%d'!!", mask);
}

- (BOOL) tableView: (NSTableView *) tableView
	acceptDrop: (id <NSDraggingInfo>) info
	       row: (NSInteger) row
     dropOperation: (NSTableViewDropOperation) op
{
  NSPasteboard *pboard;
  NSArray *objectsList, *typeArray;
  NSString *availableType;
  BOOL accept;

  pboard = [info draggingPasteboard];
  typeArray = ([info draggingSource] == playlistView)
    ? [NSArray arrayWithObject: CynthiunePlaylistDragType]
    : [NSArray arrayWithObject: NSFilenamesPboardType];
  availableType = [pboard availableTypeFromArray: typeArray];
  objectsList = [pboard propertyListForType: availableType];

  if ([objectsList count])
    {
      if ([availableType isEqualToString: CynthiunePlaylistDragType])
        [self _acceptDroppedRows: objectsList atRow: row
              withMask: [info draggingSourceOperationMask]];
      else
        [self _acceptDroppedFiles: objectsList atRow: row];
      [self invalidateSortedColumn];
      [playlistView reloadData];
      accept = YES;
    }
  else
    accept = NO;

  return accept;
}

/* delegate */

- (void) tableViewSelectionIsChanging: (NSNotification *) notification
{
  [playlistController updateStatusLabel];
}

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
  [playlistController updateSongInspector];
  [playlistController updateStatusLabel];
}

/* scrollView delegate */
- (void) scrollViewDidResize: (NSNotification *) notification
{
  [playlistView sizeToFit];
}

/* real methods */
- (int) getFirstSelectedRow
{
  return ([playlist numberOfSongs] ? [playlistView selectedRow] : -1);
}

- (Song *) getFirstSelectedSong
{
  int nbr;

  nbr = [self getFirstSelectedRow];

  return ((nbr > -1) ? [playlist songAtIndex: nbr] : nil);
}

- (NSArray *) getSelectedSongs
{
  NSMutableArray *selection;
  int count, max;

  selection = [NSMutableArray new];
  [selection autorelease];

  max = [playlistView numberOfRows];
  for (count = 0; count < max; count++)
    if ([playlistView isRowSelected: count])
      [selection addObject: [playlist songAtIndex: count]];

  return selection;
}

- (NSArray *) getSelectedSongsAsFilenames
{
  NSMutableArray *selection;
  Song *song;
  int count, max;

  if ([playlist numberOfSongs])
    {
      max = [playlistView numberOfRows];
      selection = [NSMutableArray arrayWithCapacity: max];

      for (count = 0; count < max; count++)
        if ([playlistView isRowSelected: count])
          {
            song = [playlist songAtIndex: count];
            [selection addObject: [song filename]];
          }
    }
  else
    selection = [NSMutableArray arrayWithObject: nil];

  return selection;
}

- (NSNumber *) durationOfSelection
{
  unsigned int count, max, intDuration;
  NSArray *selection;
  Song *currentSong;

  intDuration = 0;

  selection = [self getSelectedSongs];
  max = [selection count];
  for (count = 0; count < max; count++)
    {
      currentSong = [selection objectAtIndex: count];
      intDuration += [[currentSong duration] unsignedIntValue];
    }

  return [NSNumber numberWithUnsignedInt: intDuration];
}

- (void) updateView
{
  int currentSongNumber;

  if (currentPlayerSong)
    {
      currentSongNumber = [playlist indexOfSong: currentPlayerSong];
      [playlistView scrollRowToVisible: currentSongNumber];
    }
  [playlistView reloadData];
}

- (void) setPlaylist: (Playlist *) aPlaylist
{
  SET (playlist, aPlaylist);
  [self updateView];
}

- (void) deselectAll
{
  [playlistView deselectAll: self];
}

@end
