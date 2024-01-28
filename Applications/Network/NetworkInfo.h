/*
*/

#ifndef _NETWORKINFO_H_
#define _NETWORKINFO_H_

#import <AppKit/AppKit.h>
#import <TerminalKit/TerminalKit.h>

@interface NetworkInfo : NSObject
{
   IBOutlet NSTextView* textView;
   IBOutlet NSPanel* panel;
}

- (NSPanel*) panel;
- (void) showPanelAndRunInfo:(id)sender;

@end

#endif // _NETWORKINFO_H_

