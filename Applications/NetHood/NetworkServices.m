/*
   Project: NetHood

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

#import "NetworkServices.h"

@implementation NetworkServices

- (id) init {
  if ((self = [super init])) {
    status = -1;
    services = [[NSMutableArray alloc]init];
  }
  return self;
}

- (void) dealloc {
  [task terminate];
  [task release];
  [services release];
  [super dealloc];
}

- (NSArray*) foundServices {
  return services;
}

- (NSArray*) foundServiceGroups {
  NSMutableArray* ls = [NSMutableArray array];
  for (NSDictionary* it in services) {
    NSString* title = [it valueForKey:@"title"];
    if (![ls containsObject:title]) {
      [ls addObject:title];
    }
  }
  return [ls sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray*) foundServicesForGroup:(NSString*) group {
  NSMutableArray* ls = [NSMutableArray array];
  for (NSDictionary* it in services) {
    NSString* title = [it valueForKey:@"title"];
    if ([title isEqualToString:group]) {
      [ls addObject:it];
    }
  }
  return ls;
}

- (NSInteger) status {
  return status;
}

- (NSArray*) serviceTaskArguments {
  return [NSArray array];
}

- (NSString*) serviceTaskExec {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"services/discover"];
  return exec;
}

- (void) execTask {
  NSArray* args = [self serviceTaskArguments];
  NSString* exec = [self serviceTaskExec];
  
  [services removeAllObjects];

  //NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  //[[NSRunLoop currentRunLoop] runUntilDate: limit];
  NSLog(@"start %@ [%@]", exec, args);
  
  NSPipe* pipe = [NSPipe pipe];
  fh = [[pipe fileHandleForReading] retain];
  task = [[NSTask alloc] init];
  buff = [[NSMutableData alloc]init];
  li = nil;

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
  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];

  status = 0;

  [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceStatusHasChanged" object:self];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  NSLog(@"terminated");

  [fh closeFile];
  [fh release];
  [task release];
  task = nil;
  fh = nil;
  li = nil;
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
  if ([line hasPrefix:@"S:"]) {
    NSMutableDictionary* item = [NSMutableDictionary dictionary];
    [item setValue:[line substringFromIndex:2] forKey:@"service"];
    
    [services addObject:item];
    li = item;
  }
  else if ([line hasPrefix:@"T:"]) {
    [li setValue:[line substringFromIndex:2] forKey:@"title"];
  }
  else if ([line hasPrefix:@"U:"]) {
    [li setValue:[line substringFromIndex:2] forKey:@"location"];
  }

  NSLog(@">%@<", line);
}

- (void) refresh {
  if (task) {
    NSLog(@"task running already?");
    return;
  }
  
  [self execTask];
}

@end
