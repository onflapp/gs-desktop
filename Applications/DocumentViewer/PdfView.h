#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <PDFKit/PDFDocument.h>
#import <PDFKit/PDFImageRep.h>

@interface PdfView : NSView {
  PDFDocument* doc;
  NSImageView* imageView;
  PDFImageRep* imageRep;
  NSScrollView* scrollView;
  
  NSInteger currentPage;
}

- (BOOL) loadFile:(NSString*) path;
- (void) displayPage:(NSUInteger) page;

- (NSInteger) displayedPage;
- (NSInteger) countPages;

@end

