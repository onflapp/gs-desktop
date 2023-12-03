/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "SaverWindow.h"
#include "ModuleView.h"

@interface InnerSpaceController : NSObject
{
  // interface vars.
  id window;
  id moduleList;
  id inBackground;
  id locker;
  id saver;
  id run;
  id controlsView;
  id emptyView;
  id lockerPanel;
  id speedSlider;

  // internal vars.
  SaverWindow *saverWindow;
  NSTimer *timer;
  ModuleView *currentModule;
  NSMutableDictionary *modules;
  NSUserDefaults *defaults;
  NSString *currentModuleName;

  // booleans...
  BOOL isSaver;
  BOOL isLocker;
  BOOL isInBackground;
}
// methods called from interface
- (void) selectSaver: (id)sender;
- (void) inBackground: (id)sender;
- (void) locker: (id)sender;
- (void) saver: (id)sender;
- (void) doSaver: (id)sender;
- (void) doSaverInBackground: (id)sender;
- (void) stopSaver; // : (id)sender;
- (void) stopAndStartSaver; // : (id)sender;

// internal methods
- (NSMutableDictionary *) modules;
- (void) createSaverWindow: (BOOL)desktop;
- (void) startTimer;
- (void) stopTimer;
- (void) resetTimer;
- (void) runAnimation: (NSTimer *)atimer;
- (void) loadModule: (NSString *)moduleName;
- (void) loadDefaults;
- (void) findModulesInDirectory: (NSString *) directory;
- (void) findModules;
@end
