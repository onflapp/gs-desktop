/*
 * PQFontManager.m - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: December 16, 2007
 * License: 3-Clause BSD license (see file COPYING)
 */


#import "PQFontManager.h"
#import "PQCompat.h"


@implementation PQFontManager

- (NSArray *) makeAvailableFontAtPath: (NSString *)path
{
	// TEMP:
	//return [NSArray arrayWithObjects:
	//	[NSArray arrayWithObjects: @"Helvetica", "Regular", 5, 0, NO, nil], nil];
	return nil;
}

- (BOOL) makeUnavailableFont: (NSString *)font
{
	return NO;
}

- (NSString *) pathToFont: (NSString *)font
{
	//return @"/usr/home/isaiah/Desktop/Ezra SIL.ttf"; //TEMP
	return nil;
}

@end
