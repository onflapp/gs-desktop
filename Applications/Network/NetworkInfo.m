/*
*/

#import "NetworkInfo.h"

@implementation NetworkInfo

- (id) init {
  self = [super init];

  [NSBundle loadNibNamed:@"NetworkInfo" owner:self];
  [panel setFrameUsingName:@"netinfo_window"];
  return self;
}

- (NSPanel*) panel {
  return panel;
}

- (void) runInfo {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"networkinfo"];

  NSPipe* pipe = [NSPipe pipe];
  NSFileHandle* fh = [pipe fileHandleForReading];
  NSTask* task = [[NSTask alloc] init];

  [task setLaunchPath:exec];
  [task setStandardOutput:pipe];
  [task launch];

  NSData* data = [fh readDataToEndOfFile];
  if (data) {
    NSString* rv = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self setMessage:rv];
  }

  [task release];
}

- (void) setMessage:(NSString*) str {
  NSFont* font = [NSFont userFixedPitchFontOfSize:[NSFont systemFontSize]];
  NSDictionary* attrs = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];

  NSAttributedString* message = [[NSAttributedString alloc] initWithString:str
                                                                attributes:attrs];

  [[textView textStorage] setAttributedString:message];
}

- (void) refresh:(id)sender {
  [self runInfo];
}

- (void) showPanelAndRunInfo:(id)sender {
  [panel makeKeyAndOrderFront:sender];
  [self runInfo];
}

@end
