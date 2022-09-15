/* 
 * DefaultsManager.m created by phr on 2000-11-10 22:03:38 +0000
 *
 * Project GSDefaults
 *
 * Created with ProjectCenter - http://www.projectcenter.ch
 *
 * $Id: DefaultsManager.m,v 1.2 2000/12/31 14:26:29 robert Exp $
 */

#import "DefaultsManager.h"
#import "BrowserController.h"

@interface DefaultsManager (Private)
- (void)_createUI;
@end

@implementation DefaultsManager (Private)

- (void)_createUI
{
  NSView *_c_view;
  NSMatrix *matrix;
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask | 
                       NSMiniaturizableWindowMask | NSResizableWindowMask;
  NSRect _w_frame = NSMakeRect(100,100,560,380);
  NSBrowser *browser;
  id button;
  NSButtonCell* buttonCell = [[[NSButtonCell alloc] init] autorelease];
  NSScrollView *scrollView;

  mainWindow = [[NSWindow alloc] initWithContentRect:_w_frame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:YES];
  [mainWindow setDelegate:self];
  [mainWindow setTitle:@"GNUstep Defaults Database Editor"];
  [mainWindow setMinSize:NSMakeSize(560,380)];
  [mainWindow setReleasedWhenClosed:NO];
  [mainWindow center];
  [mainWindow setFrameAutosaveName:@"MainWindow"];

  browser = [[NSBrowser alloc] initWithFrame:NSMakeRect(8,168,544,208)];
  [browser setMaxVisibleColumns:2];
  [browser setAllowsMultipleSelection:NO];
  [browser setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];

  browserController = [[BrowserController alloc] initWithBrowser:browser];
  [browserController setDelegate:self];

  _c_view = [mainWindow contentView];
  [_c_view addSubview:browser];

  RELEASE(browser);

  /*
   *
   *
   */

  textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,512,104)];
  [textView setMaxSize:NSMakeSize(1e7, 1e7)];
  [textView setRichText:NO];
  [textView setEditable:NO];
  [textView setSelectable:YES];
  [textView setVerticallyResizable:YES];
  [textView setHorizontallyResizable:NO];
  [textView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [textView setBackgroundColor:[NSColor whiteColor]];
  [[textView textContainer] setWidthTracksTextView:YES];

  scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect (8,36,544,128)];
  [scrollView setDocumentView:textView];
  [[textView textContainer] setContainerSize:NSMakeSize([scrollView contentSize].width,1e7)];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  [_c_view addSubview:scrollView];

  RELEASE(textView);
  RELEASE(scrollView);

  /*
   *
   *
   */

  _w_frame = NSMakeRect(334,8,216,22);
  matrix = [[NSMatrix alloc] initWithFrame: _w_frame
			     mode: NSHighlightModeMatrix
			     prototype: buttonCell
			     numberOfRows: 1
			     numberOfColumns: 2];
  [matrix sizeToCells];
  [matrix setTarget:self];
  [matrix setAction:@selector(buttonsPressed:)];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMinXMargin | NSViewMaxYMargin)];
  [_c_view addSubview:matrix];
  RELEASE(matrix);

  button = [matrix cellAtRow:0 column:0];
  [button setTag:0];
  [button setImagePosition:NSNoImage];
  [button setTitle:@"Remove Domain"];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:1];
  [button setTag:1];
  [button setImagePosition:NSNoImage];
  [button setTitle:@"Synchronise"];
  [button setButtonType:NSMomentaryPushButton];
}

@end

@implementation DefaultsManager

static DefaultsManager *_manager = nil;

+ (id)sharedManager
{
  if (!_manager) {
    _manager = [[DefaultsManager alloc] init];
  }
  return _manager;
}

- (void)dealloc
{
  RELEASE(mainWindow);
  RELEASE(browserController);

  [super dealloc];
}

- (void)openMainWindow
{
  if (!mainWindow) {
    [self _createUI];
  }

  if (![mainWindow isVisible]) { 
    [mainWindow setFrameUsingName:@"MainWindow"];
  }

  [mainWindow makeKeyAndOrderFront:self];
}

- (void)buttonsPressed:(id)sender
{
  switch ([[sender selectedCell] tag]) { 
  case 0:
    if(NSRunAlertPanel(@"Attention!",
		       @"Really remove the selected domain?",
		       @"OK",
		       @"Cancel",
		       nil)) {
      NSString *_n;

      _n = [browserController selectedDomain];
      [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:_n];
      [browserController update];
    }
    break;
  case 1:
    [[NSUserDefaults standardUserDefaults] synchronize];
    break;
  }
}

@end

@implementation DefaultsManager (DelegateMethod)

- (void)browserController:(id)sender didSelectPropertyList:(id)plist
{
  [textView setString:[plist description]];
  [textView display];
}

@end
