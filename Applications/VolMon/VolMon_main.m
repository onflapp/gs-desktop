/* 
   Project: VolMon

   Author: Ondrej Florian,,,

   Created: 2022-10-21 09:49:06 +0200 by oflorian
*/

#import <AppKit/AppKit.h>

int 
main(int argc, const char *argv[])
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"UseWindowMakerIcons"];
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];

  return NSApplicationMain (argc, argv);
}

