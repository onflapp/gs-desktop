#
#  GNUstep Makefile for the Pantomime Framework
#
#  Copyright (C) 2001-2006 Ludovic Marcotte
#		 2013-2014 Riccardo Mottola
#
#  Author: Ludovic Marcotte <ludovic@Sophos.ca>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details. 
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = Pantomime

PANTOMIME_MAJOR_VERSION=1
PANTOMIME_MINOR_VERSION=3
PANTOMIME_SUBMINOR_VERSION=0
PANTOMIME_VERSION=${PANTOMIME_MAJOR_VERSION}.${PANTOMIME_MINOR_VERSION}.${PANTOMIME_SUBMINOR_VERSION}
VERSION=${PANTOMIME_VERSION}
Pantomime_INTERFACE_VERSION=${PANTOMIME_MAJOR_VERSION}.${PANTOMIME_MINOR_VERSION}


# The Objective-C source files to be compiled
Pantomime_OBJC_FILES = \
	CWCacheManager.m \
	CWCharset.m \
	CWConstants.m \
	CWContainer.m \
	CWDNSManager.m \
	CWFlags.m \
	CWFolder.m \
	CWFolderInformation.m \
	CWIMAPCacheManager.m \
	CWIMAPFolder.m \
	CWIMAPMessage.m \
	CWIMAPStore.m \
	CWInternetAddress.m \
	CWISO8859_1.m \
	CWISO8859_2.m \
	CWISO8859_3.m \
	CWISO8859_4.m \
	CWISO8859_5.m \
	CWISO8859_6.m \
	CWISO8859_7.m \
	CWISO8859_8.m \
	CWISO8859_9.m \
	CWISO8859_10.m \
	CWISO8859_11.m \
	CWISO8859_13.m \
	CWISO8859_14.m \
	CWISO8859_15.m \
	CWKOI8_R.m \
	CWKOI8_U.m \
	CWLocalCacheManager.m \
	CWLocalFolder.m \
	CWLocalFolder+maildir.m \
	CWLocalFolder+mbox.m \
	CWLocalMessage.m \
	CWLocalStore.m \
	CWMD5.m \
	CWMessage.m \
	CWMIMEMultipart.m \
	CWMIMEUtility.m \
	CWParser.m \
	CWPart.m \
	CWPOP3CacheManager.m \
	CWPOP3CacheObject.m \
	CWPOP3Folder.m \
	CWPOP3Message.m \
	CWPOP3Store.m \
	CWRegEx.m \
	CWService.m \
	CWSendmail.m \
	CWSMTP.m \
	CWTCPConnection.m \
	CWURLName.m \
	CWUUFile.m \
	CWVirtualFolder.m \
	CWWINDOWS_1250.m \
	CWWINDOWS_1251.m \
	CWWINDOWS_1252.m \
	CWWINDOWS_1253.m \
	CWWINDOWS_1254.m \
	NSData+Extensions.m \
	NSFileManager+Extensions.m \
	NSScanner+Extensions.m \
	NSString+Extensions.m \
	io.m \


# The Headers that are to be installed with the Pantomime Framework
Pantomime_HEADER_FILES = \
	io.h \
	CWCacheManager.h \
	CWCharset.h \
	CWConnection.h \
	CWConstants.h \
	CWContainer.h \
	CWDNSManager.h \
	CWFlags.h \
	CWFolder.h \
	CWFolderInformation.h \
	CWIMAPCacheManager.h \
	CWIMAPFolder.h \
	CWIMAPMessage.h \
	CWIMAPStore.h \
	CWInternetAddress.h \
	CWISO8859_1.h \
	CWISO8859_2.h \
	CWISO8859_3.h \
	CWISO8859_4.h \
	CWISO8859_5.h \
	CWISO8859_6.h \
	CWISO8859_7.h \
	CWISO8859_8.h \
	CWISO8859_9.h \
	CWISO8859_10.h \
	CWISO8859_11.h \
	CWISO8859_13.h \
	CWISO8859_14.h \
	CWISO8859_15.h \
	CWKOI8_R.h \
	CWKOI8_U.h \
	CWLocalCacheManager.h \
	CWLocalFolder.h \
	CWLocalFolder+maildir.h \
	CWLocalFolder+mbox.h \
	CWLocalMessage.h \
	CWLocalStore.h \
	CWMD5.h \
	CWMIMEMultipart.h \
	CWMIMEUtility.h \
	CWMessage.h \
	CWParser.h \
	CWPart.h \
	CWPOP3CacheManager.h \
	CWPOP3CacheObject.h \
	CWPOP3Folder.h \
	CWPOP3Message.h \
	CWPOP3Store.h \
	CWRegEx.h \
	CWSendmail.h \
	CWService.h \
	CWSMTP.h \
	CWStore.h \
	CWTCPConnection.h \
	CWTransport.h \
	CWURLName.h \
	CWUUFile.h \
	CWVirtualFolder.h \
	CWWINDOWS_1250.h \
	CWWINDOWS_1251.h \
	CWWINDOWS_1252.h \
	CWWINDOWS_1253.h \
	CWWINDOWS_1254.h \
	NSData+Extensions.h \
	NSFileManager+Extensions.h \
	NSScanner+Extensions.h \
	NSString+Extensions.h \
	Pantomime.h

Pantomime_RESOURCE_FILES = \
        ../../Resources/*.lproj

Pantomime_LANGUAGES = \
        ../../Resources/English\
        ../../Resources/German

Pantomime_LOCALIZED_RESOURCE_FILES = Localizable.strings

ADDITIONAL_INCLUDE_DIRS = -I..
ADDITIONAL_OBJCFLAGS += -DHAVE_ICONV -Wall -Wno-import
ifeq ($(GNUSTEP_TARGET_OS),mingw32)
#ADDITIONAL_GUI_LIBS += -lregex -liconv -lssl -lcrypto
LIBRARIES_DEPEND_UPON += $(FND_LIBS) $(OBJC_LIBS) -lregex -liconv -lssl
else
#ADDITIONAL_LDFLAGS += -lssl -lcrypto
LIBRARIES_DEPEND_UPON += $(FND_LIBS) $(OBJC_LIBS) -lssl
endif

# Under Solaris, we include SSL headers / libraries 
ifeq ($(findstring solaris, $(GNUSTEP_TARGET_OS)), solaris)
ADDITIONAL_OBJCFLAGS += -I/usr/local/ssl/include
ADDITIONAL_LDFLAGS += -L/usr/local/ssl/lib
LIBRARIES_DEPEND_UPON +=  -lresolv -lsocket -lnsl
endif

include $(GNUSTEP_MAKEFILES)/framework.make

