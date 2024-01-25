/*
*/

#import "VNCDisplay.h"

@implementation VNCDisplay

- (id) init {
  self = [super init];

  [NSBundle loadNibNamed:@"VNCDisplay" owner:self];
  buff = [[NSMutableData alloc] init];
  
  return self;
}

- (void) dealloc {
  [task terminate];
  [buff release];
  [super dealloc];
}

- (void) connect:(NSURL*) url {
  ASSIGN(displayURL, url);

  [self execTask];
}

- (void) showWindow {
  [window setFrameAutosaveName:@"vncdisplay_window"];
  [window makeKeyAndOrderFront:self];
}

- (void) execTask {
  NSMutableArray* args = [NSMutableArray array];
  
  NSString* host = [displayURL host];
  NSString* cmd = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sdlvncviewer"];
  [args addObject:host];
  
  //NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  //[[NSRunLoop currentRunLoop] runUntilDate: limit];
  NSLog(@"start %@", cmd);
  
  NSPipe* ipipe = [NSPipe pipe];
  NSPipe* opipe = [NSPipe pipe];

  fin  = [[ipipe fileHandleForReading] retain];
  fout = [[opipe fileHandleForWriting] retain];
  task = [[NSTask alloc] init];

  [task setLaunchPath:cmd];
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
  [task interrupt];
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

  NSLog(@"TERMINATED");
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
      [self processCommand:line];
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

- (void) processCommand:(NSString*) line {
  if ([line hasPrefix:@"S:"]) {
    connected = YES;
    Window xwinid = [[line substringFromIndex:2] integerValue];
    [displayView reparentXWindowID:xwinid];
  }
  else if ([line hasPrefix:@"Q:"]) {
    connected = NO;
  }
}

@end
