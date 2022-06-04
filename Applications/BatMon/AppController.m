/* 
   Project: batmon

   Copyright (C) 2005-2016 GNUstep Application Project

   Author: Riccardo Mottola

   Created: 2005-06-25 21:06:19 +0200 by multix
   
   Application Controller

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

#include <math.h>
#import "AppController.h"



@implementation AppController

+ (void)initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];


  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)init
{
    if ((self = [super init]))
      {
        NSMutableParagraphStyle *style;
	NSFont *font;

        batModel = [[BatteryModel alloc] init];
        style = [[NSMutableParagraphStyle alloc] init];
    	[style setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    	
	font = [NSFont systemFontOfSize:9.0];
	stateStrAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
        font, NSFontAttributeName,
	[NSColor blueColor], NSForegroundColorAttributeName,
        style, NSParagraphStyleAttributeName, nil] retain];
        iconPlug = [[NSImage imageNamed:@"small_plug.tif"] retain];
        iconBattery = [[NSImage imageNamed:@"small_battery.tif"] retain];
        
        /* localization */
        [rateLabel setStringValue:_(@"Discharge Rate")];
      }
    return self;
}

- (void)dealloc
{
    [stateStrAttributes release];
    [super dealloc];
}

- (void)awakeFromNib
{
    NSTimer *timer;

    [[NSApp mainMenu] setTitle:@"batmon"];
    [self updateInfo:nil];
  
    if (YES)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateInfo:) userInfo:nil repeats:YES];
        [timer fire];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif
{
}

- (BOOL)applicationShouldTerminate:(id)sender
{
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotif
{
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
  return NO;
}

- (IBAction)showMonitor:(id)sender
{
  [monitorWin makeKeyAndOrderFront:nil];
}

- (void)showPrefPanel:(id)sender
{
}



- (void)getInfo
{

}

#define HEIGHT 42
#define WIDTH  20
- (void)drawImageRep
{
    NSString *str;
    float chargePercentToDraw; /* we need this beause chargePercent can go beyond 100% */
    NSImage *chargeStatusIcon;

    if ([batModel isCharging])
      chargeStatusIcon = iconPlug;
    else
      chargeStatusIcon = iconBattery;

    [chargeStatusIcon compositeToPoint: NSMakePoint(WIDTH+6, HEIGHT-15) operation:NSCompositeSourceOver];

    chargePercentToDraw = [batModel chargePercent];
    if (chargePercentToDraw > 100)
        chargePercentToDraw = 100;
    else if (chargePercentToDraw < 0 || isnan(chargePercentToDraw))
      chargePercentToDraw = 0;

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

- (void)drawIcon
{
    NSImageRep *rep;
    NSImage    *icon;
    
    icon = [[NSImage alloc] initWithSize: NSMakeSize(48, 48)];
    rep = [[NSCustomImageRep alloc]
            initWithDrawSelector: @selector(drawImageRep)
            delegate:self];
    [rep setSize: NSMakeSize(48, 48)];
    [icon addRepresentation: rep];
    [NSApp setApplicationIconImage:icon];
    [rep release];
    [icon release]; /* setApplicationIconImage does a retain */
}


- (IBAction)updateInfo:(id)sender
{
    float lifeVal;
    float timeRem;
    float chargePercentToDraw; /* we need this because chargePercent can go beyond 100% */

    [batModel update];

    chargePercentToDraw = [batModel chargePercent];
    if (chargePercentToDraw > 100)
        chargePercentToDraw = 100;

    /* main window */
    timeRem = [batModel timeRemaining];
    hours = timeRem;
    mins = (int)((timeRem - (float)hours) * 60);

    [voltage setStringValue:[NSString stringWithFormat:@"%3.2f V", [batModel volts]]];
    [level setDoubleValue:chargePercentToDraw];
    [percent setStringValue:[NSString stringWithFormat:@"%3.1f%%", [batModel chargePercent]]];
    [amperage setStringValue:[NSString stringWithFormat:@"%3.2f A", [batModel amps]]];
    [rate setStringValue:[NSString stringWithFormat:@"%3.2f W", [batModel watts]]];
    if (timeRem >= 0)
        [timeLeft setStringValue:[NSString stringWithFormat:@"%dh %d\'", hours, mins]];
    else
        [timeLeft setStringValue:@"unknown"];
    [chState setStringValue:[batModel state]];

    if ([batModel isUsingWattHours])
      [presentCap setStringValue:[NSString stringWithFormat:@"%3.2f Wh", [batModel remainingCapacity]]];
    else 
      [presentCap setStringValue:[NSString stringWithFormat:@"%3.2f Ah", [batModel remainingCapacity]]];
    
    if ([batModel isCharging])
      [rateLabel setStringValue:_(@"Charge Rate")];
    else
      [rateLabel setStringValue:_(@"Discharge Rate")];

    /* info window */
    lifeVal = [batModel lastCapacity]/[batModel designCapacity];
    [lifeGauge setDoubleValue:lifeVal*100];
    [lifeGaugePercent setStringValue:[NSString stringWithFormat:@"%3.1f%%", lifeVal*100]];

    [battType setStringValue:[batModel batteryType]];
    [manufacturer setStringValue:[batModel manufacturer]];

    if ([batModel isUsingWattHours])
      {
	[designCap setStringValue:[NSString stringWithFormat:@"%3.2f Wh", [batModel designCapacity]]];
	[lastFullCharge setStringValue:[NSString stringWithFormat:@"%3.2f Wh", [batModel lastCapacity]]];
      }
    else
      {
	[designCap setStringValue:[NSString stringWithFormat:@"%3.2f Ah", [batModel designCapacity]]];
	[lastFullCharge setStringValue:[NSString stringWithFormat:@"%3.2f Ah", [batModel lastCapacity]]];
      }


    [self drawIcon];
}


- (IBAction)showBattInfo:(id)sender
{
    [infoWin makeKeyAndOrderFront:self];
}


@end
