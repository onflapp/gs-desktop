/* 
 * DefaultsManager.h created by phr on 2000-11-10 22:03:39 +0000
 *
 * Project GSDefaults
 *
 * Created with ProjectCenter - http://www.projectcenter.ch
 *
 * $Id: DefaultsManager.h,v 1.1.1.1 2000/11/10 23:04:55 robert Exp $
 */

#import <AppKit/AppKit.h>

@class BrowserController;

@interface DefaultsManager : NSObject
{
  NSWindow *mainWindow;
  BrowserController *browserController;
  NSTextView *textView;
}

+ (id)sharedManager;

- (void)dealloc;

- (void)openMainWindow;
- (void)buttonsPressed:(id)sender;

@end

@interface DefaultsManager (DelegateMethod)

- (void)browserController:(id)sender didSelectPropertyList:(id)plist;

@end
