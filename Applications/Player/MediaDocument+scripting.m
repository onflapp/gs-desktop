#import "MediaDocument.h"

@implementation MediaDocument(scripting)

- (BOOL) isPlaying {
  return playing;
}

- (void) play {
  [self play:playButton];
}

- (void) stop {
  [self stop:nil];
}

@end
