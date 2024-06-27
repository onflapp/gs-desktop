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
    script = [nm retain];
  }
  return self;
}

- (void) dealloc {
  [task terminate];
  [delegate release];
  [buff release];
  [env release];
  [exec release];
  [script release];
  [task release];
  [super dealloc];
}

- (NSDictionary*)makeEnvironment
{
    NSDictionary* nenv = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: nenv];
    NSString* cmdkey = [[NSUserDefaults standardUserDefaults] valueForKey:@"GSFirstCommandKey"];

    if ([cmdkey hasPrefix:@"Super_"])        [dict setValue:@"SUPER" forKey:@"GS_COMMAND_KEY"];
    else if ([cmdkey hasPrefix:@"Control_"]) [dict setValue:@"CTRL" forKey:@"GS_COMMAND_KEY"];
    else if ([cmdkey hasPrefix:@"Meta_"])    [dict setValue:@"META" forKey:@"GS_COMMAND_KEY"];
    else                                     [dict setValue:@"ALT" forKey:@"GS_COMMAND_KEY"];

    return dict;
}

- (void) execTaskWithArguments:(NSArray*) args 
                          data:(NSData*) data
                      delegate:(id) del {

  [self stopTask];
  ASSIGN(delegate, del);
  
  NSPipe* pipe = [NSPipe pipe];
  fh = [[pipe fileHandleForReading] retain];
  task = [[NSTask alloc] init];
  buff = [[NSMutableData alloc]init];

  NSMutableDictionary *nenv = [NSMutableDictionary dictionaryWithDictionary:[self makeEnvironment]];

  if (env) {
    [nenv addEntriesFromDictionary:env];
  }

  [task setEnvironment:nenv];
  if (exec) {
    [task setLaunchPath:exec];
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:script];
    if ([args count])  {
      [a addObjectsFromArray:args];
    }
    NSLog(@"start %@ [%@]", exec, a);
    [task setArguments:a];
  }
  else {
    [task setLaunchPath:script];
    [task setArguments:args];
    NSLog(@"start %@ [%@]", script, args);
  }

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
     
  @try {
    [task launch];
  }
  @catch (NSException* ex) {
    NSLog(@"exception %@", ex);
    [self taskDidTerminate:nil];
    return;
  }
   
  status = 1;
  [fh readInBackgroundAndNotify];

  if ([data length]) {
    NSLog(@"write data");
    [fo writeData:data];
    [fo closeFile];
    [fo release];
    fo = nil;
    status = 2;
  }
}

- (void) setShellExec:(NSString*) sh {
  ASSIGN(exec, sh);
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
  NSInteger i;
  for (i = 0; i < sz; i++) {
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
