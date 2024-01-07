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

#import "ShellUITask.h"

@implementation ShellUITask

- (id) initWithScript:(NSString*) nm {
  if ((self = [super init])) {
    exec = [nm retain];
  }
  return self;
}

- (void) dealloc {
  [self stopTask];
  [delegate release];
  [buff release];
  [env release];
  [exec release];
  [task release];
  [super dealloc];
}

- (void) execTaskWithArguments:(NSArray*) args 
                          data:(NSData*) data
                      delegate:(id) del {

  [self stopTask];
  ASSIGN(delegate, del);
  NSLog(@"start %@ [%@]", exec, args);
  
  NSPipe* pipe = [NSPipe pipe];
  fh = [[pipe fileHandleForReading] retain];
  task = [[NSTask alloc] init];
  buff = [[NSMutableData alloc]init];

  if (env) {
    NSDictionary *myenv = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *nenv = [NSMutableDictionary dictionaryWithDictionary:myenv];
    [nenv addEntriesFromDictionary:env];
    [task setEnvironment:nenv];
  }

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

  if ([data length]) {
    NSLog(@"write data");
    [fo writeData:data];
    [fo closeFile];
    [fo release];
    fo = nil;
    status = 2;
  }
}

- (void) setEnvironment:(NSDictionary*) e {
  ASSIGN(env, e);
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
  [delegate release];
  task = nil;
  fh = nil;
  fo = nil;
  delegate = nil;

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];

  NSLog(@"terminated");
}

- (void) dataReceived:(NSNotification*) not {
  if (status == -1) return;

  NSData* data = [[not userInfo] objectForKey:NSFileHandleNotificationDataItem];

  char* bytes = [data bytes];
  NSInteger sz = [data length];
  NSInteger c = 0;

  NSLog(@"data in %d", sz);
  for (NSInteger i = 0; i < sz; i++) {
    if (*(bytes+i) == '\n') {
      [buff appendBytes:bytes+c length:i-c];
      NSString* line = [[NSString alloc] initWithData:buff encoding:[NSString defaultCStringEncoding]];
      [delegate processLine:line];
      [line release];
      [buff setLength:0];
      c = i+1;
    }
  }
  if (c < sz) {
    [buff appendBytes:bytes+c length:sz - c];
  }

  if (sz > 0) {
    [fh readInBackgroundAndNotify];
  }
}

- (void) waitFor:(NSTimeInterval) val {
  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:val];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
}

- (void) writeLine:(NSString*) line {
  NSData* data = [[NSString stringWithFormat:@"%@\n", line?line:@""] dataUsingEncoding:NSUTF8StringEncoding];
  [fo writeData:data];
}

- (void) stopTask {
  if (status) {
    status = -1;
    NSLog(@"stop existing task");
    [task terminate];
    while (1) {
      if (status == 0) return;
      NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
      [[NSRunLoop currentRunLoop] runUntilDate: limit];
      NSLog(@"wait...");
    }
  }
}

@end
