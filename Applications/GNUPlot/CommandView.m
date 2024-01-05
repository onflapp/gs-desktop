/*
   Project: vim

   Copyright (C) 2022 Free Software Foundation

   Author: Ondrej Florian,,,

   Created: 2022-04-19 08:52:45 +0200 by oflorian

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

#import "CommandView.h"

@implementation CommandView

- (id) initWithFrame:(NSRect) frame {
  [super initWithFrame:frame];

  return self;
}

- (void) runWithFile:(NSString*) path windowID:(NSString*) xid {
  NSMutableArray* args = [NSMutableArray new];
  NSString* td = NSTemporaryDirectory();

  [args addObject:xid];
  if (path) [args addObject:path];

  NSString* vp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"plotview"];
  NSString* exec = [vp stringByAppendingPathComponent:@"start.sh"];

  NSLog(@">>>%@ %@", exec, args);
  
  [self runProgram:exec
     withArguments:args
      initialInput:nil];
}

- (void) help:(id) sender {
  //[self ts_sendCString:"\e\e:help\r"];
}

- (void) saveDocument:(id) sender {
}

- (void) quit:(id) sender {
  //[self ts_sendCString:"\e\e:q!\r"];
  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
}

- (void) dealloc {
  [self closeProgram];

  [super dealloc];
}

@end
