/* =============================================================================
	FILE:		UKNibOwner.h
	PROJECT:	CocoaTADS

    COPYRIGHT:  (c) 2004-2006 M. Uli Kusterer, all rights reserved.
    
	AUTHORS:	M. Uli Kusterer - UK
                Guenther Noack - GN
    
    LICENSES:   GPL, Modified BSD

	REVISIONS:
		2004-11-13	UK	Created.
        2006-08-17  GN  Added -bundle method.
        2006-08-18  GN  Added -loadNib method, removed topLevelObjects field.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

@interface UKNibOwner : NSObject
{
    BOOL nibLoaded;
}

-(NSString*) nibFilename; // Defaults to name of the class.

-(NSBundle*) bundle; // Defaults to the bundle of the concrete UKNibOwner (sub)class.

-(BOOL) loadNib; // Loads Nib and returns YES on success.

@end
