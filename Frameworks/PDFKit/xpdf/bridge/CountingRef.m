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

#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include "CountingRef.h"

/**
 * Non-Public methods.
 */
@interface CountingRef(Private)
@end


@implementation CountingRef

- (id) initWithPointer: (void*)aPointer
              delegate: (id<CountingRefDelegate>)aDelegate
{
   NSAssert(aPointer != NULL, @"reference's pointer is NULL");
   NSAssert(aDelegate, @"no delegate for reference");
   
   if ((self = [super init]))
   {
      pointer  = aPointer;
      delegate = RETAIN((id)aDelegate);
   }

   return self;
}


- (void) dealloc
{
   [delegate freePointerForReference: self];
   pointer = NULL;
   RELEASE((id)delegate);

   [super dealloc];
}


- (void*) pointer
{
   return pointer;
}


- (BOOL) isNULL
{
   return (pointer == NULL ? YES : NO);
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation CountingRef (Private)
@end
