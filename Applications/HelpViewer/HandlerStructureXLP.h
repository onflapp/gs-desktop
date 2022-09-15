/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003 Nicolas Roard (nicolas@roard.com)
                  2020 Riccardo Mottola (rm@gnu.org)

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

#ifndef __HANDLER_STRUCTURE_XLP_H__
#define __HANDLER_STRUCTURE_XLP_H__

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "HandlerStructure.h"
//#include "Parser.h"
#include "ModNSString.h"

#ifdef MACOSX
@interface HandlerStructureXLP : NSObject <HandlerStructure>
#else
#include <GNUstepBase/GSXML.h>
@interface HandlerStructureXLP : GSSAXHandler <HandlerStructure>
#endif
{
	NSMutableArray* pages;
	NSString* path;
	NSData* content;

	BOOL _document;
	NSMutableAttributedString* _currentContent;
	Section* _firstSection;
	Section* _currentSection;

	float current, max;
}
- (void) parse;
- (Section*) sections;
- (void) setPath: (NSString*) path;
@end

#endif
