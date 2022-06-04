/*
   Project: batmon

   Copyright (C) 2006-2015 GNUstep Application Project

   Author: Riccardo Mottola 
   FreeBSD support by Chris B. Vetter (initial version)

   Created: 2013-07-23 Riccardo Mottola

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

#if defined(freebsd) || defined( __FreeBSD__ )

#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <dev/acpica/acpiio.h>
#define ACPIDEV	"/dev/acpi"

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

#import "BatteryModel.h"

@implementation BatteryModel (PlatformSpecific)

- (void)initPlatformSpecific
{

}

- (void)updatePlatformSpecific
{
  union acpi_battery_ioctl_arg battio;
  int acpifd;
  
  battio.unit = 0;
  
  acpifd = open(ACPIDEV, O_RDWR);
  if (acpifd == -1) acpifd = open(ACPIDEV, O_RDONLY);
  if (acpifd == -1) return;
  if( -1 == ioctl(acpifd, ACPIIO_CMBAT_GET_BIF, &battio) ) return;

  desCap = (float)battio.bif.dcap / 1000;	// design capacity
  lastCap = (float)battio.bif.lfcap / 1000;	// last full capacity

  if( -1 == ioctl(acpifd, ACPIIO_CMBAT_GET_BST, &battio) ) return;
  close(acpifd);

  currCap = (float)battio.bst.cap / 1000;	// remaining capacity
  volts = (float)battio.bst.volt / 1000;	// present voltage
  watts = (float)battio.bst.rate / 1000;	// present rate
  amps = 0;
  if (volts)
    amps = watts / volts;
  
  batteryType = @"";
  if( ACPI_BATT_STAT_NOT_PRESENT != battio.bst.state )
    {
      isCritical = NO;
      if( battio.bst.state & ACPI_BATT_STAT_CRITICAL )
        isCritical = YES;     

      if( battio.bst.state == 0 )
        batteryState = BMBStateHigh;
      else if( battio.bst.state & ACPI_BATT_STAT_CHARGING )
        batteryState = BMBStateCharging;
      else if( battio.bst.state & ACPI_BATT_STAT_DISCHARG )
        batteryState = BMBStateDischarging;
      else if (battio.bst.state & ACPI_BATT_STAT_INVALID )
        batteryState = BMBStateUnknown;
      else
        batteryState = BMBStateUnknown;

      batteryType = [NSString stringWithFormat: @"%s", battio.bif.type];
    }
  else
    {
      batteryState = BMBStateMissing;
      batteryType = @"Missing";
    }

  if( batteryState == BMBStateHigh )
    {
      timeRemaining = 0;
      chargePercent = currCap/lastCap*100;
      isCharging = YES;
    }  
  else if( batteryState == BMBStateCharging )
    {
      timeRemaining = (lastCap-currCap) / watts;
      chargePercent = currCap/lastCap*100;
      isCharging = YES;
    }
  else if( batteryState == BMBStateDischarging )
    {
      timeRemaining = currCap / watts;
      chargePercent = currCap/lastCap*100;
      isCharging = NO;
    }
}

@end

#endif
