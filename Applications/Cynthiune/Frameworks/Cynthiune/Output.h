/* Output.h - this file is part of Cynthiune
 *
 * Copyright (C) 2004 Wolfgang Sourdeau
 *               2012 The Free Software Foundation
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
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

#ifndef OUTPUT_H
#define OUTPUT_H

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSObject.h>

#import <Cynthiune/Format.h>

#define DEFAULT_BUFFER_SIZE 8192

@class NSData;

@protocol Output <NSObject>

+ (BOOL) isThreaded;

- (void) setParentPlayer: (id) aPlayer;

- (BOOL) openDevice;
- (void) closeDevice;

- (BOOL) prepareDeviceWithChannels: (unsigned int) numberOfChannels
                           andRate: (unsigned long) sampleRate
		    withEndianness: (Endianness) e;

@end

/* an informal protocol for non-threaded output classes */
@interface NSObject (UnthreadedOutput)

- (void) playChunk: (NSData *) chunk;

@end

/* an informal protocol for threaded output classes */
@interface NSObject (ThreadedOutput)

- (BOOL) startThread;
- (void) stopThread;

@end

@interface NSObject (ParentPlayer)

- (int) readNextChunk: (unsigned char *) buffer
             withSize: (unsigned int) bufferSize;
- (void) chunkFinishedPlaying;

@end

#endif /* OUTPUT_H */
