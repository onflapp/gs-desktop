/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003 Nicolas Roard (nicolas@roard.com)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the
    Free Software Foundation, Inc.  
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
*/

#ifndef __PAGE_H__
#define __PAGE_H__

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include "GNUstep.h"
#include "Section.h"

@interface Part : NSObject
{
    NSMutableArray* sections;
    NSMutableArray* subviews;
    NSString* title;
    NSMutableAttributedString* text;
} 
- (id) init;
- (void) dealloc;
- (NSString*) title;
- (void) setTitle: (NSString*) title;
- (NSMutableAttributedString*) text;
- (void) addSection: (Section*) section;
- (void) addSubview: (NSView*) view;
- (void) addSubviewsToView: (NSView*) view;
- (void) removeSubviews;
- (NSAttributedString*) getPage;
- (NSArray*) sections;
@end

#endif
