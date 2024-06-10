/*
     File: SKTZoomingScrollView.m
 Abstract: A controller to manage zooming of a Sketch graphics view.
 */

#import "SKTZoomingScrollView.h"


// Default labels and values for the menu items that will be in the popup button that we build.
static NSString * const SKTZoomingScrollViewLabels[] = {@"10%", @"25%", @"50%", @"75%", @"100%", @"125%", @"150%", @"200%", @"400%", @"800%", @"1600%"};
static const CGFloat SKTZoomingScrollViewFactors[] = {0.1f, 0.25f, 0.5f, 0.75f, 1.0f, 1.25f, 1.5f, 2.0f, 4.0f, 8.0f, 16.0f};
static const NSInteger SKTZoomingScrollViewPopUpButtonItemCount = sizeof(SKTZoomingScrollViewLabels) / sizeof(NSString *);

@implementation SKTZoomingScrollView


- (void)validateFactorPopUpButton {

    // Ignore redundant invocations.
    if (!_factorPopUpButton) {

	// Create the popup button and configure its appearance. The initial size doesn't matter.
        _factorPopUpButton = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        NSPopUpButtonCell *factorPopUpButtonCell = [_factorPopUpButton cell];
        [factorPopUpButtonCell setArrowPosition:NSPopUpArrowAtBottom];
        [factorPopUpButtonCell setBezelStyle:NSShadowlessSquareBezelStyle];
        [_factorPopUpButton setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];

        // Populate it and size it to fit the just-added menu item cells.
        NSInteger index;
        for (index = 0; index<SKTZoomingScrollViewPopUpButtonItemCount; index++) {
            [_factorPopUpButton addItemWithTitle:NSLocalizedStringFromTable(SKTZoomingScrollViewLabels[index], @"SKTZoomingScrollView", nil)];
            id item = [_factorPopUpButton itemAtIndex:index];
            [item setRepresentedObject:[NSNumber numberWithDouble:SKTZoomingScrollViewFactors[index]]];
            [item setTarget:self];
            [item setAction:@selector(selectFactor:)];
        }
        [_factorPopUpButton sizeToFit];
        [_factorPopUpButton selectItemAtIndex:4];

        // Make it appear, and then release it right away, which is safe because -addSubview: retains it.
        [self addSubview:_factorPopUpButton];
        [_factorPopUpButton release];
    }
}

- (void) selectFactor:(id) sender {
    CGFloat factor = [[sender representedObject]doubleValue];
    [self setFactor:factor];
}


#pragma mark *** Bindings ***


- (void)setFactor:(CGFloat)factor {

    //The default implementation of key-value binding is informing this object that the value to which our "factor" property is bound has changed. Record the value, and apply the zoom factor by fooling with the bounds of the clip view that every scroll view has. (We leave its frame alone.)
    _factor = factor;
    NSView *clipView = [[self documentView] superview];
    NSSize clipViewFrameSize = [clipView frame].size;
    [clipView setBoundsSize:NSMakeSize((clipViewFrameSize.width / factor), (clipViewFrameSize.height / factor))];
    
}

#pragma mark *** View Customization ***


// An override of the NSScrollView method.
- (void)tile {

    // This class lives to put a popup button next to a horizontal scroll bar.
    NSAssert([self hasHorizontalScroller], @"SKTZoomingScrollView doesn't support use without a horizontal scroll bar.");

    // Do NSScrollView's regular tiling, and find out where it left the horizontal scroller.
    [super tile];
    NSScroller *horizontalScroller = [self horizontalScroller];
    NSRect horizontalScrollerFrame = [horizontalScroller frame];

    // Place the zoom factor popup button to the left of where the horizontal scroller will go, creating it first if necessary, and leaving its width alone.
    [self validateFactorPopUpButton];
    NSRect factorPopUpButtonFrame = [_factorPopUpButton frame];
    factorPopUpButtonFrame.origin.x = horizontalScrollerFrame.origin.x;
    factorPopUpButtonFrame.origin.y = horizontalScrollerFrame.origin.y;
    factorPopUpButtonFrame.size.height = horizontalScrollerFrame.size.height;
    [_factorPopUpButton setFrame:factorPopUpButtonFrame];

    // Adjust the scroller's frame to make room for the zoom factor popup button next to it.
    horizontalScrollerFrame.origin.x += factorPopUpButtonFrame.size.width;
    horizontalScrollerFrame.size.width -= factorPopUpButtonFrame.size.width;
    [horizontalScroller setFrame:horizontalScrollerFrame];    
}

@end
