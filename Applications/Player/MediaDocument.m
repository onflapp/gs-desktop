/*
   Project: Player

   Copyright (C) 2022 Free Software Foundation

   Author: Parallels

   Created: 2022-11-02 17:46:30 +0000 by parallels

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

#import "MediaDocument.h"

@implementation MediaDocument

- (id) init {
  self = [super init];
  buff = [[NSMutableData alloc] init];

  [self makeWindow];
  
  return self;
}

- (void) dealloc {
  [buff release];
  [super dealloc];
}

- (void) loadFile:(NSString*) file {
  ASSIGN(mediaFile, file);

  [self execTask];
}

- (IBAction) play:(id) sender {
  [self writeCommand:@"pause"];
}

- (void) checkStatus {
  [self writeCommand:@"status"];
  if (running) {
    [self performSelector:@selector(checkStatus) withObject:nil afterDelay:1.0];
  }
}

- (NSString*) playerExec {
  return @"playerview/start_audio.sh";
}

- (NSArray*) playerArguments {
  if (mediaFile) {
    return [NSArray arrayWithObject:mediaFile];
  }
  else {
    return [NSArray array];
  }
}

- (void) makeWindow {
  [NSBundle loadNibNamed:@"MediaDocument" owner:self];
  [window setFrameAutosaveName:@"media_window"];
  
  [window makeKeyAndOrderFront:self];
}

- (void) execTask {
  NSMutableArray* args = [NSMutableArray array];
  
  NSString* cmd = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[self playerExec]];
  [args addObject:cmd];
  [args addObjectsFromArray:[self playerArguments]];
  
  //NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  //[[NSRunLoop currentRunLoop] runUntilDate: limit];
  NSLog(@"start %@", cmd);
  
  NSPipe* ipipe = [NSPipe pipe];
  NSPipe* opipe = [NSPipe pipe];

  fin  = [[ipipe fileHandleForReading] retain];
  fout = [[opipe fileHandleForWriting] retain];
  task = [[NSTask alloc] init];

  [task setLaunchPath:@"/bin/bash"];
  [task setArguments:args];
  [task setStandardOutput:ipipe];
  [task setStandardInput:opipe];
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
     object:fin];

  [fin readInBackgroundAndNotify];
  [task launch];
}

- (void) windowWillClose:(NSWindow*) win {
  [self writeCommand:@"quit"];
}

- (void) taskDidTerminate:(NSNotification*) not {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

  [mediaFile release];

  [fin closeFile];
  [fin release];

  [fout closeFile];
  [fout release];

  [task release];

  task = nil;
  fin = nil;
  fout = nil;

  [nc removeObserver:self name:NSFileHandleReadCompletionNotification object:nil];
  [nc removeObserver:self name:NSTaskDidTerminateNotification object:nil];

  running = NO;
}

- (void) dataReceived:(NSNotification*) not {
  NSData* data = [[not userInfo] objectForKey:NSFileHandleNotificationDataItem];
  char* bytes = [data bytes];
  NSInteger sz = [data length];
  NSInteger c = 0;

  for (NSInteger i = 0; i < sz; i++) {
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
  [fin readInBackgroundAndNotify];
}

- (void) writeCommand:(NSString*) cmd {
  NSString* line = [NSString stringWithFormat:@"%@\n", cmd];
  NSData* data = [line dataUsingEncoding:NSUTF8StringEncoding];
  [fout writeData:data];
}

- (void) processLine:(NSString*) line {
//NSLog(@"[%@]", line);

  if ([line hasPrefix:@"Command Line Interface initialized."]) {
    running = YES;
    [self performSelector:@selector(checkStatus) withObject:nil afterDelay:0.1];
  }
  else if ([line hasPrefix:@"( state playing )"]) {
    playing = YES;
  }
  else if ([line hasPrefix:@"( state stopped )"]) {
    playing = NO;
  }
}

@end
