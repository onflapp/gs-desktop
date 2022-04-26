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

#import <PDFKit/PDFOutline.h>
#include "XPDFBridge.h"
#include "CountingRef.h"

#import <Foundation/NSException.h>


/*
 * Non-Public methods of PDFOutlineItem.
 */
@interface PDFOutlineItem(Private)
- (void) setTitle: (NSString*)_title;
@end


NSArray* buildItemsArray(XPDFObject* outlineItems, CountingRef* pdfDocRef)
{
   NSMutableArray* items = [[NSMutableArray alloc] initWithCapacity: 0];
   int i;

   for (i = 0; i < PDFOutline_CountItems(outlineItems); i++)
   {
      NSString* title;
      char*     titleBuffer;

      XPDFObject xpdfItem = PDFOutline_ItemAt(outlineItems, i);
      id outlineItem = [[PDFOutlineItem alloc] initWithOutlineItem: xpdfItem
                                                        ofDocument: pdfDocRef];

      titleBuffer = PDFOutline_GetTitle(xpdfItem);
      title = [[NSString alloc] initWithCString: titleBuffer];
      free(titleBuffer);
      [outlineItem setTitle: title];
      
      [items addObject: outlineItem];
      RELEASE(outlineItem);
   }

   return items;
}


@implementation PDFOutline

- (id) initWithOutlineItems: (void*)xpdfItems ofDocument: (id)aDocRef
{
   if ((self = [super init]))
   {
      NSAssert(xpdfItems, @"OutlineItems(xpdf) is NULL");
      items = nil;
      xpdfOutlineItems = xpdfItems;
      xpdfDocRef = RETAIN(aDocRef);
   }

   return self;
}


- (void) dealloc
{
   [items release];
   RELEASE(xpdfDocRef);

   [super dealloc];
}


- (NSArray*) items
{
   if (!items)
   {
      items = buildItemsArray(xpdfOutlineItems, xpdfDocRef);
   }

   return items;
}

@end


/*
 * An item of an PDFDocument Outline.
 */
@implementation PDFOutlineItem

- (id) initWithOutlineItem: (void*)xpdfItem ofDocument: (id)aDocRef
{
   if ((self = [super init]))
   {
      NSAssert(xpdfItem, @"OutlineItem(xpdf) is NULL");
      title = nil;
      kids  = nil;
      xpdfOutlineItem = xpdfItem;
      xpdfDocRef = RETAIN(aDocRef);
      PDFOutline_ItemOpen(xpdfOutlineItem);
   }

   return self;
}


- (void) dealloc
{
   PDFOutline_ItemClose(xpdfOutlineItem);

   [title release];
   [kids release];

   RELEASE(xpdfDocRef);

   [super dealloc];
}


- (void) setTitle: (NSString*)_title
{
   title = _title;
}

- (NSString*) title
{
   return title;
}


- (int) destinationPage
{
   return PDFOutline_GetTargetPage(xpdfOutlineItem, [xpdfDocRef pointer]);
}


- (BOOL) hasKids
{
   return PDFOutline_HasKids(xpdfOutlineItem);
}


- (NSArray*) kids
{
   if (!kids)
   {
      if ([self hasKids])
      {
         kids = buildItemsArray(PDFOutline_GetKids(xpdfOutlineItem), xpdfDocRef);
      }
      else
      {
         kids = [[NSArray alloc] init];
      }
   }

   return kids;
}


- (int) countKids
{
   return [[self kids] count];
}


@end
