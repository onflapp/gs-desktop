/*
**  CWMacOSXGlue.m
**
**  Copyright (c) 2001-2004 Ludovic Marcotte, Stephane Corthesy
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Stephane Corthesy <stephane@sente.ch>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "CWMacOSXGlue.h"

#import <Foundation/NSException.h>
#import <Foundation/NSString.h>

//
//
//
@implementation NSObject(PantomimeMacOSXGlue)

- (id) subclassResponsibility: (SEL) theSel
{
  [NSException raise: NSGenericException
	       format: @"subclass %s should override %s", object_getClassName(self),
	       sel_getName(theSel)];
  return nil;
}

@end
