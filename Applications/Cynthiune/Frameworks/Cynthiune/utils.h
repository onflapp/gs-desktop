/* utils.h - this file is part of Cynthiune
 *
 * Copyright (C) 2003 Wolfgang Sourdeau
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

#ifndef UTILS_H
#define UTILS_H

#import <Foundation/NSException.h>
#import <Foundation/NSGeometry.h>

@class NSArray;

#define SET(X,Y) ASSIGN(X,Y)
#define RELEASEIFSET(X) RELEASE(X)

#define RETURNSTRING(X) return ((X) ? [NSString stringWithString: X] : @"")

#ifdef __MACOSX__

#define RELEASE(object)         [(object) release]

#define ASSIGN(object,value)    ({\
  id __object = object; \
  object = [(value) retain]; \
  [__object release]; \
})


#define NSStandardLibraryPaths() \
    NSSearchPathForDirectoriesInDomains (NSAllLibrariesDirectory, \
                                         NSAllDomainsMask, YES)

#endif /* __MACOSX__ */

#if defined (__WIN32__) || defined (__MACOSX__)

char *strndup (const char *string, unsigned int len);

#endif /* __WIN32__ || __MACOSX__ */

#define obsoleteMethod() \
    [[NSException exceptionWithName: @"Obsolete method" \
                  reason: ([NSString stringWithFormat: @"'%s'" \
                            @" (%s, %d) is an obsolete method.", \
                            sel_getName (_cmd), __FILE__, __LINE__]) \
                  userInfo: nil] raise]

#define unimplementedMethod() \
    [[NSException exceptionWithName: @"Unimplemented method" \
                  reason: ([NSString stringWithFormat: @"'%s'" \
                            @" (%s, %d) unimplemented.", \
                            sel_getName (_cmd), __FILE__, __LINE__]) \
                  userInfo: nil] raise]

#define raiseException(t,r) \
    [[NSException exceptionWithName: (t) \
                  reason: ([NSString stringWithFormat: @"%@ in '%s'" \
                            @" (%s:%d).", \
                            (r), sel_getName (_cmd), __FILE__, __LINE__]) \
                  userInfo: nil] raise]

#define indexOutOfBoundsException(i,m) \
    raiseException (@"Index out of bounds", \
                    ([NSString stringWithFormat: \
                     @"index '%u' too high (max = %d)", i, m]))

BOOL fileIsAReadableDirectory (NSString *fileName);
BOOL fileIsAcceptable (NSString *fileName);

void logRect (NSRect *rect);
NSString *_b (Class bundleClass, NSString *string);

void invertBytesInBuffer (char *buffer, int length);

void convert8to16 (unsigned char *inBuffer,
                   unsigned char *outBuffer,
                   unsigned int size);
NSComparisonResult reverseComparisonResult (NSComparisonResult result);

NSString *makeTitleFromFilename (NSString *fileName);

#endif /* UTILS_H */
