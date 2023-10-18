/*
*/

#import "NMSetup.h"

@implementation NMTerminalView

- (id) initWithFrame:(NSRect) frame {
  [super initWithFrame:frame];

  Defaults* prefs = [[Defaults alloc] init];
  [prefs setScrollBackEnabled:NO];
  [prefs setWindowBackgroundColor:[NSColor controlBackgroundColor]];
  //[prefs setTextNormalColor:[NSColor blackColor]];
  //[prefs setTextBoldColor:[NSColor greenColor]];
  //[prefs setUseBoldTerminalFont:NO];
  [prefs setCursorColor:[NSColor redColor]];
  [prefs setScrollBottomOnInput:NO];
  
  [self setCursorStyle:[prefs cursorStyle]];

  return self;
}

- (void) runSetup {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"nmsetup.sh"];
  NSArray* args = [NSArray new];

  [self clearBuffer:self];
  [self runProgram:exec
     withArguments:args
      initialInput:nil];
}

@end

@implementation NMSetup

- (id) init {
  self = [super init];

  [NSBundle loadNibNamed:@"NMSetupPanel" owner:self];

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

- (void) viewBecameIdle:(NSNotification*) n {
  [terminalView closeProgram];
  [panel close];
}

- (void) showPanelAndRunSetup:(id)sender {
  [panel makeKeyAndOrderFront:sender];
  [panel center];
  [terminalView runSetup];
}

- (void) goBack:(id)sender {
  [terminalView ts_sendCString:"\ec"];
}

@end
