/*
 * PQFontManager.h - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: December 16, 2007
 * License: 3-Clause BSD license (see file COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PQFontManager : NSFontManager
{
}

- (NSArray *) makeAvailableFontAtPath: (NSString *)path;
- (BOOL) makeUnavailableFont: (NSString *)font;
- (NSString *) pathToFont: (NSString *)font;

@end
