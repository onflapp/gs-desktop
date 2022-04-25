/*
 * PQCompat.h - Font Manager
 *
 * Mac OS X compatibility.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: Modified BSD license (see file COPYING)
 */

#ifndef GNUSTEP

#define AUTORELEASE(object) [object autorelease]
#define RELEASE(object) [object release]
#define RETAIN(object) [object retain]
#define ASSIGN(object, value)	({\
id __value = (id)(value); \
id __object = (id)(object); \
if (__value != __object) { \
   if (__value != nil) \
      [__value retain]; \
   object = __value; \
   if (__object != nil) \
      [__object release]; \
}})

#endif
