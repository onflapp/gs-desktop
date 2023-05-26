/*
     File: SKTToolPaletteController.m
 Abstract: A controller to manage the tools palette.
 */

#import "SKInspectorController.h"

@implementation SKInspectorController

+ (id)sharedInspectorController {
    static SKInspectorController *sharedInspectorController = nil;

    if (!sharedInspectorController) {
        sharedInspectorController = [[SKInspectorController allocWithZone:NULL] init];
    }

    return sharedInspectorController;
}

- (id)init {
    self = [self initWithWindowNibName:@"Inspector"];
    if (self) {
        [self setWindowFrameAutosaveName:@"Inspector"];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (void)refreshSelection {
    NSArray* sel = [NSApp valueForKeyPath:@"mainWindow.windowController.graphicsController.selectedObjects"];
    [fillButtton setState:0];
    [lineButtton setState:0];
    [lineWidthSlider setIntegerValue:1];
    [lineWidthField setIntegerValue:1];

    for (id it in sel) {
        if ([[it valueForKey:@"drawingFill"] integerValue]) {
            [fillButtton     setState:1];
            [fillColorWell   setColor:[it valueForKey:@"fillColor"]];
        }
        if ([[it valueForKey:@"drawingStroke"] integerValue]) {
            [lineButtton     setState:1];
            [lineColorWell   setColor:[it valueForKey:@"strokeColor"]];
            NSInteger val = [[it valueForKey:@"strokeWidth"] integerValue];
            if (val) {
                [lineWidthField  setIntegerValue:val];
                [lineWidthSlider setIntegerValue:val];
            }
        }
    }
}

- (IBAction)updateSelection:(id) sender {
    id sel = [NSApp valueForKeyPath:@"mainWindow.windowController.graphicsController.selectedObjects"];
    id ctrl = [NSApp valueForKeyPath:@"mainWindow.windowController"];

    if (sender == fillColorWell) {
        [fillButtton setState:1];
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:1] forKey:@"drawingFill"];
            [it setValue:[fillColorWell color] forKey:@"fillColor"];
        }
    }
    if (sender == fillButtton) {
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:[fillButtton state]] forKey:@"drawingFill"];
            [it setValue:[fillColorWell color] forKey:@"fillColor"];
        }
    }
    if (sender == lineButtton) {
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:[lineButtton state]] forKey:@"drawingStroke"];
            [it setValue:[lineColorWell color] forKey:@"strokeColor"];
        }
    }
    if (sender == lineColorWell) {
        [lineButtton setState:1];
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:1] forKey:@"drawingStroke"];
            [it setValue:[lineColorWell color] forKey:@"strokeColor"];
        }
    }
    if (sender == lineWidthSlider) {
        NSInteger val = floor([lineWidthSlider floatValue]);
        NSInteger drs = 1;
        [lineWidthField setIntegerValue:val];
        if (val == 0) {
            drs = 0;
            [lineButtton setState:0];
        }
        else {
            [lineButtton setState:1];
        }
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:val] forKey:@"strokeWidth"];
            [it setValue:[NSNumber numberWithInteger:drs] forKey:@"drawingStroke"];
        }
    }
    if (sender == lineWidthField) {
        [lineWidthSlider setIntegerValue:[lineWidthField integerValue]];
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:[lineWidthField integerValue]] forKey:@"strokeWidth"];
        }
    }

    [ctrl redraw];
}
@end
