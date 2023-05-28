/* 
   Project: DocumentViewer

   Author: Ondrej Florian,,,

   Created: 2022-09-12 13:07:11 +0200 by oflorian
   
   Application Controller
*/

#import "AppController.h"
#import "PdfDocument.h"
#import "HtmlDocument.h"
#import "Preferences.h"
#import <WebKit/WebKit.h>

@implementation AppController

+ (void) initialize {
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"reuse_document_window"];
  
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
  [pref setUserStyleSheetEnabled:YES];
}

- (BOOL) applicationShouldTerminate: (id)sender {
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif {
}

- (Document*) documentForFile:(NSString*) fileName {

  for (NSWindow* win in [NSApp windows]) {
    if ([[win delegate] isKindOfClass:[Document class]]) {
      Document* doc = (Document*) [win delegate];
      if ([[doc fileName] isEqualToString: fileName]) {
        [doc reload];
        return doc;
      }
    }
  }

  NSString* ext = [fileName pathExtension];
  if ([ext isEqualToString:@"pdf"]) {
    PdfDocument* doc = [[PdfDocument alloc] init];
    [doc loadFile:fileName];

    return doc;
  }
  else if ([ext isEqualToString:@"html"]) {
    HtmlDocument* doc = [[HtmlDocument alloc] init];
    [doc loadFile:fileName];

    return doc;
  }
  else {    
    NSLog(@"try to convert %@ as PDF", fileName);
    NSString* ptype = [NSString stringWithFormat:@"NSFilenamesPboardType:%@", ext];
    NSData* fdata = [fileName dataUsingEncoding:NSUTF8StringEncoding];

    // try filter to PDF from fileName
    NSPasteboard* pboard = [NSPasteboard pasteboardByFilteringData:fdata ofType:ptype];
    NSData* data = [pboard dataForType:NSPDFPboardType];

    if (!data) {
      // try filter to PDF from data
      pboard = [NSPasteboard pasteboardByFilteringFile:fileName];
      data = [pboard dataForType:NSPDFPboardType];
    }

    if (data) {
      NSString* tfile = [NSString stringWithFormat:@"%@/temp.%lx.pdf", NSTemporaryDirectory(), [data hash]];
      [data writeToFile:tfile atomically:NO];

      PdfDocument* doc = [[PdfDocument alloc] init];
      [doc loadFile:tfile];

      return doc;
    }
    
    NSLog(@"try to convert %@ as HTML", fileName);
    data = [pboard dataForType:NSHTMLPboardType];

    // try filter to HTML
    if (data) {
      NSString* tfile = [NSString stringWithFormat:@"%@/temp.%lx.html", NSTemporaryDirectory(), [data hash]];
      [data writeToFile:tfile atomically:NO];

      HtmlDocument* doc = [[HtmlDocument alloc] init];
      [doc loadFile:tfile];

      return doc;
    }
    else {
      NSLog(@"not sure how to open %@", fileName);
    }
  }

  return nil;
}

- (BOOL) application: (NSApplication *)application
            openFile: (NSString *)fileName {

  Document* doc = [self documentForFile:fileName];
  [doc showWindow];
  return NO;
}

- (void) openDocument:(id)sender {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  if ([panel runModal]) {
    [self application:NSApp openFile:[panel filename]];
  } 
}

- (void) showPrefPanel:(id)sender {
  Preferences* prefs = [Preferences sharedInstance];
  [[prefs panel] makeKeyAndOrderFront:sender]; 
}

@end
