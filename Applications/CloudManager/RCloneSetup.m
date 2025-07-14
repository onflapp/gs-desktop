/*
   Project: CloudManager

   Copyright (C) 2023 Free Software Foundation

   Author: Parallels

   Created: 2023-05-08 13:10:39 +0000 by parallels

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "RCloneSetup.h"

@implementation RCloneTerminalView

- (id) initWithFrame:(NSRect) frame {
  [super initWithFrame:frame];

  Defaults* prefs = [[Defaults alloc] init];
  [prefs setScrollBackEnabled:YES];
  //[prefs setWindowBackgroundColor:[NSColor whiteColor]];
  //[prefs setTextNormalColor:[NSColor blackColor]];
  //[prefs setTextBoldColor:[NSColor greenColor]];
  //[prefs setCursorColor:[NSColor controlBackgroundColor]];
  //[prefs setUseBoldTerminalFont:NO];
  [prefs setScrollBottomOnInput:NO];
  
  [self setCursorStyle:[prefs cursorStyle]];

  return self;
}

- (void) runSetup {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"services/rclone-config"];
  NSArray* args = [NSArray new];

  [self clearBuffer:self];
  [self runProgram:exec
     withArguments:args
      initialInput:nil];
}

@end

@implementation RCloneSetup

- (id) init {
  self = [super init];

  [NSBundle loadNibNamed:@"RCloneSetup" owner:self];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(viewBecameIdle:)
           name:TerminalViewBecameIdleNotification
         object:terminalView];

  return self;
}

- (NSPanel*) panel {
  return panel;
}

- (void) registerServices:(id)sender {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"services/rclone-config"];
  NSArray* args = [NSArray arrayWithObject:@"--services"];

  NSPipe* pipe = [NSPipe pipe];
  NSFileHandle* fh = [pipe fileHandleForReading];
  NSTask* task = [[NSTask alloc] init];

  [task setLaunchPath:exec];
  [task setArguments:args];
  [task setStandardOutput:pipe];

  [task launch];

  NSData* data = [fh readDataToEndOfFile];
  NSString* rv = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

  NSMutableArray* services = [NSMutableArray array];

  for (NSString* line in [rv componentsSeparatedByString:@"\n"]) {
    if ([line hasSuffix:@":"]) {
      [services addObject:line];
    }
  }

  NSUserDefaults* cfg = [NSUserDefaults standardUserDefaults];
  [cfg setObject:services forKey:@"rclone_services"];
  [cfg synchronize];
  
  [rv release];
  [task release];

  [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceRegistrationHasChanged" object:self];

  [panel performClose:self];
}

- (void) viewBecameIdle:(NSNotification*) n {
  [terminalView closeProgram];
  [panel close];
}

- (void) showPanelAndRunSetup:(id)sender {
  [panel makeKeyAndOrderFront:sender];
  [terminalView runSetup];
}

@end
