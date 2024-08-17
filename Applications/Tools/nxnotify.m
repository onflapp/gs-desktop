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
#import "nxnotify.h"

@interface NotMonApp
- (void) showModalPanelWithTitle:(NSString*) title
                            info:(NSString*) info
                           delay:(NSTimeInterval) delay;
- (void) showPanelWithTitle:(NSString*) title
                       info:(NSString*) info
                      delay:(NSTimeInterval) delay;
- (void) hidePanelAfter:(NSTimeInterval) time;
@end

void printUsage() {
  fprintf(stderr, "Usage: nxnotify\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Help: send notification from the command line\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  show-panel --title <text> --info <text>\n");
  fprintf(stderr, "  show-panel --title <text> --info <text> --hide-panel <timeout>\n");
  fprintf(stderr, "  show-modal-panel --title <text> --info <text> --hide-panel <timeout>\n");
  fprintf(stderr, "  hide-panel\n");
  fprintf(stderr, "  show-message --title <text> --info <text>\n");
  fprintf(stderr, "  show-console --cmd <command> --arg <text>\n");
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

  @try {
    if ([arguments count] == 1) {
      printUsage();
      exit(1);
    }
    else if ([arguments count] >= 2 ) {
      NSEnumerator* en = [arguments objectEnumerator];
      [en nextObject];

      NSInteger type = 0;
      NSString* title = nil;
      NSString* cmd = nil;
      NSString* arg = nil;
      NSString* info = nil;
      NSTimeInterval hide = -1;

      id it = nil;
      while (it = [en nextObject]) {
        if ([it isEqualToString:@"--title"]) {
          title = [en nextObject];
        }
        else if ([it isEqualToString:@"--info"]) {
          info = [en nextObject];
        }
        else if ([it isEqualToString:@"--cmd"]) {
          cmd = [en nextObject];
        }
        else if ([it isEqualToString:@"--arg"]) {
          arg = [en nextObject];
        }
        else if ([it isEqualToString:@"show-panel"]) {
          type = 1;
        }
        else if ([it isEqualToString:@"show-modal-panel"]) {
          type = 4;
        }
        else if ([it isEqualToString:@"show-message"]) {
          type = 2;
        }
        else if ([it isEqualToString:@"show-console"]) {
          type = 3;
        }
        else if ([it isEqualToString:@"hide-panel"]) {
          type = 5;
          hide = 0;
        }
        else if ([it isEqualToString:@"--hide-panel"]) {
          hide = [[en nextObject] floatValue];
        }
      }

      id app = (NotMonApp*)[NSConnection rootProxyForConnectionWithRegisteredName:@"NotMon" host:@""];
      if (!app) {
        NSLog(@"unable to contact app NotMon");
        exit(1);
      }

      if (type == 1) {
        if (hide <= 0) hide = 5.0;
        [app showPanelWithTitle:title info:info delay:hide];
      }
      else if (type == 4) {
        if (hide <= 0) hide = 5.0;
        [app showModalPanelWithTitle:title info:info delay:hide];
      }
      else if (type == 2) {
        if (cmd) {
          NSMutableString* str = [NSMutableString string];
          if (cmd) [str appendString:cmd];
          if (arg) [str appendFormat:@" %@", arg];

          [app showMessageWithTitle:title info:info action:str];
        }
        else {
          [app showMessageWithTitle:title info:info];
        }
      }
      else if (type == 3) {
        [app showConsoleWithCommand:cmd argument:arg];
      }
      else if (type == 5) {
        [app hidePanelAfter:hide];
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

