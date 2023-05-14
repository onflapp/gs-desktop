/* 
*/

#import "AppController.h"
#import "Document.h"

@implementation AppController (scripting)

- (Document*) newDocument {
  Document* doc = [[Document alloc] init];
  [doc showWindow];
  return doc;
}

@end
