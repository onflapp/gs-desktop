/*
*/

#ifndef _USERMANAGER_H_
#define _USERMANAGER_H_

#import <AppKit/AppKit.h>
#import <TerminalKit/TerminalKit.h>

@interface UMTerminalView : TerminalView
- (void) runManager;
@end

@interface UserManager : NSObject
{
   IBOutlet UMTerminalView* terminalView;
   IBOutlet NSPanel* panel;
   IBOutlet NSView* view;
}

- (NSPanel*) panel;
- (NSView*) view;

@end

#endif // _USERMANAGER_H_

