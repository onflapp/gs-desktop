#import <AppKit/AppKit.h>

@interface InspectorPanel : NSObject {
  IBOutlet NSPanel* panel;
  IBOutlet NSTextField* sel_xField;
  IBOutlet NSTextField* sel_yField;
  IBOutlet NSTextField* sel_wField;
  IBOutlet NSTextField* sel_hField;

  IBOutlet NSTextField* img_wField;
  IBOutlet NSTextField* img_hField;

  IBOutlet NSPopUpButton* img_reps;
}

+ (id)sharedInstance;
- (void)orderFrontInspectorPanel:(id)sender;

- (NSRect) selectedRectangle;
- (void)updateSelection:(NSRect)r;
- (void)updateImageInfo:(NSImage*)img;

@end
