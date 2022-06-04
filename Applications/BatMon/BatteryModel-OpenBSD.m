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

#if defined(openbsd) || defined(__OpenBSD__)
#include <unistd.h>
#include <fcntl.h>  /* open */
#include <sys/ioctl.h>
#include <machine/apmvar.h>


#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/param.h>
#include <sys/sysctl.h>
#include <sys/sensors.h>


#define APMDEV "/dev/apm"

#define SensorUnitKey @"unit"
#define SensorValueKey @"value"
#define SensorDescriptionKey @"description"
#define SensorStatusKey @"status"

#import <Foundation/Foundation.h>

#import "BatteryModel.h"

struct ctlname hwname[] = CTL_HW_NAMES;
struct list {
        struct  ctlname *list;
        int     size;
};

int sysctl_sensors(int *, int *, NSMutableDictionary *);
void descendSensorDev(char *, int *, u_int, struct sensordev *, NSMutableDictionary *);
NSDictionary *parseSensor(struct sensor *);


/* Maximum size object to expect from sysctl(3) */
#define SYSCTL_BUFSIZ   8192

NSDictionary *readSensors ()
{
  int mib[CTL_MAXNAME], type, indx;
  NSMutableDictionary *sensors;
  
  mib[0] = CTL_HW;
  mib[1] = HW_SENSORS;

  struct list lp = { hwname, HW_MAXID };

  indx = 6; /* CTL_HW */
  type = lp.list[indx].ctl_type;
  
  sensors = [[NSMutableDictionary alloc] init];
  sysctl_sensors(mib, &type, sensors);

  return [NSDictionary dictionaryWithDictionary:sensors];
}

/*
 * Handle hardware monitoring sensors support
 */
int sysctl_sensors(int mib[], int *typep, NSMutableDictionary *sensors)
{
  int dev;
  struct sensordev snsrdev;
  size_t sdlen = sizeof(snsrdev);
  
  char buf[SYSCTL_BUFSIZ];
  
  /* scan all sensor devices */
  for (dev = 0; ; dev++)
    {
      mib[2] = dev;
      if (sysctl(mib, 3, &snsrdev, &sdlen, NULL, 0) == -1) {
        if (errno == ENXIO)
          continue;
        if (errno == ENOENT)
          break;
      }
      /* which sensors do we want to look for ? */
      if (strstr(snsrdev.xname, "acpibat") > 0)
        { 
          snprintf(buf, sizeof(buf), "%s", snsrdev.xname);
          descendSensorDev(buf, mib, 3, &snsrdev, sensors);
        }
      else if (strstr(snsrdev.xname, "acpiac0") > 0)
        { 
          snprintf(buf, sizeof(buf), "%s", snsrdev.xname);
          descendSensorDev(buf, mib, 3, &snsrdev, sensors);
        }
    }
  return (-1);
}

/*
 * Descend recursively each sensor.
 * Sensors have three levels: name and order (acbibat0), type (volt)  and order (volt0) then value in a struct (12 Vdc)
 * 
 */
void descendSensorDev(char *string, int mib[], u_int mlen, struct sensordev *snsrdev, NSMutableDictionary * sensorsDict)
{
  char buf[SYSCTL_BUFSIZ];
  enum sensor_type type;

  if (mlen == 3)
    {
      for (type = 0; type < SENSOR_MAX_TYPES; type++)
        {
          mib[3] = type;
          snprintf(buf, sizeof(buf), "%s.%s", string, sensor_type_s[type]);
          descendSensorDev(buf, mib, mlen+1, snsrdev, sensorsDict);
        }
      return;
    }

  if (mlen == 4)
    {
      int numt;
      type = mib[3];
      for (numt = 0; numt < snsrdev->maxnumt[type]; numt++)
        {
          mib[4] = numt;
          snprintf(buf, sizeof(buf), "%s%u", string, numt);
          descendSensorDev(buf, mib, mlen+1, snsrdev, sensorsDict);
        }
      return;
    }

  if (mlen == 5)
    {

      struct sensor snsr;
      size_t slen = sizeof(snsr);
      /* this function is only printing sensors in bulk, so we
       * do not return any error messages if the requested sensor
       * is not found by sysctl(3)
       */
      if (sysctl(mib, 5, &snsr, &slen, NULL, 0) == -1)
        return;
      if (slen > 0 && (snsr.flags & SENSOR_FINVALID) == 0)
        {
          NSDictionary *sensorDict;
          NSString *sensorName;
                  
          sensorName = [NSString stringWithCString:string];
          sensorDict = parseSensor(&snsr);
          if (sensorDict)
            [sensorsDict setObject:sensorDict forKey:sensorName];
        }
      return;
    }
}

/* Once at the bottom level is reached, we parse the struct and format it into a Dictionary */
NSDictionary *parseSensor(struct sensor *s)
{
  NSDictionary *result;
  NSMutableDictionary *resD;
  NSString *unit = nil;
  NSString *status = nil;
  NSNumber *value = nil;
  NSString *description = nil;
  
  if (s->flags & SENSOR_FUNKNOWN)
    return nil;
   
  resD = [[NSMutableDictionary alloc] init];
  
  switch (s->type)
    {
    case SENSOR_TEMP:
      value = [NSNumber numberWithFloat:(s->value - 273150000) / 1000000.0];
      unit = @"C";
      break;
    case SENSOR_FANRPM:
      value = [NSNumber numberWithLong:s->value];
      unit = @"rpm";
      break;
    case SENSOR_VOLTS_DC:
      value = [NSNumber numberWithFloat: s->value / 1000000.0];
      unit = @"Vdc";
      break;
    case SENSOR_VOLTS_AC:
      value = [NSNumber numberWithFloat: s->value / 1000000.0];
      unit = @"Vac";
      break;
    case SENSOR_WATTS:
      value = [NSNumber numberWithFloat: s->value / 1000000.0];
      unit = @"W";
      break;
    case SENSOR_AMPS:
      value = [NSNumber numberWithFloat: s->value / 1000000.0];
      unit = @"A";
      break;
    case SENSOR_WATTHOUR:
      value = [NSNumber numberWithFloat: s->value / 1000000.0];
      unit = @"Wh";
      break;
    case SENSOR_AMPHOUR:
      value = [NSNumber numberWithFloat: s->value / 1000000.0];
      unit = @"Ah";
      break;
    case SENSOR_INDICATOR:
      value = [NSNumber numberWithBool: s->value ? YES : NO];
      unit = @"boolean";
      break;
    case SENSOR_INTEGER:
      value = [NSNumber numberWithLong:s->value];
      unit = @"long";
      break;
    case SENSOR_PERCENT:
      value = [NSNumber numberWithFloat: s->value / 1000.0];
      unit = @"\%";
      break;
    case SENSOR_TIMEDELTA:
      value = [NSNumber numberWithFloat:s->value / 1000000000.0];
      unit = @"s";
      break;
    default:
      NSLog(@"unknown");
    }

  if (s->desc[0] != '\0')
    {
      description = [NSString stringWithCString: s->desc];
    }

  switch (s->status)
    {
    case SENSOR_S_UNSPEC:
      status =nil;
      break;
    case SENSOR_S_OK:
      status = @"Ok";
      break;
    case SENSOR_S_WARN:
      status = @"Warning";
      break;
    case SENSOR_S_CRIT:
      status = @"Critical";
      break;
    case SENSOR_S_UNKNOWN:
      status = @"Unknown";
      break;
    }

        
  if (unit)
    [resD setObject:unit forKey:SensorUnitKey];
  if (value)
    [resD setObject:value forKey:SensorValueKey];
  if (description)
    [resD setObject:description forKey:SensorDescriptionKey];
  if (status)
    [resD setObject:status forKey:SensorStatusKey];

  result = nil;
  if ([resD count] > 0)
    {
      result = [NSDictionary dictionaryWithDictionary:resD];
      [resD release];
    }
  NSLog(@"sensor: %@", result);
  return result;
}


@implementation BatteryModel (PlatformSpecific)

- (void)initPlatformSpecific
{
}

- (BOOL)updateACPI
{
  NSDictionary *sensors;

  sensors = readSensors();
  NSLog(@"updateACPI Sensors: %@", sensors);

  batteryState = BMBStateUnknown;
  if ([sensors count])
    {
      isCharging = NO;
      isCritical = NO;

      if([sensors objectForKey:@"acpibat0.watthour3"] || [sensors objectForKey:@"acpibat0.amphour3"])
         {
           if([sensors objectForKey:@"acpibat0.watthour3"])
             {
               useWattHours = YES;
               lastCap = [[[sensors objectForKey:@"acpibat0.watthour0"] objectForKey:SensorValueKey] floatValue];
               warnCap = [[[sensors objectForKey:@"acpibat0.watthour1"] objectForKey:SensorValueKey] floatValue];
               critCap = [[[sensors objectForKey:@"acpibat0.watthour2"] objectForKey:SensorValueKey] floatValue];
               currCap = [[[sensors objectForKey:@"acpibat0.watthour3"] objectForKey:SensorValueKey] floatValue];
               desCap  = [[[sensors objectForKey:@"acpibat0.watthour4"] objectForKey:SensorValueKey] floatValue];

               volts = [[[sensors objectForKey:@"acpibat0.volt1"] objectForKey:SensorValueKey] floatValue];
               watts = [[[sensors objectForKey:@"acpibat0.power0"] objectForKey:SensorValueKey] floatValue];
               amps = watts/volts;
             }
           else if ([sensors objectForKey:@"acpibat0.amphour3"])
             {
               useWattHours = NO;
               lastCap = [[[sensors objectForKey:@"acpibat0.amphour0"] objectForKey:SensorValueKey] floatValue];
               warnCap = [[[sensors objectForKey:@"acpibat0.amphour1"] objectForKey:SensorValueKey] floatValue];
               critCap = [[[sensors objectForKey:@"acpibat0.amphour2"] objectForKey:SensorValueKey] floatValue];
               currCap = [[[sensors objectForKey:@"acpibat0.amphour3"] objectForKey:SensorValueKey] floatValue];
               desCap  = [[[sensors objectForKey:@"acpibat0.amphour4"] objectForKey:SensorValueKey] floatValue];

               volts = [[[sensors objectForKey:@"acpibat0.volt1"] objectForKey:SensorValueKey] floatValue];
               amps = [[[sensors objectForKey:@"acpibat0.current0"] objectForKey:SensorValueKey] floatValue];
               watts = amps*volts;
             }

           /* fiddling with raw is tricky but found no other way to know if it is charging*/
           if([sensors objectForKey:@"acpibat0.raw0"])
             {
               NSString *rawDescription;
               NSString *rawStatus;

               rawStatus = [[sensors objectForKey:@"acpibat0.raw0"] objectForKey:SensorStatusKey];
               rawDescription = [[sensors objectForKey:@"acpibat0.raw0"] objectForKey:SensorDescriptionKey];
               NSLog(@"raw desc %@", rawDescription);
               NSLog(@"raw status %@", rawStatus);

               if ([rawStatus isEqualToString:@"Critical"])
                 {
                   isCritical = YES;
                   batteryState = BMBStateCritical;
                 }
               else if ([rawStatus isEqualToString:@"Warning"])
                 {
                   isCritical = YES;
                   batteryState = BMBStateLow;
                 }
               else if ([rawDescription isEqualToString:@"battery charging"])
                 {
                   isCharging = YES;
                   batteryState = BMBStateCharging;
                 }
               else if ([rawDescription isEqualToString:@"battery full"])
                 {
                   isCharging = YES;
                   batteryState = BMBStateFull;
                   chargePercent = 100;
                 }
               else if ([rawDescription isEqualToString:@"battery idle"])
                 {
                   isCharging = YES;
                   batteryState = BMBStateFull;
                   chargePercent = 100;
                 }
               else if ([rawDescription isEqualToString:@"battery discharging"])
                 {
                   isCharging = YES;
                   batteryState = BMBStateDischarging;
                 }
               else
                 {
                   NSLog(@"did not assign state");
                 }

               if( batteryState == BMBStateCharging )
                 {
                   if (useWattHours)
                     timeRemaining = (lastCap-currCap) / watts;
                   else
                     timeRemaining = (lastCap-currCap) / amps;
                   chargePercent = currCap/lastCap*100;
                 }
               else if( batteryState == BMBStateDischarging )
                 {
                   if (useWattHours)
                     timeRemaining = currCap / watts;
                   else
                     timeRemaining = currCap / amps;
                   chargePercent = currCap/lastCap*100;
                 }
             }
         }
      if([sensors objectForKey:@"acpiac0.indicator0"])
        {
          isCharging = [[[sensors objectForKey:@"acpiac0.indicator0"] objectForKey:SensorValueKey] boolValue];
        }
      return YES;
    }

  return NO;
}

- (void)updateAPM
{
  int apmfd;
  struct apm_power_info apmPwInfo;
  BOOL validBattery;

  apmfd = open(APMDEV, O_RDONLY);
  if (apmfd == -1)
    return;

  if( -1 == ioctl(apmfd, APM_IOC_GETPOWER, &apmPwInfo) )
    return;

  isCharging = NO;
  isCritical = NO;
  validBattery = YES;
  if (APM_BATT_HIGH == apmPwInfo.battery_state)
    batteryState = BMBStateHigh;
  else if (APM_BATT_LOW == apmPwInfo.battery_state)
    {
      batteryState = BMBStateLow;
    }
  else if (APM_BATT_CRITICAL == apmPwInfo.battery_state)
    {
      batteryState = BMBStateCritical;
      isCritical = YES;
    }
  else if (APM_BATT_CHARGING == apmPwInfo.battery_state)
    {
      batteryState = BMBStateCharging;
      isCharging = YES;
    }
  else if (APM_BATTERY_ABSENT == apmPwInfo.battery_state)
    {
      batteryState = BMBStateMissing;
      validBattery = NO;
    }
  else
    {
      batteryState = BMBStateUnknown;;
      validBattery = NO;
    }

  if (APM_AC_ON == apmPwInfo.ac_state)
    isCharging = YES;

  /* we expect time in hours */
  if (validBattery)
    {
      timeRemaining = (float)apmPwInfo.minutes_left / 60;
      chargePercent = (float)(int)apmPwInfo.battery_life;

      /* sanity checks */
      if (isCharging && timeRemaining > 100)
	timeRemaining = 0;
      if (chargePercent > 100)
	chargePercent = 100;
      else if (chargePercent < 0)
	chargePercent = 0;

      if (timeRemaining < 0)
	timeRemaining = 0;
    }
  else
    {
      chargePercent = 0;
      timeRemaining= 0;
    }

  close(apmfd);
}

- (void)updatePlatformSpecific
{
  if(![self updateACPI])
    [self updateAPM];
}

@end

#endif
