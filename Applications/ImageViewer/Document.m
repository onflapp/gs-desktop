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
#import "InspectorPanel.h"

@implementation Document

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Document" owner:self];
  [window setFrameAutosaveName:@"image_window"];
  [window makeFirstResponder:imageView];
  [window makeKeyAndOrderFront:self];

  [imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
  return self;
}

- (void) dealloc {
  [originalImage release];
  [super dealloc];
}

- (void) readFromPasteboard {
  NSPasteboard* pboard = [NSPasteboard generalPasteboard];
  NSData* data = [pboard dataForType:NSTIFFPboardType];
  if (data) {
    NSImage* img = [[NSImage alloc] initWithData:data];
    if (img) {
      [originalImage release];
      originalImage = [img retain];

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
    [originalImage release];
    originalImage = [img retain];

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
  NSSize sz = [imageView frame].size;
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

- (IBAction) revertDocumentToSaved:(id) sender {
  NSImage* img = originalImage;

  [imageView setFrameSize:[img size]];
  [imageView setImage:img];
  [self resizeToFit:nil];
}

- (IBAction) crop:(id) sender {
  NSImage* img = [imageView image];
  NSRect r1 = NSMakeRect(0, 0, img.size.width, img.size.height);
  NSRect r2 = [imageView selectedRectangle];
  NSImageRep* rep = [img bestRepresentationForRect:r1 context:nil hints:nil];

  NSImage* nimg = [[NSImage alloc] initWithSize:r2.size];
  [nimg lockFocus];
  [rep setSize:img.size];
  [rep drawInRect:NSMakeRect(0, 0, r2.size.width, r2.size.height) 
         fromRect:r2
        operation:NSCompositeCopy
         fraction:1.0
   respectFlipped:YES
            hints:nil];
  [nimg unlockFocus];

  [imageView resetSelectionRectangle];
  [imageView setFrameSize:[nimg size]];
  [imageView setImage:nimg];
  [nimg release];

  [self resizeToFit:nil];
}

- (IBAction) zoomIn:(id) sender {
  [imageView zoomIn:sender];
  [self resizeToFit:sender];
}

- (IBAction) zoomOut:(id) sender {
  [imageView zoomOut:sender];
  [self resizeToFit:sender];
}

- (void) windowDidBecomeMain: (NSNotification*)aNotification {
  [[InspectorPanel sharedInstance] updateSelection:[imageView selectedRectangle]];
}

@end
