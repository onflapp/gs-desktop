/*
     File: SKTAppDelegate.m
 Abstract: The application delegate: This object manages display of the preferences panel, graphics inspector, and tools palette.
 */

#import "SKTAppDelegate.h"
#import "SKTToolPaletteController.h"


// Keys that are used in Sketch's user defaults.
static NSString *SKTAppAutosavesPreferenceKey = @"autosaves";
static NSString *SKTAppAutosavingDelayPreferenceKey = @"autosavingDelay";


#pragma mark *** NSWindowController Conveniences ***


@interface NSWindowController(SKTConvenience)
- (BOOL)isWindowShown;
- (void)showOrHideWindow;
@end
@implementation NSWindowController(SKTConvenience)


- (BOOL)isWindowShown {

    // Simple.
    return [[self window] isVisible];

}

- (void)showOrHideWindow {

    // Simple.
    NSWindow *window = [self window];
    if ([window isVisible]) {
	[window orderOut:self];
    } else {
	[self showWindow:self];
    }

}

@end


@implementation SKTAppDelegate


#pragma mark *** Launching ***


// Conformance to the NSObject(NSApplicationNotifications) informal protocol.
- (void)applicationDidFinishLaunching:(NSNotification *)notification {

    // The tool palette should always show up right away.
    [self showOrHideToolPalette:self];
}


#pragma mark *** Preferences ***


// Conformance to the NSObject(NSApplicationNotifications) informal protocol.
- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    _gridInspectorController     = [SKGridPanelController sharedGridPanelController];
    _graphicsInspectorController = [SKInspectorController sharedInspectorController];

    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    [userDefaultsController setInitialValues:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], SKTAppAutosavesPreferenceKey, [NSNumber numberWithDouble:60.0], SKTAppAutosavingDelayPreferenceKey, nil]];
}


- (void)setAutosaves:(BOOL)autosaves {
    // The user has toggled the "autosave documents" checkbox in the preferences panel.
    if (autosaves) {

	// Get the autosaving delay and set it in the NSDocumentController.
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:_autosavingDelay];

    } else {

	// Set a zero autosaving delay in the NSDocumentController. This tells it to turn off autosaving.
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:0.0];

    }
    _autosaves = autosaves;

}

- (void)setAutosavingDelay:(NSTimeInterval)autosaveDelay {

    // Is autosaving even turned on right now?
    if (_autosaves) {

	// Set the new autosaving delay in the document controller, but only if autosaving is being done right now.
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:autosaveDelay];

    }
    _autosavingDelay = autosaveDelay;
}


- (IBAction)showPreferencesPanel:(id)sender {

    // We always show the same preferences panel. Its controller doesn't get deallocated when the user closes it.
    if (!_preferencesPanelController) {
	_preferencesPanelController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];

	// Make the panel appear in a good default location.
	[[_preferencesPanelController window] center];

    }
    [_preferencesPanelController showWindow:sender];

}


#pragma mark *** Other Actions ***


- (IBAction)showOrHideGraphicsInspector:(id)sender {
    [_graphicsInspectorController refreshSelection];
    [_graphicsInspectorController showOrHideWindow];
}


- (IBAction)showOrHideGridInspector:(id)sender {
    [_gridInspectorController showOrHideWindow];
}


- (IBAction)showOrHideToolPalette:(id)sender {
    // We always show the same tool palette panel. Its controller doesn't get deallocated when the user closes it.
    [[SKTToolPaletteController sharedToolPaletteController] showOrHideWindow];
}


- (IBAction)chooseSelectionTool:(id)sender {

    // Simple.
    [[SKTToolPaletteController sharedToolPaletteController] selectArrowTool];

}


// Conformance to the NSObject(NSMenuValidation) informal protocol.
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    // A few menu item's names change between starting with "Show" and "Hide."
    SEL action = [menuItem action];
    if (action==@selector(showOrHideGraphicsInspector:)) {
	[menuItem setTitle:([_graphicsInspectorController isWindowShown] ? NSLocalizedStringFromTable(@"Hide Inspector", @"SKTAppDelegate", @"A main menu item title.") : NSLocalizedStringFromTable(@"Show Inspector", @"SKTAppDelegate", @"A main menu item title."))];
    } else if (action==@selector(showOrHideGridInspector:)) {
	[menuItem setTitle:([_gridInspectorController isWindowShown] ? NSLocalizedStringFromTable(@"Hide Grid Options", @"SKTAppDelegate", @"A main menu item title.") : NSLocalizedStringFromTable(@"Show Grid Options", @"SKTAppDelegate", @"A main menu item title."))];
    } else if (action==@selector(showOrHideToolPalette:)) {
	[menuItem setTitle:([[SKTToolPaletteController sharedToolPaletteController] isWindowShown] ? NSLocalizedStringFromTable(@"Hide Tools", @"SKTAppDelegate", @"A main menu item title.") : NSLocalizedStringFromTable(@"Show Tools", @"SKTAppDelegate", @"A main menu item title."))];
    }
    return YES;

}


@end
