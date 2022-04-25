/*
 * PQMain.h - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: 3-Clause license (see file COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "PQFontManager.h"

int main(int argc, char *argv[])
{
	[PQFontManager setFontManagerFactory: [PQFontManager class]];
	
	return NSApplicationMain(argc, (const char **) argv);
}
