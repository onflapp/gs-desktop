/*
  Project: CloudManager
*/

#import "ServiceManager.h"
#import "ServiceTask.h"

@implementation ServiceManager

- (id) init {
  self = [super init];
  services = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc {
  [self stopAllServices];
  [services release];

  [super dealloc];
}

- (NSArray*) listServices {
  return services;
}

- (void) startService:(ServiceTask*) task {
  [task startTask];
  [services addObject:task];
}

- (void) stopAllServices {
  for (ServiceTask* task in services) {
    [task stopTask];
  }
}

@end
