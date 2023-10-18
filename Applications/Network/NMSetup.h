/*
*/

#ifndef _NMSETUP_H_
#define _NMSETUP_H_

#import <AppKit/AppKit.h>
#import <TerminalKit/TerminalKit.h>

@interface NMTerminalView : TerminalView
- (void) runSetup;
@end

@interface NMSetup : NSObject
{
   IBOutlet NMTerminalView* terminalView;
   IBOutlet NSPanel* panel;
}

- (NSPanel*) panel;
- (void) showPanelAndRunSetup:(id)sender;

@end

#endif // _NMSETUP_H_

