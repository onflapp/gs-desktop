/*
 * Copyright (C) 2003  Stefan Kleine Stegemann
 *               2016 GNUstep Application Project
 *
 * Authors: Stefan Kleine Stegemann
 *          Riccardo Mottola
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#ifndef _H_PDF_FONT_MANAGER
#define _H_PDF_FONT_MANAGER

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>



/* The font manager is mainly used to manage font substitutions
 * for the defaults fonts that are used during PDF rendering.
 * For each font, a file containing a Type1 or TrueType font has
 * to be defined (otherwise, you won't see text in some documents).
 * The font manager provides a default font substitution with fonts
 * that are bundled with PDFKit. If you're happy with this fonts,
 * you can leave here. If not, you have to use the shared instance
 * of this font manager to setup your own substitution.
 *
 * Note that the way the font's are handled by PDFKit does not
 * fit very well (not a all?) in GNUsteps font handling. Maybe,
 * i'll create a peer sometime when the font handling in GNUstep
 * has been unified through the backends. For now, we have to live
 * with this approach.  The value you get from this drawback is
 * that you have all the power of the XPDF backend without much
 * work.  */
@interface PDFFontManager : NSObject
{
   NSMutableArray*       fontNames;
   NSMutableDictionary*  fontMappings;
}

/* You should use sharedManager to obtain a PDFFontManager.  */
- (id) init;
- (void) dealloc;

+ (PDFFontManager*) sharedManager;

/* Get the names of all fonts that have a substitute.  */
- (NSArray*) fontNames;

/* Get the names of the default fonts that should have a substitute.  */
- (NSArray*) defaultFontNames;

/* Get the file that contains the substitute font for the font
 * with the given name.  Returns nil if no substitute font has
 * been defined.  */
- (NSString*) fontFileFor: (NSString*)fontName;

/* Set a subsitute font for a particular font.  */
- (void) setFontFile: (NSString*)file 
             forFont: (NSString*)fontName;

@end

#endif
