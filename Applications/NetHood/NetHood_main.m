/* 
   Project: NetHood

   Author: Ondrej Florian,,,

   Created: 2023-09-06 23:21:19 +0200 by oflorian
*/

#import <AppKit/AppKit.h>

int 
main(int argc, const char *argv[])
{
// Uncomment if your application is Renaissance application
/*  CREATE_AUTORELEASE_POOL (pool);
  [NSApplication sharedApplication];
  [NSApp setDelegate: [AppController new]];

  #ifdef GNUSTEP
    [NSBundle loadGSMarkupNamed: @"MainMenu-GNUstep"  owner: [NSApp delegate]];
  #else
    [NSBundle loadGSMarkupNamed: @"MainMenu-OSX"  owner: [NSApp delegate]];
  #endif
   
  RELEASE (pool);
*/

  return NSApplicationMain (argc, argv);
}

