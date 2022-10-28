/* Timidity.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
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

#import <Foundation/Foundation.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Format.h>
#import <Cynthiune/Output.h>
#import <Cynthiune/utils.h>

#import "Timidity.h"

#define LOCALIZED(X) _b ([Timidity class], X)

#define timidity "timidity"
#define rate 22050

@implementation Timidity : NSObject

- (id) init
{
  if ((self = [super init]))
    {
      tiTask = nil;
      in = nil;
      err = nil;
      title = nil;
      duration = 0;
    }

  return self;
}

+ (NSString *) bundleDescription
{
  return @"Wrapper plug-in for the Timidity midi reader";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2005  Wolfgang Sourdeau",
                  nil];
}

+ (NSArray *) compatibleTagBundles
{
  return nil;
}

- (void) _createTask: (NSString *) fileName
{
  NSString *timidityPath, *freqString;

  tiTask = [NSTask new];
  [tiTask autorelease];
  freqString = [NSString stringWithFormat: @"-s%d", rate];
  timidityPath = [NSString stringWithCString: timidity];

  [tiTask setLaunchPath: timidityPath];
  [tiTask setArguments: [NSArray arrayWithObjects: freqString, @"-OrSs1",
                                 @"-idv", @"-o", @"-", fileName, nil]];
}

- (BOOL) _parseData: (NSData *) data
{
  BOOL result;
  NSString *content, *durationString;
  NSRange range;
  NSArray *elements;

  result = NO;
  content = [[NSString alloc] initWithData: data
                              encoding: NSNonLossyASCIIStringEncoding];
  range = [content rangeOfString: @"samples, time "];
  if (range.length)
    {
      durationString = [content substringFromIndex: NSMaxRange (range)];
      elements = [durationString componentsSeparatedByString: @":"];
      if ([elements count])
        duration = ([[elements objectAtIndex: 0] intValue] * 60
                    + [[elements objectAtIndex: 1] intValue]);
      result = YES;
    }
  [content release];

  return result;
}

- (void) _parseStdErr
{
  NSData *data;
  BOOL done;

  done = NO;

  while (!done)
    {
      data = [err availableData];
      done = [self _parseData: data];
    }
}

- (BOOL) streamOpen: (NSString *) fileName
{
  BOOL result;
  NSPipe *tiPipe, *stderrPipe;

  [self _createTask: fileName];

  tiPipe = [NSPipe pipe];
  [tiTask setStandardOutput: tiPipe];
  stderrPipe = [NSPipe pipe];
  [tiTask setStandardError: stderrPipe];

  in = [tiPipe fileHandleForReading];
  err = [stderrPipe fileHandleForReading];


  NS_DURING
    {
      [tiTask launch];
    }
  NS_HANDLER
    {
      NSLog(@"Error while lauching task '%@'", [tiTask launchPath]);
    }
  NS_ENDHANDLER

  if ([tiTask isRunning])
    {
      [tiTask retain];
      title = makeTitleFromFilename (fileName);
      [title retain];
      [self _parseStdErr];
      result = YES;
    }
  else
    {
      [in closeFile];
      [err closeFile];
      result = NO;
    }

  return result;
}

+ (BOOL) canTestFileHeaders
{
  return NO;
}

+ (BOOL) streamTestOpen: (NSString *) fileName
{
  return NO;
}

+ (NSString *) errorText: (int) error
{
  return @"";
}

- (int) readNextChunk: (unsigned char *) buffer
	     withSize: (unsigned int) bufferSize
{
  NSData *bytes;
  int size;

  bytes = [in readDataOfLength: DEFAULT_BUFFER_SIZE];
  if (bytes)
    {
      size = [bytes length];
      [bytes getBytes: buffer length: (unsigned int) size];
    }
  else
    size = 0;

  return size;
}

- (int) lastError
{
  return 0;
}

- (unsigned int) readChannels
{
  return 2;
}

- (unsigned long) readRate
{
  return rate;
}

- (Endianness) endianness
{
  return NativeEndian;
}

- (unsigned int) readDuration
{
  return duration;
}

- (NSString *) readTitle
{
  return title;
}

- (NSString *) readGenre
{
  return @"";
}

- (NSString *) readArtist
{
  return @"";
}

- (NSString *) readAlbum
{
  return @"";
}

- (NSString *) readYear
{
  return @"";
}

- (NSString *) readTrackNumber
{
  return @"";
}

- (void) streamClose
{
  [err closeFile];
  [in closeFile];
  if (title)
    [title release];
  if ([tiTask isRunning])
    [tiTask terminate];
  [tiTask release];
}

// Player Protocol
+ (NSArray *) acceptedFileExtensions
{
  return [NSArray arrayWithObjects: @"mid", @"rmi", nil];
}

- (BOOL) isSeekable
{
  return NO;
}

- (void) seek: (unsigned int) aPos
{
}

@end
