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

#ifndef __HANDLER_STRUCTURE_H__
#define __HANDLER_STRUCTURE_H__

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "Section.h"

@class Section;

@protocol HandlerStructure
- (Section*) sections;
- (void) setPath: (NSString*) path;
- (void) setTextView: (NSTextView*) view;
- (void) parse;
- (id) initWithSection: (Section*) section;
@end

#endif
