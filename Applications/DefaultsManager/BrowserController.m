/* 
 * BrowserController.m created by phr on 2000-11-10 22:18:36 +0000
 *
 * Project GSDefaults
 *
 * Created with ProjectCenter - http://www.projectcenter.ch
 *
 * $Id: BrowserController.m,v 1.2 2000/12/31 14:26:29 robert Exp $
 */

#import "BrowserController.h"

@implementation BrowserController

- (id)initWithBrowser:(NSBrowser *)aBrowser;
{
  NSAssert(aBrowser,@"No valid browser!");

  if ((self = [super init])) {
    browser = RETAIN(aBrowser);
    [browser setDelegate:self];
    [browser setTitle:@"Domains" ofColumn:0];
    [browser setTarget:self];
    [browser setAction:@selector(click:)];

    defs = [NSUserDefaults standardUserDefaults];
  }
  return self;
}

- (void)dealloc;
{
  RELEASE(browser);

  [super dealloc];
}

- (void)setDelegate:(id)del
{
  delegate = del;
}

- (id)delegate
{
  return delegate;
}

- (NSString *)selectedDomain
{
  return [[browser selectedCellInColumn:0] stringValue];
}

- (NSString *)selectedKey
{
  NSCell *cell = [browser selectedCellInColumn:1];

  if (cell) {
    return [cell stringValue];
  }
  else {
    return nil;
  }
}

- (void)click:(id)sender
{
  if ([[sender selectedCell] isLeaf]) {
    NSString *key = [[sender selectedCell] stringValue];
    NSString *domain = [[sender selectedCellInColumn:0] stringValue];
    id plist = [[defs persistentDomainForName:domain] objectForKey:key];

    if (delegate && 
	[delegate respondsToSelector:@selector(browserController:didSelectPropertyList:)]) {
      [delegate browserController:self didSelectPropertyList:plist];
    }
  }
}

- (void)update
{
  [defs synchronize];
  [browser loadColumnZero];
}

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
{
  if (column == 0) {
    return [[defs persistentDomainNames] count];
  }
  else if (column == 1) {
    NSString *nm = [[browser selectedCellInColumn:0] stringValue];

    return [[defs persistentDomainForName:nm] count];
  }

  return 0;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column
{
  if ([sender isEqual:browser]) {
    if (column == 0) {
      id _str = [[[defs persistentDomainNames] objectAtIndex:row] description];

      [cell setStringValue:_str];
    }
    else if (column == 1) {
      NSString *nm = [[browser selectedCellInColumn:0] stringValue];      
      NSArray *keys = [[defs persistentDomainForName:nm] allKeys];
      NSString *_title = [keys objectAtIndex:row];

      [cell setLeaf:YES];
      [cell setStringValue:_title];
    }
  }
}

- (BOOL)browser:(NSBrowser *)sender isColumnValid:(int)column
{
  return YES;
}

- (BOOL)browser:(NSBrowser *)sender selectCellWithString:(NSString *)title inColumn:(int)column
{
  return YES;
}

@end

