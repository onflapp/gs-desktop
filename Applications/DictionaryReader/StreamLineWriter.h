/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef _STREAMLINEWRITER_H_
#define _STREAMLINEWRITER_H_

#import <Foundation/Foundation.h>


@interface StreamLineWriter : NSObject
{
  // Instance variables
  NSOutputStream* outputStream;
}

// Class methods



// Instance methods

-(id)init;
-(id)initWithOutputStream: (NSOutputStream*) anOutputStream;

-(void)dealloc;

-(BOOL)writeLine: (NSString*) aString;

@end

#endif // _STREAMLINEWRITER_H_
