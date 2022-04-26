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

#ifndef _H_PDFOUTLINE
#define _H_PDFOUTLINE

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>


/* Outline of a PDFDocument.  */
@interface PDFOutline : NSObject
{
   NSArray* items;
   void*    xpdfOutlineItems;
   id       xpdfDocRef;
}

- (id) initWithOutlineItems: (void*)xpdfItems ofDocument: (id)aDocRef;
- (void) dealloc;

- (NSArray*) items;

@end


@interface PDFOutlineItem : NSObject
{
   NSString*  title;
   NSArray*   kids;
   void*      xpdfOutlineItem;
   id         xpdfDocRef;
}

- (id) initWithOutlineItem: (void*)xpdfItem ofDocument: (id)aDocRef;
- (void) dealloc;

- (NSString*) title;
- (int) destinationPage;

- (BOOL) hasKids;
- (NSArray*) kids;
- (int) countKids;

@end

#endif
