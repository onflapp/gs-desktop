#import <AppKit/AppKit.h>

@interface InspectorPanel : NSObject {
  IBOutlet NSPanel* panel;
  IBOutlet NSTextField* sel_xField;
  IBOutlet NSTextField* sel_yField;
  IBOutlet NSTextField* sel_wField;
  IBOutlet NSTextField* sel_hField;
}

+ (id)sharedInstance;
- (void)orderFrontInspectorPanel:(id)sender;

- (void)updateSelection:(NSRect)r;

@end
