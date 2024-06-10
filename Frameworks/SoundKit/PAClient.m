/* -*- mode: objc -*- */
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

#import <pulse/pulseaudio.h>
#import "PAClient.h"

// typedef struct pa_client_info {
//   uint32_t    index;        // Index of this client
//   const char  *name;        // Name of this client
//   uint32_t    owner_module; // Index of the owning module, or PA_INVALID_INDEX.
//   const char  *driver;      // Driver name
//   pa_proplist *proplist;    // Property list
// } pa_client_info;

@implementation PAClient

@synthesize name;
@synthesize index;
@synthesize appName;

- (void)dealloc
{
  self.name = nil;
  self.appName = nil;

  [super dealloc];
}

- (id)updateWithValue:(NSValue *)value
{
  const pa_client_info *info;
  const char *app_binary;
  const char *app_name;
  
  //Zinfo = malloc(sizeof(const pa_client_info));
  //Z[value getValue:(void *)info];
  info = [value pointerValue];

  self.name = [[NSString alloc] initWithCString:info->name];
  self.index = info->index;

  app_name = pa_proplist_gets(info->proplist, "application.name");
  app_binary = pa_proplist_gets(info->proplist, "application.process.binary");
  self.appName = [[NSString alloc] initWithFormat:@"%s : %s", app_binary, app_name];

  return self;
}

@end
