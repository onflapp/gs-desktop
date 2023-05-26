/*
     File: SKInspectorController.h
 Abstract: A controller to manage the inspector panel.
 */

#import <Cocoa/Cocoa.h>

@interface SKInspectorController : NSWindowController {
     IBOutlet NSButton* lineButtton;
     IBOutlet NSButton* fillButtton;
     IBOutlet NSColorWell* lineColorWell;
     IBOutlet NSColorWell* fillColorWell;
     IBOutlet NSSlider* lineWidthSlider;
     IBOutlet NSTextField* lineWidthField;
     IBOutlet NSTextField* boundsXField;
     IBOutlet NSTextField* boundsYField;
     IBOutlet NSTextField* boundsWField;
     IBOutlet NSTextField* boundsHField;
}

+ (id)sharedInspectorController;
- (void)refreshSelection;
- (IBAction)updateSelection:(id) sender;
@end
