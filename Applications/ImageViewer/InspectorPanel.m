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
    [NSBundle loadNibNamed:@"InspectorPanel" owner:sharedInspectorPanel];
  }
  return sharedInspectorPanel;
}

- (void) dealloc {
  if (self != sharedInspectorPanel) {
    [super dealloc];
  }
}

- (void) orderFrontInspectorPanel:(id)sender {
  [panel makeKeyAndOrderFront:nil];
}

@end
