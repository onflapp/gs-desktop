#import "Document.h"
#import "InspectorPanel.h"

@implementation Document (scripting)

- (BOOL) writeImageDataToFile:(NSString*) path {
  NSData* data = [originalImage TIFFRepresentation];
  return [data writeToFile:path atomically:NO];
}

@end
