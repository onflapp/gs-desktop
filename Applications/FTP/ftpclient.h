/*
 Project: FTP

 Copyright (C) 2005-2015 Riccardo Mottola

 Author: Riccardo Mottola

 Created: 2005-03-30

 FTP client class

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

 */

#include <string.h> /* for bcopy or memcpy */

#ifdef _WIN32
#include <windows.h>
#include <winsock.h>
#define BCOPY(SRC, DST, LEN) memcpy(DST, SRC, LEN)
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#define BCOPY(SRC, DST, LEN) bcopy(SRC, DST, LEN)
#endif /* WIN32 */

#include <stdio.h>

#import <Foundation/Foundation.h>
#import "client.h"
#import "localclient.h"
#import "fileElement.h"


#define MAX_SOCK_BUFF 1024

#define MAX_DIR_RECURSION 5

#define ERR_COULDNT_RESOLVE -1
#define ERR_SOCKET_FAIL -2
#define ERR_CONNECT_FAIL -3
#define ERR_GESOCKNAME_FAIL -4
#define ERR_READ_FAIL -5

/** connection types: PASV or PORT */
typedef enum { defaultMode, portMode, passiveMode } connectionModes;

/** private structure to use a socket like it was a file stream */
typedef struct
{
    int socket;
    int position;
    int len;
    char buffer[MAX_SOCK_BUFF];
} streamStruct;

@interface FtpClient : Client
{
    int                 userDataPort;
    int                 serverDataPort;
    int                 dataSocket;
    int                 controlSocket;
    int                 localSocket;
    streamStruct        dataStream;
    streamStruct        ctrlStream;
    struct sockaddr_in  remoteSockName;
    struct sockaddr_in  localSockName;
    struct sockaddr_in  dataSockName;
    BOOL                usesPassive;
    BOOL                usesPorts;
    @protected BOOL     connected;
}

- (id)initWithController:(id)cont :(connectionModes)cMode;
- (void)setPortDefault;
- (void)setPortPort;
- (void)setPortPassive;

- (void)logIt:(NSString *)str;

/** reads a reply from the control socket */
- (int)readReply :(NSMutableArray **)result;

- (int)writeLine:(NSString *)line;
- (int)writeLine:(NSString *)line byLoggingIt:(BOOL)doLog;
- (oneway void)retrieveFile:(FileElement *)file to:(LocalClient *)localClient;
- (BOOL)retrieveFile:(FileElement *)file to:(LocalClient *)localClient beingAt:(int)depth;
- (oneway void)storeFile:(FileElement *)file from:(LocalClient *)localClient;
- (BOOL)storeFile:(FileElement *)file from:(LocalClient *)localClient beingAt:(int)depth;

- (int)connect:(int)port :(char *)server;
- (void)disconnect;
- (int)authenticate:(NSString *)user :(NSString *)pass;
- (int)initDataConn;
- (int)initDataStream;
- (int)closeDataConn;
- (void)closeDataStream;

@end


