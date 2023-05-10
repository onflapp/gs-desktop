/*
*/

#import "VNCDisplayView.h"
#import "SDLvncclient.h"

@implementation VNCDisplayView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];
  xwindowid = 0;
  xdisplay = NULL;

  return self;
}

- (void) VNCprocess:(id)sender {
  NSString* host = [[sender displayURL] host];

  NSLog(@"host:%@", host);
  int argc = 2;
  char** argv = malloc(sizeof(char*) * argc);
  argv[0] = [@"remoteview" cString];
  argv[1] = [host cString];

  NSLog(@"- start");
  int rv = main_proc(self, argc, argv);
  NSLog(@"- end");
}

- (NSURL*) displayURL {
  return displayURL;
}

- (void) connect:(NSURL*) url {
  ASSIGN(displayURL, url);

  [self performSelectorInBackground:@selector(VNCprocess:) withObject:self];
}

@end
