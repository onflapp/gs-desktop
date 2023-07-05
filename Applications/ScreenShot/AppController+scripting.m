#import "AppController.h"

@implementation AppController(scripting)

- (void) grabScreen
{
  [self execScrot:1];
}
- (void) grabWindow
{
  [self execScrot:2];
}
- (void) grabSelection
{
  [self execScrot:3];
}

@end
