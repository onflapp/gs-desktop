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
    	
	font = [NSFont systemFontOfSize:9.0];
	stateStrAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
        font, NSFontAttributeName,
	[NSColor grayColor], NSForegroundColorAttributeName,
        style, NSParagraphStyleAttributeName, nil] retain];
  
  iconPlug = [[NSImage imageNamed:@"plugin.tiff"] retain];
  iconBattery = nil;//[[NSImage imageNamed:@"small_battery.tif"] retain];
  tileImage = [NSImage imageNamed:@"common_Tile"];
 
  batModel = [model retain];

  return self;
}

- (void) dealloc
{
  [iconPlug release];
  [iconBattery release];
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

#define BAT_X 16
#define BAT_Y 8
#define BAT_HEIGHT 48
#define BAT_WIDTH 32

- (void)drawRect:(NSRect)r
{
  if (tileImage)
     [tileImage compositeToPoint:NSMakePoint(0,0)
                        fromRect:NSMakeRect(0, 0, 64, 64)
                      operation:NSCompositeSourceAtop];

  NSString *str;
  float chargePercentToDraw; /* we need this beause chargePercent can go beyond 100% */
  NSImage *chargeStatusIcon;

  if ([batModel isCharging]) chargeStatusIcon = iconPlug;
  else chargeStatusIcon = iconBattery;

  chargePercentToDraw = [batModel chargePercent];

  if (chargePercentToDraw > 100) chargePercentToDraw = 100;
  else if (chargePercentToDraw < 0 || isnan(chargePercentToDraw)) chargePercentToDraw = 0;

  [[NSGraphicsContext currentContext] setShouldAntialias: NO];
  [NSBezierPath setDefaultLineWidth:1];

  [[NSColor grayColor] set];
  [NSBezierPath strokeRect: NSMakeRect(BAT_X, BAT_Y, BAT_WIDTH, BAT_HEIGHT)];

  [[NSColor darkGrayColor] set];
  [NSBezierPath fillRect: NSMakeRect(BAT_X+1, BAT_Y+1, BAT_WIDTH-2, BAT_HEIGHT-2)];
  
  /* draw the charge status */
  if ([batModel isWarning] == YES) {
    [[NSColor orangeColor] set];
  }
  else if ([batModel isCritical] == YES) {
    [[NSColor redColor] set];
  }
  else {
    [[NSColor greenColor] set];
  }

  [NSBezierPath fillRect: NSMakeRect(BAT_X+1, BAT_Y+1, BAT_WIDTH-2, (chargePercentToDraw/100) * BAT_HEIGHT-2)];

  [[NSColor grayColor] set];
  int z = 12;
  [NSBezierPath strokeLineFromPoint:NSMakePoint(BAT_X, BAT_Y+z) toPoint:NSMakePoint(BAT_X+BAT_WIDTH, BAT_Y+z)];
  z+=12;
  [NSBezierPath strokeLineFromPoint:NSMakePoint(BAT_X, BAT_Y+z) toPoint:NSMakePoint(BAT_X+BAT_WIDTH, BAT_Y+z)];
  z+=12;
  [NSBezierPath strokeLineFromPoint:NSMakePoint(BAT_X, BAT_Y+z) toPoint:NSMakePoint(BAT_X+BAT_WIDTH, BAT_Y+z)];
  z+=12;
  [NSBezierPath strokeLineFromPoint:NSMakePoint(BAT_X, BAT_Y+z) toPoint:NSMakePoint(BAT_X+BAT_WIDTH, BAT_Y+z)];

  [chargeStatusIcon compositeToPoint: NSMakePoint(BAT_X+4, BAT_HEIGHT - 12) operation:NSCompositeSourceOver];

  str = [NSString stringWithFormat:@"%2.0f%%", [batModel chargePercent]];
  [str drawAtPoint: NSMakePoint(BAT_X+4 , BAT_Y) withAttributes:stateStrAttributes];
}

@end
