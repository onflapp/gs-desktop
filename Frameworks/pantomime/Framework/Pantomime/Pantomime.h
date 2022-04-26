/*
**  Pantomime.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte Ludovic Marcotte
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef _Pantomime_H_Pantomime
#define _Pantomime_H_Pantomime

#import <Foundation/Foundation.h>

#include <Pantomime/CWCacheManager.h>
#include <Pantomime/CWCharset.h>
#include <Pantomime/CWConstants.h>
#include <Pantomime/CWContainer.h>
#include <Pantomime/CWRegEx.h>
#include <Pantomime/CWDNSManager.h>
#include <Pantomime/CWFlags.h>
#include <Pantomime/CWFolder.h>
#include <Pantomime/CWFolderInformation.h>
#include <Pantomime/CWIMAPCacheManager.h>
#include <Pantomime/CWIMAPFolder.h>
#include <Pantomime/CWIMAPMessage.h>
#include <Pantomime/CWIMAPStore.h>
#include <Pantomime/CWInternetAddress.h>
#include <Pantomime/CWISO8859_1.h>
#include <Pantomime/CWISO8859_10.h>
#include <Pantomime/CWISO8859_11.h>
#include <Pantomime/CWISO8859_13.h>
#include <Pantomime/CWISO8859_14.h>
#include <Pantomime/CWISO8859_15.h>
#include <Pantomime/CWISO8859_2.h>
#include <Pantomime/CWISO8859_3.h>
#include <Pantomime/CWISO8859_4.h>
#include <Pantomime/CWISO8859_5.h>
#include <Pantomime/CWISO8859_6.h>
#include <Pantomime/CWISO8859_7.h>
#include <Pantomime/CWISO8859_8.h>
#include <Pantomime/CWISO8859_9.h>
#include <Pantomime/CWKOI8_R.h>
#include <Pantomime/CWKOI8_U.h>
#include <Pantomime/CWLocalCacheManager.h>
#include <Pantomime/CWLocalFolder.h>
#include <Pantomime/CWLocalFolder+maildir.h>
#include <Pantomime/CWLocalFolder+mbox.h>
#include <Pantomime/CWLocalMessage.h>
#include <Pantomime/CWLocalStore.h>
#ifdef MACOSX
#include <Pantomime/CWMacOSXGlue.h>
#endif
#include <Pantomime/CWMD5.h>
#include <Pantomime/CWMessage.h>
#include <Pantomime/CWMIMEMultipart.h>
#include <Pantomime/CWMIMEUtility.h>
#include <Pantomime/NSData+Extensions.h>
#include <Pantomime/NSFileManager+Extensions.h>
#include <Pantomime/NSString+Extensions.h>
#include <Pantomime/CWParser.h>
#include <Pantomime/CWPart.h>
#include <Pantomime/CWPOP3CacheManager.h>
#include <Pantomime/CWPOP3CacheObject.h>
#include <Pantomime/CWPOP3Folder.h>
#include <Pantomime/CWPOP3Message.h>
#include <Pantomime/CWPOP3Store.h>
#include <Pantomime/CWSendmail.h>
#include <Pantomime/CWService.h>
#include <Pantomime/CWSMTP.h>
#include <Pantomime/CWStore.h>
#include <Pantomime/CWTCPConnection.h>
#include <Pantomime/CWTransport.h>
#include <Pantomime/CWUUFile.h>
#include <Pantomime/CWVirtualFolder.h>
#include <Pantomime/CWWINDOWS_1250.h>
#include <Pantomime/CWWINDOWS_1251.h>
#include <Pantomime/CWWINDOWS_1252.h>
#include <Pantomime/CWWINDOWS_1253.h>
#include <Pantomime/CWWINDOWS_1254.h>

#endif // _Pantomime_H_Pantomime
