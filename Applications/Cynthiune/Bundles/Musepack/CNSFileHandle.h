/* CNSFileHandle.h - this file is part of Cynthiune
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

#ifndef CNSFILEHANDLE_H
#define CNSFILEHANDLE_H

#ifdef MUSEPACK_API_126
#include <mpcdec/config_types.h>
#else
#import <mpc/reader.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#ifdef MUSEPACK_API_126
void CNSFileHandleRetain (void *fileHandle);
void CNSFileHandleRelease (void *fileHandle);

int CNSFileHandleRead (void *fileHandle, void *ptr, int size);
int CNSFileHandleTell (void *fileHandle);
mpc_bool_t CNSFileHandleCanSeek (void *fileHandle);
mpc_bool_t CNSFileHandleSeek (void *fileHandle, int offset);
int CNSFileHandleGetSize (void *fileHandle);
#else
int CNSFileHandleRead (mpc_reader *fileHandle, void *ptr, int size);
int CNSFileHandleTell (mpc_reader *fileHandle);
mpc_bool_t CNSFileHandleCanSeek (mpc_reader *fileHandle);
mpc_bool_t CNSFileHandleSeek (mpc_reader *fileHandle, int offset);
int CNSFileHandleGetSize (mpc_reader *fileHandle);
#endif

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* CNSFILEHANDLE_H */
