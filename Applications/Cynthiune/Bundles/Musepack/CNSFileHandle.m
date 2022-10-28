/* CNSFileHandle.m - this file is part of Cynthiune
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

#import <Foundation/NSData.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSString.h>

#import "CNSFileHandle.h"

#ifdef MUSEPACK_API_126
void
CNSFileHandleRetain (void *fileHandle)
{
  [(NSFileHandle *) fileHandle retain];
}

void
CNSFileHandleRelease (void *fileHandle)
{
  [(NSFileHandle *) fileHandle release];
}

int
CNSFileHandleRead (void *fileHandle, void *ptr, int size)
{
  NSData *data;

  data = [(NSFileHandle *) fileHandle readDataOfLength: size];
  [data getBytes: ptr];

  return [data length];
}

int
CNSFileHandleTell (void *fileHandle)
{
  return [(NSFileHandle *) fileHandle offsetInFile];
}

mpc_bool_t
CNSFileHandleCanSeek (void *fileHandle)
{
  return YES;
}

mpc_bool_t
CNSFileHandleSeek (void *fileHandle, int offset)
{
  [(NSFileHandle *) fileHandle seekToFileOffset: (long long) offset];

  return YES;
}

int
CNSFileHandleGetSize (void *fileHandle)
{
  int size, where;

  where = [(NSFileHandle *) fileHandle offsetInFile];
  size = [(NSFileHandle *) fileHandle seekToEndOfFile];
  [(NSFileHandle *) fileHandle seekToFileOffset: (long long) where];

  return size;
}

# else
int
CNSFileHandleRead (mpc_reader *fileHandle, void *ptr, int size)
{
  NSData *data;

  data = [(NSFileHandle *) fileHandle->data readDataOfLength: size];
  [data getBytes: ptr];

  return [data length];
}

int
CNSFileHandleTell (mpc_reader *fileHandle)
{
  return [(NSFileHandle *) fileHandle->data offsetInFile];
}

mpc_bool_t
CNSFileHandleCanSeek (mpc_reader *fileHandle)
{
  return YES;
}

mpc_bool_t
CNSFileHandleSeek (mpc_reader *fileHandle, int offset)
{
  [(NSFileHandle *) fileHandle->data seekToFileOffset: (long long) offset];

  return YES;
}

int
CNSFileHandleGetSize (mpc_reader *fileHandle)
{
  int size, where;

  where = [(NSFileHandle *) fileHandle->data offsetInFile];
  size = [(NSFileHandle *) fileHandle->data seekToEndOfFile];
  [(NSFileHandle *) fileHandle->data seekToFileOffset: (long long) where];

  return size;
}

#endif
