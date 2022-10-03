/* =============================================================================
	FILE:		UKNibOwner.m
	PROJECT:	CocoaTADS

    COPYRIGHT:  (c) 2004-2006 M. Uli Kusterer, all rights reserved.
    
	AUTHORS:	M. Uli Kusterer - UK
                Guenther Noack - GN
     
    LICENSES:   GPL, Modified BSD

	REVISIONS:
		2004-11-13	UK	Created.
        2006-08-17  GN  Made it load the Nib from the classes bundle instead
                        of just using the main bundle.
        2006-08-18  GN  Added loadNib method, modified comments to be doxygen
                        compatible.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKNibOwner.h"
#import "GNUstep.h"


/**
 * On instantiation, an object which inherits from UKNibOwner automatically loads
 * the Nib file which is named just like the concrete UKNibOwner subclass it is an
 * instance of.
 *
 * For example, a direct instance of the UKNibOwner subclass "PreferencesPanel"
 * would try to load the Nib file named "PreferencesPanel.nib".
 *
 * @author Uli Kusterer
 8 @author Guenther Noack
 */
@implementation UKNibOwner

/**
 * Create this object and load NIB file. Note that for subclasses, this
 * is called before your subclass has been fully constructed. Thus,
 * awakeFromNib can't rely on stuff that's done in the constructor.
 * I'll probably change this eventually.
 * 
 * If Nib file loading fails, this method returns nil and deallocates
 * the instance.
 * 
 * REVISIONS:
 *     2004-12-23  UK  Documented.
 *
 * @return an instance of the class if Nib loading succeeded
 */
-(id)	init
{
	if( (self = [super init]) )
	{
        // Mark Nib as not loaded
        nibLoaded = NO;
        
        // XXX: If removing loading Nibs from init, also update the
        //      comment for the UKNibOwner class!
        if ([self loadNib] == NO) {
            DESTROY(self);
        }
	}
	
	return self;
}


-(void)	dealloc
{
	// XXX: How do I deallocate the Nib correctly? -GN
    
	[super dealloc];
}



/**
 * Loads the owners Nib file. If it works, it returns YES. If it doesn't, it returns
 * NO and prints a log message.
 * 
 * This method may throw an exception if the bundle of the current class could not be
 * determined.
 * 
 * REVISIONS
 *     2006-08-18  GN  Created.
 * 
 * @return YES, if and only if the Nib loading succeeded.
 */
-(BOOL) loadNib
{
    // Ensure we don't load the Nib multiple times.
    if (nibLoaded == YES)
        return YES;
    
    // get my bundle
    NSBundle* bundle = [self bundle];
    
    // ensure the bundle has been found
    NSAssert1(bundle != nil, @"Failed finding bundle for NibOwner %@", self);
    
    NSDictionary* ent = [NSDictionary dictionaryWithObjectsAndKeys:
                                        self, @"NSOwner", nil];
    
    // load Nib belonging to bundle
    nibLoaded = [bundle  loadNibFile: [self nibFilename]
                   externalNameTable: ent
                            withZone: [self zone]];
    
    // Return NO if the Nib loading failed.
    if (nibLoaded == NO) {
        NSLog(@"NibOwner %@ couldn't load Nib (Gorm) file %@.nib (~.gorm)", self, [self nibFilename]);
        return NO;
    }
    
    nibLoaded = YES;
    return YES;
}

/**
 * Returns the filename (minus ".nib" suffix) for the NIB file to load.
 * Note that, if you subclass this, it will use the subclass's name, and
 * if you subclass that, the sub-subclass's name. So, you *may* want to
 * override this to return a constant string if you don't expect subclasses
 * to have their own similar-but-different NIB file.
 * 
 * REVISIONS:
 *    2004-12-23  UK  Documented.
 *
 * @return the filename (minus ".nib" suffix) for the Nib file.
 */
-(NSString*) nibFilename
{
    return NSStringFromClass([self class]);
}


/**
 * Returns the NSBundle to load the Nib from.
 *
 * REVISIONS:
 *      2006-08-17  GN  Created
 */
-(NSBundle*) bundle
{
    return [NSBundle bundleForClass: [self class]];
}

@end
