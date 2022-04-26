/*
**  CWLocalFolder+maildir.h
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

#ifndef _Pantomime_H_CWLocalFolder_maildir
#define _Pantomime_H_CWLocalFolder_maildir

#include <Pantomime/CWLocalFolder.h>

@interface CWLocalFolder (maildir)

- (void) expunge_maildir;

- (void) parse_maildir: (NSString *) theDirectory  all: (BOOL) theBOOL;

@end

#endif // _Pantomime_H_CWLocalFolder_maildir
