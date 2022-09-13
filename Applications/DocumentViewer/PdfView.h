#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PdfView : NSView {
  NSImageView* imageView;
}

- (void) displayFile:(NSString*) path;

@end

