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
- (void) windowWillClose:(NSNotification*)aNotification {
  [NSApp terminate:self];
}
@end

void printUsage() {
  fprintf(stderr, "Usage: shellui <gorm file> <shell file> <args...>\n");
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
    if ([arguments count] < 3)  {
      printUsage();
      rv = 1;
    }
    else {
      NSString* script   = [arguments objectAtIndex:2];
      NSString* gorm     = [arguments objectAtIndex:1];
      NSMutableArray* ha = [NSMutableArray array];
      NSApplication* app = [NSApplication sharedApplication];
      Delegate* del      = [[Delegate alloc]init];

      [app setDelegate:del];

      for (NSInteger n = 3; n < [arguments count]; n++) {
        [ha addObject:[arguments objectAtIndex:n]];
      }

      ShellUITask* shelltask = [[ShellUITask alloc]initWithScript:script];
      ShellUIProxy* shellui = [[ShellUIProxy alloc]init];

      NSMutableDictionary* o = [NSMutableDictionary dictionary];
      [o setValue:shellui forKey:@"NSOwner"];
      [NSBundle loadNibFile:gorm externalNameTable:o withZone:nil];
      
      [[shellui window]setDelegate:del];
      [shellui handleActions:shelltask withArguments:ha];

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

