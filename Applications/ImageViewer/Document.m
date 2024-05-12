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

static NSWindow* _lastMainWindow;

@implementation Document

+ (Document*) lastActiveDocument {
  return (Document*)[_lastMainWindow delegate];
}

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Document" owner:self];
  [imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
  return self;
}

- (void) dealloc {
  [fileName release];
  fileName = nil;

  [imageView setImage:nil];
  imageView = nil;

  [originalImage release];
  originalImage = nil;

  [super dealloc];
}

- (NSString*) fileName {
  return fileName;
}

- (NSWindow*) window {
  return window;
}

- (void) showWindow {
  [window setFrameAutosaveName:@"image_window"];
  [window makeFirstResponder:imageView];
  [self resizeToFit:self];

  if (!_lastMainWindow) _lastMainWindow = [[NSApp orderedWindows] lastObject];
  if (_lastMainWindow) {
    NSRect  r = [_lastMainWindow frame];
    NSPoint p = r.origin;

    p.x += 24;
    p.y -= 24;
    [window setFrameOrigin:p];
  }

  [window makeKeyAndOrderFront:self];
}

- (id)validRequestorForSendType:(NSString *)st
                     returnType:(NSString *)rt {
  if ([fileName length]) {
    if ([st isEqual:NSFilenamesPboardType]) return self;
  }
  return nil;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pb
                             types:(NSArray *)types {
  if ([fileName length]) {
    [pb declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    [pb setPropertyList:[NSArray arrayWithObject:fileName] forType:NSFilenamesPboardType];
    return YES;
  } else {
    return NO;
  }
}

- (BOOL) readFromPasteboard:(NSPasteboard*) pboard {
  NSData* data = [pboard dataForType:NSTIFFPboardType];
  if (data) {
    NSImage* img = [[NSImage alloc] initWithData:data];
    [self setImage:img];
    [img release];
    return YES;
  }
  else {
    return NO;
  }
}

- (NSRect) selection {
  return [imageView selectedRectangle];
}

- (void) setSelection:(NSRect) r {
}

- (NSImage*) image {
  return [imageView image];
}

- (void) setImage:(NSImage*) img {
  ASSIGN(originalImage, img);

  [imageView setFrameSize:[img size]];
  [imageView setImage:img];
  [self resizeToFit:nil];
}

- (void) displayFile:(NSString*) path {
  NSImage* img = [[NSImage alloc] initWithContentsOfFile:path];
  if (!img) {
    NSLog(@"try to use filter");
    NSPasteboard* pboard = [NSPasteboard pasteboardByFilteringFile:path];
    NSData* data = [pboard dataForType:NSTIFFPboardType];
    if (data) {
      img = [[NSImage alloc] initWithData:data];
    }
  }
  [self setImage:img];
  [img release];

  ASSIGN(fileName, path);

  [self updateTitle:path];
}

- (void) updateTitle:(NSString*) path {
  NSString* name = [path lastPathComponent];
  NSString* dir  = [path stringByDeletingLastPathComponent];
  dir            = [dir stringByAbbreviatingWithTildeInPath];

  [window setTitle:[NSString stringWithFormat:@"%@ (%@)", name, dir]];
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
  NSPasteboard* pboard = [NSPasteboard generalPasteboard];
  [self readFromPasteboard:pboard];
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
  if (fileName) {
    [self writeToFile:fileName];
  }
  else {
    NSSavePanel* panel = [NSSavePanel savePanel];
    if ([panel runModal]) {
      NSString* path = [panel filename];

      [self writeToFile:path];
      [self updateTitle:path];

      ASSIGN(fileName, path);
    }
  }
}

- (void) saveDocumentAs:(id)sender {
  NSSavePanel* panel = [NSSavePanel savePanel];
  if ([panel runModal]) {
    NSString* path = [panel filename];
    [self writeToFile:path];
  }
}

- (void) writeToFile:(NSString*) path {
  NSInteger type = [self typeForFilename:path];
  NSData* data = [[imageView image]TIFFRepresentation];
  NSBitmapImageRep* rep = [[[NSBitmapImageRep alloc]initWithData:data]autorelease];
  
  data = [rep representationUsingType:type properties:nil];
  [data writeToFile:path atomically:YES];
}

- (IBAction) revertDocumentToSaved:(id) sender {
  NSImage* img = originalImage;

  [imageView setFrameSize:[img size]];
  [imageView setImage:img];
  [self resizeToFit:nil];
}

- (IBAction) crop:(id) sender {
  NSRect r = [imageView selectedRectangle];
  NSImage* nimg = [imageView croppedImage:r];

  [imageView resetSelectionRectangle];
  [imageView setFrameSize:[nimg size]];
  [imageView setImage:nimg];

  [self resizeToFit:nil];
}

- (IBAction) cropAsNew:(id) sender {
  NSRect r = [imageView selectedRectangle];
  if (r.size.height == 0 || r.size.width == 0) return;

  Document* doc = [[Document alloc] init];
  NSImage* img = [imageView croppedImage:r];
  [doc setImage:img];
  [doc showWindow];
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
  _lastMainWindow = window;
  InspectorPanel* inspector = [InspectorPanel sharedInstance];
  [inspector updateSelection:[imageView selectedRectangle]];
  [inspector updateImageInfo:[imageView image]];
}

- (void) windowWillClose:(NSNotification *)notification {
  if (_lastMainWindow == window) _lastMainWindow = nil;

  [window setDelegate: nil];
  [self release];
}

@end
