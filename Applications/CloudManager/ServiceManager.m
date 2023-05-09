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

  CustomServiceTask* task = [[CustomServiceTask alloc] initWithName:@"Personal FTP"];
  NSString* mdir = [self makeMountPointForName:@"FTPDrop"];
  if (mdir) {
    [task setMountPoint:mdir];
    [task setRemoteName:@"personal-ftp.sh"];
    [services addObject:task];
    [task release];
  }

  task = [[CustomServiceTask alloc] initWithName:@"Personal VNC"];
  [task setRemoteName:@"personal-vnc.sh"];
  [services addObject:task];
  [task release];
}

@end
