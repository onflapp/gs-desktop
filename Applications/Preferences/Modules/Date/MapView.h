/* MapView.h
 *  
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: December 2005
 *
 * This file is part of the GNUstep TimeZone Preference Pane
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */
 
#ifndef MAP_VIEW_H
#define MAP_VIEW_H

#include <Foundation/Foundation.h>
#include <AppKit/NSView.h>

@class NSImage;
@class MapLocation;
@class MapZone;

@interface MapView : NSView 
{
  NSImage *mapImage;
  NSMutableArray *locations;
  NSMutableArray *zones;
  id pane;
}

- (id)initWithFrame:(NSRect)rect
       withMapImage:(NSImage *)image
      timeZonesPath:(NSString *)path
  forPreferencePane:(id)apane;

- (void)readZones:(NSString *)path;

- (MapLocation *)locationNearestToPoint:(NSPoint)p;

- (NSInteger) zoneCount;

- (NSString*) zoneAtIndex:(NSInteger) index;

- (MapZone*) zoneForName:(NSString*) name;

@end

@interface MapLocation : NSObject
{
  NSString *code;
  NSString *zone;
  NSString *name;
  float latitude;
  float longitude;
  NSString *comments;
}
                            
- (void)setCode:(NSString *)cd;

- (NSString *)code;

- (void)setZone:(NSString *)zn;

- (NSString *)zone;

- (void)setLatitude:(float)lat;

- (float)latitude;

- (void)setLongitude:(float)lon;

- (float)longitude;

- (void)setComments:(NSString *)cm;

- (NSString *)comments;

- (void)setName:(NSString *)nm;

- (NSString *)name;

@end

@interface MapZone : NSObject
{
  NSString *name;
  NSMutableArray* locations;
}
                            
- (void)setName:(NSString *)nm;

- (NSString *)name;

- (void) addLocation:(MapLocation*) loc;

- (NSInteger) locationCount;

- (MapLocation*) locationAtIndex:(NSInteger) index;

@end

#endif // MAP_VIEW_H

