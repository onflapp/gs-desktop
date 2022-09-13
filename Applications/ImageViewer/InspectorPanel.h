#import <AppKit/AppKit.h>

@interface InspectorPanel : NSObject {
  IBOutlet NSPanel* panel;
  IBOutlet NSTextField* typeField;
}

+ (id)sharedInstance;
- (void)orderFrontInspectorPanel:(id)sender;

@end
