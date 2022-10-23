/*
   Project: Librarian

   Copyright (C) 2022 Free Software Foundation

   Author: Ondrej Florian,,,

   Created: 2022-10-22 14:04:38 +0200 by oflorian

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

#import "Books.h"

@implementation Books

- (id) init {
  self = [super init];
  status = 0;
  config = [[NSMutableDictionary alloc] init];
  
  return self;
}

- (void) dealloc {
  RELEASE(config);
  RELEASE(baseDir);
  [super dealloc];
}

- (void) openFile:(NSString*) file {
  NSString* cfile = [file stringByAppendingPathComponent:@"config.plist"];
  NSDictionary* cfg = [NSDictionary dictionaryWithContentsOfFile:cfile];
  [config addEntriesFromDictionary:cfg];

  ASSIGN(baseDir, file);
}

- (void) saveFile:(NSString*) file {
  NSString* cfile = [file stringByAppendingPathComponent:@"config.plist"];
  NSFileManager* fm = [NSFileManager defaultManager];
  BOOL isdir = NO;

  if (![fm fileExistsAtPath:file isDirectory:&isdir]) {
    [fm createDirectoryAtPath:file attributes:nil];
  }

  [config writeToFile:cfile atomically:NO];
}

- (NSArray*) paths {
  return [config objectForKey:@"paths"];
}

- (void) setPaths:(NSArray*) paths {
  [config setObject:paths forKey:@"paths"];
}

- (void) rebuild {
  if (!baseDir) {
    NSLog(@"no based dir");
    return;
  }

  NSMutableArray* args = [NSMutableArray array];
  NSString* cmd = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"commands/txtindx_build.pl"];

  [args addObject:baseDir];

  [self execTask:cmd withArguments:args];
}

- (void) search {
}

- (void) execTask:(NSString*) cmd withArguments:(NSArray*) args {
  NSLog(@"start");
  
  NSPipe* pipe = [NSPipe pipe];
  fh = [[pipe fileHandleForReading] retain];
  task = [[NSTask alloc] init];
  [task setLaunchPath:cmd];
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
  NSLog(@"task terminated");
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
  
  NSLog(@"[[[%@]]]", str);
}

@end
