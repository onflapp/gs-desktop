/*
**  CWContainer.h
**
**  Copyright (c) 2002-2007 Ludovic Marcotte
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
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

#ifndef _Pantomime_H_CWContainer
#define _Pantomime_H_CWContainer

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSObject.h>

@class CWMessage;

/*!
  @class CWContainer
  @discussion This class is a simple placeholder used when doing message threading.
              A container is composed of a CWMessage instance which might be nil, a parent,
	      child and next CWContainer instances. For a full description of the implemented
	      algorithm, see <a href="http://www.jwz.org/doc/threading.html">message threading</a>.
	      Instance variables of this class must be accessed directly (ie., without
	      an accessor) - for performance reasons.
*/
@interface CWContainer : NSObject
{
  @public
    CWContainer *parent, *child, *next;
    CWMessage *message;
}

/*!
  @method setParent:
  @discussion This method is used to set the parent CWContainer of the receiver.
  @param theParent The parent CWContainer, which might be nil if the receiver
                   is part of the root set.
*/
- (void) setParent: (CWContainer *) theParent;

/*!
  @method setChild:
  @discussion This method is used to add the specified child to the list
              of children.
  @param theChild The child to add which can be nil to remove the first child.
*/
- (void) setChild: (CWContainer *) theChild;

/*!
  @method childAtIndex:
  @discussion This method is used to get the child at the specified index.
  @param theIndex The index of the child, which is 0 based.
  @result The CWContainer instance.
*/
- (CWContainer *) childAtIndex: (unsigned int) theIndex;

/*!
  @method count
  @discussion This method is used to obtain the number of children of
              the receiver.
  @result The number of children.
*/
- (unsigned int) count;

/*!
  @method setNext:
  @discussion This method is used to set the next element in
              sibling list.
  @param theNext The next element, or nil if there's none.
*/
- (void) setNext: (CWContainer *) theNext;

/*!
  @method childrenEnumerator
  @discussion This method is used to obtain all children of the receiver.
  @result All children, as a NSEnumerator instance.
*/
- (NSEnumerator *) childrenEnumerator;

@end

#endif // _Pantomime_H_CWContainer
