/* MacOSXPlayer.m - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2005  Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <wolfgang@contre.com>
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

#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

#import <CoreAudio/CoreAudio.h>
#import <CoreAudio/AudioHardware.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioUnit/AudioUnitProperties.h>
#import <AudioToolbox/DefaultAudioOutput.h>
#import <AudioToolbox/AudioConverter.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>

#import "MacOSXPlayer.h"

#define LOCALIZED(X) _b ([MacOSXPlayer class], X)

static OSStatus
inputCallback (AudioConverterRef inAudioConverter, UInt32* outDataSize,
	       void** outData, void* selfRef)
{
  unsigned int chunkSize;
  PlayerRef *self;
  NSAutoreleasePool *pool;

  pool = [NSAutoreleasePool new];

  self = selfRef;
  *outData = self->buffer[self->bufferNumber];
  memset (*outData, DEFAULT_BUFFER_SIZE, 0);
  chunkSize = [self->parentPlayer readNextChunk: *outData
                   withSize: DEFAULT_BUFFER_SIZE];
  *outDataSize = chunkSize;
  self->bufferNumber = 1 - self->bufferNumber;
  memset (self->buffer[self->bufferNumber], DEFAULT_BUFFER_SIZE, 0);

  [pool release];

  return noErr;
}

static OSStatus
converterRenderer (void* selfRef, AudioUnitRenderActionFlags inActionFlags, 
                   const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, 
                   AudioBuffer *ioData)
{
  UInt32 size;
  PlayerRef *self;

  self = selfRef;

  size = ioData->mDataByteSize;
  AudioConverterFillBuffer (self->converter, inputCallback, self,
			    &size, ioData->mData);

  return noErr;
}

@implementation MacOSXPlayer : NSObject

+ (NSString *) bundleDescription
{
  return @"Output plug-in for the MacOS sound system";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2005  Wolfgang Sourdeau",
                  nil];
}

+ (BOOL) isThreaded
{
  return YES;
}

- (id) init
{
  if ((self = [super init]))
    {
      parentPlayer = nil;
      bufferNumber = 0;
      bytes = 0;
      converter = NULL;
      isBigEndian = NO;
      inputFormat.mFormatID = kAudioFormatLinearPCM;
      inputFormat.mFormatFlags = (kLinearPCMFormatFlagIsSignedInteger 
                                  | kLinearPCMFormatFlagIsPacked);
      inputFormat.mFramesPerPacket = 1;
      inputFormat.mBitsPerChannel = 16;
    }

  return self;
}

- (void) setParentPlayer: (id) aPlayer;
{
  parentPlayer = aPlayer;
}

- (BOOL) _modifyConverter
{
  UInt32 aStreamSize;

  aStreamSize = sizeof (AudioStreamBasicDescription);
  AudioUnitGetProperty (outputUnit,
                        kAudioUnitProperty_StreamFormat,
                        kAudioUnitScope_Output,
                        0,
                        &outputFormat,
                        &aStreamSize);
  if (converter)
    AudioConverterDispose (converter);

  inputFormat.mSampleRate = rate;
  inputFormat.mBytesPerPacket = channels * 2;
  inputFormat.mBytesPerFrame = channels * 2;
  inputFormat.mChannelsPerFrame = channels;
  inputFormat.mFormatFlags = (kLinearPCMFormatFlagIsSignedInteger 
                              | kLinearPCMFormatFlagIsPacked);
  if (isBigEndian)
    inputFormat.mFormatFlags |= kAudioFormatFlagIsBigEndian;

  return (AudioConverterNew (&inputFormat, &outputFormat, &converter)
          == noErr);
}

- (BOOL) _audioInit
{
  UInt32 aStreamSize;
  struct AudioUnitInputCallback input;

  input.inputProc = converterRenderer;
  input.inputProcRefCon = self;

  aStreamSize = sizeof (AudioStreamBasicDescription);

  return (OpenDefaultAudioOutput (&outputUnit) == noErr
          && AudioUnitInitialize (outputUnit) == noErr
          && AudioUnitSetProperty (outputUnit, 
                                   kAudioUnitProperty_SetInputCallback, 
                                   kAudioUnitScope_Input,
                                   0,
                                   &input, sizeof (input)) == noErr
          && AudioUnitGetProperty (outputUnit,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Output,
                                   0,
                                   &outputFormat,
                                   &aStreamSize) == noErr);
}

- (BOOL) openDevice
{
  return ([self _audioInit] && [self _modifyConverter]);
}

- (BOOL) startThread
{
  isOpen = YES;
  return (AudioOutputUnitStart (outputUnit) == noErr);
}

- (void) stopThread
{
  isOpen = NO;
  AudioOutputUnitStop (outputUnit);
}

- (void) closeDevice
{
  CloseComponent (outputUnit);
  isOpen = NO;
}

- (BOOL) prepareDeviceWithChannels: (unsigned int) numberOfChannels
                           andRate: (unsigned long) sampleRate
		    withEndianness: (Endianness) e
{
  BOOL result;

  channels = numberOfChannels;
  rate = sampleRate;
  
  isBigEndian = NO;
  if (e == NativeEndian)
    {
#if defined (__ppc__)
    isBigEndian = YES;
#elif defined (__i386__)
    isBigEndian = NO;
#else
#warning Unknown architecture
    isBigEndian = YES;
#endif
    }
  else if (e == BigEndian)
    isBigEndian = YES;

  if (isOpen)
    {
      AudioOutputUnitStop (outputUnit);
      result = ([self _modifyConverter]
                && (AudioOutputUnitStart (outputUnit) == noErr));
    }
  else
    result = YES;

  return result;
}

@end
