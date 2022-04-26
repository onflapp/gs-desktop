/*
 * Copyright (C) 2003  Stefan Kleine Stegemann
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

#ifndef _H_PDF_IMAGE_REP
#define _H_PDF_IMAGE_REP

#import <Foundation/NSData.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSImageRep.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSBitmapImageRep.h>

#import <PDFKit/PDFDocument.h>


/* The standard resolution (in dpi) that is used when a
   page is rendered. All size computations are based on
   this resolution.  */
extern const double PDFBaseResolution;


@interface PDFImageRep : NSImageRep
{
   PDFDocument*       pdfDoc;
   void*              outputDevice;
   int                pageNum;
   NSSize             targetSize;
   double             resolution;
   NSBitmapImageRep*  page;
   BOOL               pageNeedsUpdate;
}

+ (void) initialize;

- (id) initWithDocument: (PDFDocument*)pdfDoc;
- (void) dealloc;

/* Set the number of the page to be displayed next  */
- (void) setPageNum: (int)aPage;
/* Get the number of the currently displayed page  */
- (int) pageNum;

/* Returns the size of the displayed page (scaled by
   the configured scale factor)  */
- (NSSize) size;

- (void) setResolution: (double)aResolution;
- (double) resolution;

+ (BOOL) canInitWithData: (NSData*)data;
+ (BOOL) canInitWithPasteboard: (NSPasteboard*)pasteboard; 
+ (NSArray*) imageFileTypes;
+ (NSArray*) imageUnfilteredFileTypes;
+ (NSArray*) imagePasteboardTypes;
+ (NSArray*) imageUnfilteredPasteboardTypes;

- (BOOL) drawInRect: (NSRect)rect;

@end

#endif
