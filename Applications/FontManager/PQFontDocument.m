/*
 * PQFontDocument.m - Font Manager
 *
 * Class which represents a font document.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 11/30/07
 * License: 3-Clause BSD license (see file COPYING)
 */

#import "PQFontDocument.h"
#import "PQFontManager.h"
#import "PQCompat.h"

@implementation PQFontDocument

- (id) init
{
	[super init];
	
	fontInfo = [[NSMutableDictionary alloc] init];
	fontInfoIndex = [[NSMutableArray alloc] init];
	fontName = [[NSString alloc] initWithString: @"Bitstream Vera Sans"];
	
	return self;
}

- (void) awakeFromNib
{
	/* Values that should be set in FontDocument.gorm, but aren't */
	NSTableColumn *keyColumn = [[infoView tableColumns] objectAtIndex: 0];
	NSTableColumn *valueColumn = [[infoView tableColumns] objectAtIndex: 1];
	[[keyColumn headerCell] setTitle: @"Key"];
	[[valueColumn headerCell] setTitle: @"Value"];
	[keyColumn setEditable: NO];
	[valueColumn setEditable: NO];
	[keyColumn setWidth: 128.0];
	[infoView sizeLastColumnToFit];
	
	// FIXME:
	[facePopUpButton setEnabled: NO];
	[facePopUpButton setHidden: YES];
	[installAllButton setEnabled: NO];
	[installAllButton setHidden: YES];
	
	[sampleController setFonts: [NSArray arrayWithObject: fontName]];
	[charactersController setFont: fontName];
}

- (void) dealloc
{
	RELEASE(fontName);
	RELEASE(fontInfo);
	RELEASE(fontInfoIndex);
	
	[super dealloc];
}

- (void) setFont: (NSString *)newFont
{
	ASSIGN(fontName, newFont);
	
	[sampleController setFonts: [NSArray arrayWithObject: fontName]];
	[charactersController setFont: fontName];
}

- (void) selectFace: (id)sender
{
}

- (void) installAll: (id)sender
{
	if ([[installButton title] isEqualToString:@"Install All"])
	{
		[installButton setTitle:@"Uninstall All"];
	}
	else
	{
		[installButton setTitle:@"Install All"];
	}
}

- (void) install: (id)sender
{
	if ([[installButton title] isEqualToString:@"Install"])
	{
		[installButton setTitle:@"Uninstall"];
	}
	else
	{
		[installButton setTitle:@"Install"];
	}
}

- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
	return [fontInfoIndex count];
}

- (id) tableView: (NSTableView *)aTableView
	objectValueForTableColumn: (NSTableColumn *)aTableColumn
	           row: (int)rowIndex
{
	if ([[[aTableColumn headerCell] title] isEqualToString: @"Key"])
	{
		return [fontInfoIndex objectAtIndex: rowIndex];
	}
	else
	{
		return [fontInfo objectForKey: [fontInfoIndex objectAtIndex: rowIndex]];
	}
	
	return nil;
}

- (NSString *) windowNibName
{
	return @"FontDocument";
}

- (NSString *)displayName
{
	return [[NSFont fontWithName: fontName size: 0] displayName];
}

- (BOOL) readFromFile: (NSString *)fileName ofType: (NSString *)docType
{

#ifdef GNUSTEP
	/*ASSIGN(fontName,
		[[[(PQFontManager *)[PQFontManager sharedFontManager] makeAvailableFontAtPath: fileName]
		objectAtIndex: 0] objectAtIndex: 0]);*/
	//ASSIGN(fontName, @"Luxi Sans Roman"); //TEMP
	
	fontName = @"Bitstream Vera Sans";
#else
	// In theory this code should make the font available, I'm not sure if it
	// works though. Any way, after it's activated I'm not sure how to find out
	// it's postscript name.
	
	//FSRef iFile;
	//char *path = [fileName UTF8String];
	//
	//if (! FSPathMakeRef((UInt8 *)path, &iFile, NO))
	//{
	//	return NO;
	//}
	//
	//if (ATSFontActivateFromFileSpecification(&iFile, kATSFontContextLocal,
	//	kATSFontFormatUnspecified, NULL, kATSOptionFlagsDefault, &fontContainer) !=
	//	kATSIterationCompleted)
	//{
	//	return NO;
	//}
	
	// Just so it runs we'll use Helvetica instead.
	ASSIGN(fontName, @"Helvetica"); //TEMP
#endif
	
	if (fontName == nil)
	{
		return NO;
	}
	
	NSFont *font = [NSFont fontWithName: fontName size: 0];
	
	[fontInfoIndex addObject:@"Name"];
	[fontInfo setObject:[font displayName] forKey:@"Name"];
	[fontInfoIndex addObject:@"Family Name"];
	[fontInfo setObject:[font familyName] forKey:@"Family Name"];
	[fontInfoIndex addObject:@"Postscript Name"];
	[fontInfo setObject:[font fontName] forKey:@"Postscript Name"];
	[fontInfoIndex addObject:@"File"];
	[fontInfo setObject:fileName forKey:@"File"];
	
	return YES;
}

- (void) close
{
	// [[GSFontEnumerator sharedEnumerator] makeFontUnvailable: font]

	[super close];
}

@end
