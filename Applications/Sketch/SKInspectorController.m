/*
     File: SKTToolPaletteController.m
 Abstract: A controller to manage the tools palette.
 */

#import "SKInspectorController.h"
#import "SKTGraphic.h"

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

- (BOOL)isSelectingLineColor {
    return [lineColorWell isActive];
}

- (BOOL)isSelectingFillColor {
    return [fillColorWell isActive];
}

- (void)refreshSelection {
    NSArray* sel = [NSApp valueForKeyPath:@"mainWindow.windowController.graphicsController.selectedObjects"];
    [fillButtton setState:0];
    [lineButtton setState:0];
    [lineWidthSlider setIntegerValue:1];
    [lineWidthField setIntegerValue:1];

    for (id it in sel) {
        if ([[it valueForKey:SKTGraphicIsDrawingFillKey] integerValue]) {
            [fillButtton     setState:1];
            [fillColorWell   setColor:[it valueForKey:SKTGraphicFillColorKey]];
        }
        if ([[it valueForKey:SKTGraphicIsDrawingStrokeKey] integerValue]) {
            [lineButtton     setState:1];
            [lineColorWell   setColor:[it valueForKey:SKTGraphicStrokeColorKey]];
            NSInteger val = [[it valueForKey:SKTGraphicStrokeWidthKey] integerValue];
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
            [it setValue:[NSNumber numberWithInteger:1] forKey:SKTGraphicIsDrawingFillKey];
            [it setValue:[fillColorWell color] forKey:SKTGraphicFillColorKey];
        }
    }
    else if (sender == fillButtton) {
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:[fillButtton state]] forKey:SKTGraphicIsDrawingFillKey];
            [it setValue:[fillColorWell color] forKey:SKTGraphicFillColorKey];
        }
    }
    else if (sender == lineButtton) {
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:[lineButtton state]] forKey:SKTGraphicIsDrawingStrokeKey];
            [it setValue:[lineColorWell color] forKey:SKTGraphicStrokeColorKey];
        }
    }
    else if (sender == lineColorWell) {
        [lineButtton setState:1];
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:1] forKey:SKTGraphicIsDrawingStrokeKey];
            [it setValue:[lineColorWell color] forKey:SKTGraphicStrokeColorKey];
        }
    }
    else if (sender == lineWidthSlider) {
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
            [it setValue:[NSNumber numberWithInteger:val] forKey:SKTGraphicStrokeWidthKey];
            [it setValue:[NSNumber numberWithInteger:drs] forKey:SKTGraphicIsDrawingStrokeKey];
        }
    }
    else if (sender == lineWidthField) {
        [lineWidthSlider setIntegerValue:[lineWidthField integerValue]];
        for (id it in sel) {
            [it setValue:[NSNumber numberWithInteger:[lineWidthField integerValue]] forKey:SKTGraphicStrokeWidthKey];
        }
    }

    [ctrl redraw];
}
@end
