/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
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

#import <Foundation/NSException.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/DPSOperators.h>
#import "PDFPrintView.h"
#import "XPDFBridge.h"

/*
 * Non-Public methods.
 */
@interface PDFPrintView (Private)
@end


@implementation PDFPrintView

- (id) initWithDocument: (PDFDocument*)aDocument
{
   NSAssert(aDocument, @"cannot init a PDFPrintView without PDFDocument");

   if ((self = [super initWithFrame: NSMakeRect(1,1,1,1)]))
   {
      document = RETAIN(aDocument);
      psDevice = NULL;
   }

   return self;
}


- (void) dealloc
{
   RELEASE(document);
   [super dealloc];
}


- (void) beginDocument
{
   NSGraphicsContext* ctx = [NSGraphicsContext currentContext];

   DPSPrintf(ctx, "%% ---- BeginDocument\n");
   [super beginDocument];

   psDevice = PDFPS_CreateOutputDevice([document xpdfobject],
                                       1,
                                       [document countPages]);
}


- (void) beginPageInRect: (NSRect)aRect atPlacement:(NSPoint) aLocation
{
   return;
}


- (void) drawRect: (NSRect)aRect
{
   NSGraphicsContext* ctx = [NSGraphicsContext currentContext];

   NSAssert(psDevice, @"no postscript device");

   if ([ctx isDrawingToScreen])
   {
      NSLog(@"A PDFPrintView cannot draw to a screen");
      return;
   }

   NSLog(@"CHECKPOINT");
   DPSPrintf(ctx, "%% ---- Page\n");
   PDFPS_OutputPages([document xpdfobject],
                     psDevice,
                     1,
                     1);
}


- (void) endPage
{
   return;
}


- (void) endDocument
{
   NSGraphicsContext* ctx = [NSGraphicsContext currentContext];

   NSAssert(psDevice, @"no postscript device");

   DPSPrintf(ctx, "%% ---- EndDocument\n");

   PDFPS_DestroyOutputDevice(psDevice);
   psDevice = NULL;

   [super endDocument];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PDFPrintView (Private)
@end
