/*
 * PQFontFamily.h - Font Manager
 *
 * Class which represents a font family.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: Modified BSD license (see file COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PQFontFamily : NSObject
{
	NSString *name;
	NSArray *members;
}

/* Designated initializer */
- (id) initWithName: (NSString *)aName members: (NSArray *)someMembers;

- (void) setName: (NSString *)aName;
- (NSString *) name;

- (void) setMembers: (NSArray *)someMembers;
- (NSArray *) members;

- (BOOL) hasMultipleMembers;

- (NSComparisonResult) caseInsensitiveCompare: (PQFontFamily *)aFontFamily;

@end
