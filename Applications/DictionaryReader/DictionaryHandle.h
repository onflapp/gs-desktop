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

#ifndef _DICTIONARY_H_
#define _DICTIONARY_H_

#import <Foundation/Foundation.h>
#import "DefinitionWriter.h"

/**
 * The Dictionary handle protocol.
 */
@interface NSObject (DictionaryHandle)


// MAIN FUNCTIONALITY

/**
 * Gives away the client identification string to the dictionary handle.
 */
-(void) sendClientString: (NSString*) clientName;

/**
 * Lets the dictionary handle show handle information in the main window.
 */
-(void) handleDescription;

/**
 * Lets the dictionary handle describe a specific database.
 */
-(void) descriptionForDatabase: (NSString*) aDatabase;

/**
 * Lets the dictionary handle print all available definitions
 * for aWord in the main window.
 */
-(void) definitionFor: (NSString*) aWord;

/**
 * Lets the dictionary handle print the defintion for aWord
 * in a specific dictionary. (Note: The dictionary handle may
 * represent multiple dictionaries.)
 */
-(void) definitionFor: (NSString*) aWord
	 inDictionary: (NSString*) aDict;


// SETTING UP THE CONNECTION

/**
 * Opens the dictionary handle. Needs to be done before asking for
 * definitions. Implementing classes may open network connections
 * here.
 */
-(void)open;

/**
 * Closes the dictionary handle. Implementing classes may close
 * network connections here.
 */
-(void)close;

/**
 * Provides the dictionary handle with a definition writer to write
 * its word definitions to.
 */
-(void) setDefinitionWriter: (id<DefinitionWriter>) aDefinitionWriter;


/**
 * Returns a NSDictionary instance that shortly describes the dictionary so
 * that it can be restored again using the initFromPropertyList: method. The
 * key @"class" must be present and the corresponding object must be the class
 * name of the DictionaryHandle class.
 */
-(NSDictionary*) shortPropertyList;

/**
 * Initialises the DictionaryHandle from the property list aPropertyList.
 */
-(id) initFromPropertyList: (NSDictionary*) aPropertyList;

/**
 * Returns YES if and only if the dictionary is active
 */
-(BOOL) isActive;

/**
 * Sets if the dictionary is active
 */
-(void) setActive: (BOOL) isActive;
@end




/**
 * The dictionary handle class
 */
@interface DictionaryHandle : NSObject
{
    BOOL _active;
}

+(id) dictionaryFromPropertyList: (NSDictionary*) aPropertyList;
-(id) initFromPropertyList: (NSDictionary*) aPropertyList;
-(NSDictionary*) shortPropertyList;
-(BOOL) isActive;
-(void) setActive: (BOOL) isActive;
@end

#endif // _DICTIONARY_H_
