/* 
  Project: DispMon

  Author: Ondrej Florian,,,

  Created: 2022-10-21 09:49:06 +0200 by oflorian
*/

#import <AppKit/AppKit.h>

int 
main(int argc, const char *argv[])
{
  /* 
   * I tried to get UseWindowMakerIcons working in order to avoid patching GNUstep
   * but there are too many problems with this approach
   *
   * 1. redraw issues (sometimes the view does redraw)
   * 2. autostart problems (it seems like WM tries to reparet the icon window?)
   * 3. sometimes WM fails to grabs icon window for dragging (unable to move icon window)

  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"UseWindowMakerIcons"];
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];

  */
  return NSApplicationMain (argc, argv);
}

