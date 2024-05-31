/*
   Project: TouchController

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

#include <X11/Xutil.h>
#include <X11/extensions/XTest.h>
#import "TouchController.h"

@implementation TouchController

- (id) init {
  if ((self = [super init])) {
    status = -1;
  }
  return self;
}

- (void) dealloc {
  [task terminate];
  [task release];

  [cmd terminate];
  [cmd release];

  [hold3cmd release];
  [super dealloc];
}

- (NSInteger) status {
  return status;
}

- (void) simulateClick:(NSInteger) button {
  if (!display) {
    display = XOpenDisplay(0);
  }

  XTestFakeButtonEvent(display, button, True,  0);
  XTestFakeButtonEvent(display, button, False, 0);

  XFlush(display);
}

- (void) simulateClick2:(NSInteger) button {
  XEvent event;
  Window last_win = 0;
  
  event.xbutton.button = button;
  event.xbutton.subwindow = DefaultRootWindow (display);
  
  while (event.xbutton.subwindow) {
    last_win = event.xbutton.subwindow;
    event.xbutton.window = event.xbutton.subwindow;
    XQueryPointer (display, event.xbutton.window,
		  &event.xbutton.root, &event.xbutton.subwindow,
		  &event.xbutton.x_root, &event.xbutton.y_root,
		  &event.xbutton.x, &event.xbutton.y,
		  &event.xbutton.state);

    XClassHint* ch = XAllocClassHint();
    if (XGetClassHint(display, event.xbutton.window, ch)) {
      last_win = event.xbutton.window;
    }
    XFree(ch);
  }

  event.xbutton.window = last_win;

  event.type = ButtonPress;
  event.xbutton.same_screen = True;
  XSendEvent (display, PointerWindow, True, ButtonPressMask, &event);

  usleep(100000);
  
  event.type = ButtonRelease;
  XSendEvent (display, PointerWindow, True, ButtonReleaseMask, &event);

  XFlush(display);
}

- (void) execCommand:(NSString*) exec withArguments:(NSArray*) args {
  if (cmd) {
    NSLog(@"command is still running");
    return;
  }

  cmd = [[NSTask alloc] init];
  [cmd setLaunchPath:exec];
  [cmd setArguments:args];

  //NSLog(@"exec %@ %@", exec, args);

  [[NSNotificationCenter defaultCenter] 
     addObserver:self
     selector:@selector(taskDidTerminate:) 
     name:NSTaskDidTerminateNotification
     object:cmd];

  [cmd launch];
}

- (void) stopTask {
  [task terminate];
  [task release];
  task = nil;
}

- (void) execTask {
  NSArray* args = [NSArray array];
  NSString* exec = @"/System/Frameworks/SystemKit.framework/Resources/gesture_helper";
  
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

  [self reconfigure];
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
}

- (void) reconfigure {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  scrollEnabled = [[defaults valueForKey:@"ScrollEnabled"] boolValue];
  scrollReversed = [[defaults valueForKey:@"ScrollReversed"] boolValue];

  BOOL v = [[defaults valueForKey:@"Hold3Enabled"] boolValue];
  NSString *c = [defaults valueForKey:@"Hold3Command"];

  [hold3cmd release];
  hold3cmd = nil;
  if (v && [c length]) hold3cmd = [c retain];
}

- (void) taskDidTerminate:(NSNotification*) not {
  if ([not object] == cmd) {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSTaskDidTerminateNotification
                                                  object:cmd];
    [cmd release];
    cmd = nil;
    return;
  }

  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];

  status = 0;

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  NSLog(@"terminated");

  [fh closeFile];
  [fh release];
  [task release];
  task = nil;
  fh = nil;
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
  [fh readInBackgroundAndNotify];
}

- (void) processLine:(NSString*) line {
  if (scrollEnabled) {
    NSString *aa = (scrollReversed?@"5":@"4");
    NSString *bb = (scrollReversed?@"4":@"5");

    if ([line isEqualToString:@"SCROLL_UP"]) {
      [self simulateClick:Button4];
      //[self execCommand:@"xdotool" withArguments:[NSArray arrayWithObjects:@"click", aa, nil]];
    }
    else if ([line isEqualToString:@"SCROLL_DOWN"]) {
      [self simulateClick:Button5];
      //[self execCommand:@"xdotool" withArguments:[NSArray arrayWithObjects:@"click", bb, nil]];
    }
  }
  if (hold3cmd) {
    if ([line isEqualToString:@"HOLD3"]) {
      [self execCommand:@"sh" withArguments:[NSArray arrayWithObjects:@"-c", hold3cmd, nil]];
    }
  }
}

- (void) refresh {
  if (task) {
    NSLog(@"task running already?");
    return;
  }
  
  [self execTask];
}

@end
