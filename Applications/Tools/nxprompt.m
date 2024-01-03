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
#import "nxprompt.h"

@implementation Delegate

- (NSWindow*) panel {
  return panel;
}

- (NSTextField*) field {
  return field;
}

- (NSTextField*) label {
  return label;
}

- (NSTextField*) message {
  return msg;
}

- (void) buildUI:(NSInteger) type {
  label = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 65, 340, 18)];
  [label setEditable: NO];
  [label setSelectable: NO];
  [label setBezeled: NO];
  [label setDrawsBackground: NO];
  [label setStringValue: @"Text Value"];

  msg = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 88, 340, 52)];
  [msg setEditable: NO];
  [msg setSelectable: NO];
  [msg setBezeled: NO];
  [msg setDrawsBackground: NO];
  [msg setStringValue: @"Enter text value and press OK."];

  if (type) {
    field = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(10, 39, 340, 21)];
  }
  else {
    field = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 39, 340, 21)];
  }
  [field setTarget:self];
  [field setAction:@selector(ok:)];

  NSButton* ok = [[NSButton alloc] initWithFrame:NSMakeRect(294, 10, 56, 24)];
  [ok setTitle:@"Ok"];
  [ok setTarget:self];
  [ok setAction:@selector(ok:)];

  NSButton* cancel = [[NSButton alloc] initWithFrame:NSMakeRect(232, 10, 56, 24)];
  [cancel setTitle:@"Cancel"];
  [cancel setTarget:self];
  [cancel setAction:@selector(cancel:)];

  panel = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 360, 150)
                                                styleMask:NSTitledWindowMask
                                                  backing:NSBackingStoreBuffered 
                                                    defer:NO];
  [panel setTitle:@"Prompt For Text"];

  [[panel contentView] addSubview:msg];
  [[panel contentView] addSubview:label];
  [[panel contentView] addSubview:field];
  [[panel contentView] addSubview:ok];
  [[panel contentView] addSubview:cancel];
}

- (void) ok:(id) sender {
  [NSApp stopModal];

  NSString* val = [field stringValue];
  fprintf(stdout, "%s\n", [val cString]);
  code = 0;
}

- (void) cancel:(id) sender {
  [NSApp stopModal];
  code = 1;
}

- (void) applicationDidFinishLaunching:(id) not {
  [panel center];
  [NSApp runModalForWindow:panel];
  exit(code);
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
      NSEnumerator* en = [arguments objectEnumerator];
      [en nextObject];

      NSInteger type = 0;
      NSString* title = nil;
      NSString* msg = nil;
      NSString* field = nil;
      NSString* value = nil;

      id it = nil;
      while (it = [en nextObject]) {
        if ([it isEqualToString:@"--secret"]) {
          type = 1;
        }
        else if ([it isEqualToString:@"--field"]) {
          field = [en nextObject];
        }
        else if ([it isEqualToString:@"--message"]) {
          msg = [en nextObject];
        }
        else if ([it isEqualToString:@"--title"]) {
          title = [en nextObject];
        }
        else if ([it isEqualToString:@"--value"]) {
          value = [en nextObject];
        }
      }
      NSApplication* app = [NSApplication sharedApplication];
      Delegate* del = [[Delegate alloc]init];

      [del buildUI:type];
      
      if (field) [[del label] setStringValue:field];
      if (msg)   [[del message] setStringValue:msg];
      if (title) [[del panel] setTitle:title];
      if (value) [[del field] setStringValue:value];

      [app setDelegate:del];
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

