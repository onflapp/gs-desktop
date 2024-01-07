/* Copyright (C) 2020 Free Software Foundation, Inc.

   Written by:  onflapp
   Created: September 2020

   This file is part of the gs-desktop Project

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   You should have received a copy of the GNU General Public
   License along with this program; see the file COPYING.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

   */

#import	<AppKit/AppKit.h>
#import "shellui.h"
#import "ShellUIProxy.h"
#import "ShellUITask.h"

@implementation Delegate
- (void) applicationDidFinishLaunching:(id) not {
}
- (BOOL) application:(NSApplication*)app openFile:(NSString*) fileName {
  return YES;
}
@end

void printUsage() {
  fprintf(stderr, "Usage: nxprompt --secret --field <val> --message <val> --title <val> --value <val>\n");
  fprintf(stderr, "\n");
}

int main(int argc, char** argv, char** env) {
  
  NSProcessInfo *pInfo;
  NSArray *arguments;
  CREATE_AUTORELEASE_POOL(pool);

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env_c];
#endif

  pInfo = [NSProcessInfo processInfo];
  arguments = [pInfo arguments];
  int rv = 1;

  @try {
    if ([arguments count] < 2)  {
      printUsage();
      rv = 1;
    }
    else {
      NSApplication* app = [NSApplication sharedApplication];
      Delegate* del = [[Delegate alloc]init];
      [app setDelegate:del];

      ShellUITask* shelltask = [[ShellUITask alloc]initWithScript:@"/home/oflorian/test.sh"];
      ShellUIProxy* shellui = [[ShellUIProxy alloc]init];

      [shellui handleActions:shelltask];

      NSMutableDictionary* o = [NSMutableDictionary dictionary];
      [o setValue:shellui forKey:@"NSOwner"];
      [NSBundle loadNibFile:@"/home/oflorian/test.gorm" externalNameTable:o withZone:nil];
      
      [app run];
    }
  }
  @catch (NSException* ex) {
    NSLog(@"exception %@", ex);
    printUsage();
    rv = 6;
  }

  RELEASE(pool);

  exit(rv);
}

