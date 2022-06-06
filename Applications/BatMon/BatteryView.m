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
	[NSColor blueColor], NSForegroundColorAttributeName,
        style, NSParagraphStyleAttributeName, nil] retain];
  
  iconPlug = [[NSImage imageNamed:@"small_plug.tif"] retain];
  iconBattery = [[NSImage imageNamed:@"small_battery.tif"] retain];
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

#define HEIGHT 42
#define WIDTH  20

- (void)drawRect:(NSRect)r
{
  NSLog(@"draw");

  if (tileImage)
     [tileImage compositeToPoint:NSMakePoint(0,0)
                        fromRect:NSMakeRect(0, 0, 64, 64)
                      operation:NSCompositeSourceAtop];

  NSString *str;
  float chargePercentToDraw; /* we need this beause chargePercent can go beyond 100% */
  NSImage *chargeStatusIcon;

  if ([batModel isCharging]) chargeStatusIcon = iconPlug;
  else chargeStatusIcon = iconBattery;

  [chargeStatusIcon compositeToPoint: NSMakePoint(WIDTH+6, HEIGHT-15) operation:NSCompositeSourceOver];

  chargePercentToDraw = [batModel chargePercent];

  if (chargePercentToDraw > 100) chargePercentToDraw = 100;
  else if (chargePercentToDraw < 0 || isnan(chargePercentToDraw)) chargePercentToDraw = 0;

  [[NSColor darkGrayColor] set];
  /* main body */
  [NSBezierPath strokeRect: NSMakeRect(0, 1, WIDTH, HEIGHT)];
  /* top nib */
  [NSBezierPath strokeRect: NSMakeRect((WIDTH/2)-3, HEIGHT+1, 6, 4)];

  [[NSColor grayColor] set];
  /* right light shadow */
  [NSBezierPath strokeLineFromPoint:NSMakePoint(WIDTH+1, 0) toPoint:NSMakePoint(WIDTH+1, HEIGHT-1)];
  /* nib filler */
  [NSBezierPath fillRect: NSMakeRect((WIDTH/2)-2, HEIGHT+1+1, 4, 2)];
    
  /* draw the charge status */
  if ([batModel isWarning] == YES)
    [[NSColor orangeColor] set];
  else if ([batModel isCritical] == YES)
    [[NSColor redColor] set];
  else
    [[NSColor greenColor] set];
  [NSBezierPath fillRect: NSMakeRect(0+1, 1, WIDTH-1, (chargePercentToDraw/100) * HEIGHT -2)];

  str = [NSString stringWithFormat:@"%2.0f%%", [batModel chargePercent]];
  [str drawAtPoint: NSMakePoint(WIDTH + 5 , 1) withAttributes:stateStrAttributes];
}

@end
