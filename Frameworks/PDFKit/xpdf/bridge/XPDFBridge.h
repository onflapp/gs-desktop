/*
 * Copyright (C) 2003  Stefan Kleine Stegemann
 *               2016-2017 GNUstep Application Project
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

#ifndef _H_XPDF_OBJC_BRIDGE
#define _H_XPDF_OBJC_BRIDGE

#include <stdlib.h>

/*
 * 'Bridge-Functions' to create a Objective-C
 * Interface to (a part of) the XPDF System.
 */

#ifdef __cplusplus 
extern "C" {
#endif

/*
 * Types.
 */
typedef void* XPDFObject;

typedef struct OutputOptions
{
   int  resolution;
   int  firstPage;
   int  lastPage;
   int  paperWidth;
   int  paperHeight;
} OutputOptions;


typedef enum RenderResult
{
   RenderResult_Ok,
   RenderResult_ErrorOutputDevice,
   RenderResult_MiscError
} RenderResult;


typedef enum DisplayFontType
{
   T1DisplayFont,
   TTDisplayFont
} DisplayFontType;


typedef struct SearchContext
{
   XPDFObject textOutputDevice;
   XPDFObject pdfDoc;
   int        currentPage;
} SearchContext;

typedef void (*infoDictFunc)(char *key, char *value, void *infoDict);


/*
 * Managing access to the xpdf engine. Since this
 * engine seems not to be thread-safe, we use
 * a locking mechanism to guarantee that only one
 * thread uses the engine at a time.
 */
void XPDF_AcquireLock();
void XPDF_ReleaseLock();

/*
 * The bridge has to be initialized before it can be used.
 * To free resources that have been allocated during initialization,
 * the destroy function has to be called.
 */
void   XPDF_Initialize(double dpi);
void   XPDF_Destroy(void);
int    XPDF_IsInitialized(void);
double XPDF_DPI(void);

/* 
 * PDFDoc class 
 */
XPDFObject PDFDoc_create(const char* filename,
                         const char* ownerPassword,
                         const char* userPassword);
void PDFDoc_delete(XPDFObject pdfDoc);

int PDFDoc_isOk(XPDFObject pdfDoc);
int PDFDoc_getErrorCode(XPDFObject pdfDoc);

double PDFDoc_getPageMediaWidth(XPDFObject pdfDoc, int pageNum);
double PDFDoc_getPageMediaHeight(XPDFObject pdfDoc, int pageNum);
double PDFDoc_getPageCropWidth(XPDFObject pdfDoc, int pageNum);
double PDFDoc_getPageCropHeight(XPDFObject pdfDoc, int pageNum);
int    PDFDoc_getPageRotate(XPDFObject pdfDoc, int pageNum);

int PDFDoc_getNumPages(XPDFObject pdfDoc);
 
const char* PDFDoc_getMetaData(XPDFObject pdfDoc);

 /*
  * Searching
  */
// defines how many text from left to right
// is included in the textContext when a
// text has been found somewhere.
#define FOUND_CONTEXT_LEFT  80
#define FOUND_CONTEXT_RIGHT 80

/* When performing subsequent searchs in the same document,
 * a search contexts helps to avoid 'rendering' the same page
 * to text more than once. If you have many hit's on the same
 * page, this will speed up the search noticable.  */

SearchContext* PDFSearch_CreateSearchContext(XPDFObject pdfDoc);
void PDFSearch_DestroySearchContext(SearchContext* aSearchContext);
int PDFSearch_FindText(SearchContext* aSearchContext,
                       const char* text,
                       int* pageA,
                       int toPage,
                       short wholeWord,
                       double *xMin,
                       double* yMin,
                       double* xMax,
                       double *yMax,
                       char** textContext,
                       int* textContextLength);

/*
 * Access content
 */
int PDFUtil_GetAllText(XPDFObject pdfDoc, void *func, void *ms);

void PDFUtil_GetText(XPDFObject pdfDoc,
                     int page,
                     double xMin,
                     double yMin,
                     double xMax,
                     double yMax,
                     char** textA,
                     int* length);

int PDFUtil_GetInfo(XPDFObject pdfDoc, infoDictFunc dictfunc, void *docInfoDict);

/*
 * Outline
 */
int PDFOutline_HasOutline(XPDFObject pdfDoc);
XPDFObject PDFOutline_GetOutlineItems(XPDFObject pdfDoc);
int PDFOutline_CountItems(XPDFObject outlineItems);
XPDFObject PDFOutline_ItemAt(XPDFObject outlineItems, int index);
void PDFOutline_ItemOpen(XPDFObject outlineItem);
void PDFOutline_ItemClose(XPDFObject outlineItem);
int PDFOutline_HasKids(XPDFObject outlineItem);
XPDFObject PDFOutline_GetKids(XPDFObject outlineItem);
char* PDFOutline_GetTitle(XPDFObject outlineItem);
int PDFOutline_GetTargetPage(XPDFObject outlineItem, XPDFObject pdfDoc);


/*
 * Font Management
 */
void PDFFont_AddFontFile(const char* fontName,
                         const char* fontFile);
void PDFFont_FindFontFile(const char* fontName,
                          const char** fontFile);

/*
 * Rendering
 */
XPDFObject PDFRender_CreateOutputDevice(XPDFObject pdfDoc);
void PDFRender_DestroyOutputDevice(XPDFObject device);
XPDFObject PDFRender_RenderPage(XPDFObject pdfDoc,
                                XPDFObject device,
                                int page,
                                double dpi,
                                int rotate);
void PDFRender_GetBitmapSize(XPDFObject bitmap, int* width, int* height);
void PDFRender_GetRGB(XPDFObject bitmap, unsigned char** buffer);

/*
 * Postscript Output
 */
XPDFObject PDFPS_CreateOutputDevice(XPDFObject pdfDoc, int firstPage, int lastPage);
void PDFPS_OutputPages(XPDFObject pdfDoc, XPDFObject device, int firstPage, int lastPage);
void PDFPS_DestroyOutputDevice(XPDFObject device);

#ifdef __cplusplus 
};
#endif



#endif
