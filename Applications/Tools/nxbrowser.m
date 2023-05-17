/* Copyright (C) 2020 Free Software Foundation, Inc.

   Written by: onflapp
   Created: September 2020

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

void printUsage() {
  fprintf(stderr, "Usage: nxbrowser <url> [--open <url>] [--seach <text>]\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Help: open url in the WebBrowser.app\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  --open <url>         \n");
  fprintf(stderr, "  --search <text>      \n");
  fprintf(stderr, "\n");
}

int main(int argc, char** argv, char** env)
{
  NSProcessInfo *pInfo;
  NSArray *arguments;
  CREATE_AUTORELEASE_POOL(pool);

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env_c];
#endif

  pInfo = [NSProcessInfo processInfo];
  arguments = [pInfo arguments];

   //register service types, this will refresh the service manager
   id app = [NSApplication sharedApplication]; 
   [app registerServicesMenuSendTypes:[NSArray arrayWithObject:NSPasteboardTypeString] 
                          returnTypes:[NSArray arrayWithObject:NSPasteboardTypeString]];

  @try {
    if ([arguments count] == 1) {
      printUsage();
      exit(1);
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--open"] && [arguments count] >= 3 ) {
      NSWorkspace* ws = [NSWorkspace sharedWorkspace];
      NSURL* url = [NSURL URLWithString:[arguments objectAtIndex:2]];
      if (url) {
	[ws openURL:url];
      }
      else {
	NSLog(@"invalid URL");
	exit(2);
      }
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--search"] && [arguments count] >= 3 ) {
      NSString* text = [arguments objectAtIndex:2];
      if ([text length] > 0) {
        NSString* serviceMenu = @"WebBrowser/Search Selection";
        NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
        [pboard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
        [pboard setString:text forType:NSPasteboardTypeString];

        NSPerformService(serviceMenu, pboard);
      }
      else {
	NSLog(@"invalid search query");
	exit(2);
      }
    }
    else if ([arguments count] >= 2) {
      NSWorkspace* ws = [NSWorkspace sharedWorkspace];
      NSURL* url = [NSURL URLWithString:[arguments objectAtIndex:1]];
      if (url) {
	[ws openURL:url];
      }
      else {
	NSLog(@"invalid URL");
	exit(2);
      }
    }
    else {
      printUsage();
      exit(1);
    }
  }
  @catch (NSException* ex) {
    NSLog(@"exception: %@", ex);
    printUsage();
    exit(6);
  }

  RELEASE(pool);

  exit(EXIT_SUCCESS);
}

