/* PdfViewer.m
 *  
 * Copyright (C) 2004-2012 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: January 2004
 *
 * This file is part of the GNUstep Inspector application
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <math.h>

#import <AppKit/AppKit.h>
#import <PDFKit/PDFDocument.h>
#import <PDFKit/PDFImageRep.h>
#import "PdfView.h"

#define MAXPAGES 9999

const double PDFResolution = 72.0;

@implementation PdfView

- (id)initWithFrame:(NSRect)rect {
  self = [super initWithFrame:rect];
  
  if(self) {
    imageView = [[NSImageView alloc] initWithFrame:rect];
    [self addSubview:imageView]; 
  }
  return self;
}

- (void)dealloc  {
  RELEASE (imageView);

  [super dealloc];
}

- (void) displayFile:(NSString *)path {
  PDFDocument *doc;
  NSLog(@">>> %@", path);
  
  //ASSIGN (pdfPath, path);
  
  doc = [PDFDocument documentFromFile:path];

  if ([doc isOk] && ([doc errorCode] == 0)) {
    //npages = [doc countPages];
    
    NSSize imageSize = NSMakeSize([doc pageWidth:1],
                                  [doc pageHeight:1]);

    PDFImageRep* imageRep = [[PDFImageRep alloc] initWithDocument:doc];
    //[imageRep setSize: imageSize];
    
      //[imageRep setPageNum: index];
  
    NSImage* image = [[NSImage alloc] initWithSize: [imageRep size]];
    [image setBackgroundColor: [NSColor whiteColor]];
    [image addRepresentation:imageRep];
    [imageView setImage:image];

    RELEASE (image);
  }
}

@end

