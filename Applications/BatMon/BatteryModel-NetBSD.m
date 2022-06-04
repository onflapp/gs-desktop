/*
   Project: batmon

   Copyright (C) 2006-2017 GNUstep Application Project

   Author: Riccardo Mottola 

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

#if defined(netbsd) || defined (__NetBSD__)

#include <paths.h>  /* path for the system devices */
#include <fcntl.h>  /* open */
#include <unistd.h>
#include <sys/envsys.h>
#include <prop/proplib.h> /* psd property dictionaries */

#import <Foundation/Foundation.h>
#import "BatteryModel.h"

@implementation BatteryModel (PlatformSpecific)

- (void)initPlatformSpecific
{
}

- (void)updatePlatformSpecific
{
  int		      sysmonfd; /* fd of /dev/sysmon */
  int                 rval;
  prop_dictionary_t   bsd_dict;
  NSString            *string;
  NSDictionary        *dict;
  char                *cStr;
  NSEnumerator        *enum1;
  id                  obj1;
  NSDictionary        *acpibat0;
  NSMutableDictionary *batDict;
  NSDictionary        *chargeDict;
  NSString            *valueStr;
  float               chargeRate;
  float               dischargeRate;

  /* Open the device in ro mode */
  if ((sysmonfd = open(_PATH_SYSMON, O_RDONLY)) == -1)
    NSLog(@"Error opening device: %s", _PATH_SYSMON);

  rval = prop_dictionary_recv_ioctl(sysmonfd,
				    ENVSYS_GETDICTIONARY,
				    &bsd_dict);
  if (rval)
    {
      NSLog(@"Error: %s", strerror(rval));
      return;
    }
  
  cStr = prop_dictionary_externalize(bsd_dict);
  string = [NSString stringWithCString: cStr];
  dict = [string propertyList];
  if (dict == nil)
    {
      NSLog(@"Could not parse dictionary");
      return;
    }

  acpibat0 = [dict objectForKey: @"acpibat0"];
  //NSLog(@"acpibat0: %@", acpibat0);
  batDict = [NSMutableDictionary dictionaryWithCapacity: 3];
  enum1 = [acpibat0 objectEnumerator];
  while ((obj1 = [enum1 nextObject]))
    {
      if ([obj1 isKindOfClass: [NSDictionary class]])
	{
	  NSString *descriptionKey;

	  descriptionKey = [obj1 objectForKey:@"description"];
	  if (descriptionKey)
	    [batDict setObject: obj1 forKey: descriptionKey];
	}
      else
	NSLog(@"not a dict");

    }
  //NSLog(@"battery dictionary: %@", batDict);
  (void)close(sysmonfd);

  valueStr = [[batDict objectForKey: @"voltage"] objectForKey: @"cur-value"];
  if (valueStr)
    volts = [valueStr floatValue] / 1000000;
  NSLog(@"voltage: %@ %f", valueStr, volts);

  valueStr = [[batDict objectForKey: @"design cap"] objectForKey: @"cur-value"];
  if (valueStr)
    {
      if ([[[batDict objectForKey: @"design cap"] objectForKey: @"type"] isEqualToString: @"Ampere hour"])
	{
	  useWattHours = NO;
	}
      else if ([[[batDict objectForKey: @"design cap"] objectForKey: @"type"] isEqualToString: @"Watt hour"])
	{
	  useWattHours = YES;
	}
      desCap = [valueStr floatValue] / 1000000;
    }
  NSLog(@"design cap: %@ %f, type: %@", valueStr, desCap, [[batDict objectForKey: @"design cap"] objectForKey: @"type"]);

  chargeDict = [batDict objectForKey: @"charge"];
  valueStr = [chargeDict objectForKey: @"critical-capacity"];
  if (valueStr)
    {
      critCap = [valueStr floatValue] / 1000000;
    }
  NSLog(@"crit cap: %@ %f", valueStr, critCap);
  valueStr = [chargeDict objectForKey: @"warning-capacity"];
  if (valueStr)
    {
      warnCap = [valueStr floatValue] / 1000000;
    }
  //NSLog(@"warn cap: %@ %f", valueStr, warnCap);
  valueStr = [[batDict objectForKey: @"last full cap"] objectForKey: @"cur-value"];
  if (valueStr)
    lastCap = [valueStr floatValue] / 1000000;
  //NSLog(@"last full cap: %@, %f", valueStr, lastCap);

  valueStr = [[batDict objectForKey: @"charge rate"] objectForKey: @"cur-value"];
  chargeRate = 0;
  if (valueStr)
    chargeRate = [valueStr floatValue] / 1000000;

  valueStr = [[batDict objectForKey: @"discharge rate"] objectForKey: @"cur-value"];
  dischargeRate = 0;
  if (valueStr)
    dischargeRate = [valueStr floatValue] / 1000000;
  NSLog(@"discharge rate: %@ %f", valueStr, dischargeRate);

  valueStr = [[batDict objectForKey: @"charge"] objectForKey: @"cur-value"];
  if (valueStr)
    currCap = [valueStr floatValue] / 1000000;
  NSLog(@"charge: %@, %f", valueStr, currCap);

  valueStr = [[batDict objectForKey: @"charging"] objectForKey: @"cur-value"];
  NSLog(@"charging: %@", valueStr);
  if ([valueStr intValue] == 0)
    {
      if (useWattHours)
        amps = dischargeRate / volts;
      else
        amps = dischargeRate;
      watts = amps * volts;
      NSLog(@"useWattHours %d amps %f", useWattHours, amps);
      
      isCharging = NO;
      if (useWattHours && volts > 0 && amps > 0)
	timeRemaining = currCap / watts;
      else if (!useWattHours && amps > 0)
	timeRemaining = currCap / amps;
      else 
	timeRemaining = -1;

      if (lastCap)
        chargePercent = currCap/lastCap*100;
      batteryState = BMBStateDischarging;
    }
  else
    {
      if (useWattHours)
        amps = chargeRate / volts;
      else
        amps = chargeRate;
      watts = amps * volts;
      NSLog(@"useWattHours %d amps %f", useWattHours, amps);

      isCharging = YES;
       if (useWattHours && volts > 0 && amps > 0)
	timeRemaining = (lastCap-currCap) / watts;
      else if (!useWattHours && amps > 0)
	timeRemaining = (lastCap-currCap) /  amps;
      else
	timeRemaining = -1;
      chargePercent = 0;
      if (lastCap)
        chargePercent = currCap/lastCap*100;
      batteryState = BMBStateCharging;
    }


  /* sanitize */
  if (critCap > warnCap)
    critCap = warnCap;
  if (critCap == 0)
    {
      if (warnCap > 0)
        critCap = warnCap;
      else
        critCap = desCap / 100;
    }
      
  isCritical = NO;
  if (currCap <= critCap)
    isCritical = YES;

}

@end

#endif
