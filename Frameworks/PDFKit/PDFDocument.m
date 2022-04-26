/*
 * Copyright (C) 2003  Stefan Kleine Stegemann
 *           (C) 2013-2016  The GNUstep Application Team
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

#import "PDFDocument.h"
#import "PDFImageRep.h"
#import "XPDFBridge.h"
#import "CountingRef.h"
#import "PDFOutline.h"

#define CONTENT_SIZE 262144


@interface PDFDocRefDelegate : NSObject <CountingRefDelegate>
{
}
@end


/*
 * Non-Public methods of PDFDocument.
 */
@interface PDFDocument (Private)

- (id)_initWithBridgeDocument:(XPDFObject)aPdfDoc;

- (void)_translateRectToPageCoords:(int)pageNum
                              rect:(NSRect)rect
                              xMin:(double *)xMin
                              yMin:(double *)yMin
                              xMax:(double *)xMax
                              yMax:(double *)yMax;
@end

/*
 * Non-Public methods of PDFSearchContext.
 */
@interface PDFSearchContext (Private)

- (SearchContext *)_xpdfSearchContext;

@end



@implementation PDFDocument

- (id) init
{
  return [self _initWithBridgeDocument: NULL];
}


- (void) dealloc
{
  NSLog(@"dealloc PDFDocument, retain count is %lu", (unsigned long)[self retainCount]);
  RELEASE (outline);
  RELEASE (pdfDocRef);
  RELEASE (textContents);
  RELEASE (documentInfo);
   
  [super dealloc];
}


+ (void) initialize
{
   [super initialize];

   // Initialize XPDF backend
   XPDF_Initialize(PDFBaseResolution); // base resolution is
     
  NSLog(@"xpdf backend initialized");  
}


+ (PDFDocument*)documentFromFile: (NSString*)fileName
{
   return [PDFDocument documentFromFile: fileName
                       ownerPassword: nil
                       userPassword: nil];
}


+ (PDFDocument *)documentFromFile:(NSString *)fileName 
                    ownerPassword:(NSString *)ownerPassword
                     userPassword:(NSString *)userPassword
{
   XPDFObject    newPdfDoc;
   const char*   cFileName;
   const char*   cOwnerPassword;
   const char*   cUserPassword;

   NSAssert(fileName != nil, @"no filename");

   cFileName = [fileName cString];
   
   cOwnerPassword = (ownerPassword != nil ? [ownerPassword cString] : NULL);
   cUserPassword  = (userPassword != nil ? [userPassword cString] : NULL);

   newPdfDoc = PDFDoc_create(cFileName,
                             cOwnerPassword,
                             cUserPassword);

   return AUTORELEASE([[PDFDocument alloc] _initWithBridgeDocument: newPdfDoc]);
}


- (BOOL) isOk
{
   NSAssert(![pdfDocRef isNULL], @"no document");

   return PDFDoc_isOk([pdfDocRef pointer]);
}


- (int) errorCode
{
   NSAssert(![pdfDocRef isNULL], @"no document");
   
   return PDFDoc_getErrorCode([pdfDocRef pointer]);
}


- (double) pageWidth: (int)pageNum
{
   NSAssert(![pdfDocRef isNULL], @"no document");
   
   return PDFDoc_getPageCropWidth([pdfDocRef pointer], pageNum);
}


- (double) pageHeight: (int)pageNum
{
   NSAssert(![pdfDocRef isNULL], @"no document");
   
   return PDFDoc_getPageCropHeight([pdfDocRef pointer], pageNum);
}


- (NSSize) pageSize: (int)pageNum considerRotation: (BOOL)rotation
{
   NSSize size;
   
   size = NSMakeSize([self pageWidth: pageNum], [self pageHeight: pageNum]);
   if (rotation)
   {
      if (([self pageRotate: pageNum] == 90) || ([self pageRotate: pageNum] == 180))
      {
         CGFloat height = size.height;
         size.height = size.width;
         size.width  = height;
      }
   }
   NSLog(@"PDFDocument pageSize: %f %f", size.width, size.height);
   return size;
}


- (int) pageRotate: (int)pageNum
{
   NSAssert(![pdfDocRef isNULL], @"no document");
   
   return PDFDoc_getPageRotate([pdfDocRef pointer], pageNum);
}


- (int) countPages
{
   return (int) [self pageCount];
}

- (NSUInteger) pageCount
{
   NSAssert(![pdfDocRef isNULL], @"no document");
   
   return (NSUInteger) PDFDoc_getNumPages([pdfDocRef pointer]);  
}

- (NSString*)metaData
{
   const char* data;
   NSAssert(![pdfDocRef isNULL], @"no document");

   data = PDFDoc_getMetaData([pdfDocRef pointer]);
   return (data != NULL ? 
           [[[NSString alloc] initWithCString: data] autorelease]
           : 
           nil);
}


- (BOOL) hasOutline
{
   NSAssert(![pdfDocRef isNULL], @"no document");
   return PDFOutline_HasOutline([pdfDocRef pointer]);
}


- (PDFOutline*) outline
{
   NSAssert(![pdfDocRef isNULL], @"no document");

   if ((!outline) && [self hasOutline])
   {
      outline =
         [[PDFOutline alloc] initWithOutlineItems:
                                PDFOutline_GetOutlineItems([pdfDocRef pointer])
                                       ofDocument: pdfDocRef];
   }

   return outline;
}


- (BOOL) findText: (NSString*)text
             page: (int*)pageNum
           toPage: (int)maxPage
         position: (NSRect*)pos
          context: (NSString**)context
{
   BOOL result;

   PDFSearchContext* searchContext = [[PDFSearchContext alloc] initWithDocument: self];

   result = [self findText: text
        usingSearchContext: searchContext
                      page: pageNum
                    toPage: maxPage
                  position: pos
               textContext: context];

   RELEASE(searchContext);

   return result;
}


- (PDFSearchContext*) createSearchContext
{
   return AUTORELEASE([[PDFSearchContext alloc] initWithDocument: self]);
}


- (BOOL) findText: (NSString*)aText
usingSearchContext: (PDFSearchContext*)aSearchContext
             page: (int*)pageNum
           toPage: (int)maxPage
         position: (NSRect*)pos
      textContext: (NSString**)aTextContext
{
   double     xMin, yMin, xMax, yMax;
   char*      textCtxBuffer;
   int        textCtxBufferLength;

   NSAssert(aSearchContext, @"search context is nil");

   // Note that PDFUtil_FindText uses upside down coords
   // (0,0 is upper left corner)

   if (pos->size.height == -1)
   {
      pos->size.height = [self pageHeight: *pageNum];
   }
   
   [self _translateRectToPageCoords: *pageNum rect: *pos
          xMin: &xMin yMin: &yMin xMax: &xMax yMax: &yMax];

   if (!PDFSearch_FindText([aSearchContext _xpdfSearchContext],
                           [aText cString],
                           pageNum,
                           maxPage,
                           0,
                           &xMin,
                           &yMin,
                           &xMax,
                           &yMax,
                           &textCtxBuffer,
                           &textCtxBufferLength))
   {
      //NSLog(@"%@ not found", text);
      return NO;
   }

   // translate resulting coords
   yMin = [self pageHeight: *pageNum] - yMin;
   yMax = [self pageHeight: *pageNum] - yMax;

   //NSLog(@"found %@ at %f, %f, %f, %f", text, xMin, yMin, xMax, yMax);
   pos->origin.x = (xMin < xMax ? xMin : xMax);
   pos->origin.y = (yMin < yMax ? yMin : yMax);
   pos->size.width = (xMax > xMin ? xMax - xMin : xMin - xMax);
   pos->size.height = (yMax > yMin ? yMax - yMin : yMin - yMax);

   if (textCtxBuffer != NULL)
   {
      if (aTextContext != NULL)
      {
         *aTextContext = [NSString stringWithCString: textCtxBuffer
                                              length: textCtxBufferLength];
      }
      // we copy the buffer here instead of using initWithCStringNoCopy
      // because it has not been allocated with NSZoneMalloc
      free(textCtxBuffer);
   }
   else
   {
      if (aTextContext != NULL)
      {
         *aTextContext = @"??";
      }
   }
   
   return YES;
}

static void outputToString(void *stream, char *text, int len) 
{
  NSMutableString *ms;

  ms = (NSMutableString *)stream;
  [ms appendString: [[[NSString alloc] initWithBytes:text
					      length:(NSUInteger)len
					    encoding:NSUTF8StringEncoding] autorelease]];
}

- (NSString *)getAllText
{
  CREATE_AUTORELEASE_POOL(arp);
  
  [textContents setString: @""];
  
  if (PDFUtil_GetAllText([pdfDocRef pointer], outputToString, textContents) == 0) {
    DESTROY (textContents);
  } 

  RELEASE (arp);
  
  return textContents;
}

static void getDictPair(char *key, char *value, void *iD) 
{
  if (key != NULL && strlen(key) && value != NULL && strlen(value)) {
    NSString *keystr = nil;
    NSString *valuestr = nil;
    BOOL pairok = YES;
    NSMutableDictionary *documentInfo = (NSMutableDictionary *)iD;    
    
    NS_DURING
	    {
        keystr = [NSString stringWithUTF8String: key];
        valuestr = [NSString stringWithUTF8String: value];
	    }
    NS_HANDLER
	    {
	      fprintf (stderr, "invalid key/value pair.\n");
        pairok = NO;
      }
    NS_ENDHANDLER
  
    if (pairok && keystr && [keystr length] && valuestr && [valuestr length]) {
      [documentInfo setObject: valuestr forKey: keystr];
    }
  }
}

- (NSDictionary *)getDocumentInfo
{
  CREATE_AUTORELEASE_POOL(arp);

  [documentInfo removeAllObjects];

  if (PDFUtil_GetInfo([pdfDocRef pointer], getDictPair, documentInfo) == 0) {
    DESTROY (documentInfo);
  } 

  RELEASE (arp);

  return documentInfo;
}

- (NSString*) getTextAtPage: (int)pageNum inRect: (NSRect)pos
{
   NSString* text = nil;
   char*     buffer;
   int       buffLen;
   double    xMin, yMin, xMax, yMax;
   
   [self _translateRectToPageCoords: pageNum rect: pos
          xMin: &xMin yMin: &yMin xMax: &xMax yMax: &yMax];

   PDFUtil_GetText([pdfDocRef pointer],
                   pageNum,
                   xMin,
                   yMin,
                   xMax,
                   yMax,
                   &buffer,
                   &buffLen);

   if (buffer != NULL)
   {
      text = [NSString stringWithCString: buffer length: buffLen];
      // we copy the buffer here instead of using initWithCStringNoCopy
      // because it has not been allocated with NSZoneMalloc
      free(buffer);
   }

   return text;
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PDFDocument (Private)

/** Designated initializer.  */
- (id) _initWithBridgeDocument: (XPDFObject)aPdfDoc
{
  if ((self = [super init])) {
    id refDelegate = [[PDFDocRefDelegate alloc] init];
    pdfDocRef = [[CountingRef alloc] initWithPointer: aPdfDoc
                                              delegate: refDelegate];
    RELEASE(refDelegate);

    outline   = nil;
      
    textContents = [[NSMutableString alloc] initWithCapacity: CONTENT_SIZE];
    documentInfo = [NSMutableDictionary new];
  }

  return self;
}   


/** Translate a rectangular area to coordinates on a page.
 *  The coordinate system is upside down.  */
- (void) _translateRectToPageCoords: (int)pageNum
                               rect: (NSRect)rect
                               xMin: (double*)xMin
                               yMin: (double*)yMin
                               xMax: (double*)xMax
                               yMax: (double*)yMax
{
   *xMin = rect.origin.x;
   *yMin = [self pageHeight: pageNum] - (rect.origin.y + rect.size.height);
   *xMax = rect.origin.x + rect.size.width;
   *yMax = [self pageHeight: pageNum] - rect.origin.y;
}

@end


/* ----------------------------------------------------- */
/*  Category Wrapper                                     */
/* ----------------------------------------------------- */

@implementation PDFDocument (Wrapper)

- (void*) xpdfobject
{
   return [pdfDocRef pointer];
}

@end


/* ----------------------------------------------------- */
/*  Class PDFDocRefDelegate                              */
/* ----------------------------------------------------- */




@implementation PDFDocRefDelegate

- (id) init
{
   if ((self = [super init]))
   {
      // ....
   }
   return self;
}


- (void) dealloc
{
   [super dealloc];
}


- (void) freePointerForReference: (CountingRef*)aReference
{
   if (![aReference isNULL])
   {
      PDFDoc_delete([aReference pointer]);
   }
}

@end


/* ----------------------------------------------------- */
/*  Implemenation of PDFSearchContext                    */
/* ----------------------------------------------------- */

@implementation PDFSearchContext

- (id) initWithDocument: (PDFDocument*)aDocument
{
   NSAssert(aDocument, @"no document");

   if ((self = [super init]))
   {
      theDocument = aDocument;
      theSearchContext = PDFSearch_CreateSearchContext([aDocument xpdfobject]);
      NSAssert(theSearchContext, @"failed to create the internal search context");
   }

   return self;
}


- (void) dealloc
{
   NSLog(@"dealloc PDFSearchContext");
   PDFSearch_DestroySearchContext(theSearchContext);
   [super dealloc];
}


- (PDFDocument*) document
{
   return theDocument;
}

@end


/* ----------------------------------------------------- */
/*  Category Private of PDFSearchContext                 */
/* ----------------------------------------------------- */

@implementation PDFSearchContext (Private)

- (SearchContext*) _xpdfSearchContext
{
   return (SearchContext*)theSearchContext;
}

@end

