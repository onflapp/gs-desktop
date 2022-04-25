/*
 * PQFontFamily.m - Font Manager
 *
 * Class which represents a font family.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: Modified BSD license (see file COPYING)
 */

#import "PQFontFamily.h"
#import "PQCompat.h"

@implementation PQFontFamily

- (id) init
{
	return [self initWithName: @"" members: [NSArray arrayWithObject:@""]];
}

- (id) initWithName: (NSString *)aName members: (NSArray *)someMembers
{
	[super init];

	ASSIGN(name, aName);
	ASSIGN(members, someMembers);

	return self;
}

- (void) setName: (NSString *)aName
{
	ASSIGN(name, aName);
}

- (NSString *) name
{
	return name;
}

- (void) setMembers: (NSArray *)someMembers
{
	ASSIGN(members, someMembers);
}

- (NSArray *) members
{
	return members;
}

- (BOOL) hasMultipleMembers
{
	if (2 > [members count])
	{
		return NO;
	}
	/* else */
	return YES;
}

- (NSComparisonResult) caseInsensitiveCompare: (PQFontFamily *)aFontFamily
{
	return [[self name] caseInsensitiveCompare:[aFontFamily name]];
}

- (void) dealloc
{
	RELEASE(name);
	RELEASE(members);
	
	[super dealloc];
}

@end
