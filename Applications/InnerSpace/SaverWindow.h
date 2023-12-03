/* All Rights reserved */

#include <AppKit/AppKit.h>

@interface SaverWindow : NSWindow
{
  id  target;
  SEL action;
}
- (void) setAction: (SEL)action forTarget: (id) target;
- (void) makeOmnipresent;
@end
