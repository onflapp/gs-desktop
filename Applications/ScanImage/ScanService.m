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

#import "ScanService.h"

@implementation ScanService

- (id) init {
  if ((self = [super init])) {
  }
  return self;
}

- (void) dealloc {
  [task terminate];
  [task release];
  [super dealloc];
}

- (BOOL) isRunning {
  return running;
}

- (void) stop {
  [task terminate];
}

- (void) start {
  if (running) {
    NSLog(@"running already");
    return;
  }
  [self execTask];
}

- (NSArray*) serviceTaskArguments {
  return nil;
}

- (NSString*) serviceTaskExec {
  return nil;
}

- (void) execTask {
  NSArray* args = [self serviceTaskArguments];
  NSString* exec = [self serviceTaskExec];
  
  NSLog(@"start %@ [%@]", exec, args);
  running = YES;
  
  NSPipe* pipe = [NSPipe pipe];
  fh = [[pipe fileHandleForReading] retain];
  task = [[NSTask alloc] init];
  buff = [[NSMutableData alloc]init];

  [task setLaunchPath:exec];
  [task setArguments:args];
  [task setStandardOutput:pipe];

  //[task setCurrentDirectoryPath:wp];

  [[NSNotificationCenter defaultCenter] 
     addObserver:self
     selector:@selector(taskDidTerminate:) 
     name:NSTaskDidTerminateNotification 
     object:task];

  [[NSNotificationCenter defaultCenter] 
     addObserver:self
     selector:@selector(dataReceived:) 
     name:NSFileHandleReadCompletionNotification 
     object:fh];
     
  [fh readInBackgroundAndNotify];
  [task launch];

  
  [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceStatusHasChanged" object:self];
}

- (void) taskDidTerminate:(NSNotification*) not {
  running = NO;

  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];

  [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceStatusHasChanged" object:self];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  NSLog(@"terminated");

  [fh closeFile];
  [fh release];
  [task release];
  task = nil;
  fh = nil;

}

- (void) dataReceived:(NSNotification*) not {
  NSData* data = [[not userInfo] objectForKey:NSFileHandleNotificationDataItem];

  char* bytes = [data bytes];
  NSInteger sz = [data length];
  NSInteger c = 0;

  NSInteger i;
  for (i = 0; i < sz; i++) {
    if (*(bytes+i) == '\n') {
      [buff appendBytes:bytes+c length:i-c];
      NSString* line = [[NSString alloc] initWithData:buff encoding:[NSString defaultCStringEncoding]];
      [self processLine:line];
      [line release];
      [buff setLength:0];
      c = i+1;
    }
  }
  if (c < sz) {
    [buff appendBytes:bytes+c length:sz - c];
  }
  [fh readInBackgroundAndNotify];
}

- (void) processLine:(NSString*) line {
  NSLog(@">%@<", line);
}

@end
