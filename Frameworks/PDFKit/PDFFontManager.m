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

#import <PDFKit/PDFFontManager.h>

#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>

#include "XPDFBridge.h"


/* Default fonts and their subsitutes (font names from xpdf's GlobalParams).  */
static struct 
{
   NSString* name;
   NSString* fileName;
} FontTab[] =
{
   {@"Courier",               @"n022003l.pfb"},
   {@"Courier-Bold",          @"n022004l.pfb"},
   {@"Courier-BoldOblique",   @"n022024l.pfb"},
   {@"Courier-Oblique",       @"n022023l.pfb"},
   {@"Helvetica",             @"n019003l.pfb"},
   {@"Helvetica-Bold",        @"n019004l.pfb"},
   {@"Helvetica-BoldOblique", @"n019024l.pfb"},
   {@"Helvetica-Oblique",     @"n019023l.pfb"},
   {@"Symbol",                @"s050000l.pfb"},
   {@"Times-Bold",            @"n021004l.pfb"},
   {@"Times-BoldItalic",      @"n021024l.pfb"},
   {@"Times-Italic",          @"n021023l.pfb"},
   {@"Times-Roman",           @"n021003l.pfb"},
   {@"ZapfDingbats",          @"d050000l.pfb"},
   {nil, nil}
};


/* The shared instance of PDFFontManager.  */
static PDFFontManager* sharedPDFFontManager = nil;


/*
 * Non-Public methods.
 */
@interface PDFFontManager(Private)
- (NSString*) _findFontFile: (NSString*)fileName;
- (BOOL) _findFileName: (NSString**)fileName
               forFont: (NSString*)fontName;
@end


@implementation PDFFontManager

- (id) init
{
   int       i;
   NSString* fontFile;

   if ((self = [super init]))
   {
      fontNames    = [[NSMutableArray alloc] initWithCapacity: 0];

      for (i = 0; FontTab[i].name; i++)
      {
         fontFile = [self _findFontFile: FontTab[i].fileName];
         if (fontFile)
         {
            [self setFontFile: fontFile
                      forFont: FontTab[i].name];
         }
         else
         {
            NSLog(@"WARNING: no font for %@", FontTab[i].name);
         }
      }
   }

   return self;
}


- (void) dealloc
{
   RELEASE(fontNames);

   [super dealloc];
}


+ (PDFFontManager*) sharedManager
{
   if (!sharedPDFFontManager)
   {
      sharedPDFFontManager = [[PDFFontManager alloc] init];
   }

   return sharedPDFFontManager;
}


- (NSArray*) fontNames
{
   return [NSArray arrayWithArray: fontNames];
}


- (NSArray*) defaultFontNames
{
   NSMutableArray* names;
   int             i;

   names = [[NSMutableArray alloc] initWithCapacity: 0];

   for (i = 0; FontTab[i].name; i++)
   {
      [names addObject: [FontTab[i].name copy]];
   }

   return names;
}


- (NSString*) fontFileFor: (NSString*)fontName
{
   NSString* fileName;

   if ([self _findFileName: &fileName
                   forFont: fontName])
   {
      return fileName;
   }

   return nil;
}



- (void) setFontFile: (NSString*)file 
             forFont: (NSString*)fontName
{
   NSUInteger i;

   NSAssert([[NSFileManager defaultManager] fileExistsAtPath: file],
            @"font file does no exist");

   PDFFont_AddFontFile([fontName cString],
                       [file cString]);

   // ensure that the fontname is in the list of fonts
   for (i = 0; i < [fontNames count]; i++)
   {
      if ([[fontNames objectAtIndex: i] isEqualToString: fontName])
      {
         break;
      }
   }

   if (i >= [fontNames count])
   {
      [fontNames addObject: [fontName copy]];
   }
}

@end



@implementation PDFFontManager(Private)

- (NSString*) _findFontFile: (NSString*)fileName
{
   NSBundle* bundle;
   NSString* pathToFile;
   
   bundle = [NSBundle bundleForClass: [self class]];
   NSAssert(bundle, @"Could not load PDFKit Bundle");

   pathToFile = [bundle pathForResource: [fileName stringByDeletingPathExtension]
                                 ofType: [fileName pathExtension]];

   if (!pathToFile)
   {
      NSLog(@"WARNING: Resource %@ of type %@ not found",
            [fileName stringByDeletingPathExtension],
            [fileName pathExtension]);
   }

   return pathToFile;
}


- (BOOL) _findFileName: (NSString**)fileName
               forFont: (NSString*)fontName
{
   const char*      _fileName;
   
   PDFFont_FindFontFile([fontName cString],
                          &_fileName);

   if (_fileName == NULL)
   {
      return NO;
   }

   *fileName = [NSString stringWithCString: _fileName];

   return YES;
}

@end
