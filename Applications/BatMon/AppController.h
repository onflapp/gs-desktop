/* 
   Project: batmon

   Copyright (C) 2005-2015 GNUstep Application Project

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
 

#import <AppKit/AppKit.h>
#import "BatteryModel.h"

@interface AppController : NSObject
{
    IBOutlet NSWindow            *monitorWin;
    IBOutlet NSTextField         *voltage;
    IBOutlet NSTextField         *amperage;
    IBOutlet NSTextField         *presentCap;
    IBOutlet NSTextField         *rate;
    IBOutlet NSTextField         *rateLabel;
    IBOutlet NSTextField         *percent;
    IBOutlet NSTextField         *timeLeft;
    IBOutlet NSTextField         *chState;
    IBOutlet NSProgressIndicator *level;
    IBOutlet NSButton            *cellInfoButton;
    IBOutlet NSBox               *lifeBox;
    IBOutlet NSBox               *cellDataBox;

    IBOutlet NSWindow            *infoWin;
    IBOutlet NSProgressIndicator *lifeGauge;
    IBOutlet NSTextField         *lifeGaugePercent;
    IBOutlet NSTextField         *designCap;
    IBOutlet NSTextField         *battType;
    IBOutlet NSTextField         *battTypeLabel;
    IBOutlet NSTextField         *manufacturer;
    IBOutlet NSTextField         *manufacturerLabel;
    IBOutlet NSTextField         *lastFullCharge;
    IBOutlet NSBox               *cellHealthBox;

    NSDictionary *stateStrAttributes;
    
    NSImage *iconBattery;
    NSImage *iconPlug;

    BatteryModel *batModel;
    @private int hours;
    @private int mins;
}

- (void)awakeFromNib;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif;
- (BOOL)applicationShouldTerminate:(id)sender;
- (void)applicationWillTerminate:(NSNotification *)aNotif;
- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName;

- (void)getInfo;

- (IBAction)showMonitor:(id)sender;
- (IBAction)showPrefPanel:(id)sender;
- (IBAction)updateInfo:(id)sender;
- (IBAction)showBattInfo:(id)sender;
@end

