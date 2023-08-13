//
//
//

#include <stdio.h>

#import <Foundation/Foundation.h>
#import <SystemKit/OSEUDisksAdaptor.h>
#import <SystemKit/OSEUDisksVolume.h>

void printVolumes(NSDictionary *volumes)
{
  NSEnumerator *e = [volumes objectEnumerator];
  OSEUDisksVolume *v;
      
  while ((v = [e nextObject]) != nil) {
    if ([v type] != -1 && [v isFilesystem]) {
      NSLog(@"%d %@ %@", [v type], [v UNIXDevice], [v mountPoints]);
    }
  }
}

OSEUDisksVolume* volumeForDevice(OSEUDisksAdaptor* uda, NSString* path) {
  NSArray* drives = [uda availableDrives];
  OSEUDisksVolume *v;
  NSDictionary      *d;

  NSEnumerator* e = [drives objectEnumerator];
  while ((d = [e nextObject]) != nil) {
    NSDictionary* volumes = [uda availableVolumesForDrive:[d objectPath]];
    NSEnumerator *ve = [volumes objectEnumerator];
    while ((v = [ve nextObject]) != nil) {
      if ([[v UNIXDevice] isEqualToString:path]) return v;
    }
  }
  return nil;
}

int main(int argc, char *argv[])
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  OSEUDisksAdaptor   *uda;
  NSArray           *drives, *mountPoints;
  NSEnumerator      *e;
  NSDictionary      *d;

  uda = [OSEUDisksAdaptor new];
  drives = [uda availableDrives];

  e = [drives objectEnumerator];
  while ((d = [e nextObject]) != nil) {
    NSString* path = [d objectPath];
    NSDictionary* volumes = [uda availableVolumesForDrive:[d objectPath]];
    NSLog(@"%@", path);
    printVolumes(volumes);
  }

  mountPoints = [uda mountedRemovableMedia];
  if ([mountPoints count] > 0)
    NSLog(@"mountedRemovableMedia: %@", mountPoints);
  else
    NSLog(@"No removable media mounted.");

  OSEUDisksVolume* v = volumeForDevice(uda, @"/dev/sda1");
  NSLog(@"%@", [v unmount:YES]);
  [uda release];
  
  [pool release];

  return 0;
}
