/*
   Project: CloudManager

   Copyright (C) 2022 Free Software Foundation

   Author: Parallels

   Created: 2022-09-16 15:40:26 +0000 by parallels

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "ServiceManager.h"
#import "ServiceTask.h"

@implementation ServiceManager

- (NSArray*) listServices {
   if (services) return services;

   NSMutableArray* list = [NSMutableArray new];
   NSArray* ls = [NSArray arrayWithObjects:@"dropbox", nil];
   for (NSString* it in ls) {
     ServiceTask* task = [[ServiceTask alloc] initWithName:it];
     [task setMountPoint:@"/home/parallels/Dropbox"];
     [task setRemoteName:@"dropbox:"];
     [list addObject:task];
     [task release];
   }

   services = list;
   return list;
}

@end
