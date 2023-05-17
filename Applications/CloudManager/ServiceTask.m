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
    log = [[NSMutableString alloc]init];
    status = -1;
  }
  return self;
}

- (void) dealloc {
  [self stopTask];
  [log release];
  [name release];
  [task release];
  [super dealloc];
}

- (void) setRemoteName:(NSString*) rn {
  [remotename release];
  remotename = [rn retain];
}

- (NSString*) remoteName {
  return remotename;
}

- (void) setMountPoint:(NSString*) mp {
  [mountpoint release];
  mountpoint = [mp retain];
}
  
- (NSString*) mountPoint {
  return mountpoint;
}

- (NSString*) name {
  return name;
}

- (NSInteger) status {
  return status;
}

- (NSString*) message {
  return [log description];
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
     
  status = 1;
  [fh readInBackgroundAndNotify];
  [task launch];
  
  [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceStatusHasChanged" object:self];
}

- (void) taskDidTerminate:(NSNotification*) not {
  [log appendString:@"task terminated!"];

  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];

  status = 0;

  [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceStatusHasChanged" object:self];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [fh closeFile];
  [fh release];
  [task release];
  task = nil;
  fh = nil;
}

- (void) dataReceived:(NSNotification*) not {
  NSData* data = [[not userInfo] objectForKey:NSFileHandleNotificationDataItem];
  NSString* str = [[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]];
  
  NSLog(@"task:[%@]", str);
  [log appendString:str];

  [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceStatusHasChanged" object:self];

  [fh readInBackgroundAndNotify];
}

- (void) startTask {
  if (task) {
    NSLog(@"task running already?");
    return;
  }
  
  [log setString:@""];
  [self execTask];
}

- (void) stopTask {
  [task terminate];
}

@end
