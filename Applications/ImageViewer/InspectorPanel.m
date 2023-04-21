#import <AppKit/AppKit.h>
#import "InspectorPanel.h"

@implementation InspectorPanel

- (id)init {
  if (!(self = [super init]))
    return nil;

  return self;
}

static id sharedInspectorPanel = nil;

+ (id)sharedInstance {
  if (! sharedInspectorPanel) {
    sharedInspectorPanel = [[self alloc] init];
    [NSBundle loadNibNamed:@"Inspector" owner:sharedInspectorPanel];
  }
  return sharedInspectorPanel;
}

- (void) dealloc {
  if (self != sharedInspectorPanel) {
    [super dealloc];
  }
}
- (void)updateSelection:(NSRect)r {
  [sel_xField setIntegerValue:(NSInteger)r.origin.x];
  [sel_yField setIntegerValue:(NSInteger)r.origin.y];
  [sel_wField setIntegerValue:(NSInteger)r.size.width];
  [sel_hField setIntegerValue:(NSInteger)r.size.height];
}

- (void) orderFrontInspectorPanel:(id)sender {
  [panel makeKeyAndOrderFront:nil];
}

@end
