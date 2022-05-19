//
// Constants.h
//
//  Ludovic Marcotte <ludovic@Sophos.ca>
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#import <Foundation/Foundation.h>

#ifndef GNUSTEP_BASE_VERSION
#define RETAIN(object)          [object retain]
#define RELEASE(object)         [object release]
#define AUTORELEASE(object)     [object autorelease]
#define TEST_RELEASE(object)    ({ if (object) [object release]; })
#define ASSIGN(object,value)    ({\
id __value = (id)(value); \
id __object = (id)(object); \
if (__value != __object) \
  { \
    if (__value != nil) \
      { \
        [__value retain]; \
      } \
    object = __value; \
    if (__object != nil) \
      { \
        [__object release]; \
      } \
  } \
})

#define DESTROY(object) ({ \
  if (object) \
    { \
      id __o = object; \
      object = nil; \
      [__o release]; \
    } \
})

#define CREATE_AUTORELEASE_POOL(X)      \
  NSAutoreleasePool *(X) = [NSAutoreleasePool new]

#define NSLocalizedString(key, comment) \
  [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

#define _(X) NSLocalizedString (X, @"")

#endif

#define BLUE   1
#define GRAY   2
#define GREEN  3  
#define PURPLE 4
#define YELLOW 5

#define TOP_LEFT     1
#define TOP_RIGHT    2
#define CENTER       3
#define BOTTOM_LEFT  4
#define BOTTOM_RIGHT 5

#define NO_TITLE           1
#define FIRST_LINE_OF_NOTE 2
#define CUSTOM             3

#define DEFAULT_NOTE_WIDTH  200
#define DEFAULT_NOTE_HEIGHT 100

// Contants for the UI
extern const int TextFieldHeight;
extern const int ButtonHeight;


NSString *AfficheUserLibraryPath();
