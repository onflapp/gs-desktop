/* Copyright (C) 2003 Raffael Herzog
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * $Id: IconView.h 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/IconView.h $
 */

#ifndef _GSWrapper_IconView_H
#define _GSWrapper_IconView_H

#include <AppKit/AppKit.h>
#include <AppKit/NSDragging.h>

#include "Icon.h"

extern NSString * const IconViewDidChangeIconNotification;

#define IconWidth 48.0f
#define IconHeight 48.0f


@interface IconView : NSView
{
    BOOL registeredForDraggedTypes;

    Icon *icon;
    NSImage *draggingImage;

    float insetsSize;

    id delegate;

    BOOL armed;
    BOOL dndOperation;
}

- (id)init;

- (Icon *)icon;
- (void)setIcon: (Icon *)i;

- (float)insetsSize;
- (void)setInsetsSize: (float)size;

- (void)drawRect: (NSRect)rect;

- (void)viewDidMoveToSuperview;

- (NSDragOperation)draggingEntered: (id<NSDraggingInfo>)info;
- (void)draggingExited: (id<NSDraggingInfo>)info;

- (BOOL)prepareForDragOperation: (id<NSDraggingInfo>)info;
- (BOOL)performDragOperation: (id<NSDraggingInfo>)info;
- (void)concludeDragOperation: (id<NSDraggingInfo>)info;

@end


#endif
