/* Copyright (C) 2020 Free Software Foundation, Inc.

   Written by: onflapp
   Created: September 2020

   This file is part of the NEXTSPACE Project

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
#import <DesktopKit/NXTDefaults.h>
#import "nxdisplay.h"

void printUsage() {
  fprintf(stderr, "Usage: nxdisplay\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Help: conntrol display command line\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  --set volume\n");
  fprintf(stderr, "  --increase\n");
  fprintf(stderr, "  --decrease\n");
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

  OSEScreen* systemScreen = [OSEScreen new];
  OSEDisplay* display = nil;
  for (OSEDisplay *d in [systemScreen connectedDisplays]) {
    if ([d isDisplayBrightnessSupported]) {
      display = d;
      break;
    }
  }

  if (!display) {
    NSLog(@"no display with backlight found");
    exit(3);
  }

  @try {
    if ([arguments count] == 1) {
      printUsage();
      exit(1);
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--set"] && [arguments count] >= 2 ) {
      NSInteger v = [[arguments objectAtIndex:2] integerValue];
      [display setDisplayBrightness:(CGFloat)v];
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--increase"]) {
    }
    else if ([[arguments objectAtIndex:1] isEqualToString:@"--decrease"]) {
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
