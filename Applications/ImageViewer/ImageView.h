/*
   Project: ImageViewer

   Copyright (C) 2023 Free Software Foundation

   Author: Parallels

   Created: 2023-04-21 19:57:22 +0200 by parallels

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

#ifndef _IMAGEVIEW_H_
#define _IMAGEVIEW_H_

#import <AppKit/AppKit.h>

@interface ImageView : NSImageView
{
   NSRect dragRect;
   NSRect selectionRect;
   CGFloat displayScale;
   BOOL selectionMove;
   NSPoint moveOffset;
   CGFloat linePattern[2];
}

- (void) resetSelectionRectangle;
- (NSRect) selectedRectangle;
- (void) setSelectionRectangle:(NSRect) r;

- (NSImage*) croppedImage:(NSRect) r2;
- (IBAction) zoomIn:(id) sender;
- (IBAction) zoomOut:(id) sender;
- (IBAction) zoomReset:(id) sender;
@end

#endif // _IMAGEVIEW_H_

