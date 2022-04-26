/*
 * Copyright (C) 2003  Stefan Kleine Stegemann
 *               2010-2012 Free Software Foundation
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
 */

#include <stdlib.h>

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/DPSOperators.h>

#import <PDFKit/PDFImageRep.h>
#import <PDFKit/PDFFontManager.h>


#include "XPDFBridge.h"


const double PDFBaseResolution = 72.0;

/*
 * Non-Public methods.
 */
@interface PDFImageRep(Private)
- (void) _updatePage;
@end


/*
 */
@implementation PDFImageRep

+ (void) initialize
{
   [super initialize];

   // we have to make sure that font mappings are initialized
   [PDFFontManager sharedManager];
}


- (id) initWithDocument: (PDFDocument*)aDocument
{
   if ((self = [super init]))
   {
      pdfDoc  = RETAIN(aDocument);
      outputDevice = PDFRender_CreateOutputDevice([pdfDoc xpdfobject]);
      [self setResolution: PDFBaseResolution];
      [self setPageNum: 1];
      pageNeedsUpdate = YES;
      page = nil;
   }

   return self;
}


- (void) dealloc
{
   NSLog(@"dealloc PDFImageRep");
   
   PDFRender_DestroyOutputDevice(outputDevice);
   RELEASE(pdfDoc);
   RELEASE(page);

   [super dealloc];
}


- (void) setPageNum: (int)aPage
{
   pageNum         = aPage;
   pageNeedsUpdate = YES;
}


- (int) pageNum
{
   return pageNum;
}


- (NSSize) size
{
   NSSize size;

   size = [pdfDoc pageSize: [self pageNum] considerRotation: YES];

   // consider resolution
   size.height = ([self resolution] / PDFBaseResolution) * size.height;
   size.width  = ([self resolution] / PDFBaseResolution) * size.width;

   return size;
}


- (void) setResolution: (double)aResolution
{
   resolution      = aResolution;
   pageNeedsUpdate = YES;
}


- (double) resolution
{
   return resolution;
}


+ (BOOL) canInitWithData: (NSData*)data
{
   return NO;
}


+ (BOOL) canInitWithPasteboard: (NSPasteboard*)pasteboard
{
   return NO;
}


+ (NSArray*) imageFileTypes
{
   return [self imageUnfilteredFileTypes];
}


+ (NSArray*) imageUnfilteredFileTypes
{
   return [NSArray array];
}


+ (NSArray*) imagePasteboardTypes
{
   return [self imageUnfilteredPasteboardTypes];
}


+ (NSArray*) imageUnfilteredPasteboardTypes
{
   return [NSArray array];
}


/* overriding -draw is mandatory */
- (BOOL) draw
{
  NSSize size = [self size];
  return [self drawInRect: NSMakeRect(0, 0, size.width, size.height)];
}

- (BOOL) drawInRect: (NSRect)rect
{
   NSGraphicsContext* gc = GSCurrentContext();
   
   // fill background with white color
   [[NSColor whiteColor] set];
   DPSrectfill(gc, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

   if (pageNeedsUpdate)
   {
      [self _updatePage];
   }

   [page drawInRect: rect];

   return YES;
}

@end



@implementation PDFImageRep(Private)

/* Render the current page with the current resolution into
 * a bitmap.  */
- (void) _updatePage
{
   XPDFObject     bitmap;
   int            width, height;
   unsigned char* repData;

   AUTORELEASE(page);

   NSLog(@"Render page %d with resolution %f", [self pageNum], [self resolution]);
   bitmap = PDFRender_RenderPage([pdfDoc xpdfobject],
                                 outputDevice,
                                 [self pageNum],
                                 [self resolution],
                                 0);
   NSAssert(bitmap, @"could not render page");

   PDFRender_GetBitmapSize(bitmap, &width, &height);

   page = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                  pixelsWide: width
                                                  pixelsHigh: height
                                               bitsPerSample: 8
                                             samplesPerPixel: 3
                                                    hasAlpha: NO
                                                    isPlanar: NO
                                              colorSpaceName: NSCalibratedRGBColorSpace
                                                 bytesPerRow: 3 * width
                                                bitsPerPixel: 8 * 3];

   repData = [page bitmapData];
   PDFRender_GetRGB(bitmap, &repData);
   [page setSize: [self size]];
}

@end
