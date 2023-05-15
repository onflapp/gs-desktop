#import "Document.h"
#import "InspectorPanel.h"

@implementation Document (scripting)

- (BOOL) writeImageDataToFile:(NSString*) path {
  NSData* data = [originalImage TIFFRepresentation];
  return [data writeToFile:path atomically:NO];
}

- (BOOL) readImageDataFromFile:(NSString*) path {
  NSImage* img = [[NSImage alloc] initWithContentsOfFile:path];
  if (!img) return NO;
  
  [self setImage:img];
  [img release];
  return YES;
}

@end
