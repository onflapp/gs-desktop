/*
     File: SKTToolPaletteController.m
 Abstract: A controller to manage the tools palette.
 */

#import "SKTToolPaletteController.h"
#import "SKTCircle.h"
#import "SKTLine.h"
#import "SKTRectangle.h"
#import "SKTText.h"

enum {
    SKTArrowToolRow = 0,
    SKTRectToolRow,
    SKTCircleToolRow,
    SKTLineToolRow,
    SKTTextToolRow,
};

NSString *SKTSelectedToolDidChangeNotification = @"SKTSelectedToolDidChange";

@implementation SKTToolPaletteController

+ (id)sharedToolPaletteController {
    static SKTToolPaletteController *sharedToolPaletteController = nil;

    if (!sharedToolPaletteController) {
        sharedToolPaletteController = [[SKTToolPaletteController allocWithZone:NULL] init];
    }

    return sharedToolPaletteController;
}

- (id)init {
    self = [self initWithWindowNibName:@"ToolPalette"];
    if (self) {
        [self setWindowFrameAutosaveName:@"ToolPalette"];
    }
    return self;
}

- (void)windowDidLoad {
    NSArray *cells = [toolButtons cells];
    NSUInteger i, c = [cells count];
    
    [super windowDidLoad];

    for (i=0; i<c; i++) {
        [[cells objectAtIndex:i] setRefusesFirstResponder:YES];
    }
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
}

- (IBAction)selectToolAction:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKTSelectedToolDidChangeNotification object:self];
}

- (Class)currentGraphicClass {
    NSInteger row = [toolButtons selectedRow];
    Class theClass = nil;
    if (row == SKTRectToolRow) {
        theClass = [SKTRectangle class];
    } else if (row == SKTCircleToolRow) {
        theClass = [SKTCircle class];
    } else if (row == SKTLineToolRow) {
        theClass = [SKTLine class];
    } else if (row == SKTTextToolRow) {
        theClass = [SKTText class];
    }
    return theClass;
}

- (void)selectArrowTool {
    [toolButtons selectCellAtRow:SKTArrowToolRow column:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKTSelectedToolDidChangeNotification object:self];
}

@end
