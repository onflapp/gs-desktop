/*
   Project: Introspector

   Copyright (C) 2023 Free Software Foundation

   Created: 2023-05-28 22:07:30 +0200 by oflorian

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _INTROSPECTOR_H_
#define _INTROSPECTOR_H_

#import <Foundation/Foundation.h>


@interface Introspector : NSObject
{
   id _object;
}
- (void) printDescription;
- (void) printObject;
- (void) printMethods;

+ (void) printDescription:(id)val;
+ (void) printObject:(id)val;
+ (void) printMethods:(id)val;
@end

@interface NSObject (Introspect)
- (Introspector*) introspect;
@end

#endif // _INTROSPECTOR_H_

