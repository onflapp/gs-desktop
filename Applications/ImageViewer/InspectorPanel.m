#import <AppKit/AppKit.h>
#import "InspectorPanel.h"

@implementation InspectorPanel

- (id)init {
  if (!(self = [super init]))
    return nil;

  return self;
}

static id sharedInspectorPanel = nil;

+ (id) sharedInstance {
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

- (NSRect) selectedRectangle {
  NSInteger x = [sel_xField integerValue];
  NSInteger y = [sel_yField integerValue];
  NSInteger w = [sel_wField integerValue];
  NSInteger h = [sel_hField integerValue];

  return NSMakeRect(x, y, w, h);
}

- (void) updateSelection:(NSRect)r {
  [sel_xField setIntegerValue:(NSInteger)r.origin.x];
  [sel_yField setIntegerValue:(NSInteger)r.origin.y];
  [sel_wField setIntegerValue:(NSInteger)r.size.width];
  [sel_hField setIntegerValue:(NSInteger)r.size.height];
}

- (void) updateImageInfo:(NSImage*)img {
  NSSize sz = [img size];
  [img_wField setIntegerValue:(NSInteger)sz.width];
  [img_hField setIntegerValue:(NSInteger)sz.height];
  
  [img_reps removeAllItems];
  for (NSImageRep* rep in [img representations]) {
    NSString* title = [rep description];
    [img_reps addItemWithTitle:title];
  }
}

- (void) orderFrontInspectorPanel:(id)sender {
  [panel makeKeyAndOrderFront:nil];
}

@end
