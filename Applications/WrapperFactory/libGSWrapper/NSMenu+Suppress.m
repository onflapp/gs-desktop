#include <AppKit/AppKit.h>

#include "NSMenu+Suppress.h"

@implementation NSMenu (Supress)

- (BOOL) _isMain
{
  if ([NSApp suppressActivation])
    return NO;
  else
    return [NSApp mainMenu] == self;
}

- (void) show 
{
  [self display];
}

@end
