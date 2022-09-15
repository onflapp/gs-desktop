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

#ifndef __TEXT_FORMATTER_XLP_H__
#define __TEXT_FORMATTER_XLP_H__

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "TextFormatter.h"
#include "Section.h"
#include "BRCell.h"
#include "FigureCell.h"
#include "NoteCell.h"
//#include "Parser.h"

#ifdef MACOSX
@interface TextFormatterXLP : NSObject <TextFormatter>
#else
#include <GNUstepBase/GSXML.h>
@interface TextFormatterXLP : GSSAXHandler <TextFormatter>
#endif
{
	NSTextView* textView;
	NSMutableArray* pages;
	NSString* path;
	NSData* content;

	BOOL _document;
	NSMutableAttributedString* _currentContent;
	Section* _firstSection;
	Section* _currentSection;

	BOOL _italic, _bold, _smallcaps;
	BOOL _code, _url, _pre;

	BOOL _legendfig;
	BOOL _ol, _ul, _li;

	BOOL _note,_listing,_caution,_information;

	int _listLevel;

	NSMutableArray* legends;
	NSMutableArray* _listCounter;
	NSString* imgSource;
	NSMutableAttributedString* _string;
	NSMutableAttributedString* _preString;
	int legendX;
	int legendY;

	NSBundle* Bundle;
}
- (void) addImage: (NSString*) pathname;
- (void) addImage: (NSImage*) img onString: (NSMutableAttributedString*) as;
- (void) addLegendFig: (NSString*) imgpath withLegends: (NSArray*) plegends;
- (void) addNote: (NSMutableAttributedString*) string withImage: (NSImage*) img withColor: (NSColor*) color;
- (void) addRuleTo: (NSMutableAttributedString*) string withHeight: (CGFloat) height;
@end

#endif
