/*
 Project: FTP

 Copyright (C) 2005-2016 Riccardo Mottola

 Author: Riccardo Mottola

 Created: 2005-04-18

 Single element of a file listing

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
 Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

       
#import <Foundation/Foundation.h>



@interface FileElement : NSObject
{
  NSString           *fileName;
  NSString           *filePath;
  NSString           *linkTargetName;
  BOOL               isDir;
  BOOL               isLink;
  unsigned long long size;
  NSDate             *modifDate;
}

- (id)initWithPath:(NSString *)path andAttributes:(NSDictionary *)attribs;
- (id)initWithLsLine :(char *)line;
- (NSDictionary *)attributes;
- (NSString *)name;
- (void)setName: (NSString *)n;
- (NSString *)path;
- (void)setPath: (NSString *)p;
- (NSString *)linkTargetName;
- (BOOL)isDir;
- (BOOL)isLink;
- (void)setIsLink:(BOOL)flag;
- (unsigned long long)size;

@end
