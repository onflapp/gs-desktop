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

@implementation ResultItem

- (void) setTitle:(NSString*) title {
  ASSIGN(_title, title);
}
- (void) setPath:(NSString*) path {
  ASSIGN(_path, path);
}
- (void) setType:(NSInteger) type {
  _type = type;
}

- (NSInteger) type {
  return _type;
}
- (NSString*) path {
  return _path;
}
- (NSString*) title {
  return _title;
}

- (void) dealloc {
  RELEASE(_title);
  RELEASE(_path);
  [super dealloc];
}

@end

@implementation Books

- (id) init {
  self = [super init];
  status = 0;
  config = [[NSMutableDictionary alloc] init];
  buff = [[NSMutableData alloc] init];
  results = [[NSMutableArray alloc] init];
  
  return self;
}

- (void) dealloc {
  RELEASE(buff);
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

  status = 1;
  [self execTask:cmd withArguments:args];
}

- (void) search:(NSString*) qry {
  NSMutableArray* args = [NSMutableArray array];
  NSString* cmd = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"commands/txtindx_query.pl"];

  [args addObject:baseDir];
  [args addObject:qry];

  [results removeAllObjects];

  status = 2;
  [self execTask:cmd withArguments:args];
}

- (void) list {
  NSMutableArray* args = [NSMutableArray array];
  NSString* cmd = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"commands/txtindx_list.pl"];

  [args addObject:baseDir];

  [results removeAllObjects];

  status = 3;
  [self execTask:cmd withArguments:args];
}


- (void) execTask:(NSString*) cmd withArguments:(NSArray*) args {
  NSLog(@"start");
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  
  [buff setLength:0];

  NSPipe* pipe = [NSPipe pipe];
  fh = [[pipe fileHandleForReading] retain];
  task = [[NSTask alloc] init];

  [task setLaunchPath:cmd];
  [task setArguments:args];
  [task setStandardOutput:pipe];
  //[task setCurrentDirectoryPath:wp];

  [nc addObserver:self
      selector:@selector(taskDidTerminate:) 
      name:NSTaskDidTerminateNotification 
      object:task];

  [nc addObserver:self
      selector:@selector(dataReceived:) 
      name:NSFileHandleReadCompletionNotification 
      object:fh];
     
  [fh readInBackgroundAndNotify];
  [task launch];
  
  [nc postNotificationName:@"statusHasChanged" object:self];
}

- (void) taskDidTerminate:(NSNotification*) not {
  NSLog(@"task terminated");
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

  if (status == 2 || status == 3) [nc postNotificationName:@"searchHasEnded" object:self];

  status = 0;

  [nc postNotificationName:@"statusHasChanged" object:self];
  
  [fh closeFile];
  [fh release];
  [task release];
  task = nil;
  fh = nil;


  [nc removeObserver:self name:NSFileHandleReadCompletionNotification object:nil];
  [nc removeObserver:self name:NSTaskDidTerminateNotification object:nil];
}

- (void) dataReceived:(NSNotification*) not {
  NSData* data = [[not userInfo] objectForKey:NSFileHandleNotificationDataItem];

  char* bytes = [data bytes];
  NSInteger sz = [data length];
  NSInteger c = 0;

  for (NSInteger i = 0; i < sz; i++) {
    if (*(bytes+i) == '\n') {
      NSLog(@"%d %d", c, i);
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

- (NSArray*) searchResults {
  return results;
}

- (void) processLine:(NSString*) line {
  ResultItem* item = [[ResultItem alloc] init];

  if ([line hasPrefix:@"T:"]) {
    [item setTitle:[line substringFromIndex:2]];
    [item setType:1];

    [results addObject:item];
    [item release];
  }
  else if ([line hasPrefix:@"P:"]) {
    NSString* p = [line substringFromIndex:2];
    [item setPath:p];
    [item setTitle:[p lastPathComponent]];
    [item setType:2];

    [results addObject:item];
    [item release];
  }
  else {
    NSLog(@"[%@]", line);
  }
}

@end
