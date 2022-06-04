/*
   Project: batmon

   Copyright (C) 2006-2015 GNUstep Application Project

   Author: Riccardo Mottola 

   Created: 2006-01-14 23:58:48 Riccardo Mottola

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
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSException.h>

#import "BatteryModel.h"

@implementation BatteryModel

- (id)init
{
  if ((self = [super init]))
    {
      useWattHours = YES;
      
      isCritical = NO;
      isCharging = NO;
      lastCap = 0;
      currCap = 0;
      critCap = 0;
      chargePercent = 0;
      critPercent = 8;
      warnPercent = 16;

      batteryType = nil;
      batteryManufacturer = nil;
      
      [self initPlatformSpecific];
    }
  return self;

}

- (void)dealloc
{
  if (batteryType != nil)
    [batteryType release];
  [super dealloc];
}


- (void) update
{
  [self updatePlatformSpecific];
}

- (float)volts
{
    return volts;
}

- (float)amps
{
    return amps;
}

- (float)watts
{
    return watts;
}

- (float)timeRemaining
{
    return timeRemaining;
}

- (float)remainingCapacity
{
    return currCap;
}

- (float)warningCapacity
{
    return warnCap;
}

- (float)lastCapacity
{
    return lastCap;
}

- (float)designCapacity
{
    return desCap;
}

- (float)chargePercent
{
    return chargePercent;
}

- (NSString *)state
{
  NSString *s;

  switch(batteryState)
    {
    case BMBStateUnknown:
      s = @"Unknown";
      break;
    case BMBStateCharging:
      s = @"Charging";
      break;
    case BMBStateDischarging:
      s = @"Discharging";
      break;
    case BMBStateHigh:
      s = @"High";
      break;
    case BMBStateLow:
      s = @"Low";
      break;
    case BMBStateCritical:
      s = @"Critical";
      break;
    case BMBStateFull:
      s = @"Full";
      break;
    case BMBStateMissing:
      s = @"Missing";
      break;
    default:
      NSLog(@"Unrecognized battery state");
      s = @"Unrecognized";
      break;
    }
  return s;
}

- (NSString *)batteryType
{
    return batteryType;
}

- (NSString *)manufacturer
{
  return batteryManufacturer;
}

- (BOOL)isCritical
{
  if (isCritical)
    return YES;

  if (batteryState == BMBStateCritical)
    return YES;

  if (batteryState == BMBStateCharging ||
      batteryState == BMBStateDischarging ||
      batteryState == BMBStateHigh ||
      batteryState == BMBStateLow )
    {
      if (critCap > 0)
        {
          if (currCap < critCap)
            return YES;
          else
            return NO;
        }
      else
        {
          if (chargePercent < critPercent)
            return YES;
          else
            return NO;
        }
    }

  return NO;
}

- (BOOL)isWarning
{
  if (batteryState == BMBStateCharging ||
      batteryState == BMBStateDischarging ||
      batteryState == BMBStateHigh ||
      batteryState == BMBStateLow)
    {
      if (warnCap > 0)
        {
          if (currCap < warnCap)
            return YES;
          else
            return NO;
        }
      else
        {
          if (chargePercent < warnPercent)
            return YES;
          else
            return NO;
        }
    }

  return NO;
}

- (BOOL)isCharging
{
  return isCharging;
}

- (BOOL)isUsingWattHours
{
  return useWattHours;
}

@end

#if defined(linux)
#elif defined(openbsd) || defined(__OpenBSD__)
#elif defined(netbsd) || defined (__NetBSD__)
#elif defined(freebsd) || defined( __FreeBSD__ )
#else
#warning "Unsupported Platform, no specific battery model"
#endif
