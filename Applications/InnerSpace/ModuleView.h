#include <AppKit/AppKit.h>

@interface ModuleView : NSView
{
}
// animation methods...
- (void) oneStep;
- (NSTimeInterval) animationDelayTime;
- (void) didLockFocus;

// inspector methods...
- (NSView *) inspector: (id)sender;
- (void) inspectorInstalled;
- (void) inspectorWillBeRemoved;

// window methods...
- (BOOL) useBufferedWindow;
- (BOOL) isBoringScreenSaver;
- (BOOL) ignoreMouseMovement;
- (NSString *) windowTitle;

// notification methods..
- (void) willEnterScreenSaverMode;
- (void) enteredScreenSaverMode;
- (void) willExitScreenSaverMode;
@end
