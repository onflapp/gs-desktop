/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003      Nicolas Roard (nicolas@roard.com)
                  2020-2021 Riccardo Mottola <rm@gnu.org>

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

#ifndef __LEGEND_H__
#define __LEGEND_H__

#import <Foundation/Foundation.h>
#import "GNUstep.h"

@interface Legend : NSObject 
{
    NSMutableAttributedString* legend;
    NSPoint point;
    CGFloat height;
    BOOL rightPos;
}
+ (id) legendWithString: (NSMutableAttributedString*) str andPoint: (NSPoint) p;
- (id) initWithString: (NSMutableAttributedString*) str andPoint: (NSPoint) p;
- (NSMutableAttributedString*) legend;
- (NSPoint) point;
- (CGFloat) height;
- (void) setHeight: (CGFloat) h;
- (void) setRightPos;
- (void) setPoint: (NSPoint) p;
- (BOOL) isRightPos;
- (NSComparisonResult) compareWith: (id)sender;
@end

#endif
