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


@protocol DefinitionWriter

-(void) beginWriting;
-(void) endWriting;

-(void) clearResults;
-(void) writeBigHeadline: (NSString*) aString;
-(void) writeHeadline: (NSString*) aString;
-(void) writeLine: (NSString*) aString;
-(void) writeString: (NSString*) aString
	       link: (id) aClickable;

@end

