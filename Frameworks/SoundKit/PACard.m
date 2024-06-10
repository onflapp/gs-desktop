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

#import "PACard.h"

@interface PACard ()
@end

@implementation PACard

@synthesize context;

@synthesize index;
@synthesize name;
@synthesize description;

@synthesize outPorts;
@synthesize inPorts;
@synthesize profiles;
@synthesize activeProfile;

- (void)dealloc
{
  self.name = nil;
  self.profiles = nil;
  
  [super dealloc];
}

- (void)_updatePorts:(const pa_card_info *)info
{
  NSMutableArray *ports;
  NSMutableArray *outPorts;
  NSMutableArray *inPorts;
  NSDictionary   *d;
  NSString       *newActivePort;

  if (info->n_ports > 0) {
    outPorts = [NSMutableArray new];
    inPorts = [NSMutableArray new];
    
    unsigned i;
    for (i = 0; i < info->n_ports; i++) {
      d = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithCString:info->ports[i]->name],@"Name",
            [NSString stringWithCString:info->ports[i]->description],@"Description", nil];
      if (info->ports[i]->direction == PA_DIRECTION_OUTPUT) {
        [outPorts addObject:d];
      }
      else if (info->ports[i]->direction == PA_DIRECTION_INPUT) {
        [inPorts addObject:d];
      }
      else {
        [outPorts addObject:d];
        [inPorts addObject:d];
      }
    }

    if ([outPorts count] > 0) {
      if (outPorts) {
        [outPorts release];
      }
      outPorts = [[NSArray alloc] initWithArray:outPorts];
      [outPorts release];
    }
    
    if ([inPorts count] > 0) {
      if (inPorts) {
        [inPorts release];
      }
      inPorts = [[NSArray alloc] initWithArray:inPorts];
      [inPorts release];
    }
  }
}

- (void)_updateProfiles:(const pa_card_info *)info
{
  NSDictionary       *d;
  NSMutableArray     *profs;
  NSString           *newActiveProfile;

  if (info->n_profiles > 0) {
    profs = [NSMutableArray new];
    unsigned i;
    for (i = 0; i < info->n_profiles; i++) {
      d = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithCString:info->profiles2[i]->name], @"Name",
            [NSString stringWithCString:info->profiles2[i]->description], @"Description", nil];
      [profs addObject:d];
    }
    
    if ([profs count] > 0) {
      self.profiles = [[NSArray alloc] initWithArray:profs];
      [profs release];
    }
  }

  newActiveProfile = [[NSString alloc] initWithCString:info->active_profile->description];
  if (self.activeProfile == nil || [self.activeProfile isEqualToString:newActiveProfile] == NO) {
    if (info->active_profile != NULL) {
      self.activeProfile = newActiveProfile;
    }
    else {
      self.activeProfile = nil;
    }
  }
}

- (id)updateWithValue:(NSValue *)val
{
  const pa_card_info *info;
  const char         *desc;
  
  // Convert PA structure into NSDictionary
  info = malloc(sizeof(const pa_card_info));
  [val getValue:(void *)info];

  self.index = info->index;
  self.name = [[NSString alloc] initWithCString:info->name];

  //pa_proplist_gets(info->proplist, "alsa.card_name"); 
  desc = pa_proplist_gets(info->proplist, "device.description"); //no all devices will have alsa.card_name

  self.description = [[NSString alloc] initWithCString:desc];

  [self _updateProfiles:info];
  [self _updatePorts:info];

  free ((void *)info);

  return self;
}

- (void)applyActiveProfile:(NSString *)profileName
{
  const char   *profile = NULL;
  pa_operation *o;
 
  for (NSDictionary *p in self.profiles) {
    if ([[p valueForKey:@"Description"] isEqualToString:profileName]) {
      profile = [[p valueForKey:@"Name"] cString];
    }
  }
  
  o = pa_context_set_card_profile_by_index(self.context, index, profile, NULL, self);
  if (o) {
    pa_operation_unref(o);
  }
}

@end
