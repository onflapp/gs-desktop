/* MapView.m
 *  
 * Copyright (C) 2005-2010 Free Software Foundation, Inc.
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

#include <AppKit/AppKit.h>
#include <math.h>
#include "MapView.h"
#include "Date.h"

#define MAP_W 550
#define MAP_H 275

double myrintf(double a)
{
	return (floor(a + 0.5));         
}

@implementation MapView

- (void)dealloc
{
  RELEASE (mapImage);
  RELEASE (locations);
  
	[super dealloc];
}

- (id)initWithFrame:(NSRect)rect
       withMapImage:(NSImage *)image
      timeZonesPath:(NSString *)path
  forPreferencePane:(id)apane
{
  self = [super initWithFrame: rect];
  
  if (self) {
    ASSIGN (mapImage, image);
    pane = apane;
    locations = [NSMutableArray new];
    [self readZones: path];
  }
  
  return self;
}

- (void)readZones:(NSString *)path
{
  CREATE_AUTORELEASE_POOL(pool);
  NSString *str = [NSString stringWithContentsOfFile: path];
  NSArray *lines = [str componentsSeparatedByString: @"\n"];
  unsigned i;

  for (i = 0; i < [lines count]; i++) {
    CREATE_AUTORELEASE_POOL(arp);
    MapLocation *mapLocation = [MapLocation new];
    NSString *line = [lines objectAtIndex: i];
    NSScanner *scanner = [NSScanner scannerWithString: line];
    NSCharacterSet *set = [scanner charactersToBeSkipped];
    NSString *word;
    NSMutableString *comments;
    NSRange range;
    unsigned len;
    NSString *sign;
    float degr;
    float mins;
    
    while ([scanner isAtEnd] == NO) {   
      [scanner scanUpToCharactersFromSet: set intoString: &word];
      [mapLocation setCode: word];

      [scanner scanUpToCharactersFromSet: set intoString: &word];
      len = [word length];
      range = NSMakeRange(0, 1);
      sign = [word substringWithRange: range];

      range = NSMakeRange(1, 2);
      degr = [[word substringWithRange: range] floatValue];
      
      len -= 3;      
      range = NSMakeRange(3, len);
      mins = ([[word substringWithRange: range] floatValue] / pow(10, len));
      
      degr += mins;
      degr = ([sign isEqual: @"-"]) ? -degr : degr;
      degr += 90;
    
      degr = myrintf(degr * MAP_H / 180);
      [mapLocation setLatitude: degr];

      [scanner scanUpToCharactersFromSet: set intoString: &word];

      len = [word length];
      range = NSMakeRange(0, 1);
      sign = [word substringWithRange: range];

      range = NSMakeRange(1, 3);
      degr = [[word substringWithRange: range] floatValue];
      
      len -= 4;
      range = NSMakeRange(4, len);
      mins = ([[word substringWithRange: range] floatValue] / pow(10, len));

      degr += mins;
      degr = ([sign isEqual: @"-"]) ? -degr : degr;
      degr += 180;

      degr = myrintf(degr * MAP_W / 360);
      [mapLocation setLongitude: degr];
      
      [scanner scanUpToCharactersFromSet: set intoString: &word];
      [mapLocation setZone: word];
      
      comments = [NSMutableString stringWithCapacity: 1];

      while ([scanner isAtEnd] == NO) {
        if ([scanner scanUpToCharactersFromSet: set intoString: &word]) {
          [comments appendFormat: @"%@ ", word];
        }
      }

      if ([comments length]) {
        [mapLocation setComments: comments];
      }
    }
    
    [locations addObject: mapLocation];
    RELEASE (mapLocation);
       
    RELEASE (arp);
  }

  RELEASE (pool);
}

- (MapLocation *)locationNearestToPoint:(NSPoint)p
{
  MapLocation *nearest = nil; 
  float min = (MAP_W * MAP_W) + (MAP_H * MAP_H);
  unsigned i;
  
  for (i = 0; i < [locations count]; i++) {
    MapLocation *loc = [locations objectAtIndex: i];
    float dx = [loc longitude] - p.x;
    float dy = [loc latitude] - p.y;
    float dist = (dy * dy) + (dx * dx);
  
    if (dist < min) {
      min = dist;
      nearest = loc;
    }
  }

  return nearest;
}

- (void)mouseDown:(NSEvent *)theEvent
{
  NSPoint p = [theEvent locationInWindow];
  
  p = [self convertPoint: p fromView: nil];
  [pane showInfoOfLocation: [self locationNearestToPoint: p]];
}

- (void)drawRect:(NSRect)rect
{	 
  unsigned i;
  
  [mapImage compositeToPoint: NSZeroPoint operation: NSCompositeSourceOver];

  [[NSColor redColor] set];

  for (i = 0; i < [locations count]; i++) {
    MapLocation *mapLocation = [locations objectAtIndex: i];
    float x = [mapLocation longitude] - 1;
    float y = [mapLocation latitude] - 1;
    
    NSRectFill(NSMakeRect(x, y, 2, 2));
  }
}

@end


@implementation MapLocation

- (void)dealloc
{
  RELEASE (code);
  RELEASE (zone);
  TEST_RELEASE (comments);
  
	[super dealloc];
}

- (NSUInteger)hash
{
  return (zone != nil) ? [zone hash] : [super hash];
}

- (BOOL)isEqual:(id)other
{
  if (other == self) {
    return YES;
  }
  if ([other isKindOfClass: [MapLocation class]]) {
    return [zone isEqual: [(MapLocation *)other zone]];
  }
  return NO;
}

- (void)setCode:(NSString *)cd
{
  ASSIGN (code, cd);
}

- (NSString *)code
{
  return code;
}

- (void)setZone:(NSString *)zn
{
  ASSIGN (zone, zn);
}

- (NSString *)zone
{
  return zone;
}

- (void)setLatitude:(float)lat
{
  latitude = lat;
}

- (float)latitude
{
  return latitude;
}

- (void)setLongitude:(float)lon
{
  longitude = lon;
}

- (float)longitude
{
  return longitude;
}

- (void)setComments:(NSString *)cm
{
  ASSIGN (comments, cm);
}

- (NSString *)comments
{
  return comments;
}

@end


