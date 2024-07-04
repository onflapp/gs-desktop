#include <libinput.h>
#include "input.h"
#import <Foundation/Foundation.h>

int main(int argc, char* argv[]) {
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  if (!initialize_context()) {
    NSLog(@"unable to initialize context");
    [pool release];
    return 1;
  }

  setbuf(stdout, NULL);
  start_loop();

  [pool release];
  return 0;
}
