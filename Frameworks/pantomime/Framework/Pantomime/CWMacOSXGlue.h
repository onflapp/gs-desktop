/*
**  CWMacOSXGlue.h
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

#ifndef _Pantomime_H_CWMacOSXGlue
#define _Pantomime_H_CWMacOSXGlue

#import <Foundation/NSObject.h>

/*!
  @category NSObject (PantomimeMacOSXGlue)
  @discussion This category is used to define a simple method in to raise
              excections if a non-implemented method is being called on
	      an abstract class instance. You should never use this
	      method directly.
*/
@interface NSObject (PantomimeMacOSXGlue)

/*!
  @method subclassResponsibility
  @discussion This method will raise a generic exception whenever
              it is invoked.
  @result This method always returns nil.
*/
- (id) subclassResponsibility: (SEL) theSel;

@end

#endif // _Pantomime_H_CWMacOSXGlue
