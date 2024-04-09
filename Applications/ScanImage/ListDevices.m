/*
   Project: ScanImage

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

#import "ListDevices.h"

@implementation ListDevices

- (id) init {
  if ((self = [super init])) {
  }
  return self;
}

- (void) dealloc {
  [devices release];
  [super dealloc];
}

- (NSArray*) devices {
  return devices;
}

- (NSArray*) serviceTaskArguments {
  return [NSArray array];
}

- (NSString*) serviceTaskExec {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"services/listdevices"];
  return exec;
}

- (void) processLine:(NSString*) line {
  if ([line hasPrefix:@"S:"]) {
    [devices release];
    devices = [[NSMutableArray alloc] init];
  }
  else if ([line hasPrefix:@"D:"]) {
    if (lastItem) {
      [devices addObject:lastItem];
      [lastItem release];
    }

    lastItem = [[NSMutableDictionary alloc] init];
    [lastItem setValue:[line substringFromIndex:2] forKey:@"device"];
  }
  else if ([line hasPrefix:@"T:"]) {
    [lastItem setValue:[line substringFromIndex:2] forKey:@"title"];
  }
  else if ([line hasPrefix:@"E:"]) {
    if (lastItem) {
      [devices addObject:lastItem];
      [lastItem release];
      lastItem = nil;
    }
  }
}

@end
