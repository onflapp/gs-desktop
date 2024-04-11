/* 
   Project: ScanImage

   Author: Ondrej Florian,,,

   Created: 2024-04-03 22:31:47 +0200 by oflorian
   
   Application Controller
*/

#import "AppController.h"

@implementation AppController

+ (void) initialize {
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init {
  if ((self = [super init])) {
    listDevices = [[ListDevices alloc] init];
    scanImage = [[ScanImage alloc] init];
  }
  return self;
}

- (void) dealloc {
  RELEASE(listDevices);
  RELEASE(scanImage);
  [super dealloc];
}

- (void) awakeFromNib {
  [panel setFrameAutosaveName:@"main_browser"];
  [self __stopProcess];
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(didReceiveServiceNotification:)
             name:@"serviceStatusHasChanged"
           object:nil];

  [NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]
                           returnTypes:[NSArray array]];

  //if([NSApp isScriptingSupported]) {
  //    [NSApp initializeApplicationScripting];
  //}
}

- (void) __startProcess {
  [scanButton setEnabled:NO];
  [progress setIndeterminate:YES];
  [progress startAnimation:self];
}

- (void) __stopProcess {
  [progress setDoubleValue:0.0];
  [progress stopAnimation:self];
  [progress setIndeterminate:NO];
}

- (void) didReceiveServiceNotification:(NSNotification*) val {
  if ([val object] == listDevices) {
    [deviceList reloadColumn:0];

    if ([listDevices isRunning]) [self __startProcess];
    else [self __stopProcess];
  }
  else if ([val object] == scanImage) {
    NSString* fl = [scanImage outputFilename];
    if (fl) {
      NSLog(@"loading image %@", fl);
      NSImage* img = [[NSImage alloc] initWithContentsOfFile:fl];
      if (img) {
        [imagePreview setImage:img];
      }
      else {
        NSLog(@"invalied image %@", fl);
      }
    }

    if ([scanImage isRunning]) [self __startProcess];
    else [self __stopProcess];
  }
}

- (BOOL) applicationShouldTerminate: (id)sender {
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif {
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName {
  return NO;
}

- (id) validRequestorForSendType:(NSString *)st
                      returnType:(NSString *)rt {

  NSString* fl = [scanImage outputFilename];
  if ([st isEqualToString:NSFilenamesPboardType] && fl) {
    return self;
  }
  else {
    return nil;
  }
}

- (BOOL) writeSelectionToPasteboard:(NSPasteboard *)pb
                             types:(NSArray *)types {
  NSString* fl = [scanImage outputFilename];
  if ([types containsObject:NSFilenamesPboardType] && fl) {
    [pb declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    return [pb setPropertyList:[NSArray arrayWithObject:fl] forType:NSFilenamesPboardType];
  }
  else {
    return NO;
  }
}

- (void) browser:(NSBrowser*) brow willDisplayCell:(NSBrowserCell*) cell atRow:(NSInteger)row column:(NSInteger)col {
  id it = [[listDevices devices] objectAtIndex:row];

  [cell setRepresentedObject:it];
  [cell setLeaf:YES];
  [cell setStringValue:[it valueForKey:@"title"]];
}

- (NSInteger) browser:(NSBrowser*) brow numberOfRowsInColumn:(NSInteger) col {
  return [[listDevices devices] count];
}

- (IBAction) selectDevice:(id)sender {
  [scanButton setEnabled:YES];
}

- (IBAction) copy:(id)sender {
  NSImage* img = [imagePreview image];
  if (img) {
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes: [NSMutableArray arrayWithObject: NSTIFFPboardType] owner: nil];
    [pboard setData:[img TIFFRepresentation] forType:NSTIFFPboardType];
  }
}

- (IBAction) showPrefPanel:(id)sender {
}

- (IBAction) showScanPanel:(id)sender {
  [panel makeKeyAndOrderFront:sender];
}

- (IBAction) openImage:(id)sender {
  NSString* fl = [scanImage outputFilename];
  if (fl) {
    [[NSWorkspace sharedWorkspace] openFile: fl];
  }
}

- (IBAction) scanImage:(id)sender {
  NSString* dev = [[[deviceList selectedCell] representedObject] valueForKey:@"device"];
  if (!dev) {
    dev = @"default";
  }
  if ([scanImage isRunning]) {
    NSLog(@"scanning already");
    return;
  }

  NSInteger type = [[outputType selectedItem] tag];
  NSInteger res = [[outputRes selectedItem] tag];

  NSMutableArray* args = [NSMutableArray array];
  [args addObject:dev];

  if (type == 1) [args addObject:@"Gray"];
  if (type == 2) [args addObject:@"Color"];
  if (type == 3) [args addObject:@"Lineart"];

  if (res == 0) res = 72;
  [args addObject:[NSString stringWithFormat:@"%ld", res]];

  [scanImage scanWithArguments:args];
}

- (IBAction) refreshDevices:(id)sender {
  [listDevices start];
}

@end
