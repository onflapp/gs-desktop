/*
   Project: FTP

   Copyright (C) 2005-2016 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2005-04-09

   Local filesystem class

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <stdlib.h>

#import "localclient.h"
#import "fileElement.h"

@implementation LocalClient

- (id)init
{
    if (!(self = [super init]))
        return nil;
    homeDir = [NSHomeDirectory() retain];
    return self;
}

/*
 creates a new directory
 If the path is absolute, use it directly, else append to wokding directory
 */
- (BOOL)createNewDir:(NSString *)dir
{
    NSFileManager *fm;
    NSString      *localPath;
    BOOL          isDir;

    fm = [NSFileManager defaultManager];
    if ([dir isAbsolutePath])
    {
        NSLog(@"%@ is an absolute path", dir);
        localPath = dir;
    }
    else
    {
        NSLog(@"%@ is a relative path", dir);
        localPath = [[self workingDir] stringByAppendingPathComponent:dir];
    }
    if ([fm fileExistsAtPath:localPath isDirectory:&isDir] == YES)
        return isDir;
    if ([fm createDirectoryAtPath:localPath attributes:nil] == NO)
        return NO;
    else
        return YES;
}

- (bycopy NSArray *)dirContents
{
    NSFileManager   *fm;
    NSArray         *fileNames;
    NSEnumerator    *en;
    NSString        *fileName;
    NSMutableArray  *listArr;
    FileElement     *aFile;

    fm = [NSFileManager defaultManager];
    fileNames = [fm directoryContentsAtPath:workingDir];
    if (fileNames == nil)
        return nil;

    listArr = [NSMutableArray arrayWithCapacity:[fileNames count]];
    
    en = [fileNames objectEnumerator];
    while ((fileName = [en nextObject]))
    {
        NSString *p;
        NSDictionary *attr;

        p = [workingDir stringByAppendingPathComponent:fileName];
        attr = [fm fileAttributesAtPath :p traverseLink:YES];
        aFile = [[FileElement alloc] initWithPath:p andAttributes:attr];
        [listArr addObject:aFile];
        [aFile release];
    }
    return [NSArray arrayWithArray:listArr];
}

- (BOOL)deleteFile:(FileElement *)file beingAt:(int)depth
{
  NSFileManager      *fm;

  fm = [NSFileManager defaultManager];
  
  if ([fm removeFileAtPath:[file path] handler:nil] == NO)
    {
      NSLog(@"an error occoured during local delete");
      return NO;
    }
  return YES;
}


- (BOOL)renameFile:(FileElement *)file to:(NSString *)name
{
  NSFileManager  *fm;
  NSString       *newFullPath;

  if (file == nil)
    return NO;

  if (name == nil)
    return NO;

  fm = [NSFileManager defaultManager];

  newFullPath = [[[file path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];

  if ([fm movePath:[file path] toPath:newFullPath handler:nil] == NO)
    {
      NSLog(@"Error during local file renaming");
      return NO;
    }
  [file setPath:newFullPath];
  return YES;
}

@end
