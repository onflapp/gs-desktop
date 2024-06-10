//
// Project: SoundKit framework.
//
// Copyright (C) 2019 Sergii Stoian
//
// This application is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This application is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
// 
// You should have received a copy of the GNU General Public
// License along with this library; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
//

#import <SoundKit/SNDServer.h>
#import <SoundKit/SNDVirtualStream.h>

#import "PAStream.h"
#import "PAClient.h"

#import "PASink.h"
#import "SNDOut.h"

@implementation SNDVirtualStream

@synthesize stream;
@synthesize appName;

- (void)dealloc
{
  NSDebugLLog(@"Memory", @"[SNDVirtualStream] dealloc");
  [super dealloc];
}

- (id)initWithStream:(PAStream *)stream
{
  if ((self = [super init]) == nil)
    return nil;

  self.stream = stream;
  
  if (self.stream == nil) {
    super.name = @"Dummy Virtual Stream";
  }
  else if ([[self.stream typeName] isEqualToString:@"sink-input-by-media-role"] != NO) {
    if ([[self.stream clientName] isEqualToString:@"event"] != NO) {
      super.name = @"System Sounds";
      super.isActive = YES;
      super.isPlayback = YES;
    }
  }
  else {
    super.name = self.stream.clientName;
  }

  // fprintf(stderr, "[SoundKit] SoundStream: %s \t\tDevice: %s\n",
  //         [_stream.name cString], [_stream.deviceName cString]);
  
  return self;  
}

- (NSString *)appName
{
  return super.client.appName;
}

- (NSUInteger)volume
{
  return [self.stream volume];
}
- (void)setVolume:(NSUInteger)volume
{
  [self.stream applyVolume:volume];
}
- (CGFloat)balance
{
  return self.stream.balance;
}
- (void)setBalance:(CGFloat)balance
{
  [self.stream applyBalance:balance];
}
- (void)setMute:(BOOL)isMute
{
  [self.stream applyMute:isMute];
}
- (BOOL)isMute
{
  return (BOOL)self.stream.mute;
}

- (NSString *)activePort
{
  SNDServer *server = [SNDServer sharedServer];

  return [server defaultOutput].sink.activePort;
}

- (void)setActivePort:(NSString *)portName
{
  SNDServer *server = [SNDServer sharedServer];

  [[server defaultOutput].sink applyActivePort:portName];
}

@end
