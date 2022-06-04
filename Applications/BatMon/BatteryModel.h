/*
   Project: batmon

   Copyright (C) 2006-2014 GNUstep Application Project

   Author: Riccardo Mottola

   Created: 2006-01-14 23:58:48 +0100 by Riccardo

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <Foundation/NSObject.h>

#if defined (linux)
#define DEV_SYS_POWERSUPPLY  @"/sys/class/power_supply"
#define DEV_PROC_PMU  @"/proc/pmu"
#endif



typedef enum
  {
    BMBStateUnknown = 0,
    BMBStateCharging,
    BMBStateDischarging,
    BMBStateHigh,
    BMBStateLow,
    BMBStateCritical,
    BMBStateFull,
    BMBStateMissing
  } BMBatteryStates;

@class NSString;

@interface BatteryModel : NSObject
{
#if defined (linux)
    @private char     batteryStatePath0[1024];
    @private char     batteryInfoPath0[1024];
    @private char     apmPath[1024];
    @private NSString *batterySysAcpiString;

    /* ACPI on Linux, using files in /sys : modern kernels and laptops*/
    @private BOOL     useACPIsys;

    /* ACPI on Linux, using files in /proc, now as fallback */
    @private BOOL     useACPIproc; 

    /* APM on linux, for old kernels, older laptops, non-x86 machines, netbooks, embedded devices */
    @private BOOL     useAPM;

    /* PMU: Power management Unit, specific for powermac, ibooks Apple laptops*/
    @private BOOL     usePMU;
#endif

    @private BOOL     useWattHours;
    @private float    volts;
    @private float    amps;
    @private float    watts;
    @private float    desCap;
    @private float    lastCap;
    @private float    currCap;
    @private float    critCap;
    @private float    warnCap;
    @private float    chargePercent;
    @private float    timeRemaining;
    @private BOOL     isCharging;
    @private BOOL     isCritical;
    @private float    critPercent;
    @private float    warnPercent;
    @private BMBatteryStates batteryState;
  
    @private NSString *batteryType;
    @private NSString *batteryManufacturer;

}

- (void)update;
- (float)volts;
- (float)amps;
- (float)watts;
- (float)timeRemaining;
- (float)remainingCapacity;
- (float)warningCapacity;
- (float)lastCapacity;
- (float)designCapacity;
- (float)chargePercent;

- (BOOL)isCritical;
- (BOOL)isWarning;
- (BOOL)isCharging;

- (BOOL)isUsingWattHours;

- (NSString *)state;
- (NSString *)batteryType;
- (NSString *)manufacturer;

@end


@interface BatteryModel (PlatformSpecific)

- (void)initPlatformSpecific;
- (void)updatePlatformSpecific;

@end
