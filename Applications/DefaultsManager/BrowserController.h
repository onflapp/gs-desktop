/* 
 * BrowserController.h created by phr on 2000-11-10 22:18:37 +0000
 *
 * Project GSDefaults
 *
 * Created with ProjectCenter - http://www.projectcenter.ch
 *
 * $Id: BrowserController.h,v 1.2 2000/12/31 14:26:29 robert Exp $
 */

#import <AppKit/AppKit.h>

@interface BrowserController : NSObject
{
  id delegate;

  @private
  NSBrowser *browser;
  NSUserDefaults *defs;
}

- (id)initWithBrowser:(NSBrowser *)aBrowser;
- (void)dealloc;

- (void)setDelegate:(id)del;
- (id)delegate;

- (NSString *)selectedDomain;
- (NSString *)selectedKey;

- (void)click:(id)sender;
- (void)update;

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column;
- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column;

- (BOOL)browser:(NSBrowser *)sender isColumnValid:(int)column;
- (BOOL)browser:(NSBrowser *)sender selectCellWithString:(NSString *)title inColumn:(int)column;

@end

@interface NSObject (BrowserControllerDelegates)

- (void)browserController:(id)sender didSelectPropertyList:(id)plist;

@end
