/*
     File: SKTToolPaletteController.m
 */

#import "SKGridPanelController.h"

@implementation SKGridPanelController

+ (id)sharedGridPanelController {
    static SKGridPanelController *sharedGridPanelController = nil;

    if (!sharedGridPanelController) {
        sharedGridPanelController = [[SKGridPanelController allocWithZone:NULL] init];
    }

    return sharedGridPanelController;
}

- (id)init {
    self = [self initWithWindowNibName:@"GridPanel"];
    if (self) {
        [self setWindowFrameAutosaveName:@"GridPanel"];
	      [self setShouldCascadeWindows:NO];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

@end
