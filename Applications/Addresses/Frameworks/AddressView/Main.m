#import <AppKit/AppKit.h>
#import "ADSinglePropertyView.h"

@interface Controller: NSObject
@end
@implementation Controller
- (void) applicationDidFinishLaunching: (NSNotification*) note
{
  NSLog(@"Finish\n");
  NSRect r = NSMakeRect(0, 0, 400, 400);
  [[NSAutoreleasePool alloc] init];
  NSWindow *win = [[NSWindow alloc] initWithContentRect: r
				    styleMask: NSTitledWindowMask |
				    NSResizableWindowMask
				    backing: NSBackingStoreBuffered
				    defer: NO];
  ADSinglePropertyView *v =
    [[ADSinglePropertyView alloc] initWithFrame: r];
  [win setContentView: v];
  [win makeKeyAndOrderFront: self];
}
@end

int main(int argc, const char** argv)
{
  [[NSAutoreleasePool alloc] init];
  [[NSApplication sharedApplication] setDelegate: [[Controller alloc] init]];
  NSApplicationMain(argc, argv);
}
