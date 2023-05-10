/*
  Project: CloudManager
*/

#import "ServiceManager.h"
#import "ServiceTask.h"
#import "RCloneServiceTask.h"
#import "CustomServiceTask.h"

@implementation ServiceManager

- (id) init {
  self = [super init];
  services = [[NSMutableArray alloc] init];
  return self;
}

- (NSArray*) listServices {
  return services;
}

- (void) stopAllServices {
  for (ServiceTask* task in services) {
    [task stopTask];
  }
}

- (NSString*) makeMountPointForName:(NSString*) name {

  NSUserDefaults* cfg = [NSUserDefaults standardUserDefaults];
  NSFileManager* fm   = [NSFileManager defaultManager];
  NSString* basedir   = [[cfg stringForKey:@"default_base"] stringByExpandingTildeInPath];
  NSString* namedir   = [basedir stringByAppendingPathComponent:name];

  [fm createDirectoryAtPath:namedir withIntermediateDirectories:YES attributes:nil error:nil];
  BOOL isdir = NO;
  BOOL rv = [fm fileExistsAtPath:namedir isDirectory:&isdir];

  if (rv && isdir) return namedir;
  else {
    NSLog(@"unable to create directory %@", namedir);
    return nil;
  }
}

- (void) configureAllServices {
  if ([services count]) {
    [self stopAllServices];
    NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.5];
    [[NSRunLoop currentRunLoop] runUntilDate: limit];
  }

  [services removeAllObjects];

  /* register rclone services */
  NSUserDefaults* cfg = [NSUserDefaults standardUserDefaults];
  NSArray* rclone = [cfg objectForKey:@"rclone_services"];

  for (NSString* it in rclone) {

    NSString* name = [it substringToIndex:[it length] - 1];
    NSString* mdir = [self makeMountPointForName:name];
    if (!mdir) continue;

    RCloneServiceTask* task = [[RCloneServiceTask alloc] initWithName:name];
    [task setMountPoint:mdir];
    [task setRemoteName:it];
    [services addObject:task];

    [task release];
  }

  /* register custom services */
  NSFileManager* fm = [NSFileManager defaultManager];
  NSMutableDictionary* found = [NSMutableDictionary new];
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);

  for (NSString* it in paths) {
    NSString* path = [it stringByAppendingPathComponent:@"CloudManager/Services"];
    NSArray* spaths = [fm directoryContentsAtPath:path];
    for (NSString* it in spaths) {
      if (![[it pathExtension] isEqualToString:@"cservice"]) continue;

      NSString* name = [[it lastPathComponent] stringByDeletingPathExtension];
      if (![found valueForKey:name]) {
        NSString* spath = [path stringByAppendingPathComponent:it];
        [found setValue:spath forKey:name];
      }
    }
  }

  for (NSString* name in [found allKeys]) {
    CustomServiceTask* task = [[CustomServiceTask alloc] initWithName:name];
    NSString* mdir = [self makeMountPointForName:name];
    NSString* path = [found valueForKey:name];

    if (mdir) {
      [task setMountPoint:mdir];
      [task setRemoteName:path];
      [services addObject:task];
      [task release];
    }
  }
}

@end
