/* AO.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004 Wolfgang Sourdeau
 * Copyright (C) 2012 Philippe Roussel
 *
 * Author: Philippe Roussel <p.o.roussel@free.fr>
 *         Riccardo Mottola <rm@gnu.org>
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#import <AppKit/AppKit.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>
#import <ao/ao.h>


@interface AO : NSObject <CynthiuneBundle, Output>
{
  id parentPlayer;
  BOOL stopRequested;
  ao_device *dev;
  int driver;
  ao_sample_format format;
  unsigned char buffer[DEFAULT_BUFFER_SIZE];
  NSLock *devlock;
}
@end

@implementation AO : NSObject

+ (NSString *) bundleDescription
{
  return @"Output plug-in based on libao";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects: @"Copyright (C) 2012 Philippe Roussel", nil];
}

+ (BOOL) isThreaded
{
  return YES;
}

- (void) setParentPlayer: (id) aPlayer;
{
  parentPlayer = aPlayer;
}

- (id) init
{
  if ((self = [super init])) {
    stopRequested = NO;
    memset(&format, 0, sizeof(format));
    devlock = [NSLock new];
    ao_initialize();
    driver = ao_default_driver_id();
  }
  return self;
}

/* FIXME : this is never called */
- (void)dealloc
{
  ao_shutdown();
  [devlock release];
  [super dealloc];
}

- (BOOL) prepareDeviceWithChannels: (unsigned int) numberOfChannels
                           andRate: (unsigned long) sampleRate
		    withEndianness: (Endianness) e
{
  BOOL result = YES;

  format.channels = (int)numberOfChannels;
  format.rate = (int)sampleRate;
  /* FIXME : this should somehow come from the input bundle */
  format.bits = 16;
  if (e == BigEndian)
    format.byte_format = AO_FMT_BIG;
  else
    format.byte_format = AO_FMT_LITTLE;
  [devlock lock];
  if (dev) {
    ao_close(dev);
    dev = ao_open_live(driver, &format, NULL);
    result = (dev == NULL) ? NO : YES;
  }
  [devlock unlock];
  return result;
}

- (BOOL) openDevice
{
  BOOL result;

  [devlock lock];
  dev = ao_open_live(driver, &format, NULL);
  result = (dev == NULL) ? NO : YES;
  [devlock unlock];
  return result;
}

- (void) closeDevice
{
  [devlock lock];
  ao_close(dev);
  dev = NULL;
  [devlock unlock];
}

- (void) threadLoop
{
  int bufferSize;
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  while (!stopRequested) {
      bufferSize = [parentPlayer readNextChunk: buffer
				      withSize: DEFAULT_BUFFER_SIZE];
      [devlock lock];
      if (dev && bufferSize > 0)
	ao_play(dev, (char *)buffer, (uint_32)bufferSize);
      [devlock unlock];
      /* FIXME : copied from ALSA.m, I'm not sure this is needed */
      if ([pool autoreleaseCount] > 50)
	[pool emptyPool];
  }
  stopRequested = NO;
  [pool release];
}

- (BOOL) startThread
{
  [NSThread detachNewThreadSelector: @selector(threadLoop)
			   toTarget: self
			 withObject: nil];
  return YES;
}

- (void) stopThread
{
  stopRequested = YES;
}
@end
