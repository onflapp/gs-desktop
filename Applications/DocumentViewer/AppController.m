/* 
   Project: DocumentViewer

   Author: Ondrej Florian,,,

   Created: 2022-09-12 13:07:11 +0200 by oflorian
   
   Application Controller
*/

#import "AppController.h"
#import "PdfDocument.h"
#import "HtmlDocument.h"
#import <WebKit/WebKit.h>

@implementation AppController

+ (void) initialize {
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init {
  if ((self = [super init])) {
  }
  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (void) awakeFromNib {
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif {
  WebPreferences* pref = [WebPreferences standardPreferences];	// all windows share this
  [pref setJavaScriptEnabled:NO];
  [pref setDefaultFontSize:12];
}

- (BOOL) applicationShouldTerminate: (id)sender {
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif {
}

- (BOOL) application: (NSApplication *)application
            openFile: (NSString *)fileName {

  NSString* ext = [fileName pathExtension];
  if ([ext isEqualToString:@"pdf"]) {
    PdfDocument* doc = [[PdfDocument alloc] init];
    [doc displayFile:fileName];
  }
  else if ([ext isEqualToString:@"html"]) {
    HtmlDocument* doc = [[HtmlDocument alloc] init];
    [doc displayFile:fileName];
  }
  else {    
    /*
    NSLog(@"try to convert %@", path);

    NSPasteboard* pboard = [NSPasteboard pasteboardByFilteringFile:path];
    NSData* data = [pboard dataForType:NSPDFPboardType];
    if (data) {
      NSString* tfile = [NSString stringWithFormat:@"%@/temp.%x.pdf", NSTemporaryDirectory(), [self hash]];
      [data writeToFile:tfile atomically:NO];
      pdffile = tfile;
    }
*/
    NSLog(@"not sure how to open %@", fileName);
  }
  return NO;
}

- (void) openDocument:(id)sender {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  if ([panel runModal]) {
    [self application:NSApp openFile:[panel filename]];
  } 
}

- (void) showPrefPanel:(id)sender {
}

@end
