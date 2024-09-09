/*
*/

#import "UserManager.h"

@implementation UMTerminalView

- (id) initWithFrame:(NSRect) frame {
  [super initWithFrame:frame];

  Defaults* prefs = [[Defaults alloc] init];
  [prefs setScrollBackEnabled:NO];
  [prefs setWindowBackgroundColor:[NSColor whiteColor]];
  //[prefs setWindowBackgroundColor:[NSColor controlBackgroundColor]];
  //[prefs setTextNormalColor:[NSColor blackColor]];
  //[prefs setTextBoldColor:[NSColor greenColor]];
  //[prefs setUseBoldTerminalFont:NO];
  [prefs setCursorColor:[NSColor redColor]];
  [prefs setScrollBottomOnInput:NO];
  
  [self setCursorStyle:[prefs cursorStyle]];

  return self;
}

- (void) runManager:(NSString*) mode {
  NSString* exec = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"user_manager.sh"];
  NSArray* args = [NSArray arrayWithObject:mode];

  NSLog(@"exec %@", exec);
  [self clearBuffer:self];
  [self runProgram:exec
     withArguments:args
      initialInput:nil];
}

@end

@implementation UserManager

- (id) init {
  self = [super init];

  [NSBundle loadNibNamed:@"UserManager" owner:self];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(viewBecameIdle:)
           name:TerminalViewBecameIdleNotification
         object:terminalView];

  return self;
}

- (NSPanel*) panel {
  return panel;
}

- (NSView*) view {
  return view;
}

- (void) viewBecameIdle:(NSNotification*) n {
  [terminalView closeProgram];
  [view setHidden:YES];
}

- (void) showPanelAndRunManager:(id)sender {
  [view setHidden:NO];
  [[view window] makeFirstResponder:terminalView];
  if ([sender tag] == 10) {
    [terminalView runManager:@"info"];
  }
  else if ([sender tag] == 20) {
    [terminalView runManager:@"shell"];
  }
  else {
    [terminalView runManager:@"new"];
  }
}

- (void) cancel:(id)sender {
  //[terminalView ts_sendCString:"\ec"];
  [view setHidden:YES];
}

@end
