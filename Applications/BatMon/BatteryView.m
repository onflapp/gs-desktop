/* -*- mode: objc -*- */
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

#import <AppKit/NSApplication.h>
#import <AppKit/NSImageView.h>

#import "AppController.h"
#import "BatteryView.h"

@implementation BatteryView

- initWithFrame:(NSRect)aFrame batteryModel:(BatteryModel*) model
{
  self = [super initWithFrame:aFrame];
  
  NSMutableParagraphStyle *style;
  NSFont *font;

  style = [[NSMutableParagraphStyle alloc] init];
  [style setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    	
  font = [NSFont systemFontOfSize:8.0];
  stateStrAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
        font, NSFontAttributeName,
	[NSColor blackColor], NSForegroundColorAttributeName,
        style, NSParagraphStyleAttributeName, nil] retain];
  
  iconBattery_full = [[NSImage imageNamed:@"battery-full.tiff"] retain];
  iconBattery_good = [[NSImage imageNamed:@"battery-good.tiff"] retain];
  iconBattery_low = [[NSImage imageNamed:@"battery-low.tiff"] retain];
  iconBattery_caution = [[NSImage imageNamed:@"battery-caution.tiff"] retain];
  iconBattery_empty = [[NSImage imageNamed:@"battery-empty.tiff"] retain];
  iconPlug = [[NSImage imageNamed:@"plugin.tiff"] retain];
  iconPlugOut = [[NSImage imageNamed:@"plugout.tiff"] retain];

  tileImage = [[NSImage imageNamed:@"common_Tile"] retain];
  
  batModel = [model retain];

  return self;
}

- (void) dealloc
{
  [iconBattery_full release];
  [iconBattery_good release];
  [iconBattery_low release];
  [iconBattery_caution release];
  [iconBattery_empty release];
  [iconPlug release];
  [iconPlugOut release];

  [tileImage release];

  [stateStrAttributes release];
  [batModel release];
  [super dealloc];
}

- (void)setTarget:(id)target
{
  actionTarget = target;
}

- (void)setDoubleAction:(SEL)sel
{
  doubleAction = sel;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)anEvent
{
  return YES;
}

- (void)mouseDown:(NSEvent *)event
{
  if ([event clickCount] >= 2) {
    [actionTarget performSelector:doubleAction];
  }
}

- (void)drawRect:(NSRect)r
{
  float charge = [batModel chargePercent];
  NSImage *icon = nil; 

  float timeRem = [batModel timeRemaining];
  float hours = timeRem;
  float mins = (int)((timeRem - (float)hours) * 60);
  
  if (charge > 100) charge = 100;
  else if (charge < 0 || isnan(charge)) charge = 0;

  [tileImage compositeToPoint:NSMakePoint(0,0)
                     fromRect:NSMakeRect(0, 0, 64, 64)
                    operation:NSCompositeSourceAtop];

  if ([batModel isCharging]) {
    if (charge < 10) {
      icon = iconBattery_empty;
    }
    else if (charge < 33) {
      icon = iconBattery_caution;
    }
    else if (charge < 66) {
      icon = iconBattery_low;
    }
    else if (charge < 90) {
       icon = iconBattery_good;
    }
    else {
      icon = iconBattery_full;
    }
    [iconPlug compositeToPoint: NSMakePoint(36, 32-24) operation:NSCompositeSourceOver];
  }
  else {
    if ([batModel isWarning] == YES) {
      icon = iconBattery_low;
    }
    else if ([batModel isCritical] == YES) {
      icon = iconBattery_caution;
    }
    else if (charge > 90) {
      icon = iconBattery_full;
    }
    else {
      icon = iconBattery_good;
    }
    [iconPlugOut compositeToPoint: NSMakePoint(36, 12) operation:NSCompositeSourceOver];
  }
  
  [icon compositeToPoint: NSMakePoint(0, 32-24) operation:NSCompositeSourceOver];

  NSString* str = [NSString stringWithFormat:@"%2.0f%%", charge];
  [str drawAtPoint: NSMakePoint(40 , 45) withAttributes:stateStrAttributes];
  
  /*
  if (timeRem >= 0) str = [NSString stringWithFormat:@"%dh %d\'", (int)hours, (int)mins];
  else str = @"???";
  [str drawAtPoint: NSMakePoint(40 , 28) withAttributes:stateStrAttributes]; 
  */ 
}

@end
