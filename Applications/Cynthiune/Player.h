/* Player.h - this file is part of Cynthiune
 *
 * Copyright (C) 2002-2004  Wolfgang Sourdeau
 *               2012 The Free Software Foundation
 *
 * Author: Wolfgang Sourdeau <wolfgang@contre.com>
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

#ifndef Player_H
#define Player_H

#import <Foundation/NSObject.h>

#import <Cynthiune/Format.h>

@class NSLock;
@class NSNotification;
@class NSString;

@protocol Output;

#define GOOM_BUFFER_SIZE 2048

@interface Player : NSObject
{
  id delegate;

  NSObject <Output> *output;
  BOOL outputIsThreaded;

  NSLock *streamLock;
  NSObject <Format> *stream;

  NSMutableArray *streamsToClose;
  BOOL paused;
  BOOL playing;
  BOOL awaitingNewStream;
  BOOL closingThread;

  unsigned int channels;
  unsigned long rate;
  Endianness endianness;

  long totalBytes;

#ifdef GOOM
  BOOL feedGoom;
  PluginInfo *goom;
  short goomBuffer[2][512];
  unsigned int bufferedSize;
//   char *goomBufferPtr;
//   NSLock *lock;
#endif
}

- (id) init;

- (void) setDelegate: (id) anObject;
- (id) delegate;

- (void) setStream: (NSObject <Format> *) newStream;

- (int) timer;

- (BOOL) playing;

- (void) play;
- (void) stop;

- (void) setPaused: (BOOL) aBool;
- (BOOL) paused;

- (void) seek: (unsigned int) aPos;

#ifdef GOOM
- (void) setGoom: (PluginInfo *) goomPI;
#endif

@end

@interface NSObject (PlayerDelegate)

- (void) playerPlaying: (NSNotification*) aNotification;
- (void) playerStopped: (NSNotification*) aNotification;
- (void) playerPaused: (NSNotification*) aNotification;
- (void) playerResumed: (NSNotification*) aNotification;
- (void) playerSongEnded: (NSNotification*) aNotification;

@end

#endif /* Player_H */
