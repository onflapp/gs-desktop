#include <AppKit/AppKit.h>

#include "NSMenu+Suppress.h"

@implementation NSMenu (Supress)

- (void) show 
{
  [self display];
}

@end
