/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#ifndef _H_COUNTINGREF
#define _H_COUNTINGREF

#include <Foundation/NSObject.h>

@class CountingRef;

/**
 * Delegate for CountingRef's.
 */
@protocol CountingRefDelegate
- (void) freePointerForReference: (CountingRef*)aReference;
@end


/**
 * A ref-counting wrapper for pointers. When the
 * get's the dealloc message, the associated pointer
 * will be free'd using the CountingRef's delegate.
 * 
 * A CountingRef retains it's delegate and sends it
 * a release message when the CountingRef receives a
 * dealloc message.
 */
@interface CountingRef : NSObject
{
   void*                    pointer;
   id<CountingRefDelegate>  delegate;
}

- (id) initWithPointer: (void*)aPointer
              delegate: (id<CountingRefDelegate>)aDelegate;

- (void*) pointer;
- (BOOL) isNULL;

@end
#endif
