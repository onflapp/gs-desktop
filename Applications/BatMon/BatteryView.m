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
#import "NSColorExtensions.h"

@implementation BatteryView

- initWithFrame:(NSRect)aFrame batteryModel:(BatteryModel*) model
{
  self = [super initWithFrame:aFrame];
  
  iconPlug = [[NSImage imageNamed:@"plugin.tiff"] retain];
  iconBattery = nil;//[[NSImage imageNamed:@"small_battery.tif"] retain];
  tileImage = [NSImage imageNamed:@"common_Tile"];
 
  batModel = [model retain];

  [self reconfigure];

  return self;
}

- (void) dealloc
{
  [iconPlug release];
  [iconBattery release];
  [batModel release];

  [stateStrAttributes release];
  [background_color release];
  [outline_color release];
  [normal_color release];
  [warning_color release];
  [critical_color release];

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

- (void)reconfigure {
  NSMutableParagraphStyle *style;
	NSFont *font;

  NSUserDefaults *prefs     = [NSUserDefaults standardUserDefaults];

  //colors
  background_color = [NSColor colorFromStringRepresentation:[prefs objectForKey:@"background_color"]];
  if (!background_color) background_color = [NSColor blackColor];
  [background_color retain];

  outline_color    = [NSColor colorFromStringRepresentation:[prefs objectForKey:@"outline_color"]];
  if (!outline_color) outline_color = [NSColor blueColor];
  [outline_color retain];

  normal_color     = [NSColor colorFromStringRepresentation:[prefs objectForKey:@"normal_color"]];
  if (!normal_color) normal_color = [NSColor greenColor];
  [normal_color retain];

  warning_color    = [NSColor colorFromStringRepresentation:[prefs objectForKey:@"warning_color"]];
  if (!warning_color) warning_color = [NSColor orangeColor];
  [warning_color retain];

  critical_color   = [NSColor colorFromStringRepresentation:[prefs objectForKey:@"critical_color"]]; 
  if (!critical_color) critical_color = [NSColor redColor];
  [critical_color retain];

  //fonts
  
  style = [[NSMutableParagraphStyle alloc] init];
  [style setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    	
	font = [NSFont systemFontOfSize:9.0];

  stateStrAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        font, NSFontAttributeName,
	outline_color, NSForegroundColorAttributeName,
        style, NSParagraphStyleAttributeName, nil];
  [stateStrAttributes retain];
}

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

  [outline_color set];
  [NSBezierPath strokeRect: NSMakeRect(BAT_X, BAT_Y, BAT_WIDTH, BAT_HEIGHT)];

  [background_color set];
  [NSBezierPath fillRect: NSMakeRect(BAT_X, BAT_Y+1, BAT_WIDTH-1, BAT_HEIGHT-1)];
  
  /* draw the charge status */
  if ([batModel isWarning] == YES) {
    [warning_color set];
  }
  else if ([batModel isCritical] == YES) {
    [critical_color set];
  }
  else {
    [normal_color set];
  }

  [NSBezierPath fillRect: NSMakeRect(BAT_X, BAT_Y+1, BAT_WIDTH-1, (chargePercentToDraw/100) * BAT_HEIGHT-1)];

  [outline_color set];
  int z = 12;
  [NSBezierPath strokeLineFromPoint:NSMakePoint(BAT_X, BAT_Y+z) toPoint:NSMakePoint(BAT_X+BAT_WIDTH-1, BAT_Y+z)];
  z+=12;
  [NSBezierPath strokeLineFromPoint:NSMakePoint(BAT_X, BAT_Y+z) toPoint:NSMakePoint(BAT_X+BAT_WIDTH-1, BAT_Y+z)];
  z+=12;
  [NSBezierPath strokeLineFromPoint:NSMakePoint(BAT_X, BAT_Y+z) toPoint:NSMakePoint(BAT_X+BAT_WIDTH-1, BAT_Y+z)];

  [chargeStatusIcon compositeToPoint: NSMakePoint(BAT_X+4, BAT_HEIGHT - 12) operation:NSCompositeSourceOver];

  str = [NSString stringWithFormat:@"%2.0f%%", chargePercentToDraw];
  [str drawAtPoint: NSMakePoint(BAT_X+4 , BAT_Y) withAttributes:stateStrAttributes];
}

@end
