/*
*/

#import "RDPDisplay.h"

@implementation RDPDisplay

- (id) init {
  self = [super init];

  [NSBundle loadNibNamed:@"RDPDisplay" owner:self];
  buff = [[NSMutableData alloc] init];
  
  return self;
}

- (void) dealloc {
  [task terminate];
  [buff release];
  [super dealloc];
}

- (void) setURL:(NSURL*) url {
  ASSIGN(displayURL, url);
}

- (void) connect {
  [self execTask];
}

- (void) showWindow {
  NSString* tok = [NSString stringWithFormat:@"%lu_rdpdisplay_window", [displayURL hash]];
  NSString* tit = [NSString stringWithFormat:@"RDP - %@", [displayURL host]];
  [window setFrameUsingName:tok];
  [window setFrameAutosaveName:tok];
  [window makeKeyAndOrderFront:self];

  [window setTitle:tit];

  [displayView createXWindow];
}

- (void) execTask {
  NSMutableArray* args = [NSMutableArray array];
  
  NSString* host = [displayURL host];
  NSString* cmd = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"connect_rdp"];
  [args addObject:host];
  [args addObject:[NSString stringWithFormat:@"0x%lx", [displayView embededXWindowID]]];
  
  //NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.3];
  //[[NSRunLoop currentRunLoop] runUntilDate: limit];
  NSLog(@"start %@ %@", cmd, args);
  
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

  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];

  [self release];
}

- (void) taskDidTerminate:(NSNotification*) not {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];

  [fin closeFile];
  [fin release];

  [fout closeFile];
  [fout release];

  [task release];

  task = nil;
  fin = nil;
  fout = nil;

  connected = NO;

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
  NSLog(@">>%@", line);
}

@end
