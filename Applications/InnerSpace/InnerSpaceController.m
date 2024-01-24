/* All Rights reserved */

#include <AppKit/AppKit.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include "InnerSpaceController.h"

#define TIME 0.10

@implementation InnerSpaceController

// interface callbacks
- (void) selectSaver: (id)sender
{
  id module = nil;
  int row = [moduleList selectedRowInColumn: [moduleList selectedColumn]];

  if(row >= 0)
    {
      module = [[modules allKeys] objectAtIndex: row];
      [defaults setObject: module forKey: @"currentModule"];
      [self loadModule: module];
      [self createSaverWindow: YES];
      [self startTimer];
    }

  NSDebugLog(@"Called");
  /* insert your code here */
}

- (void) inBackground: (id)sender
{
  isInBackground = ([inBackground state] == NSOnState);
  [defaults setObject:[NSNumber numberWithInt:isInBackground] forKey:@"runInBackgroud"];
}

- (void) locker: (id)sender
{
  isLocker = ([locker state] == NSOnState);
}

- (void) saver: (id)sender
{
  isSaver = ([saver state] == NSOnState);
}

- (void) doSaver: (id)sender
{
  if (!currentModule && currentModuleName) {
    [self loadModule:currentModuleName];
  }
  if (currentModule) {
    NSLog(@"Do Saver");
    [self createSaverWindow: NO];
    [saverWindow setLevel: NSScreenSaverWindowLevel];
    [self startTimer];
    [NSCursor hide];
  }
}

- (void) doSaverInBackground: (id)sender
{
  [self createSaverWindow: YES];
  [self startTimer];
}

- (void) resetTimer
{
  [self stopTimer];
  [self startTimer];
}

- (void) setSpeed: (id)sender
{
  [self resetTimer];
}

- (void) loadDefaults
{
  NSMutableDictionary *appDefs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						 @"Black",@"currentModule",nil];
  int row = 0;
  float runSpeed = 0.10;

  [defaults setFloat: runSpeed forKey: @"runSpeed"];
  defaults = [NSUserDefaults standardUserDefaults];
  [defaults registerDefaults: appDefs];
  
  runSpeed = [defaults floatForKey: @"runSpeed"];
  [speedSlider setFloatValue: runSpeed];

  isInBackground = [[defaults objectForKey:@"runInBackgroud"]intValue];
  [inBackground setState:isInBackground];

  currentModuleName = [defaults stringForKey: @"currentModule"];
  row = [[modules allKeys] indexOfObject: currentModuleName];  
  if(row < [[modules allKeys] count])
    {
      [moduleList reloadColumn: 0];
      [moduleList selectRow: row inColumn: 0];
    }

  NSLog(@"current module = %@",currentModuleName);
}

- (NSMutableDictionary *) modules
{
  return modules;
}

- (void) findModulesInDirectory: (NSString *) directory
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray *files = [fm directoryContentsAtPath: directory];
  NSEnumerator *en = [files objectEnumerator];
  id item = nil;

  NSDebugLog(@"directory = %@",directory);
  while((item = [en nextObject]) != nil)
    {
      NSDebugLog(@"file = %@",item);
      if([[item pathExtension] isEqualToString: @"InnerSpace"])
	{
	  NSString *fullPath = [directory stringByAppendingPathComponent: item];
	  NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
	  
	  [infoDict setObject: fullPath forKey: @"Path"];

	  [modules setObject: infoDict forKey: [item stringByDeletingPathExtension]];
	  NSDebugLog(@"modules = %@",modules);
	}
    }
}

- (void) findModules
{
  [self findModulesInDirectory: [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: 
								      @"Resources"]];
  [self findModulesInDirectory: [NSHomeDirectory() stringByAppendingPathComponent: 
						  @"/GNUstep/Library/InnerSpace"]];
  [self findModulesInDirectory: [NSHomeDirectory() stringByAppendingPathComponent: 
						  @"/Library/InnerSpace"]];
}

- (void) awakeFromNib
{
  modules = RETAIN([NSMutableDictionary dictionary]);
  [self findModules];
  [self loadDefaults];
  RETAIN(emptyView); // hold on to this.
}

- (void) dealloc
{
  RELEASE(saverWindow);
  RELEASE(timer);
  RELEASE(currentModule);
  RELEASE(modules);
  RELEASE(currentModuleName);
  RELEASE(emptyView);
  
  [super dealloc];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notification
{
  [[[NSApp iconWindow] contentView] addSubview:iconView];
  [iconView setFrame:NSMakeRect(8, 8, 48, 48)];
  [iconView setNeedsDisplay:YES];

  if (currentModuleName && isInBackground) {
    NSLog(@"Run in Background %@", currentModuleName);
    [self loadModule:currentModuleName];
    [self doSaverInBackground: self];
  }
}

- (void) windowWillClose: (NSNotification*) not
{
  if (isInBackground) {
    [self doSaverInBackground: self];
  }
  else {
    if(currentModule) [self _stopModule: currentModule];
    [self stopSaver];
  }
}

- (void) createSaverWindow: (BOOL)desktop
{
  if (saverWindow) {
    [saverWindow close];
    saverWindow = nil;
  }
  NSRect frame = [[NSScreen mainScreen] frame];
  int store = NSBackingStoreRetained;

  // dertermine backing type...
  NS_DURING
  if([currentModule respondsToSelector: @selector(useBufferedWindow)])
    {
      if([currentModule useBufferedWindow])
	{
	  store = NSBackingStoreBuffered;
	}
    }
  NS_HANDLER
    NSLog(@"EXCEPTION: %@",localException);
    store = NSBackingStoreBuffered;
  NS_ENDHANDLER

  // create the window...
  saverWindow = [[SaverWindow alloc] initWithContentRect: frame
                                               styleMask: NSBorderlessWindowMask
				                 backing: store
				                   defer: NO];

  // set some attributes...
  [saverWindow setAction: @selector(stopAndStartSaver) forTarget: self];
  [saverWindow setAutodisplay: YES];
  [saverWindow makeFirstResponder: saverWindow];
  [saverWindow setExcludedFromWindowsMenu: YES];
  [saverWindow setBackgroundColor: [NSColor blackColor]];
  [saverWindow setOneShot:YES];

  // set up the backing store...
  if(store == NSBackingStoreBuffered)
    {
      [saverWindow useOptimizedDrawing: YES];
      [saverWindow setDynamicDepthLimit: YES];
    }

  // run the saver in on the desktop...
  if(desktop)
    {
      NSLog(@"desktop");
      [saverWindow setLevel: NSDesktopWindowLevel];
      [saverWindow makeOmnipresent];
    } 
  else
    {
      NSLog(@"screensaver");
      [saverWindow setLevel: NSScreenSaverWindowLevel];
      [saverWindow makeFullscreen:YES];
    }

  // load the view from the currently active module, if
  // there is one...
  if(currentModule)
    {
      [saverWindow setContentView: currentModule];
      NS_DURING
	if([currentModule respondsToSelector: @selector(willEnterScreenSaverMode)])
	  {
	    [currentModule willEnterScreenSaverMode];
	  }
      NS_HANDLER
	NSLog(@"EXCEPTION while creating saver window %@",localException);
      NS_ENDHANDLER
    }
  
  [saverWindow makeKeyAndOrderFront: self];
}

- (void) destroySaverWindow
{
  [saverWindow close];
  saverWindow = nil;
}

- (void) stopSaver
{
  NSDebugLog(@"%@",[inBackground stringValue]);
  [self destroySaverWindow];
  [self stopTimer];
  NSDebugLog(@"stopping");
}

- (void) stopAndStartSaver
{
  [NSCursor unhide];
  [self stopSaver];
  if (isInBackground) {
    [self doSaverInBackground: self];
  }
}

// timer managment
- (void) startTimer
{
  NSTimeInterval runSpeed = [speedSlider floatValue];
  NSTimeInterval time = runSpeed;

  NS_DURING
    {
      // Some modules may FORCE us to run at a given speed.
      if([currentModule respondsToSelector: @selector(animationDelayTime)])
	{
	  time = [currentModule animationDelayTime];
	}
    }
  NS_HANDLER
    {
      NSLog(@"EXCEPTION: %@", localException);
      time = runSpeed;
    }
  NS_ENDHANDLER
    
  if(![currentModule respondsToSelector: @selector(isBoringScreenSaver)])
    {
      timer = [NSTimer scheduledTimerWithTimeInterval: time
		       target: self
		       selector: @selector(runAnimation:)
		       userInfo: nil
		       repeats: YES];
    }
  else
    {
      // if the screen saver is "boring" it should only run oneStep
      // once.   This means that it will not waste CPU cycles spinning and
      // doing nothing...
      NS_DURING
	// do one frame..
	[currentModule lockFocus];
        if([currentModule respondsToSelector: @selector(didLockFocus)])
	  {
	    [currentModule didLockFocus];
	  }
	[currentModule oneStep];
	[saverWindow flushWindow];
	[currentModule unlockFocus];
      NS_HANDLER
	NSLog(@"EXCEPTION: %@",localException);
      NS_ENDHANDLER      
    }
  RETAIN(timer);
}

- (void) stopTimer
{
  if(timer != nil)
    {
      [timer invalidate];
      RELEASE(timer);
      timer = nil;
    }
}

- (void) runAnimation: (NSTimer *)atimer
{
  if(!saverWindow)
    {
      return;
    }
  else
    {
      NS_DURING
	// do one frame..
	[currentModule lockFocus];
        if([currentModule respondsToSelector: @selector(didLockFocus)])
	  {
	    [currentModule didLockFocus];
	  }
	[currentModule oneStep];
	[saverWindow flushWindow];
	[currentModule unlockFocus];
      NS_HANDLER
	NSLog(@"EXCEPTION while in running animation: %@",localException);
      NS_ENDHANDLER
    }
}

- (void) _startModule: (ModuleView *)moduleView
{
  NSView *inspectorView = nil;
  NS_DURING
    if([moduleView respondsToSelector: @selector(inspector:)])
      {
	inspectorView = [moduleView inspector: self];
	RETAIN(inspectorView);
	// NSLog(@"inspectorView %@",inspectorView);
	[(NSBox *)controlsView setBorderType: NSGrooveBorder];
	[(NSBox *)controlsView setContentView: inspectorView];
	if([moduleView respondsToSelector: @selector(inspectorInstalled)])
	  {
	    NSLog(@"installed");
	    [moduleView inspectorInstalled];
	  }
      }
    //[self createSaverWindow: YES];
    //[self startTimer];
  NS_HANDLER
    NSLog(@"EXCEPTION: %@",localException);
  NS_ENDHANDLER
}

- (void) _stopModule: (ModuleView *)moduleView
{
  NS_DURING
    if([moduleView respondsToSelector: @selector(inspectorWillBeRemoved)])
      {
	[moduleView inspectorWillBeRemoved];
      }
    [self stopSaver];
  NS_HANDLER
    NSLog(@"EXCEPTION while in _stopModule: %@",localException);
  NS_ENDHANDLER
 
  // Remove the view...
  [(NSBox *)controlsView setContentView: emptyView];
  [(NSBox *)controlsView setBorderType: NSGrooveBorder];
}

- (NSString *) _pathForModule: (NSString *) moduleName
{
  NSString *result = nil;
  NSMutableDictionary *dict;

  if((dict = [modules objectForKey: moduleName]) != nil)
    {
      result = [dict objectForKey: @"Path"];
    }
  return result;
}

- (void) loadModule: (NSString *)moduleName
{
  id newModule = nil;

  if(moduleName)
    {
      NSBundle *bundle = nil;
      Class    theViewClass;
      NSString *bundlePath = [self _pathForModule: moduleName];
      
      NSDebugLog(@"Bundle path = %@",bundlePath);
      bundle = [NSBundle bundleWithPath: bundlePath];
      if(bundle != nil)
	{
	  NSDebugLog(@"Bundle loaded");
	  theViewClass = [bundle principalClass];
	  if(theViewClass != nil)
	    {
	      newModule = [[theViewClass alloc] initWithFrame: [[NSScreen mainScreen] frame]];
	    }
	}
    }
  
  if(newModule != currentModule)
    {
      if(currentModule)
	{
	  [self _stopModule: currentModule];
	}
      
      ASSIGN(currentModule, (ModuleView *)newModule);
      [self _startModule: currentModule];
      [controlsView display];
    }
}
@end

// delegate
@interface InnerSpaceController(BrowserDelegate)
- (BOOL) browser: (NSBrowser*)sender selectRow: (int)row inColumn: (int)column;

- (void) browser: (NSBrowser *)sender createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix;

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)column;

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column;

- (BOOL) browser: (NSBrowser *)sender isColumnValid: (int)column;
@end

@implementation InnerSpaceController(BrowserDelegate)
- (BOOL) browser: (NSBrowser*)sender selectRow: (int)row inColumn: (int)column
{
  return YES;
}

- (void) browser: (NSBrowser *)sender createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix
{
  NSEnumerator     *e = [[[self modules] allKeys] objectEnumerator];
  NSString    *module = nil;
  NSBrowserCell *cell = nil;
  int i = 0;

  while((module = [e nextObject]) != nil)
    {
      [matrix insertRow: i withCells: nil];
      cell = [matrix cellAtRow: i column: 0];
      [cell setLeaf: YES];
      i++;
      [cell setStringValue: module];
    }
}

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)column
{
  NSLog(@"Delegate called....");
  return @"Modules";
}

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column
{
}

- (BOOL) browser: (NSBrowser *)sender isColumnValid: (int)column
{
  return NO;
}
@end
