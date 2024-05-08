/*
   Project: batmon

   Copyright (C) 2006-2015 GNUstep Application Project

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

#if defined(linux)

#import <Foundation/Foundation.h>
#import "BatteryModel.h"

@implementation BatteryModel (PlatformSpecific)

- (void)_readLine :(FILE *)f :(char *)l
{
  int ch;
    
  ch = fgetc(f);
  while (ch != EOF && ch != '\n')
    {
      *l = ch;
      l++;
      ch = fgetc(f);
    }
  *l = '\0';
}

/*
 * look for type "Battery"
 */

- (int) isTypeBattery:(NSString *)dirName
{
  char		typePath[1024]; // same as batterStatePath0
  NSString	*typeFileName;
  FILE *	typeFile;
  char		line[128];
  int		result = -1;

  typeFileName = [dirName stringByAppendingPathComponent:@"type"];

  [[DEV_SYS_POWERSUPPLY stringByAppendingPathComponent:typeFileName] getCString:typePath];
  NSLog(@"/sys checking type: %s", typePath);
  typeFile = fopen(typePath, "r");
  if (typeFile != NULL)
    {
      [self _readLine :typeFile :line];
      if (!strcmp(line, "Battery"))
	{
	  result = 1;
	}
      else
	{
	  result = 0;
	}
	
      fclose(typeFile);
    }
  return result;  
}

/*
 * to differentiate bluetooth mouses from BAT power supplies, look for "online" parameter == 1
 * -1: online parameter not found
 *  0: online parameter is 0
 *  1: online parameter is 1
 */

- (int) onlineStatus:(NSString *)dirName
{
  char		onlineStatePath[1024]; // same as batterStatePath0
  NSString	*onlineFileName;
  FILE *	onlineFile;
  char		line[128];
  int		result = -1;

  onlineFileName = [dirName stringByAppendingPathComponent:@"online"];

  [[DEV_SYS_POWERSUPPLY stringByAppendingPathComponent:onlineFileName] getCString:onlineStatePath];
  NSLog(@"/sys checking: %s", onlineStatePath);
  onlineFile = fopen(onlineStatePath, "r");
  if (onlineFile != NULL)
    {
      [self _readLine :onlineFile :line];
      if (!strcmp(line, "1"))
	{
	  result = 1;
	}
      else
	{
	  result = 0;
	}
	
      fclose(onlineFile);
    }
  return result;  
}

- (int) deviceScope:(NSString *)dirName
{
  char		onlineStatePath[1024]; // same as batterStatePath0
  NSString	*onlineFileName;
  FILE *	onlineFile;
  char		line[128];
  int		result = -1;

  onlineFileName = [dirName stringByAppendingPathComponent:@"scope"];

  [[DEV_SYS_POWERSUPPLY stringByAppendingPathComponent:onlineFileName] getCString:onlineStatePath];
  NSLog(@"/sys scope: %s", onlineStatePath);
  onlineFile = fopen(onlineStatePath, "r");
  if (onlineFile != NULL)
    {
      [self _readLine :onlineFile :line];
      if (!strcmp(line, "Device"))
	{
	  result = 1;
	}
      else
	{
	  result = 0;
	}
	
      fclose(onlineFile);
    }
  return result;  
}


- (void)initPlatformSpecific
{
  NSFileManager       *fm;
  NSArray             *dirNames;
  NSEnumerator        *en;
  NSString            *dirName;
  BOOL                done;
  FILE                *stateFile;
  char                presentStr[16];
  char                line[128];

  useACPIproc = NO;
  useACPIsys  = NO;
  useAPM      = NO;
  usePMU      = NO;

  /* look for a battery */
  fm = [NSFileManager defaultManager];
  dirNames = [fm directoryContentsAtPath:DEV_SYS_POWERSUPPLY];
  if (dirNames != nil && [dirNames count] > 0)
    {
      done = NO;
      en = [dirNames objectEnumerator];
      while (done == NO)
        {
          dirName = [en nextObject];
          if (dirName != nil)
            {
              NSString *presentFileName;
              FILE *presentFile;

              /* scan for the first present battery */
              presentFileName = [dirName stringByAppendingPathComponent:@"present"];

              [[DEV_SYS_POWERSUPPLY stringByAppendingPathComponent:presentFileName] getCString:batteryStatePath0];
              NSLog(@"/sys checking: %s", batteryStatePath0);
              presentFile = fopen(batteryStatePath0, "r");
              if (presentFile != NULL)
                {
                  [self _readLine :presentFile :line];
                  if (!strcmp(line, "1"))
                    {
		      if ([self isTypeBattery:dirName] != 1)
                        {
			  NSLog(@"/sys skipping, not a battery:%@", [DEV_SYS_POWERSUPPLY stringByAppendingPathComponent:dirName]);
                          continue;
                        }

		      /* 2024-01-04 ignore batteries with online status - like Bluetooth Mouse */
		      if ([self onlineStatus:dirName] == 1)
			{
			  NSLog(@"/sys skipping :%@", [DEV_SYS_POWERSUPPLY stringByAppendingPathComponent:dirName]);
			  continue;
			}
		      if ([self deviceScope:dirName] != -1)
			{
			  NSLog(@"/sys skipping :%@", [DEV_SYS_POWERSUPPLY stringByAppendingPathComponent:dirName]);
			  continue;
			}

                      done = YES;
                      NSLog(@"/sys: found it!: %@", [DEV_SYS_POWERSUPPLY stringByAppendingPathComponent:dirName]);
                      batterySysAcpiString = [[DEV_SYS_POWERSUPPLY stringByAppendingPathComponent:dirName] retain];
                    }
                  fclose(presentFile);
                  useACPIsys = YES;
                }           
            }
          else
            {
              done = YES;
            }
        }
    }
  else
    {
      NSLog(@"No /sys, trying /proc/acpi");
      dirNames = [fm directoryContentsAtPath:@"/proc/acpi/battery"];
      if (dirNames != nil && [dirNames count] > 0)
        {
          done = NO;
          en = [dirNames objectEnumerator];
          while (done == NO)
            {
              dirName = [en nextObject];
              if (dirName != nil)
                {
                  /* scan for the first present battery */
                  dirName = [@"/proc/acpi/battery" stringByAppendingPathComponent:dirName];
                  [dirName getCString:batteryStatePath0];
                  strcat(batteryStatePath0, "/state");
                  NSLog(@"checking: %s", batteryStatePath0);
                  stateFile = fopen(batteryStatePath0, "r");
                  if (stateFile != NULL)
                    {
                      [self _readLine :stateFile :line];
                      sscanf(line, "present: %s", presentStr);
                      if (!strcmp(presentStr, "yes"))
                        {
                          done = YES;
                          NSLog(@"/proc found it!: %@", dirName);
                          [dirName getCString:batteryInfoPath0];
                          strcat(batteryInfoPath0, "/info");
                        }
                      fclose(stateFile);
                      useACPIproc = YES;
                    }           
                }
	      else
                {
                  done = YES;
                }
            }
        }
      else
        {
          /* no acpi, but maybe apm */
          if([fm fileExistsAtPath:@"/proc/apm"] == YES)
            {
              NSLog(@"found apm");
              useAPM = YES;
              strcpy(apmPath, "/proc/apm");
            }
          else
            {
              dirNames = [fm directoryContentsAtPath:DEV_PROC_PMU];
              if (dirNames != nil && [dirNames count] > 0)
                {
                  NSLog(@"Found PMU");
                  usePMU = YES;
                  useWattHours = NO;
                }
            }
        }
    }
}

- (void)updatePlatformSpecific
{
  FILE *stateFile;
  FILE *infoFile;
  char line[128];
    
  char presentStr[16];
  char stateStr[16];
  char chStateStr[16];
  char rateStr[16];
  char capacityStr[16];
  char voltageStr[16];
  int  rateVal;
  int  capacityVal;
  int  voltageVal;
  NSString *chargeStateStr;

  char present2Str[16];
  char desCapStr[16];
  char lastCapStr[16];
  char batTypeStr[16];
  char warnCapStr[16];

  batteryState = 0;

  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

  if (useACPIsys)
    {
      NSString *ueventFileName;
      NSMutableDictionary *ueventDict;
      NSString *lineStr;
      NSRange  sepRange;
      NSString *valueStr;
      NSString *keyStr;


      //	NSLog(@"reading %@", batterySysAcpiString);
      ueventFileName = [batterySysAcpiString stringByAppendingPathComponent:@"uevent"];

      [ueventFileName getCString:batteryStatePath0];
      stateFile = fopen(batteryStatePath0, "r");
      if (stateFile == NULL)
	{
	  batteryState = BMBStateMissing;
	  watts = 0;
	  amps = 0;
	  volts = 0;
	  chargePercent = 0;
	  currCap = 0;
	  timeRemaining = -1;
	  NSLog(@"acpi /sys state file is null");
	  return;
	}

      ueventDict = [[NSMutableDictionary alloc] initWithCapacity: 4];

      [self _readLine :stateFile :line];
      lineStr = [NSString stringWithCString: line];
      while ([lineStr length] > 0)
	{
	    
	  sepRange = [lineStr rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString:@"="]];
	  if (sepRange.location != NSNotFound)
	    {
	      keyStr = [lineStr substringToIndex: sepRange.location];
	      valueStr = [lineStr substringFromIndex: sepRange.location+1];
	      [ueventDict setObject: valueStr forKey: keyStr];
	    }
	  [self _readLine :stateFile :line];
	  lineStr = [NSString stringWithCString: line];
	}

//        NSLog(@"%@", ueventDict);
      
      amps = [[ueventDict objectForKey:@"POWER_SUPPLY_CURRENT_NOW"] floatValue] / 1000000;
      if (isnan(amps))
	amps = 0;
      volts = [[ueventDict objectForKey:@"POWER_SUPPLY_VOLTAGE_NOW"] floatValue] / 1000000;
      if ([ueventDict objectForKey:@"POWER_SUPPLY_POWER_NOW"] == nil)
	watts = volts*amps;
      else
	{
	  watts = [[ueventDict objectForKey:@"POWER_SUPPLY_POWER_NOW"] floatValue] / 1000000;
	  if (isnan(watts))
	    watts = 0;
	  if (volts > 0)
	    amps = watts / volts;
	}

      useWattHours = YES;
      if ([ueventDict objectForKey:@"POWER_SUPPLY_ENERGY_FULL_DESIGN"] != nil)
	{
	  desCap = [[ueventDict objectForKey:@"POWER_SUPPLY_ENERGY_FULL_DESIGN"] floatValue] / 1000000;
	  lastCap = [[ueventDict objectForKey:@"POWER_SUPPLY_ENERGY_FULL"] floatValue] / 1000000;
	  currCap = [[ueventDict objectForKey:@"POWER_SUPPLY_ENERGY_NOW"] floatValue] / 1000000;
	}
      else
	{
	  desCap = [[ueventDict objectForKey:@"POWER_SUPPLY_CHARGE_FULL_DESIGN"] floatValue] / 1000000;
	  lastCap = [[ueventDict objectForKey:@"POWER_SUPPLY_CHARGE_FULL"] floatValue] / 1000000;
	  currCap = [[ueventDict objectForKey:@"POWER_SUPPLY_CHARGE_NOW"] floatValue] / 1000000;
	  useWattHours = NO;
	}
      warnCap = 0; // FIXME
      id lcval = [prefs objectForKey:@"last_capacity"];
      if ([lcval floatValue] > 0) {
        lastCap = [lcval floatValue];
      }

      chargeStateStr = (NSString *)[ueventDict objectForKey:@"POWER_SUPPLY_STATUS"];
      batteryType = (NSString *)[ueventDict objectForKey:@"POWER_SUPPLY_TECHNOLOGY"];
      batteryManufacturer = (NSString *)[ueventDict objectForKey:@"POWER_SUPPLY_MANUFACTURER"];

      isCharging = NO;
      if ([chargeStateStr isEqualToString:@"Charging"])
	{
	  if (useWattHours)
	    {
	      if (amps > 0)
		timeRemaining = (lastCap-currCap) / watts;
	      else
		timeRemaining = -1;
	    }
	  else
	    {
	      if (watts > 0)
		timeRemaining = (lastCap-currCap) / amps;
	      else
		timeRemaining = -1;
	    }
	  chargePercent = currCap/lastCap*100;
	  isCharging = YES;
	  batteryState = BMBStateCharging;
	}
      else if ([chargeStateStr isEqualToString:@"Discharging"])
	{
	  if (useWattHours)
	    {
	      if (amps > 0)
		timeRemaining = currCap / watts;
	      else
		timeRemaining = -1;
	    }
	  else
	    {
	      if (watts > 0)
		timeRemaining = currCap / amps;
	      else
		timeRemaining = -1;
	    }
	  chargePercent = currCap/lastCap*100;
	  batteryState = BMBStateDischarging;
	}
      else if ([chargeStateStr isEqualToString:@"Not charging"])
        {
	  isCharging = NO;
          if (lastCap > 0 && lastCap == currCap)
            {
	      chargePercent = 100;
	      timeRemaining = 0;
	      batteryState = BMBStateFull;
            }
          else if (currCap > 0) 
            {
	      chargePercent = currCap/lastCap*100;
	      timeRemaining = 0;
	      batteryState = BMBStateFull;
            }
          else
            {
	      chargePercent = 0;
	      timeRemaining = 0;
	      batteryState = BMBStateUnknown;
            }
        }
      else if ([chargeStateStr isEqualToString:@"Charged"] || [chargeStateStr isEqualToString:@"Full"])
	{
	  chargePercent = 100;
	  timeRemaining = 0;
	  isCharging = YES;
	  batteryState = BMBStateFull;
	}
      else if ([chargeStateStr isEqualToString:@"Unknown"])
	{
	  timeRemaining = 0;
	  if (amps == 0)
	    {
	      chargePercent = 100;
	      isCharging = YES;
	    }
	  batteryState = BMBStateUnknown;
	}
      fclose(stateFile);
    }
  else if (useACPIproc)
    {
      stateFile = fopen(batteryStatePath0, "r");
      if (stateFile == NULL)
	{
	  NSLog(@"acpi /proc state file null");
	  return;
	}

      [self _readLine :stateFile :line];
      sscanf(line, "present: %s", presentStr);
      [self _readLine :stateFile :line];
      sscanf(line, "capacity state: %s", stateStr);
      [self _readLine :stateFile :line];
      sscanf(line, "charging state: %s", chStateStr);
      [self _readLine :stateFile :line];
      sscanf(line, "present rate: %s mW", rateStr);
      [self _readLine :stateFile :line];
      sscanf(line, "remaining capacity: %s mWh", capacityStr);
      [self _readLine :stateFile :line];
      sscanf(line, "present voltage: %s mV", voltageStr);
      fclose(stateFile);

      rateVal = atoi(rateStr);
      capacityVal = atoi(capacityStr);
      voltageVal = atoi(voltageStr);

      infoFile = fopen(batteryInfoPath0, "r");
      NSAssert(infoFile != NULL, @"ACPI - /proc: info file shall not be NULL");

      [self _readLine :infoFile :line];
      sscanf(line, "present: %s", present2Str);
      [self _readLine :infoFile :line];
      sscanf(line, "design capacity: %s", desCapStr);
      [self _readLine :infoFile :line];
      sscanf(line, "last full capacity: %s", lastCapStr);
      [self _readLine :infoFile :line]; // battery technology
      [self _readLine :infoFile :line]; // design voltage
      [self _readLine :infoFile :line]; // design capacity warning
      sscanf(line, "design capacity warning: %s", warnCapStr);
      [self _readLine :infoFile :line];    
      [self _readLine :infoFile :line];
      [self _readLine :infoFile :line];
      [self _readLine :infoFile :line];
      [self _readLine :infoFile :line];
      [self _readLine :infoFile :line];
      sscanf(line, "battery type: %s", batTypeStr);
      if (batteryType != nil)
	[batteryType release];
      batteryType = [[NSString stringWithCString:batTypeStr] retain];

      fclose(infoFile);

      watts = (float)rateVal / 1000;

      // a sanity check, a laptop won't consume 1000W
      // necessary since sometimes ACPI returns bogus stuff
      if (isnan(watts))
	watts = 0;
      else if (watts > 1000)
	watts = 0;
      volts = (float)voltageVal / 1000;
      amps = watts / volts;

      desCap = (float)atoi(desCapStr)/1000;
      lastCap = (float)atoi(lastCapStr)/1000;
      currCap = capacityVal / 1000;
      warnCap = (float)atoi(warnCapStr)/1000;

      if (!strcmp(chStateStr, "charged"))
	{
	  chargePercent = 100;
	  timeRemaining = 0;
	  isCharging = YES;
	  batteryState = BMBStateFull;
	}
      else if (!strcmp(chStateStr, "charging"))
	{
	  if (watts > 0)
	    timeRemaining = (lastCap-currCap) / watts;
	  else
	    timeRemaining = -1;
	  chargePercent = currCap/lastCap*100;
	  isCharging = YES;
	  batteryState = BMBStateCharging;
	}
      else
	{
	  if (watts > 0)
	    timeRemaining = currCap / watts;
	  else
	    timeRemaining = -1;
	  chargePercent = currCap/lastCap*100;
	  isCharging = NO;
	  batteryState = BMBStateDischarging;
	}
      fclose(stateFile);
    }
  else if (useAPM)
    {
      char drvVersionStr[16];
      char apmBiosVersionStr[16];
      char apmBiosFlagsStr[16];
      char acLineStatusStr[16];
      char battStatusStr[16];
      int  battStatusInt;
      char battFlagsStr[16];
      char percentStr[16];
      char timeRemainingStr[16];
      char timeUnitStr[16];
      BOOL percentIsInvalid;

      percentIsInvalid = NO;
      stateFile = fopen(apmPath, "r");
      if (stateFile == NULL)
	{
	  NSLog(@"apm state file nil");
	  return;
	}


      [self _readLine :stateFile :line];
      //	NSLog(@"line: %s", line);
      sscanf(line, "%s %s %s %s %s %s %s %s %s", drvVersionStr, apmBiosVersionStr, apmBiosFlagsStr, acLineStatusStr, battStatusStr, battFlagsStr, percentStr, timeRemainingStr, timeUnitStr);

      if (strlen(percentStr) > 0)
	{
	  if (percentStr[strlen(percentStr)-1] == '%')
	    percentStr[strlen(percentStr)-1] = '\0';
	  NSLog(@"%s %s %s", drvVersionStr, apmBiosVersionStr, percentStr);
    
	  chargePercent = (float)atof(percentStr);
	  if (chargePercent > 100)
	    chargePercent = 100;
	  if (chargePercent < 0)
	    {
	      chargePercent = 0;
	      percentIsInvalid = YES;
	    }
	  //	    NSLog(@"percent %f", chargePercent);
	}

      if (strlen(battStatusStr) > 0)
	{
	  if (battStatusStr[3] == '0')
	    battStatusInt = 0;
	  else if (battStatusStr[3] == '1')
	    battStatusInt = 1;
	  else if (battStatusStr[3] == '2')
	    battStatusInt = 2;
	  else if (battStatusStr[3] == '3')
	    battStatusInt = 3;
	  else if (battStatusStr[3] == '4')
	    battStatusInt = 4;
	  else
	    battStatusInt = -1;

	  isCharging = NO;
          isCritical = NO;
	  if (battStatusInt == 0)
	    batteryState = BMBStateHigh;
	  else if (battStatusInt == 1)
	    batteryState = BMBStateLow;
	  else if (battStatusInt == 2)
	    {
	      batteryState = BMBStateDischarging;
	      isCritical = YES;
	    }
	  else if (battStatusInt == 3)
	    {
	      batteryState = BMBStateCharging;
	      isCharging = YES;
	    } 
	  else if (battStatusInt == 4)
	    batteryState = BMBStateMissing;
	  else
	    batteryState = BMBStateUnknown;


	  if (percentIsInvalid)
	    {
	      NSLog(@"Battery percent information is invalid.");

	      if (battStatusInt == 0)
		chargePercent = 75;
	      else if (battStatusInt == 1)
		chargePercent = 25;
	      else if (battStatusInt == 2)
		chargePercent = 5;
	      else if (battStatusInt == 3)
		chargePercent = 100;
	      else if (battStatusInt == 4)
		chargePercent = 0;
	      else
		chargePercent = 0;
	    }
	}
    
      fclose(stateFile);
    }
  else if (usePMU)
    {
      NSString *strPmuInfo;
      NSString *strPmuBat;
      NSArray *arrayOfLines;
      NSArray *lineArray;
      NSString *strValue;

      strPmuInfo = [NSString stringWithContentsOfFile: @"/proc/pmu/info"];
      arrayOfLines = [strPmuInfo componentsSeparatedByString: @"\n"];
      NSLog(@"info %@", arrayOfLines);
      lineArray = [[arrayOfLines objectAtIndex: 2] componentsSeparatedByString: @":"];
      strValue = [lineArray objectAtIndex: 1];
      if ([strValue intValue] == 1)
	{
	  isCharging = YES;
	  batteryState = BMBStateCharging;
	}
      else
	{
	  isCharging = NO;
	  batteryState = BMBStateDischarging;
	}

      strPmuBat = [NSString stringWithContentsOfFile: @"/proc/pmu/battery_0"];
      arrayOfLines = [strPmuBat componentsSeparatedByString: @"\n"];
      NSLog(@"battery0 %@", arrayOfLines);

      lineArray = [[arrayOfLines objectAtIndex: 2] componentsSeparatedByString: @":"];
      strValue = [lineArray objectAtIndex: 1];
      currCap = (float)([strValue doubleValue] / 1000);

      lineArray = [[arrayOfLines objectAtIndex: 3] componentsSeparatedByString: @":"];
      strValue = [lineArray objectAtIndex: 1];
      lastCap = (float)([strValue doubleValue] / 1000);

      lineArray = [[arrayOfLines objectAtIndex: 4] componentsSeparatedByString: @":"];
      strValue = [lineArray objectAtIndex: 1];
      amps = (float)([strValue doubleValue] / 1000);

      lineArray = [[arrayOfLines objectAtIndex: 5] componentsSeparatedByString: @":"];
      strValue = [lineArray objectAtIndex: 1];
      volts = (float)([strValue doubleValue] / 1000);

      lineArray = [[arrayOfLines objectAtIndex: 6] componentsSeparatedByString: @":"];
      strValue = [lineArray objectAtIndex: 1];
      timeRemaining = (float)[strValue intValue] / 3600;

      desCap = lastCap; /* we can't do better with PMU */
      chargePercent = currCap/lastCap*100;
      watts = amps * volts;
    }
}

@end

#endif
