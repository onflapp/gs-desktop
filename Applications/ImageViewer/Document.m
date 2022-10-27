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

#import "Document.h"
#import <dispatch/dispatch.h>

@implementation Document

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Document" owner:self];
  [window setFrameAutosaveName:@"image_window"];
  [window makeKeyAndOrderFront:self];
    
  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (void) readFromPasteboard {
  NSPasteboard* pboard = [NSPasteboard generalPasteboard];
  NSData* data = [pboard dataForType:NSTIFFPboardType];
  if (data) {
    NSImage* img = [[NSImage alloc] initWithData:data];
    if (img) {
      [imageView setFrameSize:[img size]];
      [imageView setImage:img];
      [img release];
      [self resizeToFit:nil];
    }
  }
}

- (void) displayFile:(NSString*) path {
  NSImage* img = [[NSImage alloc] initWithContentsOfFile:path];
  if (!img) {
    NSPasteboard* pboard = [NSPasteboard pasteboardByFilteringFile:path];
    NSData* data = [pboard dataForType:NSTIFFPboardType];
    if (data) {
      img = [[NSImage alloc] initWithData:data];
    }
  }
  if (img) {
    [imageView setFrameSize:[img size]];
    [imageView setImage:img];
    [img release];
    [self resizeToFit:nil];
  }
}

- (NSInteger) typeForFilename:(NSString*) path {
  NSString* ext = [path pathExtension];
  if ([ext isEqualToString:@"png"]) {
    return NSPNGFileType;
  }
  else if ([ext isEqualToString:@"jpg"]) {
    return NSJPEGFileType;
  }
  else if ([ext isEqualToString:@"gif"]) {
    return NSGIFFileType;
  }
  else if ([ext isEqualToString:@"bmp"]) {
    return NSBMPFileType;
  }
  else {
    return NSTIFFFileType;
  }
}

- (void) resizeToFit:(id)sender {
  NSSize sz = [[imageView image]size];
  if (sz.width > 1000) sz.width = 1000;
  if (sz.width < 30) sz.width = 30;
  if (sz.height > 1000) sz.height = 1000;
  if (sz.height < 30) sz.height = 30;
  
  sz.width += 25;
  sz.height += 25;
  [window setContentSize:sz];
}

- (void) paste:(id)sender {
  [self readFromPasteboard];
}

- (void) copy:(id)sender {
  NSImage* image = [imageView image];
  if (image) {
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObjects:NSTIFFPboardType, nil] owner:nil];
    [pboard setData:[image TIFFRepresentation] forType:NSTIFFPboardType];
  }
}

- (void) saveDocument:(id)sender {
  NSSavePanel* panel = [NSSavePanel savePanel];
  if ([panel runModal]) {
    NSString* filename = [panel filename];
    NSInteger type = [self typeForFilename:filename];
    NSData* data = [[imageView image]TIFFRepresentation];
    NSBitmapImageRep* rep = [[[NSBitmapImageRep alloc]initWithData:data]autorelease];
    data = [rep representationUsingType:type properties:nil];
    [data writeToFile:filename atomically:YES];
  }
}

@end
