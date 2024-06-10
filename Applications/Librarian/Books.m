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
#import <AppKit/NSAlert.h>

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
  status = -1;
  config = [[NSMutableDictionary alloc] init];
  buff = [[NSMutableData alloc] init];
  results = [[NSMutableArray alloc] init];
  
  return self;
}

- (NSInteger) status {
  return status;
}

- (void) dealloc {
  RELEASE(buff);
  RELEASE(config);
  RELEASE(baseDir);
  RELEASE(task);

  delegate = nil;
  [super dealloc];
}

- (void) close {
  status = -1;
  [task terminate];
}

- (void) openFile:(NSString*) file {
  NSString* cfile = [file stringByAppendingPathComponent:@"config.plist"];
  NSDictionary* cfg = [NSDictionary dictionaryWithContentsOfFile:cfile];
  [config addEntriesFromDictionary:cfg];

  ASSIGN(baseDir, file);
  status = 0;

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:@"statusHasChanged" object:self];
}

- (void) saveFile:(NSString*) file {
  if (status > 0) {
    NSLog(@"busy");
    return;
  }

  NSString* cfile = [file stringByAppendingPathComponent:@"config.plist"];
  NSFileManager* fm = [NSFileManager defaultManager];
  BOOL isdir = NO;

  if (![fm fileExistsAtPath:file isDirectory:&isdir]) {
    [fm createDirectoryAtPath:file attributes:nil];
  }

  [config writeToFile:cfile atomically:NO];
  status = 0;

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:@"statusHasChanged" object:self];
}

- (NSArray*) paths {
  return [config objectForKey:@"paths"];
}

- (void) setPaths:(NSArray*) paths {
  [config setObject:paths forKey:@"paths"];
}

- (NSString*) filter {
  return [config objectForKey:@"filter"];
}

- (void) setFilter:(NSString*) filter{
  [config setObject:filter forKey:@"filter"];
}

- (NSString*) commandForName:(NSString*) name {
  NSString* cmd = [baseDir stringByAppendingPathComponent:name];
  NSFileManager* fm = [NSFileManager defaultManager];

  if ([fm fileExistsAtPath:cmd]) return cmd;

  return [[[[NSBundle mainBundle] resourcePath] 
    stringByAppendingPathComponent:@"commands"]
    stringByAppendingPathComponent:name];
}


- (void) setDelegate:(id) del {
  delegate = del;
}

- (void) rebuild {
  [self rebuild:0];
}

- (void) rebuild:(NSInteger) type {
  if (!baseDir) {
    NSAlert* alert = [NSAlert alertWithMessageText:@"Index has not been saved yet"
                                     defaultButton:@"OK" 
                                   alternateButton:nil 
                                       otherButton:nil 
                         informativeTextWithFormat:@"Configure the index and save it to a file"];
    [alert runModal];
    return;
  }

  if (status > 0) {
    NSLog(@"busy");
    return;
  }

  [self saveFile:baseDir];

  NSMutableArray* args = [NSMutableArray array];
  NSString* cmd = [self commandForName:@"txtindx_build"];

  [args addObject:baseDir];
  [args addObject:[NSString stringWithFormat:@"%ld", type, nil]];

  status = 1;
  [self execTask:cmd withArguments:args];
}

- (void) search:(NSString*) qry {
  [self search:qry type:0];
}

- (void) search:(NSString*) qry type:(NSInteger) type {
  if (status != 0) {
    NSLog(@"busy");
    return;
  }

  NSMutableArray* args = [NSMutableArray array];
  NSString* cmd = [self commandForName:@"txtindx_query"];

  [args addObject:baseDir];
  [args addObject:qry];
  [args addObject:[NSString stringWithFormat:@"%ld", type, nil]];

  [results removeAllObjects];

  status = 2;
  [self execTask:cmd withArguments:args];
}

- (void) list {
  if (status != 0) {
    NSLog(@"busy");
    return;
  }

  NSMutableArray* args = [NSMutableArray array];
  NSString* cmd = [self commandForName:@"txtindx_list"];

  [args addObject:baseDir];

  [results removeAllObjects];

  status = 3;
  [self execTask:cmd withArguments:args];
}


- (void) execTask:(NSString*) cmd withArguments:(NSArray*) args {
  NSLog(@"start %@ %@", cmd, args);
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
  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];

  NSLog(@"task terminated");
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

  NSInteger s = status;

  status = 0;
  [nc postNotificationName:@"statusHasChanged" object:self];

  if (s == 2 || s == 3) [nc postNotificationName:@"searchHasEnded" object:self];

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

- (NSArray*) searchResults {
  return results;
}

- (void) processLine:(NSString*) line {
  ResultItem* item = [[ResultItem alloc] init];
  NSRange r = [line rangeOfString:@"\t"];
  NSString* loc = nil;
  NSString* title = nil;

  if (r.location == NSNotFound) {
    loc = line;
  }
  else {
    loc = [line substringToIndex:r.location];
    title = [line substringFromIndex:r.location+1];
  }

  if ([line hasPrefix:@"T:"]) {
    if (title) {
      [item setTitle:title];
      [item setPath:[loc substringFromIndex:2]];
    }
    else {
      [item setTitle:[loc substringFromIndex:2]];
      [item setPath:[loc substringFromIndex:2]];
    }

    [item setType:1];

    [results addObject:item];
    [item release];
  }
  else if ([line hasPrefix:@"P:"] || [line hasPrefix:@"U:"]) {
    if (title) {
      [item setTitle:title];
      [item setPath:[loc substringFromIndex:2]];
    }
    else {
      [item setTitle:[loc substringFromIndex:2]];
      [item setPath:[loc substringFromIndex:2]];
    }

    [item setType:2];

    [results addObject:item];
    [item release];
  }
  else if ([line hasPrefix:@"S:"]) {
    NSString* s = [line substringFromIndex:2];
    [delegate performSelector:@selector(books:didUpdateStatus:) withObject:self withObject:s];
  }
  else if ([line hasPrefix:@"E:"]) {
    NSString* s = [line substringFromIndex:2];
    [delegate performSelector:@selector(books:shouldDisplayError:) withObject:self withObject:s];
  }
  else {
    NSLog(@"[%@]", line);
  }
}

@end
