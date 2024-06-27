/* All Rights reserved */

#import "NetworkController.h"

static NetworkController *_controller = nil;

@implementation NetworkController

+ (instancetype)controller
{
  if (_controller == nil) {
    _controller = [NetworkController new];
  }

  return _controller;
}

+ (NSView *)view
{
  if (_controller == nil) {
    _controller = [NetworkController controller];
  }

  return [_controller view];
}

- (void)dealloc
{
  NSLog(@"NetworkController: dealloc");
  [super dealloc];
}

- (id)init
{
  if ((self = [super init])) {
    if (![NSBundle loadNibNamed:@"NetworkView" owner:self]) {
      NSLog (@"EthernetView: Could not load NIB, aborting.");
      return nil;
    }
  }  
  
  return self;
}

- (void)awakeFromNib
{
  [networkView retain];
  [networkView removeFromSuperview];
}

- (NSView *)view
{
  return networkView;
}

- (void)updateForDevice:(DKProxy<NMDevice> *)device
{
  NSString* dev = device.Interface;
  NSLog(@"updating device %@", dev);
  [self runInfo:@"devinfo" forDevice:dev];
}

- (void)updateForConnection:(DKProxy<NMConnectionSettings> *)conn
{
  NSString* con = [[[conn GetSettings] valueForKey:@"connection"] valueForKey:@"uuid"];
  NSLog(@"updating connection %@", con);
  [self runInfo:@"coninfo" forDevice:con];
}

- (void) runInfo:(NSString*) cmd forDevice:(NSString*) dev {
  NSString* exec = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:cmd];

  NSPipe* pipe = [NSPipe pipe];
  NSFileHandle* fh = [pipe fileHandleForReading];
  NSTask* task = [[NSTask alloc] init];

  [task setLaunchPath:exec];
  [task setArguments:[NSArray arrayWithObject:dev]];
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

@end
