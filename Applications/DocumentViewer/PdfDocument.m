/*
   Project: WebBrowser

   Copyright (C) 2020 Free Software Foundation

   Author: onflapp

   Created: 2020-07-22 12:41:08 +0300 by root

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "PdfDocument.h"

@implementation PdfDocument

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"PdfDocument" owner:self];
  
  [super initNavigation];
  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (void) loadFile:(NSString*) path {
  [window setTitle:path];
  [statusField setStringValue:@"loading pdf"];

  [pdfView loadFile:path];
  
  [self displayNavigation];
  [self displayPage:1];

  ASSIGN (fileName, path);
}

- (void) displayPage:(NSInteger) page {
  if (isWorking) return;

  isWorking = YES;
  pageToShow = page;

  [super displayPage:page];

  [self performSelector:@selector(refreshCurrentPage) withObject:nil afterDelay:0.1];
}

- (void) refreshCurrentPage {
  [pdfView displayPage:pageToShow];
  isWorking = NO;
}

- (NSInteger) currentPage {
  return [pdfView displayedPage];
}

- (NSInteger) pageCount {
  return [pdfView countPages];
}

@end
