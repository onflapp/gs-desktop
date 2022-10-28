/* PlaylistView.m - this file is part of Cynthiune
 *
 * Copyright (C) 2004 Wolfgang Sourdeau
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

#import <AppKit/NSEvent.h>
#import <AppKit/NSImage.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#import "PlaylistView.h"

@implementation PlaylistView : NSTableView

- (id) init
{
  if ((self = [super init]))
    {
      selectionDir = NSOrderedSame;
    }

  return self;
}

- (id) initWithCoder: (NSCoder *) coder
{
  if ((self = [super initWithCoder: coder]))
    {
      selectionDir = NSOrderedSame;
    }

  return self;
}

- (NSImage*) dragImageForRows: (NSArray*) dragRows
			event: (NSEvent*) dragEvent
	      dragImageOffset: (NSPoint*) dragImageOffset
{
  NSImage *dragImage;

  if ([dragRows count] > 1)
    {
      dragImage = [NSImage imageNamed: @"dragged-songs"];
      dragImageOffset->x = -10.0;
    }
  else
    {
      dragImage = [NSImage imageNamed: @"dragged-song"];
      dragImageOffset->x = -5.0;
    }

  dragImageOffset->y = 10.0;

  return dragImage;
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL) isLocal
{
  return ((isLocal)
          ? (NSDragOperationMove | NSDragOperationGeneric)
          : NSDragOperationCopy);
}

- (int) _findFirstSelected
{
  int row, count;

  row = -1;

  count = 0;
  while (row == -1 && count < [self numberOfRows])
    if ([self isRowSelected: count])
      row = count;
    else
      count++;

  return row;
}

- (int) _findLastSelected
{
  int row, count;

  row = -1;

  count = [self numberOfRows] - 1;
  while (row == -1 && count > -1)
    if ([self isRowSelected: count])
      row = count;
    else
      count--;

  return row;
}

- (void) _selectionUpByExtendingIt: (BOOL) keep
{
  int max, row;
  BOOL selectSingleRow;

  max = [self numberOfRows];
  if (max > 0)
    {
      selectSingleRow = NO;
      if (selectionDir == NSOrderedDescending)
        {
          row = [self _findLastSelected];
          if (keep)
            [self deselectRow: row];
          else
            selectSingleRow = YES;
        }
      else
        {
          if (selectionDir == NSOrderedSame)
            selectionDir = NSOrderedAscending;
          row = [self _findFirstSelected];
          selectSingleRow = YES;
        }

      if (selectSingleRow && row > 0)
        {
          row--;
          [self selectRow: row byExtendingSelection: keep];
        }

      [self scrollRowToVisible: row];
      [self setNeedsDisplay: YES];
    }
}

- (void) _selectionDownByExtendingIt: (BOOL) keep
{
  int max, row;
  BOOL selectSingleRow;

  max = [self numberOfRows];
  if (max > 0)
    {
      selectSingleRow = NO;
      if (selectionDir == NSOrderedAscending)
        {
          row = [self _findFirstSelected];
          if (keep)
            [self deselectRow: row];
          else
            selectSingleRow = YES;
        }
      else
        {
          if (selectionDir == NSOrderedSame)
            selectionDir = NSOrderedDescending;
          row = [self _findLastSelected];
          selectSingleRow = YES;
        }

      if (selectSingleRow && row < (max - 1))
        {
          row++;
          [self selectRow: row byExtendingSelection: keep];
        }

      [self scrollRowToVisible: row];
      [self setNeedsDisplay: YES];
    }
}

- (void) _selectionTopByExtendingIt: (BOOL) keep
{
  int row, count, max;

  max = [self numberOfRows];
  if (max > 0)
    {
      if (keep)
        {
          if (selectionDir == NSOrderedDescending)
            row = [self _findFirstSelected] + 1;
          else
            row = [self _findLastSelected] + 1;
          [self deselectAll: self];
          for (count = 0; count < row; count++)
            [self selectRow: count byExtendingSelection: YES];
        }
      else
        [self selectRow: 0 byExtendingSelection: NO];
      selectionDir = NSOrderedAscending;

      [self scrollRowToVisible: 0];
      [self setNeedsDisplay: YES];
    }
}

- (void) _selectionBottomByExtendingIt: (BOOL) keep
{
  int row, count, max;

  max = [self numberOfRows];
  if (max > 0)
    {
      if (keep)
        {
          if (selectionDir == NSOrderedAscending)
            row = [self _findLastSelected];
          else
            row = [self _findFirstSelected];
          [self deselectAll: self];
          for (count = row; count < max; count++)
            [self selectRow: count byExtendingSelection: YES];
        }
      else
        [self selectRow: (max - 1) byExtendingSelection: NO];
      selectionDir = NSOrderedDescending;

      [self scrollRowToVisible: (max - 1)];
      [self setNeedsDisplay: YES];
    }
}

- (BOOL) performKeyEquivalent: (NSEvent *) event
{
  BOOL shiftPressed, result;
  unichar character;
  id delegate;

  result = YES;
  shiftPressed = ([event modifierFlags]
                  & (NSAlphaShiftKeyMask | NSShiftKeyMask));
  character = [[event characters] characterAtIndex: 0];

  switch (character)
    {
    case NSUpArrowFunctionKey:
      [self _selectionUpByExtendingIt: shiftPressed];
      break;
    case NSDownArrowFunctionKey:
      [self _selectionDownByExtendingIt: shiftPressed];
      break;
    case NSHomeFunctionKey:
      [self _selectionTopByExtendingIt: shiftPressed];
      break;
    case NSEndFunctionKey:
      [self _selectionBottomByExtendingIt: shiftPressed];
      break;
    case CynthiuneEnterKey:
      delegate = [self delegate];
      if (delegate
          && [delegate respondsToSelector: @selector (playlistViewActivateSelection:)])
        [delegate playlistViewActivateSelection: self];
      break;
    case NSDeleteFunctionKey:
      delegate = [self delegate];
      if (delegate
          && [delegate respondsToSelector: @selector (playlistViewDeleteSelection:)])
        [delegate playlistViewDeleteSelection: self];
      break;
    default:
      result = [super performKeyEquivalent: event];
    }

  if ([self numberOfSelectedRows] < 2)
    selectionDir = NSOrderedSame;

  return result;
}

@end
