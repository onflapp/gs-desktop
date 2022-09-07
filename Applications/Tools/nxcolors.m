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
#import <GNUstepGUI/GSTheme.h>

@implementation NSColor (StringRepresentation)

- (NSString *)stringRepresentation {
  CGFloat r, g, b, a;

  [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
  return [NSString stringWithFormat:@"#%02x%02x%02x",(unsigned int)round(255*r), (unsigned int)round(255*g), (unsigned int)round(255*b)];
}

@end

void printOut() {
  fprintf(stdout, "Usage: nxcolor [--system]\n");
}

void printUsage() {
  fprintf(stderr, "Usage: nxcolor [--system]\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Help: print standard colors\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  --system            system colors\n");
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
    if ([arguments count] == 1)  {
      printUsage();
      rv = 1;
    }
    else if ([arguments containsObject: @"--theme"] == YES) {
      GSTheme* theme = [GSTheme theme];
      NSColorList* colors = [theme colors];
      NSLog(@"control=%@", [[NSColor controlColor] stringRepresentation]);
      NSLog(@"controlBackground=%@", [[NSColor controlBackgroundColor] stringRepresentation]);
      NSLog(@"controlDarkShadow=%@", [[NSColor controlDarkShadowColor] stringRepresentation]);
      NSLog(@"controlLightHighlight=%@", [[NSColor controlLightHighlightColor] stringRepresentation]);
      NSLog(@"controlShadow=%@", [[NSColor controlShadowColor] stringRepresentation]);
      NSLog(@"controlText=%@", [[NSColor controlTextColor] stringRepresentation]);
      NSLog(@"selectedText=%@", [[NSColor selectedTextColor] stringRepresentation]);
      NSLog(@"selectedTextBackground=%@", [[NSColor selectedTextBackgroundColor] stringRepresentation]);
      NSLog(@"selectedMenuItem=%@", [[NSColor selectedMenuItemColor] stringRepresentation]);
      NSLog(@"selectedMenuItemText=%@", [[NSColor selectedMenuItemTextColor] stringRepresentation]);
      NSLog(@"selectedKnob=%@", [[NSColor selectedKnobColor] stringRepresentation]);
      NSLog(@"selectedControl=%@", [[NSColor selectedControlColor] stringRepresentation]);
      NSLog(@"selectedControlText=%@", [[NSColor selectedControlTextColor] stringRepresentation]);

      rv = EXIT_SUCCESS;
    }
    else if ([arguments containsObject: @"--system"] == YES) {
      NSLog(@"control=%@", [[NSColor controlColor] stringRepresentation]);
      NSLog(@"controlBackground=%@", [[NSColor controlBackgroundColor] stringRepresentation]);
      NSLog(@"controlDarkShadow=%@", [[NSColor controlDarkShadowColor] stringRepresentation]);
      NSLog(@"controlLightHighlight=%@", [[NSColor controlLightHighlightColor] stringRepresentation]);
      NSLog(@"controlShadow=%@", [[NSColor controlShadowColor] stringRepresentation]);
      NSLog(@"controlText=%@", [[NSColor controlTextColor] stringRepresentation]);
      NSLog(@"selectedText=%@", [[NSColor selectedTextColor] stringRepresentation]);
      NSLog(@"selectedTextBackground=%@", [[NSColor selectedTextBackgroundColor] stringRepresentation]);
      NSLog(@"selectedMenuItem=%@", [[NSColor selectedMenuItemColor] stringRepresentation]);
      NSLog(@"selectedMenuItemText=%@", [[NSColor selectedMenuItemTextColor] stringRepresentation]);
      NSLog(@"selectedKnob=%@", [[NSColor selectedKnobColor] stringRepresentation]);
      NSLog(@"selectedControl=%@", [[NSColor selectedControlColor] stringRepresentation]);
      NSLog(@"selectedControlText=%@", [[NSColor selectedControlTextColor] stringRepresentation]);

      rv = EXIT_SUCCESS;
    }
    else {
      printUsage();
      rv = 1;
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

