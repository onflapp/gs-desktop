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

#import "NetworkServiceTask.h"

@implementation NetworkServiceTask

- (id) initWithURL:(NSString*) url {
  if ((self = [super init])) {
    name = [url retain];
    status = -1;
  }
  return self;
}

- (void) dealloc {
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self stopTask];
  [user release];
  [password release];
  [super dealloc];
}

- (NSString*) title {
  return [NSString stringWithFormat:@"network:%@", name];
}

- (void) setUser:(NSString*) v {
  ASSIGN(user, v);
}

- (void) setPassword:(NSString*) v {
  ASSIGN(password, v);
}

- (NSArray*) serviceTaskArguments {
  NSMutableArray* args = [NSMutableArray array];
  [args addObject:name];
  return args;
}

- (NSString*) serviceTaskExec {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"services/mount-net"];
  return exec;
}

- (void) processLine:(NSString*) line {
  NSLog(@">%@<", line);
  if ([line hasPrefix:@"P:"]) {
    ASSIGN(mountpoint, [line substringFromIndex:2]);
    status = 2;

    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"serviceStatusHasChanged" object:self];
  }
  else if ([line hasPrefix:@"D:"]) {
    ASSIGN(device, [line substringFromIndex:2]);
  }
  else if ([line hasPrefix:@"Verifying the identity of"]) {
    if (status != 99) {
      [self performSelector:@selector(_notify) withObject:nil afterDelay:5];
      [self writeLine:@"1"];
    }
  }
  else if ([line hasPrefix:@"Enter password for"]) {
    if (status != 99) {
      [self performSelector:@selector(_notify) withObject:nil afterDelay:5];
      [self waitFor:0.2];
      [self writeLine:password];
      [self waitFor:0.2];
      status = 99;
    }
  }
  else if ([line hasPrefix:@"Password"]) {
    if (status != 99) {
      [self performSelector:@selector(_notify) withObject:nil afterDelay:5];
      [self waitFor:0.2];
      [self writeLine:user];
      [self waitFor:0.2];
      [self writeLine:password];
      [self waitFor:0.2];
      status = 99;
    }
  }
  else {
    NSLog(@"[%@]", line);
  }
}

- (void) _notify {
  if (!mountpoint) {
    NSLog(@"did not mount, terminate");
    [self stopTask];
  }
}

@end
