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
    scrollView = [[NSScrollView alloc] initWithFrame:rect];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setHasVerticalScroller:YES];
    [self addSubview:scrollView];
    [scrollView setDocumentView:imageView]; 
  }
  return self;
}

- (void)dealloc  {
  RELEASE (imageRep);
  RELEASE (imageView);
  RELEASE (scrollView);
  RELEASE (doc);

  [super dealloc];
}

- (BOOL) loadFile:(NSString *)path {  
  doc = [[PDFDocument documentFromFile:path] retain];

  if ([doc isOk] && ([doc errorCode] == 0)) {
      imageRep = [[PDFImageRep alloc] initWithDocument:doc];
      return YES;
  }
  else {
    return NO;
  }
}

- (NSInteger) countPages {
  return [doc countPages];
}

- (NSInteger) displayedPage {
  return currentPage;
}

- (void) displayPage:(NSUInteger) page {
  NSSize imageSize = NSMakeSize([doc pageWidth:page],
                                [doc pageHeight:page]);

  [imageRep setSize:imageSize];    
  [imageRep setResolution:72];
  [imageRep setPageNum:page];
  
  NSLog(@"1");
  NSImage* image = [[[NSImage alloc] initWithSize:imageSize] autorelease];
  [image setBackgroundColor: [NSColor whiteColor]];
  [image addRepresentation:imageRep];
  [imageView setFrameSize:imageSize];
  [imageView setImageScaling:NSImageScaleNone];
  [imageView setImage:image];
  
  NSLog(@"2");
  currentPage = page;
}

- (void) resizeWithOldSuperviewSize:(NSSize) sz {
  [super resizeWithOldSuperviewSize:sz];
  [scrollView setFrame:[self frame]];
}
@end

