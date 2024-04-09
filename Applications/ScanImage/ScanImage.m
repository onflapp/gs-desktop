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

#import "ScanImage.h"

@implementation ScanImage

- (id) init {
  if ((self = [super init])) {
  }
  return self;
}

- (void) dealloc {
  [args release];
  [output release];
  [super dealloc];
}

- (void) scanWithArguments:(NSArray*) arguments {
  [output release];
  output = nil;

  ASSIGN(args, arguments);
  [self execTask];
}

- (NSString*) outputFilename {
  return output;
}

- (NSArray*) serviceTaskArguments {
  return args;
}

- (NSString*) serviceTaskExec {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"services/scanimage"];
  return exec;
}

- (void) processLine:(NSString*) line {
  NSLog(@">%@<", line);
  if ([line hasPrefix:@"E:"]) {
    ASSIGN(output, [line substringFromIndex:2]);
  }
}

@end
