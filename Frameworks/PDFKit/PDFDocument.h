/*
 * Copyright (C) 2003  Stefan Kleine Stegemann
 *           (C) 2016  The GNUstep Application Team
 *
 * Authors: Stefan Kleine Stegemann
 *          Riccardo Mottola
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

#ifndef _H_PDF_DOCUMENT
#define _H_PDF_DOCUMENT

#import <Foundation/Foundation.h>

@class PDFSearchContext;
@class PDFOutline;

/**
 * Provides a wrapper for an XPDF PDFDoc object. Such
 * an object provides access to the meta-data of a
 * PDF document as well as to the document content.  
 */
@interface PDFDocument : NSObject
{
   id          pdfDocRef;
   PDFOutline* outline;
   NSMutableString *textContents;
   NSMutableDictionary *documentInfo;
}

- (id) init;
- (void) dealloc;
+ (void) initialize;

/* Create a new PDF Document from an input file. 
 * If the document could not be created, an invalid
 * Document is returned (isOk returns NO). Use errorCode
 * to get the reason of the failure.
 * All returned objects are autoreleased. */
+ (PDFDocument*)documentFromFile: (NSString*)fileName;

+ (PDFDocument*)documentFromFile: (NSString*)fileName 
                   ownerPassword: (NSString*)ownerPassword
                    userPassword: (NSString*)userPassword;

- (BOOL) isOk;
- (int) errorCode;

- (double) pageWidth: (int)pageNum;
- (double) pageHeight: (int)pageNum;
- (NSSize) pageSize: (int)pageNum considerRotation: (BOOL)rotation;
- (int) pageRotate: (int)pageNum;

/** deprecated since different from Apple */
- (int) countPages;
- (NSUInteger) pageCount;

/** Returns nil if no MetaData is available
 *  otherwise an autoreleases string object.  */
- (NSString*) metaData; 

- (BOOL) hasOutline;
- (PDFOutline*) outline;

/** It is recommened to use the search-context based
 *  methods.  */
- (BOOL) findText: (NSString*)text
             page: (int*)pageNum
           toPage: (int)maxPage
         position: (NSRect*)pos
          context: (NSString**)context;

/** Create a search context for the receiver. Using a search
 *  context can speed up a search if the document is searched
 *  for text subsequently.  */
- (PDFSearchContext*) createSearchContext;

/** Find the next occurence of a text fragment starting a the
 *  specified position. If a match was found, the method returns
 *  YES and aTextContext contains the text around the occurence of
 *  the text fragment. Otherwise NO is returned and aTextContext is
 *  undefined.  */
- (BOOL) findText: (NSString*)aText
usingSearchContext: (PDFSearchContext*)aSearchContext
             page: (int*)pageNum
           toPage: (int)maxPage
         position: (NSRect*)pos
      textContext: (NSString**)aTextContext;

- (NSString *)getAllText;
- (NSDictionary *)getDocumentInfo;

- (NSString*) getTextAtPage: (int)pageNum inRect: (NSRect)pos;

@end


/**
 * A search context holds some data to improve the speed
 * of subsequent searches in the same document. There is
 * no need for the programmer to know what's going on
 * inside.
 */
@interface PDFSearchContext : NSObject
{
   void*         theSearchContext;
   PDFDocument*  theDocument;
}

/** Initialize a search context for use with a specific
 *  PDFDocument. The receiver does not retain the document. */
- (id) initWithDocument: (PDFDocument*)aDocument;

/** Get the document the receiver is associated to.  */
- (PDFDocument*) document;

@end


/**
 * Only for internal usage.
 */
@interface PDFDocument(Wrapper)

/** Returns the internal wrapped object. */
- (void*) xpdfobject;

@end

#endif
