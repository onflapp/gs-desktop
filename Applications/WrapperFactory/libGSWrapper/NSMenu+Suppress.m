#include <AppKit/AppKit.h>

#include "NSMenu+Suppress.h"

@implementation NSMenu (Supress)

- (BOOL) _isMain
{
  return NO;
}

- (void) show 
{
  [self display];
}

@end
