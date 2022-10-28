/* CynthiuneSongTitleCell.m - this file is part of Cynthiune
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

#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>
#import <Foundation/NSString.h>

#import <Cynthiune/NSCellExtensions.h>
#import <Cynthiune/utils.h>

#import "CynthiuneTextCell.h"
#import "CynthiuneSongTitleCell.h"

#define imageOffset 2.0

@implementation CynthiuneSongTitleCell : CynthiuneTextCell

- (id) init
{
  if ((self = [super init]))
    {
      songPointer = nil;
      imageSize = NSMakeSize (0.0, 0.0);
      imageShown = NO;
    }

  return self;
}

- (void) dealloc
{
  if (songPointer)
    [songPointer release];
  [super dealloc];
}

- (void) setShowImage: (BOOL) showImage
{
  imageShown = showImage;
}

- (BOOL) showImage
{
  return imageShown;
}

- (void) setPointerImage: (NSImage *) pointerImage
{
  SET (songPointer, pointerImage);
  imageSize = ((songPointer) ? [songPointer size] : NSMakeSize (0.0, 0.0));
}

- (NSImage *) pointerImage
{
  return songPointer;
}

- (void) drawWithFrame: (NSRect) cellFrame 
		inView: (NSView *) controlView
{
  NSRect aFrame, imageFrame;

  NSDivideRect (cellFrame, &aFrame, &cellFrame,
                3.0 + imageOffset + imageSize.width, NSMinXEdge);

  imageFrame = aFrame;
  imageFrame.size = imageSize;
  imageFrame.size.width += 3.0 + imageOffset;

  if ([self drawsBackground])
    {
      [[self backgroundColor] set];
      NSRectFill (aFrame);
    }

  if ([self isHighlighted])
    { 
      [[self highlightColor] set];
      NSRectFill (aFrame);
    }

  if (imageShown)
    {
      aFrame.size = imageSize;
      aFrame.origin.x += imageOffset;
      aFrame.origin.y += ((cellFrame.size.height + 1.0
                           + ([controlView isFlipped]
                              ? aFrame.size.height
                              : -aFrame.size.height))
                          / 2);

      [songPointer compositeToPoint: aFrame.origin 
                   operation: NSCompositeSourceOver];
    }

  [super drawWithFrame: cellFrame inView: controlView];
}

- (NSSize) cellSize 
{
  NSSize aSize;

  aSize = [super cellSize];
  aSize.width += imageSize.width + imageOffset + 3.0;

  return aSize;
}

- (float) widthOfText: (NSString *) text
{
  return ([super widthOfText: text] + imageSize.width + imageOffset + 3.0);
}

/* NSCopying protocol */
- (id) copyWithZone: (NSZone *) theZone 
{
  CynthiuneSongTitleCell *newTitleCell;

  newTitleCell = [[CynthiuneSongTitleCell allocWithZone: theZone] init];
  [newTitleCell setPointerImage: songPointer];
  [newTitleCell setShowImage: imageShown];

  return newTitleCell;
}

/* NSCoding protocol */
- (void) encodeWithCoder: (NSCoder *) encoder
{
  [super encodeWithCoder: encoder];
  [encoder encodeBool: imageShown forKey: @"imageShown"];
  [encoder encodeObject: songPointer forKey: @"songPointer"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  if ((self = [super initWithCoder: decoder]))
    {
      imageShown = [decoder decodeBoolForKey: @"imageShown"];
      songPointer = [decoder decodeObjectForKey: @"songPointer"];
      if (songPointer)
        [songPointer retain];
    }

  return self;
}

@end
