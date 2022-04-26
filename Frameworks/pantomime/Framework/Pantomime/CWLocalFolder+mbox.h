/*
**  CWLocalFolder+mbox.h
**
**  Copyright (c) 2004-2007 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWLocalFolder_mbox
#define _Pantomime_H_CWLocalFolder_mbox

#include <Pantomime/CWLocalFolder.h>

@interface CWLocalFolder (mbox)

- (void) close_mbox;

- (void) expunge_mbox;

- (FILE *) open_mbox;

- (void) parse_mbox: (NSString *) theFile 
             stream: (FILE *) theStream 
              flags: (CWFlags *) theFlags
                all: (BOOL) theBOOL;

- (NSData *) unfoldLinesStartingWith: (char *) firstLine
                          fileStream: (FILE *) theStream;

/*!
  @method numberOfMessagesFromData:
  @discussion This method is used to get the number of RFC2822
              messages from the supplied data. The returned value
	      will always be at least 1 unless the supplied data
	      is nil or its length is 0.
  @param theData The data holding RFC2822 messages
  @result The number of messages, 0 otherwise.
*/
+ (NSUInteger) numberOfMessagesFromData: (NSData *) theData;

- (NSArray *) messagesFromMailSpoolFile;

@end

#endif // _Pantomime_H_CWLocalFolder_mbox
