/*
 * Copyright (C) 2003  Stefan Kleine Stegemann
 *               2012-2017 GNUstep Application Project
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

#include "XPDFBridge.h"
#include "PDFDoc.h"
#include "Outline.h"
#include "SplashBitmap.h"
#include "SplashOutputDev.h"
#include "TextOutputDev.h"
#include "GString.h"
#include "GlobalParams.h"
#include "GList.h"
#include "UnicodeMap.h"
#include "Link.h"
#include "PSOutputDev.h"
#include "DPS.h"

#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#include <typeinfo>


/* ----------------------------------------------------------- */

/*
 * Initialization and destruction.
 */
static char cfgFileName[256] = "";
 
static int    initialized = 0;
static double dpi         = 0.0;

void XPDF_Initialize(double _dpi)
{
   globalParams = new GlobalParams(cfgFileName);
   dpi          = _dpi;

   globalParams->setTextEncoding("UTF-8");
   initialized = 1;
}


void XPDF_Destroy(void)
{
   initialized = 0;
   delete globalParams;
}


int  XPDF_IsInitialized(void)
{
   return initialized;
}


double XPDF_DPI()
{
   return dpi;
}


/* 
 * PDFDoc class 
 */

#define TO_PDFDoc(object) (static_cast<PDFDoc*>(object))

XPDFObject PDFDoc_create(const char* filename,
                         const char* ownerPassword,
                         const char* userPassword)
{
   GString* gsFilename;
   GString* gsOwnerPassword;
   GString* gsUserPassword;
   PDFDoc*  doc;

   gsFilename = new GString(filename);
   gsOwnerPassword = (ownerPassword != NULL ? new GString(ownerPassword) : NULL);
   gsUserPassword  = (userPassword != NULL ? new GString(userPassword) : NULL);

   doc = new PDFDoc(gsFilename, gsOwnerPassword, gsUserPassword);

   return (XPDFObject)doc;
}


void PDFDoc_delete(XPDFObject pdfDoc)
{
   fprintf(stderr, "DEBUG: delete PDFDoc\n");
   delete TO_PDFDoc(pdfDoc);
}


int PDFDoc_isOk(XPDFObject pdfDoc)
{
   return TO_PDFDoc(pdfDoc)->isOk();
}


int PDFDoc_getErrorCode(XPDFObject pdfDoc)
{
   return TO_PDFDoc(pdfDoc)->getErrorCode();
}

double PDFDoc_getPageMediaWidth(XPDFObject pdfDoc, int pageNum)
{
   return TO_PDFDoc(pdfDoc)->getPageMediaWidth(pageNum);
}


double PDFDoc_getPageMediaHeight(XPDFObject pdfDoc, int pageNum)
{
  return TO_PDFDoc(pdfDoc)->getPageMediaHeight(pageNum);
}

double PDFDoc_getPageCropWidth(XPDFObject pdfDoc, int pageNum)
{
   return TO_PDFDoc(pdfDoc)->getPageCropWidth(pageNum);
}


double PDFDoc_getPageCropHeight(XPDFObject pdfDoc, int pageNum)
{
   return TO_PDFDoc(pdfDoc)->getPageCropHeight(pageNum);
}


int PDFDoc_getPageRotate(XPDFObject pdfDoc, int pageNum)
{
   return TO_PDFDoc(pdfDoc)->getPageRotate(pageNum);
}


int PDFDoc_getNumPages(XPDFObject pdfDoc)
{
   return TO_PDFDoc(pdfDoc)->getNumPages();
}

 
const char* PDFDoc_getMetaData(XPDFObject pdfDoc)
{
   return (const char*)TO_PDFDoc(pdfDoc)->readMetadata();
}


/* ----------------------------------------------------------- */

/*
 * Seraching in PDFDocs.
 */

SearchContext* PDFSearch_CreateSearchContext(XPDFObject pdfDoc)
{
  TextOutputControl *toControl;
   SearchContext* theContext = (SearchContext*)calloc(1, sizeof(SearchContext));
   if (!theContext)
   {
      fprintf(stderr, "not enough memory to create SearchContext\n");
      fflush(stderr);
      return NULL;
   }

   toControl = new TextOutputControl();
   toControl->mode = textOutPhysLayout;
   theContext->pdfDoc = pdfDoc;
   theContext->currentPage = -1;
   theContext->textOutputDevice = new TextOutputDev(NULL, toControl, gFalse);

   if (!static_cast<TextOutputDev*>(theContext->textOutputDevice)->isOk())
   {
      fprintf(stderr, "unable to create TextOutputDev\n");
      fflush(stderr);
      PDFSearch_DestroySearchContext(theContext);
      return NULL;
   }
   delete toControl;
   return theContext;
}


void PDFSearch_DestroySearchContext(SearchContext* aSearchContext)
{
   if (!aSearchContext)
   {
      return;
   }

   if (aSearchContext->textOutputDevice)
   {
      delete static_cast<TextOutputDev*>(aSearchContext->textOutputDevice);
   }

   delete aSearchContext;
}


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
                       int* textContextLength)
{
   if ((!aSearchContext)
       || (!aSearchContext->textOutputDevice) 
       || (!aSearchContext->pdfDoc))
   {
      fprintf(stderr, "invalid context\n");
      fflush(stderr);
      return 0;
   }

   PDFDoc* doc = TO_PDFDoc(aSearchContext->pdfDoc);
   int found = 0;
   int startPage = *pageA;
   GBool top;
   GBool wholeWordBool;

   wholeWordBool = gFalse;
   if (wholeWord)
     wholeWordBool = gTrue;

   TextOutputDev* textOut = static_cast<TextOutputDev*>(aSearchContext->textOutputDevice);
   if (!textOut->isOk())
   {
      fprintf(stderr, "invalid TextOutputDev in context\n");
      fflush(stderr);
      return -1;
   }

   XPDF_AcquireLock();

   int len = strlen(text);
   Unicode* u = (Unicode *)gmalloc(len * sizeof(Unicode));
   for (int i = 0; i < len; ++i)
   {
      u[i] = (Unicode)(text[i] & 0xff);
   }

   
   if ((*xMin == 0) && (*yMin == 0) && (*xMax == 0) && (*yMax == 0))
   {
      top = gTrue;
   }
   else
   {
      top = gFalse;
   }

   //fprintf(stderr, "start search at %f, %f, %f, %f\n", *xMin, *yMin, *xMax, *yMax);
   //fflush(stderr);

   // first search forward
   int page;
   int maxPage = (toPage != -1 ? toPage : doc->getNumPages());
   for (page = startPage; page <= maxPage; page++)
   {
      if (page != aSearchContext->currentPage)
      {
  doc->displayPage(textOut, page, XPDF_DPI(), XPDF_DPI(), 0, gFalse, gFalse, gTrue);
         aSearchContext->currentPage = page;
      }

      if (page == startPage)
      {
         found =
           textOut->findText(u, len, top, gTrue, gFalse, gFalse, gFalse, gFalse, wholeWordBool, xMin, yMin, xMax, yMax);
      }
      else
      {
         found =
           textOut->findText(u, len, gTrue, gTrue, gFalse, gFalse, gFalse, gFalse, wholeWordBool, xMin, yMin, xMax, yMax);
      }

      if (found)
      {
         *pageA  = page;
         break;
      }
   }

   // continue search from the beginning of the document
   // if the whole document is searched
   if ((!found) && (toPage == -1))
   {
      for (page = 1; page <= startPage; page++)
      {
         if (page != aSearchContext->currentPage)
         {
            doc->displayPage(textOut, page, XPDF_DPI(), XPDF_DPI(), 0, gFalse, gFalse, gTrue);
            aSearchContext->currentPage = page;
         }

         if (page == startPage)
         {
            found =
              textOut->findText(u, len, gTrue, gTrue, gFalse, gFalse, gFalse, gFalse, wholeWordBool, xMin, yMin, xMax, yMax);
         }
         else
         {
            found =
              textOut->findText(u, len, gTrue, gFalse, gFalse, gFalse, gFalse, gFalse, wholeWordBool, xMin, yMin, xMax, yMax);
         }

         if (found)
         {
            *pageA = page;
            break;
         }
      }
   }

   if (found)
   {
      /*
      fprintf(stderr, "%s found at %f, %f, %f, %f\n", text, *xMin, *yMin, *xMax, *yMax);
      fflush(stderr);
      */
      // Get the context of the found text (some text around the
      // position where the text occured)
      double ctxXMin = *xMin - FOUND_CONTEXT_LEFT;
      double ctxXMax = *xMax + FOUND_CONTEXT_RIGHT;

      if (ctxXMin < 0)
      {
         ctxXMax += ctxXMin * (-1);
         if (ctxXMax > doc->getPageMediaWidth(*pageA))
         {
            ctxXMax = doc->getPageMediaWidth(*pageA);
         }
      }

      if (ctxXMax > doc->getPageMediaWidth(*pageA))
      {
         ctxXMin -= ctxXMax - doc->getPageMediaWidth(*pageA);
         if (ctxXMin < 0)
         {
            ctxXMin = 0;
         }
      }

      GString *textContextStr = textOut->getText(ctxXMin, *yMin, ctxXMax, *yMax);
      if (textContextStr)
      {
         *textContext = (char*)calloc(1, textContextStr->getLength() * sizeof(char));
         memcpy(*textContext, textContextStr->getCString(), textContextStr->getLength());
         *textContextLength = textContextStr->getLength();
         delete textContextStr;
      }
      else
      {
         *textContext = NULL;
         *textContextLength = 0;
      }
   }

   XPDF_ReleaseLock();

   return found;
}


/* ----------------------------------------------------------- */

/*
 * Accessing the pdf content.
 */

int PDFUtil_GetAllText(XPDFObject pdfDoc, void *func, void *ms)
{
  PDFDoc *doc = TO_PDFDoc(pdfDoc);
  TextOutputDev *textOut;
  TextOutputControl *toControl;
  int got = 1;

  toControl = new TextOutputControl();
  toControl->mode = textOutPhysLayout;
  
  XPDF_AcquireLock();

  textOut = new TextOutputDev((TextOutputFunc)func, (void *)ms, toControl);

  if (textOut->isOk()) {
    doc->displayPages(textOut, 1, doc->getNumPages(), 72, 72, 0,
		                                              gFalse, gTrue, gFalse);
  } else {
    got = 0;
  }
  
  delete textOut;
  delete toControl;
  XPDF_ReleaseLock();
  
  return got;  
}

void PDFUtil_GetText(XPDFObject pdfDoc,
                     int page,
                     double xMin,
                     double yMin,
                     double xMax,
                     double yMax,
                     char** textA,
                     int* length)
{
   TextOutputControl *toControl;
   XPDF_AcquireLock();

   PDFDoc* doc = TO_PDFDoc(pdfDoc);
   toControl = new TextOutputControl();
   toControl->mode = textOutPhysLayout;

   TextOutputDev* textOut = new TextOutputDev(NULL, toControl, gFalse);
   if (!textOut->isOk())
   {
      delete textOut;
      fprintf(stderr, "unable to create TextOutputDev\n");
      fflush(stderr);
      XPDF_ReleaseLock();
      return;
   }
   
   doc->displayPage(textOut, page, XPDF_DPI(), XPDF_DPI(), 0, gFalse, gFalse, gTrue);

   GString* text = textOut->getText(xMin, yMin, xMax, yMax);
   if (text)
   {
      *textA = (char*)calloc(1, text->getLength() * sizeof(char));
      memcpy(*textA, text->getCString(), text->getLength());
      *length = text->getLength();
      delete text;
   }
   else
   {
      *textA  = NULL;
      *length = 0;
   }

   delete textOut;
   delete toControl;

   XPDF_ReleaseLock();
}

int PDFUtil_GetInfo(XPDFObject pdfDoc, infoDictFunc dictfunc, void *docInfoDict)
{
  UnicodeMap *uMap;
  PDFDoc *doc;
  Object info;

  XPDF_AcquireLock();

  if ((uMap = globalParams->getTextEncoding()) == NULL) {
    XPDF_ReleaseLock();
    return 0;
  }

  doc = TO_PDFDoc(pdfDoc);
  doc->getDocInfo(&info);

  if (info.isDict())
    {
      int i;
      Dict *infoDict = info.getDict();
      int numOfKeys = infoDict->getLength();

      for (i = 0; i < numOfKeys; i++)
        {
          char *key;
          Object obj;
 
          key = infoDict->getKey(i);
          if (infoDict->lookup(key, &obj)->isString())
            {
              GString *str = obj.getString();
              char *cStr = str->getCString();

              (*dictfunc)(key, cStr, docInfoDict);
            }
          obj.free();
        }
    }
  
  info.free();

  XPDF_ReleaseLock();
  
  return 1;
}


/* ----------------------------------------------------------- */

/*
 * Outline.
 */


int PDFOutline_HasOutline(XPDFObject pdfDoc)
{
   return (TO_PDFDoc(pdfDoc)->getOutline()->getItems() != NULL);
}


XPDFObject PDFOutline_GetOutlineItems(XPDFObject pdfDoc)
{
   return TO_PDFDoc(pdfDoc)->getOutline()->getItems();
}


int PDFOutline_CountItems(XPDFObject outlineItems)
{
   return static_cast<GList*>(outlineItems)->getLength();
}


XPDFObject PDFOutline_ItemAt(XPDFObject outlineItems, int index)
{
   OutlineItem* item = (OutlineItem*)static_cast<GList*>(outlineItems)->get(index);
   return item;
}


void PDFOutline_ItemOpen(XPDFObject outlineItem)
{
   static_cast<OutlineItem*>(outlineItem)->open();
}


void PDFOutline_ItemClose(XPDFObject outlineItem)
{
   static_cast<OutlineItem*>(outlineItem)->close();
}


int PDFOutline_HasKids(XPDFObject outlineItem)
{
   return static_cast<OutlineItem*>(outlineItem)->hasKids();
}


XPDFObject PDFOutline_GetKids(XPDFObject outlineItem)
{
   return static_cast<OutlineItem*>(outlineItem)->getKids();
}


// Note that the returned character buffer must be freed
// when no longer used
char* PDFOutline_GetTitle(XPDFObject outlineItem)
{
   OutlineItem* item = static_cast<OutlineItem*>(outlineItem);
   GString* enc = new GString("Latin1");
   UnicodeMap* uMap = globalParams->getUnicodeMap(enc);
   delete enc;

   GString* title = new GString();
   char buf[8];
   int i, n;
   for (i = 0; i < item->getTitleLength(); i++)
   {
      n = uMap->mapUnicode(item->getTitle()[i], buf, sizeof(buf));
      title->append(buf, n);
   }

   char* result = (char*)malloc((sizeof(char) * title->getLength()) + 1);
   strcpy(result, title->getCString());

   delete title;
   uMap->decRefCnt();

   return result;
}


int PDFOutline_GetTargetPage(XPDFObject outlineItem, XPDFObject pdfDoc)
{
   int page = 0;
   LinkAction* action = static_cast<OutlineItem*>(outlineItem)->getAction();
   LinkDest* dest = 0;

   if (action && (action->getKind() == actionGoTo))
   {
      if (static_cast<LinkGoTo*>(action)->getDest())
      {
         dest = static_cast<LinkGoTo*>(action)->getDest();
      }
      else
      {
         dest = 
            TO_PDFDoc(pdfDoc)->findDest(static_cast<LinkGoTo*>(action)->getNamedDest());
      }
   }

   if (dest)
   {
      if (!dest->isPageRef())
      {
         page = dest->getPageNum();
      }
      else
      {
         Ref ref = dest->getPageRef();
         page = TO_PDFDoc(pdfDoc)->findPage(ref.num, ref.gen);
      }
   }

   return page;
}

/* ----------------------------------------------------------- */

/*
 * Font Management.
 */


void PDFFont_AddFontFile(const char* fontName,
                         const char* fontFile)
{
  //   DisplayFontParam* dfp;
  GString *gsFontName;
  GString *gsFontFile;

   gsFontName = new GString(fontName);
   gsFontFile = new GString(fontFile);

   globalParams->addFontFile(gsFontName, gsFontFile);
}


void PDFFont_FindFontFile(const char* fontName,
                          const char** fontFile)
{
  GString *gFontFile;
  
  *fontFile = NULL;
  gFontFile = globalParams->findFontFile(new GString(fontName));
  if (gFontFile)
    *fontFile = gFontFile->getCString();
}


/* ----------------------------------------------------------- */

/*
 * Renderer
 */

#define TO_SplashOutputDev(object) (static_cast<SplashOutputDev*>(object))
#define TO_SplashBitmap(object) (static_cast<SplashBitmap*>(object))


XPDFObject PDFRender_CreateOutputDevice(XPDFObject pdfDoc)
{
   SplashOutputDev *outputDev;
   SplashColor paperColor;
   
   fprintf(stderr, "DEBUG: creating output device\n"); fflush(stderr);

    paperColor[0] = 0xff;
    paperColor[1] = 0xff;
    paperColor[2] = 0xff;
   
   outputDev = new SplashOutputDev(splashModeRGB8, 1, gFalse, paperColor);  
   outputDev->startDoc(TO_PDFDoc(pdfDoc)->getXRef());

   return outputDev;
}


void PDFRender_DestroyOutputDevice(XPDFObject device)
{
   fprintf(stderr, "DEBUG: destroy output device\n"); fflush(stderr);
   delete TO_SplashOutputDev(device);
}


XPDFObject PDFRender_RenderPage(XPDFObject pdfDoc,
                                XPDFObject device,
                                int page,
                                double dpi,
                                int rotate)
{
   XPDF_AcquireLock();

   if ((page < 0) || (page > TO_PDFDoc(pdfDoc)->getNumPages()))
   {
      fprintf(stderr, "page %d out of range\n", page); fflush(stderr);
      return NULL;
   }

   TO_PDFDoc(pdfDoc)->displayPage(TO_SplashOutputDev(device),
                                  page, dpi, dpi, rotate, gFalse, gFalse, gFalse);
   
   XPDF_ReleaseLock();

   return (XPDFObject)TO_SplashOutputDev(device)->getBitmap();
}


void PDFRender_GetBitmapSize(XPDFObject bitmap, int* width, int* height)
{
   *width  = TO_SplashBitmap(bitmap)->getWidth();
   *height = TO_SplashBitmap(bitmap)->getHeight();
}


void PDFRender_GetRGB(XPDFObject bitmap, unsigned char** buffer)
{
  SplashBitmap *smap = TO_SplashBitmap(bitmap);
  SplashColorPtr row = smap->getDataPtr();
  int height = smap->getHeight();
  int width = smap->getWidth();
  int rowSize = smap->getRowSize();
  SplashColorPtr p;
  unsigned char *bufferPtr;
  int x, y;

  bufferPtr = *buffer;

  for (y = 0; y < height; ++y) {
    p = row;
    
    for (x = 0; x < width; ++x) {
      *bufferPtr++ = splashRGB8R(p);
      *bufferPtr++ = splashRGB8G(p);
      *bufferPtr++ = splashRGB8B(p);
      p += 3;
    }
    
    row += rowSize;
  }
}

/* ----------------------------------------------------------- */

/*
 * Postscript Output
 */

#define TO_PSOutputDev(object) (static_cast<PSOutputDev*>(object))


void OutputPS(void* stream, const char* data, int len)
{
   char* buffer = (char*)malloc((len + 1) * sizeof(char));
   memcpy(buffer, data, len);
   buffer[len] = '\0';

   DPSPrintString(buffer);

   delete buffer;
}


XPDFObject PDFPS_CreateOutputDevice(XPDFObject pdfDoc, int firstPage, int lastPage)
{
   PSOutputDev* psDev = new PSOutputDev(OutputPS,
                                        NULL,
                                        TO_PDFDoc(pdfDoc),
                                        firstPage,
                                        lastPage,
                                        psModePS);

   return psDev;
}


void PDFPS_OutputPages(XPDFObject pdfDoc, XPDFObject device, int firstPage, int lastPage)
{
   if (!pdfDoc)
   {
      fprintf(stderr, "document device is NULL\n");
      fflush(stderr);
      return;
   }

   if (!device)
   {
      fprintf(stderr, "postscript device is NULL\n");
      fflush(stderr);
      return;
   }

   TO_PDFDoc(pdfDoc)->displayPages(TO_PSOutputDev(device),
                                   firstPage,
                                   lastPage,
                                   72,
                                   72,
                                   0,
                                   gFalse,
                                   globalParams->getPSCrop(),
                                   gFalse);
}


void PDFPS_DestroyOutputDevice(XPDFObject device)
{
   if (!device)
   {
      fprintf(stderr, "postscript device is NULL\n");
      fflush(stderr);
      return;
   }

   delete TO_PSOutputDev(device);
   delete globalParams;
}
