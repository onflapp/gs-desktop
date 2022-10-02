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
 * $Id: Icon.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/Icon.m $
 */

#include <AppKit/AppKit.h>

#include "Icon.h"


@implementation Icon

- (id)init
{
    self = [super init];
    if ( self ) {
    }
    return self;
}

- (void)dealloc
{
    TEST_AUTORELEASE(image);
    [super dealloc];
}


- (id)initWithImage: (NSImage *)i
{
    self = [self init];
    if ( self ) {
        image =  RETAIN(i);
        [i setScalesWhenResized: YES];
        originalSize = [i size];
    }
    return self;
}

+ (id)iconWithImage: (NSImage *)i
{
    return AUTORELEASE([[Icon alloc] initWithImage: i]);
}

- (NSImage *)imageCopy: (BOOL)copy
{
    if ( ! image ) {
        return nil;
    }
    [image setScalesWhenResized: YES];
    if ( copy ) {
        return AUTORELEASE([image copyWithZone: (NSZone *)nil]);
    }
    else {
        return image;
    }

}

- (NSImage *)imageForSize: (NSSize)size
                     copy: (BOOL)copy
{
    NSImage *img = [self imageCopy: copy];
    if ( (originalSize.width>size.width) || (originalSize.height>size.height) ) {
        // scale the image down proportionally
        float ratio = MIN(size.width / originalSize.width,
                          size.height / originalSize.height);
        size.width = originalSize.width*ratio;
        size.height = originalSize.height*ratio;
        [img setSize: size];
    }
    else {
        [img setSize: originalSize];
    }
    return img;
}

- (NSData *)scaledTIFFRepresentation: (NSSize)size
{
    NSImage *img = [self imageForSize: size copy: YES];
    [img lockFocus];
    NSRect rect = NSMakeRect(1, 1, 3, 3);
    //rect.origin = NSZeroPoint;
    //rect.size = size;
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: rect];
    [img unlockFocus];
    NSData *tiff = [newRep TIFFRepresentation];
    RELEASE(newRep);
    return tiff;
}

- (NSImage *)imageForOriginalSizeCopy: (BOOL)copy
{
    NSImage *img = [self imageCopy: copy];
    [img setSize: originalSize];
    return img;
}

@end
