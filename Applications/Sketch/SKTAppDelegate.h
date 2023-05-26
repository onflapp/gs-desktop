/*
     File: SKTAppDelegate.h
 Abstract: The application delegate: This object manages display of the preferences panel, graphics inspector, and tools palette.
 */

#import <Cocoa/Cocoa.h>
#import "SKInspectorController.h"
#import "SKGridPanelController.h"

@interface SKTAppDelegate : NSObject {
    @private
    NSWindowController *_preferencesPanelController;
    SKInspectorController *_graphicsInspectorController;
    SKGridPanelController *_gridInspectorController;

    // Values that come from the user defaults, via the key-value bindings that we set up in -applicationWillFinishLaunching:. It might be a little more natural to put this functionality in a subclass of NSDocumentController, but it doesn't make a big difference. At the time these were added Sketch had no subclass of SKTDocumentController. Now that it has one it's not worthwhile to move this stuff.
    BOOL _autosaves;
    NSTimeInterval _autosavingDelay;

}

// Actions that show or hide various panels. In Sketch each is the target of a main menu item.
- (IBAction)showPreferencesPanel:(id)sender;
- (IBAction)showOrHideGraphicsInspector:(id)sender;
- (IBAction)showOrHideGridInspector:(id)sender;
- (IBAction)showOrHideToolPalette:(id)sender;

// The "Selection Tool" action in Sketch's Tools menu.
- (IBAction)chooseSelectionTool:(id)sender;

@end

