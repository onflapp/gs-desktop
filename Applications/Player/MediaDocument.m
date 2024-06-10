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
  [self updateStatus];
  
  return self;
}

- (void) dealloc {
  [buff release];
  [mediaFile release];
  [super dealloc];
}

- (NSWindow*) window {
  return window;
}

- (void) loadFile:(NSString*) file {
  ASSIGN(mediaFile, file);

  [self execTask];
}

- (IBAction) play:(id) sender {
  if (sender == playButton) {
    if (playing) {
      [self writeCommand:@"pause"];
      [self performSelector:@selector(checkStatus) withObject:nil afterDelay:0.1];
    }
    else {
      [self writeCommand:@"play"];
      [self performSelector:@selector(checkStatus) withObject:nil afterDelay:0.1];
    }
  }
  else if (sender == locationSlider) {
    NSInteger p = (NSInteger)[sender floatValue];
    [self writeCommand:[NSString stringWithFormat:@"seek %d", p]];
    pos = p;
  }
}

- (IBAction) stop:(id) sender {
  [self writeCommand:@"seek 0"];
  [self writeCommand:@"stop"];
  [self performSelector:@selector(checkStatus) withObject:nil afterDelay:0.1];
}

- (void) checkStatus {
  if (running) {
    [self writeCommand:@"status"];
    [self writeCommand:@"get_time"];
    [self writeCommand:@"get_length"];
    [self performSelector:@selector(checkStatus) withObject:nil afterDelay:0.7];
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

- (void) updateStatus {
  if (running) {
    [playButton setEnabled:YES];
    if (playing) {
      [playButton setTitle:@"Stop"];
      [statusField setStringValue:@"Playing"];
    }
    else {
      [statusField setStringValue:@"Stopped"];
      [playButton setTitle:@"Play"];
    }
    if (len > 0) {
      [locationSlider setMaxValue:(float)len];
    }
    [locationSlider setFloatValue:(float)pos];
  }
  else {
    [playButton setEnabled:NO];
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
  NSLog(@"will close");
  [self writeCommand:@"quit"];
  [self taskDidTerminate:nil];
  [self release];
}

- (void) taskDidTerminate:(NSNotification*) not {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

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
  playing = NO;
}

- (void) dataReceived:(NSNotification*) not {
  NSData* data = [[not userInfo] objectForKey:NSFileHandleNotificationDataItem];
  char* bytes = [data bytes];
  NSInteger sz = [data length];
  NSInteger c = 0;

  NSInteger i;
  for (i = 0; i < sz; i++) {
    if (*(bytes+i) == '\n') {
      [buff appendBytes:bytes+c length:i-c-1];
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
  if (!running) return;

  NSString* line = [NSString stringWithFormat:@"%@\n", cmd];
  NSData* data = [line dataUsingEncoding:NSUTF8StringEncoding];
  [fout writeData:data];
}

- (void) processLine:(NSString*) line {
//NSLog(@"[%@]", line);

  if ([line hasPrefix:@"Command Line Interface initialized."]) {
    running = YES;
    __linepart = 0;
    [self performSelector:@selector(checkStatus) withObject:nil afterDelay:0.1];
  }
  else if (__linepart == 1) {
    NSInteger p = [line integerValue];
    if ([line length] > 0 &&  p > 0) pos = p+1;
    __linepart = 2;
  }
  else if (__linepart == 2) {
    NSInteger l = [line integerValue];
    if ([line length] > 0 && l > 0) len = l;
    __linepart = 0;
  }
  else if ([line hasPrefix:@"( state playing )"]) {
    playing = YES;
    __linepart = 1;
  }
  else if ([line hasPrefix:@"( state stopped )"]) {
    playing = NO;
    __linepart = 1;
  }
  else if ([line hasPrefix:@"( state paused )"]) {
    playing = NO;
    __linepart = 1;
  }
  else if ([line hasPrefix:@"> ( new input: "]) {
    NSString* f = [line substringWithRange:NSMakeRange(15, [line length] - 15 - 2)];
    //NSLog(@">>%@<", f);
    __linepart = 0;
  }
  else {
    __linepart = 0;
  }
  [self updateStatus];
}

@end
