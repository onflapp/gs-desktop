/*
   Project: CloudManager

   Copyright (C) 2022 Free Software Foundation

   Author: Parallels

   Created: 2022-09-16 15:44:39 +0000 by parallels

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

#import "RootServiceTask.h"
#import "PasswordPanel.h"

@implementation RootServiceTask

- (id) initWithName:(NSString*) nm {
  if ((self = [super init])) {
    name = [nm retain];
    status = -1;
  }
  return self;
}

- (void) dealloc {
  [self stopTask];
  [name release];
  [super dealloc];
}

- (NSString*) title {
  return [NSString stringWithFormat:@"root:%@", name];
}

- (void) processLine:(NSString*) line {
  if ([line hasPrefix:@"P:"]) {
    ASSIGN(mountpoint, [line substringFromIndex:2]);
  }
  else if ([line hasPrefix:@"X:"]) {
    NSString* msg = [NSString stringWithFormat:@"Provide user password to access root protected diretory %@", name];
    NSString* pass = [[NSApp delegate] askForPasswordWithMessage:msg];
    [self performSelector:@selector(_notify) withObject:nil afterDelay:1];

    [self writeLine:pass];
  }
  else if ([line hasPrefix:@"D:"]) {
    ASSIGN(device, [line substringFromIndex:2]);
  }
}

- (void) _notify {
  if (mountpoint) {
    status = 2;
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"serviceStatusHasChanged" object:self];
  }
  else {
    NSLog(@"did not mount, terminate");
    [self stopTask];
  }
}

- (NSArray*) serviceTaskArguments {
  NSMutableArray* args = [NSMutableArray array];
  [args addObject:name];
  return args;
}

- (NSString*) serviceTaskExec {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"services/mount-root"];
  return exec;
}

@end
