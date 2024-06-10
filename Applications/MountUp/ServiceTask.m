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

#import "ServiceTask.h"

@implementation ServiceTask

- (id) initWithName:(NSString*) nm {
  if ((self = [super init])) {
    name = [nm retain];
    status = -1;
  }
  return self;
}

- (void) dealloc {
  [self stopTask];
  [mountpoint release];
  [device release];
  [buff release];
  [name release];
  [task release];
  [super dealloc];
}

- (NSString*) mountPoint {
  return mountpoint;
}

- (NSString*) UNIXDevice {
  return device;
}

- (NSString*) name {
  return name;
}

- (NSString*) title {
  return @"unknown";
}

- (NSInteger) status {
  return status;
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
  
  //NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  //[[NSRunLoop currentRunLoop] runUntilDate: limit];
  NSLog(@"start %@ [%@]", exec, args);
  
  NSPipe* pipe = [NSPipe pipe];
  fh = [[pipe fileHandleForReading] retain];
  task = [[NSTask alloc] init];
  buff = [[NSMutableData alloc]init];

  [task setLaunchPath:exec];
  [task setArguments:args];
  [task setStandardOutput:pipe];

  pipe = [NSPipe pipe];
  fo = [[pipe fileHandleForWriting] retain];
  [task setStandardInput:pipe];
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
     
  status = 1;
  [fh readInBackgroundAndNotify];
  [task launch];
  
  [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceStatusHasChanged" object:self];
}

- (void) taskDidTerminate:(NSNotification*) not {
  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];

  status = 0;

  [fh closeFile];
  [fh release];
  [fo closeFile];
  [fo release];
  [task release];
  task = nil;
  fh = nil;
  fo = nil;

  [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceStatusHasChanged" object:self];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];

  NSLog(@"terminated");
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

- (void) waitFor:(NSTimeInterval) val {
  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:val];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
}

- (void) writeLine:(NSString*) line {
  NSData* data = [[NSString stringWithFormat:@"%@\n", line?line:@""] dataUsingEncoding:NSUTF8StringEncoding];
  [fo writeData:data];
}

- (void) processLine:(NSString*) line {
  if ([line hasPrefix:@"P:"]) {
    ASSIGN(mountpoint, [line substringFromIndex:2]);
    status = 2;

    [[NSNotificationCenter defaultCenter]
       postNotificationName:@"serviceStatusHasChanged" object:self];
  }
  else if ([line hasPrefix:@"D:"]) {
    ASSIGN(device, [line substringFromIndex:2]);
  }
}

- (BOOL) isMounted {
  if (status == 2 && [mountpoint length]) {
    return YES;
  }
  else {
    return NO;
  }
}

- (void) startTask {
  if (task) {
    NSLog(@"task running already?");
    return;
  }
  
  [self execTask];
}

- (void) stopTask {
  [task terminate];
}

@end
