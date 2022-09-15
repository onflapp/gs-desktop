/* Copyright (C) 2003 Raffael Herzog
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * $Id: IconView.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/IconView.m $
 */

#include <AppKit/AppKit.h>

#include "IconView.h"


@interface IconView (Private)

- (void)setArmed: (BOOL)a;
- (BOOL)armed;

@end

@interface PopUpIconView : IconView
{
    NSWindow *win;
    IconView *current;
    BOOL armedForDrag;
}

- (id)init;
- (void)dealloc;

- (void)attachTo: (IconView *)iconView;
- (IconView *)current;
- (void)notifyDealloc: (IconView *)iconView;

- (void)hidePopUp;

@end


NSString * const IconViewDidChangeIconNotification = @"IconViewDidChangeIconNotification";
static NSString * const IconViewPopUpPositionDefault = @"IconViewPopUp_Position";
static PopUpIconView *popUpIconView;


@implementation PopUpIconView

- (id)init
{
    self = [super init];
    if ( self ) {
        win = nil;
        current = nil;
        armedForDrag = NO;
        [[NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(iconViewDidChangeIcon:)
                                              name: (IconViewDidChangeIconNotification)
                                              object: (nil)];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    if ( win ) {
        [win close];
        RELEASE(win);
    }
    [super dealloc];
}

- (void)attachTo: (IconView *)iconView
{
    if ( ! win ) {
        NSRect rect = NSMakeRect(0, 0, 64, 64);
        NSString *positionString = [[NSUserDefaults standardUserDefaults] stringForKey: IconViewPopUpPositionDefault];
        if ( positionString ) {
            rect.origin = NSPointFromString(positionString);
        }
        else {
            NSRect winFrame = [[iconView window] frame];
            NSPoint origin = [[[iconView window] contentView] convertPoint: NSMakePoint(0,0) fromView: iconView];
            NSLog(@"%@", NSStringFromPoint(origin));
            rect.origin.x = winFrame.origin.x+origin.x+rect.size.height/2;
            rect.origin.y = winFrame.origin.y+origin.y-rect.size.height/2;
        }
        win = [[NSWindow alloc] initWithContentRect: rect
                                styleMask: (NSBorderlessWindowMask)
                                backing: (NSBackingStoreRetained)
                                defer: (YES)];
        [win setReleasedWhenClosed: NO];
        [win setLevel: NSPopUpMenuWindowLevel];
        [win setTitle: @"IconView PopUp"];
        [win setContentView: self];
    }
    [self setIcon: [iconView icon]];
    [self setInsetsSize: [iconView insetsSize]];
    current = iconView;
    [win orderFront: self];
}

- (IconView *)current
{
    return current;
}

- (void)notifyDealloc: (IconView *)iconView
{
    if ( iconView == current ) {
        [self hidePopUp];
    }
}

- (void)iconViewDidChangeIcon: (NSNotification *)not
{
    if ( current && ([not object]==current) ) {
        [self setIcon: [current icon]];
    }
}

- (void)concludeDragOperation: (id<NSDraggingInfo>)info
{
    if ( current ) {
        [current setIcon: [self icon]];
    }
    NSRect originalFrame = [win frame];
    NSRect frame = originalFrame;
    float min = (1+[self insetsSize])*2;
    for(;;) {
        frame = NSInsetRect(frame, 2, 2);
        if ( (frame.size.width<=min || (frame.size.height<=min)) ) {
            break;
        }
        [win setFrame: frame display: YES];
        [self display];
        [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
    }
    [self hidePopUp];
    [win setFrame: originalFrame display: NO];
}

- (BOOL)acceptsFirstMouse: (NSEvent *)evt;
{
    return YES;
}

- (void)hidePopUp
{
    [win close];
    current = nil;
}

/*
 * mouse events
 */

- (void)mouseDown: (NSEvent *)evt
{
    [super mouseDown: evt];
    armedForDrag = YES;
}

- (void)mouseUp: (NSEvent *)evt
{
    if ( [self armed] ) {
        [self hidePopUp];
    }
    [self setArmed: NO];
}

- (void)mouseDragged: (NSEvent *)evt
{
    if ( [self armed] ) {
        [self setArmed: NO];
    }
    if ( !armedForDrag ) {
        return;
    }

    BOOL done = NO;
    [NSEvent startPeriodicEventsAfterDelay: 0.02 withPeriod: 0.02];

    NSPoint location;
    NSPoint lastLocation = [evt locationInWindow];
    unsigned eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
	| NSPeriodicMask | NSOtherMouseUpMask | NSRightMouseUpMask;
    NSDate *theDistantFuture = [NSDate distantFuture];
    while ( !done ) {
        evt = [NSApp nextEventMatchingMask: eventMask
                     untilDate: (theDistantFuture)
                     inMode: (NSEventTrackingRunLoopMode)
                     dequeue: (YES)];
        switch ([evt type]) {
        case NSRightMouseUp:
        case NSOtherMouseUp:
        case NSLeftMouseUp:
            // any mouse up means we're done
            done = YES;
            break;
        case NSPeriodic:
            location = [win mouseLocationOutsideOfEventStream];
            if (NSEqualPoints(location, lastLocation) == NO) {
                NSPoint origin = [win frame].origin;
                origin.x += (location.x - lastLocation.x);
                origin.y += (location.y - lastLocation.y);
                [win setFrameOrigin: origin];
            }
            break;

        default:
            break;
        }
    }
    armedForDrag = NO;
    [[NSUserDefaults standardUserDefaults] setObject: NSStringFromPoint([win frame].origin)
                                           forKey: (IconViewPopUpPositionDefault)];

    [NSEvent stopPeriodicEvents];
}

@end


@implementation IconView

+ (void)initialize
{
    popUpIconView = [[PopUpIconView alloc] init];
}

- (id)init
{
    self = [super init];
    if ( self ) {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib
{
    insetsSize = 8;
}

- (void)dealloc
{
    [popUpIconView notifyDealloc: self];
    TEST_AUTORELEASE(icon);
    TEST_AUTORELEASE(draggingImage);
    TEST_AUTORELEASE(delegate);
    [super dealloc];
}

- (float)insetsSize
{
    return insetsSize;
}

- (void)setInsetsSize: (float)s
{
    insetsSize = s;
    [self setNeedsDisplay: YES];
}

- (Icon *)icon
{
    return icon;
}

- (void)setIcon: (Icon *)i
{
    if ( i != icon ) {
        ASSIGN(icon, i);
        [self setNeedsDisplay: YES];
        NSNotification *not = [NSNotification notificationWithName: IconViewDidChangeIconNotification
                                              object: (self)];
        [[NSNotificationCenter defaultCenter] postNotification: not];
    }
}

- (void)drawRect: (NSRect)rect
{
    if ( NSIsEmptyRect(rect) ) {
        return;
    }

    // draw border
    if ( [self armed] ) {
        NSDrawLightBezel(rect, NSZeroRect);
    }
    else {
        NSDrawGroove(rect, NSZeroRect);
    }

    // done, if there's no image
    if ( !icon ) {
        return;
    }

    // draw the image
    NSRect interior = NSInsetRect(rect, insetsSize, insetsSize);
    NSImage *image = [icon imageForSize: interior.size
                           copy: (NO)];
    NSSize size = [image size];
    NSPoint position = interior.origin;
    // center the image
    position.x += (interior.size.width-size.width)/2;
    position.y += (interior.size.height-size.height)/2;
    [image compositeToPoint: position operation: NSCompositeSourceOver];
}

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];
    if ( [self superview] && !registeredForDraggedTypes ) {
        [self registerForDraggedTypes: [NSArray arrayWithObjects: NSTIFFPboardType, NSFilenamesPboardType, nil]];
        registeredForDraggedTypes = YES;
    }
    else if ( registeredForDraggedTypes ) {
        [self unregisterDraggedTypes];
        registeredForDraggedTypes = NO;
    }
}

- (NSDragOperation)draggingEntered: (id<NSDraggingInfo>)info
{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *types = [pboard types];
    if ( [types count] != 1 ) {
        return NSDragOperationNone;
    }
    else {
        draggingImage = RETAIN([[NSImage alloc] initWithPasteboard: pboard]);
        if ( draggingImage ) {
            return NSDragOperationCopy;
        }
        else {
            return NSDragOperationNone;
        }
    }
}

- (void)draggingExited: (id<NSDraggingInfo>)info
{
    TEST_RELEASE(draggingImage);
    draggingImage = nil;
}

- (BOOL)prepareForDragOperation: (id<NSDraggingInfo>)info
{
    if ( draggingImage ) {
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)performDragOperation: (id<NSDraggingInfo>)info
{
    if ( draggingImage ) {
        [self setIcon: [Icon iconWithImage: draggingImage]];
        RELEASE(draggingImage);
        draggingImage = nil;
        return YES;
    }
    else {
        return NO;
    }
}

- (void)concludeDragOperation: (id<NSDraggingInfo>)info
{
}



/*
 * mouse events
 */

- (void)mouseDown: (NSEvent *)evt
{
    [self setArmed: YES];
}

- (void)mouseUp: (NSEvent *)evt
{
    if ( [self armed] ) {
        if ( [popUpIconView current] == self ) {
            [popUpIconView hidePopUp];
        }
        else {
            [popUpIconView attachTo: self];
        }
    }
    [self setArmed: NO];
}

- (void)mouseDragged: (NSEvent *)evt
{
    [self setArmed: NO];
    if ( !dndOperation ) {
        NSImage *img = [[self icon] imageCopy: NO];
        NSRect interior = NSInsetRect([self bounds], insetsSize, insetsSize);
        NSImage *dragImage = [icon imageForSize: interior.size
                                   copy: (YES)];
        NSSize size = [dragImage size];
        NSPoint position = interior.origin;
        // center the image
        position.x += (interior.size.width-size.width)/2;
        position.y += (interior.size.height-size.height)/2;
        NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
        [pboard declareTypes: [NSArray arrayWithObject: NSTIFFPboardType] owner: self];
        [pboard setData: [img TIFFRepresentation] forType: NSTIFFPboardType];
        [self dragImage: dragImage
              at: (position)
              offset: (NSMakeSize(0, 0))
              event: (evt)
              pasteboard: (pboard)
              source: (self)
              slideBack: (YES)];
        dndOperation = YES;
    }
}

- (void)draggedImage: (NSImage *)img
             endetAt: (NSPoint *)where
           operation: (NSDragOperation *)operation
{
    NSLog(@"DND operation end");
    dndOperation = NO;
}

- (unsigned int)draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
    return NSDragOperationCopy;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
    return YES;
}

@end

@implementation IconView (Private)

- (void)setArmed: (BOOL)a
{
    armed = a;
    [self setNeedsDisplay: YES];
}

- (BOOL)armed
{
    return armed;
}

@end

/* This is a workaround... Gorm for some reason doesn't like it if I
 * use two times the same class for CustomViews - or maybe something's
 * wrong with the implementation of IconView? I don't know, have to
 * ask gnustep-discuss about this.
 *
 * For now, it works like this.
 */

@interface IconView2 : IconView
@end

@implementation IconView2
@end
