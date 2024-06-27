/*
   Project: SystemManager

   Copyright (C) 2020 Free Software Foundation

   Author: onflapp

   Created: 2020-07-22 12:41:08 +0300 by root

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

#import "SystemWindow.h"

@implementation SystemWindow

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"SystemWindow" owner:self];

  buff = [[NSMutableData alloc] init];
  processItems = [[NSMutableArray alloc] init];
  processDetails = [[NSMutableString alloc] init];


  [processInfo setVerticallyResizable: YES];
  [processInfo setHorizontallyResizable: YES];

  [[processInfo textContainer] setContainerSize: NSMakeSize(FLT_MAX, FLT_MAX)];
  [[processInfo textContainer] setWidthTracksTextView: NO];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(statusHasChanged:)
           name:@"statusHasChanged"
         object:NSApp];

  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter]
    removeObserver:self];

  RELEASE(buff);
  RELEASE(processDetails);
  RELEASE(processItems);

  [super dealloc];
}

- (void) showWindow {
  if ([window isVisible]) {
    [window makeKeyAndOrderFront:self];
  }
  else {
    [window setFrameUsingName:@"system_window"];
    [window setFrameAutosaveName:@"system_window"];

    [window makeKeyAndOrderFront:self];
  }
}

- (NSWindow*) window {
  return window;
}

- (IBAction) execute:(id)sender {
  NSString* unit = [[processItems objectAtIndex:[processList selectedRow]] objectAtIndex:0];
  NSString* cmd = [self commandForName:@"system_control"];
  NSArray* args = nil;
  NSString* title = nil;

  if (!unit) return;

  if ([sender tag] == 11) {
    args = [NSArray arrayWithObjects:@"start", unit, nil];
    title = @"SUDO service start";
  }
  else if ([sender tag] == 10) {
    args = [NSArray arrayWithObjects:@"stop", unit, nil];
    title = @"SUDO service stop";
  }
  else if ([sender tag] == 21) {
    args = [NSArray arrayWithObjects:@"enable", unit, nil];
    title = @"SUDO service enable";
  }
  else if ([sender tag] == 20) {
    args = [NSArray arrayWithObjects:@"disable", unit, nil];
    title = @"SUDO service disable";
  }

  if (cmd) {
    NSWindow* win = [[NSApp delegate] executeConsoleCommand:cmd 
                                              withArguments:args];

    [win setTitle:title];
    //[NSApp runModalForWindow:win];
    //[self refresh:self];
  }
}

- (IBAction) refresh:(id)sender {
  status = 1;
  [processItems removeAllObjects];
  [[[processInfo textStorage] mutableString] setString:@""];

  NSString* cmd = [self commandForName:@"system_process"];
  NSString* f = [filterText stringValue];
  if (!f) f = @"";

  [self execTask:cmd withArguments:[NSArray arrayWithObjects:@"list", f, nil]];
}

- (IBAction) select:(id) sender {
  id item = [processItems objectAtIndex:[processList selectedRow]];
  NSString* unit = [item objectAtIndex:0];

  [self setDetailMessage:@""];
  [processDetails setString:@""];

  if (unit) {
    status = 2;
    NSString* cmd = [self commandForName:@"system_process"];
    [self execTask:cmd withArguments:[NSArray arrayWithObjects:@"status", unit, nil]];
  }
}

- (void) setDetailMessage:(NSString*) str {
  NSFont* font = [NSFont userFixedPitchFontOfSize:[NSFont systemFontSize]];
  NSDictionary* attrs = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];

  NSAttributedString* message = [[NSAttributedString alloc] initWithString:str
                                                                attributes:attrs];

  [[processInfo textStorage] setAttributedString:message];
}

- (NSString*) commandForName:(NSString*) name {
  return [[[[NSBundle mainBundle] resourcePath] 
    stringByAppendingPathComponent:@"commands"]
    stringByAppendingPathComponent:name];
}

- (void) execTask:(NSString*) cmd withArguments:(NSArray*) args {
  if (task) {
    NSLog(@"running already");
    return;
  }

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
}

- (void) taskDidTerminate:(NSNotification*) not {
  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];

  NSLog(@"task terminated");
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

  [fh closeFile];
  [fh release];
  [task release];
  task = nil;
  fh = nil;

  [nc removeObserver:self name:NSFileHandleReadCompletionNotification object:nil];
  [nc removeObserver:self name:NSTaskDidTerminateNotification object:nil];

  if (status == 1) {
    [processList reloadData];
  }
  else if (status == 2) {
    [self setDetailMessage:processDetails];
  }

  status = 0;
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
  if (status == 1) {
    [processItems addObject:[line componentsSeparatedByString:@"\t"]];
  } 
  else if (status == 2) {
    [processDetails appendString:line];
    [processDetails appendString:@"\n"];
  }
  else {
    NSLog(@"[%@]", line);
  }
}

- (void) tableView:(NSTableView*)table willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)col row: (NSInteger)row {
}

- (id) tableView:(NSTableView*) table objectValueForTableColumn:(NSTableColumn*) col row:(NSInteger) row {
  if ([[col identifier] isEqualToString:@"unit"]) {
    return [[processItems objectAtIndex:row] objectAtIndex:0];
  }
  else if ([[col identifier] isEqualToString:@"load"]) {
    return [[processItems objectAtIndex:row] objectAtIndex:1];
  }
  else if ([[col identifier] isEqualToString:@"active"]) {
    return [[processItems objectAtIndex:row] objectAtIndex:2];
  }
  else if ([[col identifier] isEqualToString:@"sub"]) {
    return [[processItems objectAtIndex:row] objectAtIndex:3];
  }
  else if ([[col identifier] isEqualToString:@"desc"]) {
    return [[processItems objectAtIndex:row] objectAtIndex:4];
  }
  else {
    return @"";
  }
}

- (NSInteger) numberOfRowsInTableView:(NSTableView*) table {
  return [processItems count];
}

- (void) statusHasChanged:(NSNotification *)notification {
  if ([window isVisible]) {
    [self refresh:self];
  }
}

- (void) windowDidBecomeMain:(NSNotification *)notification {
}

- (void) windowWillClose:(NSNotification *)notification {
}

@end
