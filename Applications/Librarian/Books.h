/*
   Project: Librarian

   Copyright (C) 2022 Free Software Foundation

   Author: Ondrej Florian,,,

   Created: 2022-10-22 14:04:38 +0200 by oflorian

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

#ifndef _BOOKS_H_
#define _BOOKS_H_

#import <Foundation/Foundation.h>

@interface Books : NSObject
{
  NSMutableDictionary* config;
  NSInteger status;
  NSString* baseDir;

  NSMutableData* buff;
  NSFileHandle* fh;
  NSTask* task;

  NSMutableArray* results;
}

- (id) init;
- (void) openFile:(NSString*) file;
- (void) saveFile:(NSString*) file;
- (void) search:(NSString*) qry;
- (void) list;
- (void) rebuild;

- (NSArray*) searchResults;
- (NSArray*) paths;
- (void) setPaths:(NSArray*) paths;

@end

#endif // _BOOKS_H_

