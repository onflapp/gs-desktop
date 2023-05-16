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

- (NSArray*) documents {
  NSMutableSet* ls = [NSMutableSet setWithCapacity:1];

  for (NSWindow* win in [NSApp windows]) {
    id del = [win delegate];
    if ([del isKindOfClass:[Document class]]) {
      [ls addObject:del];
    }
  }
  return [ls allObjects];
}

- (Document*) currentDocument {
  return [Document lastActiveDocument];
}

@end
