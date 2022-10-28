/* XMMSInput.m - this file is part of Cynthiune
 *
 * Copyright (C) 2004 Wolfgang Sourdeau
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

#define _GNU_SOURCE 1
#import <string.h>
#import <Foundation/Foundation.h>

#import <dlfcn.h>
#import <pthread.h>
#import <unistd.h>

typedef void * gpointer;
typedef int gint;
typedef void * GList;
typedef char gchar;
typedef short gint16;

// #import <gtk/gtk.h>
#import <xmms/plugin.h>

#import <CynthiuneBundle.h>
#import <Format.h>
#import <utils.h>

#import "XMMSInput.h"

typedef enum _PlayAction
{
  doNothing = 0,
  readFormat = 1,
  readChunk = 2,
} PlayAction;

#define LOCALIZED(X) _b ([XMMSInput class], X)

// #define plugin_file "/home/wolfgang/.xmms/Plugins/libxmmsmad.so"
#define plugin_file "/home/wolfgang/.xmms/Plugins/xmms-musepack-1.00.so"

static void *dlHandler = NULL;
InputPlugin* (*get_iplugin_info)();

// static pthread_mutex_t instanceMutex;
// static NSLock *instanceLock;
static NSThread* mainThread;
static CXMMSInput *currentInstance = NULL;
static PlayAction playAction = doNothing;
static unsigned int bufferPlayingIteration = 0;
static BOOL reading = NO;
static char *titleFormat = NULL;

char *xmms_get_gentitle_format ()
{
  NSLog (@"xmms_get_gentitle_format (%s)", titleFormat);
  return titleFormat;
}

static void
threadCleanup ()
{
//   NSLog (@"thread %p exiting...", pthread_self());
  GSUnregisterCurrentThread ();
}

static void
registerThreadIfNeeded ()
{
  if (GSRegisterCurrentThread ())
    {
//       NSLog (@"new thread: %p", GSCurrentThread());
    }
}

static void
input_add_vis_pcm (int time, AFormat fmt, int nch, int length, void *ptr)
{
  registerThreadIfNeeded ();
//   NSLog (@"input_add_vis_pcm");
}

/* Fill in the stuff that is shown in the player window */
static void
input_set_info (char *title, int length, int rate, int freq, int nch)
{
  registerThreadIfNeeded ();
//   NSLog (@"input_set_info: %s, %d, %d, %d, %d",
//          title, length, rate, freq, nch);
}

static void
input_set_info_text (char *text)
{
  registerThreadIfNeeded ();
//   NSLog (@"input_set_info_text: %s", text);
}

static InputVisType
input_get_vis_type ()
{
  registerThreadIfNeeded ();
//   NSLog (@"input_get_vis_type");

  return INPUT_VIS_OFF;
}

int output_open_audio (AFormat fmt, int newRate, int newChannels)
{
  registerThreadIfNeeded ();

//   NSLog (@"open_audio: chans: %d, rate: %d", newChannels, newRate);
//   NSLog (@"thread id: %p", pthread_self());

  if (playAction == readFormat)
    {
      currentInstance->channels = newChannels;
      currentInstance->rate = newRate;
      playAction = doNothing;
    }

  return YES;
}

void output_init ()
{
  registerThreadIfNeeded ();
//   NSLog (@"init");
}

void output_about ()
{
  registerThreadIfNeeded ();
//   NSLog (@"about");
}

void output_configure ()
{
  registerThreadIfNeeded ();
//   NSLog (@"configure");
}

void output_write_audio (void *ptr, int length)
{
  registerThreadIfNeeded ();
  bufferPlayingIteration = 0;
//   NSLog (@"output_write_audio");
  memcpy (currentInstance->pluginBuffer, ptr, length);
  currentInstance->buffer_size = length;
  playAction = doNothing;
}

void output_close_audio (void)
{
  registerThreadIfNeeded ();
}

void output_flush (int time)
{
  registerThreadIfNeeded ();
//   NSLog (@"flush");
}

void output_pause (short paused)
{
  registerThreadIfNeeded ();
//   NSLog (@"pause");
}

int output_buffer_free (void)
{
  registerThreadIfNeeded ();
//   NSLog (@"output_buffer_free");

  while (playAction != readChunk)
    usleep (5000);

//   return BUF_LEN;
  return ((playAction == readChunk) ? BUF_LEN : 0);
}

int output_buffer_playing (void)
{
  BOOL answer;

  registerThreadIfNeeded ();
//   NSLog (@"output_buffer_playing");
//   return (playAction == readChunk);

  bufferPlayingIteration++;

  if (bufferPlayingIteration > 2 && playAction == readChunk)
    {
      NSLog (@"stopping?");
      currentInstance->buffer_size = 0;
      playAction = doNothing;
      answer = NO;
      GSUnregisterCurrentThread ();
    }
  else
    answer = YES;

  return answer;
//   return ((currentInstance->buffer_empty) ? NO : YES);
}

int output_output_time (void)
{
  registerThreadIfNeeded ();
//   NSLog (@"output_output_time");

  return 0;
}

int output_written_time (void)
{
  registerThreadIfNeeded ();
//   NSLog (@"output_written_time");

  return 0;
}

@implementation XMMSInput : NSObject

+ (void) load
{
  mainThread = GSCurrentThread();
//   instanceLock = [NSLock new];
  dlHandler = dlopen (plugin_file, RTLD_LAZY | RTLD_GLOBAL);
  if (!dlHandler)
    NSLog (@"error opening SO '%s':\n\t%s", plugin_file, dlerror());
  else
    {
      get_iplugin_info = dlsym (dlHandler, "get_iplugin_info");
      if (!get_iplugin_info)
        NSLog (@"%s: get_iplugin_info unresolved");
    }
}

+ (NSArray *) bundleClasses
{
  return [NSArray arrayWithObject: [self class]];
}

+ (NSArray *) acceptedFileExtensions
{
  return [NSArray arrayWithObjects: @"mpc", nil];
}

+ (BOOL) canTestFileHeaders
{
  return NO;
}

- (void) _createOutputPlugin
{
  outputPlugin = malloc (sizeof (OutputPlugin));
  outputPlugin->init = output_init;
  outputPlugin->about = output_about;
  outputPlugin->configure = output_configure;
  outputPlugin->open_audio = output_open_audio;
  outputPlugin->write_audio = output_write_audio;
  outputPlugin->close_audio = output_close_audio;
  outputPlugin->flush = output_flush;
  outputPlugin->pause = output_pause;
  outputPlugin->buffer_free = output_buffer_free;
  outputPlugin->buffer_playing = output_buffer_playing;
  outputPlugin->output_time = output_output_time;
  outputPlugin->written_time = output_written_time;
}

- (void) _createInputPlugin
{
  inputPlugin = get_iplugin_info ();
  inputPlugin->handle = dlHandler;
  inputPlugin->filename = plugin_file;
  inputPlugin->get_vis_type = input_get_vis_type;
  inputPlugin->add_vis_pcm = input_add_vis_pcm;
  inputPlugin->set_info = input_set_info;
  inputPlugin->set_info_text = input_set_info_text; 
  inputPlugin->output = outputPlugin;
}

+ (BOOL) streamTestOpen: (NSString *) fileName
{
  return NO;
}

- (XMMSInput *) init
{
  if ((self = [super init]))
    {
      filename = nil;
      channels = 0;
      rate = 0;
      formatKnown = NO;

      [self _createOutputPlugin];
      [self _createInputPlugin];
      inputPlugin->init ();
    }

  return self;
}

- (BOOL) streamOpen: (NSString *) fileName
{
  char *name;
  BOOL result;

  name = (char *) [fileName cString];

//   inputPlugin->output->open_audio (FMT_S16_LE,44100, 2);
  result = (inputPlugin->is_our_file (name) == 1);
  if (result)
    SET (filename, fileName);

  return result;
}

- (void) streamClose
{
  RELEASEIFSET (filename);
//   if (reading)
//     {
//       NSLog (@"streamClose: stopping");
//       [instanceLock unlock];
//       inputPlugin->stop();
//       reading = NO;
//     }
//   free (inputPlugin->output);
//   inputPlugin->stop ();
}

- (int) readNextChunk: (unsigned char *) buffer
             withSize: (unsigned int) bufferSize
{
  int realSize;
  char *bufPtr;

  if (!reading)
    {
      NSLog (@"starting");
//       [instanceLock lock];
      currentInstance = (CXMMSInput *) self;
      inputPlugin->play_file ((char *) [filename cString]);
      reading = YES;
      position = 0;
      playAction = readChunk;
    }

  while (playAction == readChunk);

  bufPtr = pluginBuffer + position;
  realSize = buffer_size - position;
  if (realSize > bufferSize)
    {
      realSize = bufferSize;
      position += realSize;
    }
  else
    position = 0;

  if (realSize > 0)
    {
      memcpy (buffer, bufPtr, realSize);
      playAction = readChunk;
    }
  else
    {
      NSLog (@"stopping");
//       [instanceLock unlock];
      inputPlugin->stop();
      reading = NO;
    }
//   buffer_empty = (position == 0);

  return realSize;
}

- (BOOL) isSeekable
{
  return YES;
}

- (void) seek: (unsigned int) aPos
{
  inputPlugin->seek (aPos);
}

- (void) _readFormat
{
  if (!formatKnown)
    {
//       [instanceLock lock];
      currentInstance = (CXMMSInput *) self;
      playAction = readFormat;
      inputPlugin->play_file ((char *) [filename cString]);
      while (playAction != doNothing);
      inputPlugin->stop ();
//       [instanceLock unlock];
      formatKnown = YES;
    }
}

- (unsigned int) readChannels
{
  [self _readFormat];
  NSLog (@"channels: %d", channels);
  return channels;
}

- (unsigned long) readRate
{
  [self _readFormat];
  NSLog (@"rate: %d", rate);
  return rate;
}

- (NSString *) _readInfo: (char *) infoFlag
{
  char *info;
  int length;

//   pthread_cleanup_push (threadCleanup, NULL);
//   [instanceLock lock];
  titleFormat = infoFlag;
  inputPlugin->get_song_info ((char *) [filename cString], &info, &length);
  if (!info)
    info = "";
//   [instanceLock unlock];
//   pthread_cleanup_pop (NO);

  NSLog (@"string for flag '%s' = '%s'", infoFlag, info);

  return [NSString stringWithCString: info];
}

- (NSString *) readTitle
{
  return [self _readInfo: "%t"];
}

- (NSString *) readGenre
{
  return [self _readInfo: "%g"];
}

- (NSString *) readArtist
{
  return [self _readInfo: "%p"];
}

- (NSString *) readAlbum
{
  return [self _readInfo: "%a"];
}

- (NSString *) readTrackNumber
{
  return [self _readInfo: "%n"];
}

- (unsigned int) readDuration
{
  char *title;
  int length;

  inputPlugin->get_song_info ((char *) [filename cString], &title, &length);

  return (length / 1000);
}

- (void) dealloc
{
  free (outputPlugin);

  [super dealloc];
}

@end
