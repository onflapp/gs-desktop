#import "Document.h"

@implementation Document(scripting)

- (void) searchText:(NSString*) text {
  [self showWindow];
  [queryField setStringValue:text];
  [self search:self];
}


@end
