/* All Rights reserved */

#include <AppKit/AppKit.h>

@interface Controller : NSObject
{
  id propSelector;
  id propView;
  id autoselPopup;
}
- (void) selectProperty: (id)sender;
- (void) printSelected: (id)sender;

- (void) setAutoselect: (id) sender;
- (void) setPreferred: (id) sender;
@end
