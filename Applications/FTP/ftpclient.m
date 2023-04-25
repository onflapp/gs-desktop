/*
 Project: FTP

 Copyright (C) 2005-2016 Riccardo Mottola

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

/*
 * this class handles acts as a remote client with the FTP server.
 * the connection modes, default, active (port) and passive
 * can be set using the three setPort* methods
 */


#import "ftpclient.h"
#import "AppController.h"
#import "fileElement.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

#ifdef _WIN32
#include <fcntl.h>
#else
#include <arpa/inet.h>  /* for inet_ntoa and similar */
#include <netdb.h>
#define INVALID_SOCKET -1
#define closesocket close
#endif /* WIN32 */


#define MAX_CONTROL_BUFF 2048
#define MAX_DATA_BUFF 2048

#if defined(__linux__) || defined (__BSD_VISIBLE) || defined (NetBSD) || defined (__APPLE__)
#define socklentype socklen_t
#else
#define socklentype int
#endif

void initStream(streamStruct *ss, int socket)
{
  ss->socket = socket;
  ss->position = 0;
  ss->len = 0;
  ss->buffer[0] = '\0';
}

int getChar(streamStruct* ss)
{
  int result;
  BOOL gotEof;

  gotEof = NO;
  if (ss->position == ss->len)
    {
      int read;

      read = recv(ss->socket, ss->buffer, MAX_SOCK_BUFF, 0);
      if (read > 0)
        {
          ss->len = read;
          ss->position = 0;
        }
      else if (read == 0)
        {
          ss->len = 0;
          ss->position = 0;
          ss->buffer[0] = '\0';
          gotEof = YES;
        } 
      else
        {
          ss->len = 0;
          ss->position = 0;
          NSLog(@"error sock read");
          perror("getChar:read");
          ss->buffer[0] = '\0';
          gotEof = YES;
        }
    }
  if (gotEof)
    {
      result = EOF;
    }
  else
    {    
      result = ss->buffer[ss->position];
      ss->position++;
    }
  return result;
}

@implementation FtpClient

+ (void)connectWithPorts:(NSArray *)portArray
{
    NSAutoreleasePool *pool;
    NSConnection *serverConnection;
    FtpClient    *serverObject;
	
    pool = [[NSAutoreleasePool alloc] init];
	
    serverConnection = [NSConnection connectionWithReceivePort: [portArray objectAtIndex:0]
                                                      sendPort:[portArray objectAtIndex:1]];
	
    serverObject = [self alloc];
    [(id)[serverConnection rootProxy] setServer:serverObject];
    [serverObject release];
	
    [[NSRunLoop currentRunLoop] run];
    [pool release];
	
    return;
}

- (id)initWithController:(id)cont :(connectionModes)cMode
{
    if (!(self =[super initWithController:cont]))
        return nil;

    switch (cMode)
    {
        case defaultMode:
            [self setPortDefault];
            break;
        case portMode:
            [self setPortPort];
            break;
        case passiveMode:
            [self setPortPassive];
            break;
        default:
            [self setPortDefault];
    }
#ifdef _WIN32
    WORD wVersionRequested;
    WSADATA wsaData;
    wVersionRequested = MAKEWORD( 1, 1 );

    WSAStartup(wVersionRequested, &wsaData);
#endif
    connected = NO;
    return self;
}

/* three methods to set the connection handling */
- (void)setPortDefault
{
    usesPassive = NO;
    usesPorts = NO;
}

- (void)setPortPort
{
    usesPassive = NO;
    usesPorts = YES;
}

- (void)setPortPassive
{
    usesPassive = YES;
    usesPorts = NO;
}

/*
 changes the current working directory
 this directory is implicit in many other actions
 */
- (void)changeWorkingDir:(NSString *)dir
{
  NSString       *tempStr;
  NSMutableArray *reply;

  if (!connected)
    return;

  tempStr = [@"CWD " stringByAppendingString:dir];
  [self writeLine:tempStr];
  if ([self readReply:&reply] == 250)
    [super changeWorkingDir:dir];
  else
    NSLog(@"cwd failed");
}

/* if we have a valid controller, we suppose it respons to appendTextToLog */
/* RM: is there a better way to append a newline? */
- (void)logIt:(NSString *)str
{
    NSMutableString *tempStr;
    
    if (controller == NULL)
        return;
    tempStr = [NSMutableString stringWithCapacity:([str length] + 1)];
    [tempStr appendString:str];
    [tempStr appendString:@"\n"];
    [controller appendTextToLog:tempStr];
}


/*
 read the reply of a command, be it single or multi-line
 returned is the first numerical code
 NOTE: the parser is NOT robust in handling errors
 */
#define NUMCODELEN 4

- (int)readReply :(NSMutableArray **)result
{
    char  buff[MAX_CONTROL_BUFF];
    int   readBytes;
    int   ch;
    /* the first numerical code, in case of multi-line output it is followed
       by '-' in the first line and by ' ' in the last line */
    char  numCodeStr[NUMCODELEN];
    int   numCode;
    int   startNumCode;
    char  separator;
    enum  states { N1, N2, N3, SEPARATOR, CHARS, GOTR, END };
    enum  states state;
    BOOL  multiline;

    readBytes = 0;
    state = N1;
    separator = 0;
    multiline = NO;
    startNumCode = numCode = 0;
    *result = [NSMutableArray arrayWithCapacity:1];

    // TODO: protect against numCodeStr overflow
    while (!(state == END))
    {
        ch = getChar(&ctrlStream);
	//NSLog(@"read char: %c", ch);
        if (ch == EOF)
            state = END;

        switch (state)
        {
            case N1:
                buff[readBytes] = ch;
                if (readBytes < NUMCODELEN)
                    numCodeStr[readBytes] = ch;
                readBytes++;
                if (ch == ' ') /* skip internal lines of multi-line */
                    state = CHARS;
                else
                    state = N2;
                break;
            case N2:
                buff[readBytes] = ch;
                numCodeStr[readBytes] = ch;
                readBytes++;
                state = N3;
                break;
            case N3:
                buff[readBytes] = ch;
                numCodeStr[readBytes] = ch;
                readBytes++;
                state = SEPARATOR;
                break;
            case SEPARATOR:
                buff[readBytes] = ch;
                numCodeStr[readBytes] = '\0';
                readBytes++;
                numCode = atoi(numCodeStr);
                separator = ch;
                state = CHARS;
                break;
            case CHARS:
                if (ch == '\r')
                    state = GOTR;
                else
                {
                    buff[readBytes++] = ch;
                }
                break;
            case GOTR:
                if (ch == '\n')
                {
                    buff[readBytes] = '\0';
                    [self logIt:[NSString stringWithCString:buff]];
                    [*result addObject:[NSString stringWithCString:buff]];
                    readBytes = 0;
                    if (separator == ' ')
                    {
                        if (multiline)
                        {
                            if (numCode == startNumCode)
                                state = END;
                        } else
                        {
                            startNumCode = numCode;
                            state = END;
                        }
                    } else
                    {
                        startNumCode = numCode;
                        multiline = YES;
                        state = N1;
                    }
                }
                break;
            case END:
                NSLog(@"EOF reached prematurely");
		startNumCode = -1;
                break;
            default:
                NSLog(@"Duh, a case default in the readReply parser");
        }
    }
    [*result retain];
    return startNumCode;
}

/*
 writes a single line to the control connection, logging it always
 */
- (int)writeLine:(NSString *)line
{
  return [self writeLine:line byLoggingIt:YES];
}

/*
 writes a single line to the control connection
 */
- (int)writeLine:(NSString *)line byLoggingIt:(BOOL)doLog
{
  int  sentBytes;
  int  bytesToSend;
  char command[MAX_CONTROL_BUFF];
  NSString *commandStr;

  commandStr = [line stringByAppendingString:@"\r\n"];
  [commandStr getCString:command];
  bytesToSend = strlen(command);
  if (doLog)
    [self logIt:line];
  if ((sentBytes = send(controlSocket, command, bytesToSend, 0)) < bytesToSend)
    NSLog(@"sent %d out of %d", sentBytes, bytesToSend);
  return sentBytes;
}


- (int)setTypeToI
{
  NSMutableArray *reply;
  int            retVal;
  
  retVal = [self writeLine:@"TYPE I"];
  if (retVal > 0)
    {
      [self readReply:&reply];
      [reply release];
    }
  
  return retVal;
}

- (int)setTypeToA
{
  NSMutableArray *reply;
  int            retVal;
  
  retVal = [self writeLine:@"TYPE A"];
  if (retVal > 0)
    {
      [self readReply:&reply];
      [reply release];
    }
  
  return retVal;
}

- (oneway void)retrieveFile:(FileElement *)file to:(LocalClient *)localClient
{
  BOOL gotFile;
  
  gotFile = [self retrieveFile:file to:localClient beingAt:0];
  
  [controller fileRetrieved:gotFile];
}

- (BOOL)retrieveFile:(FileElement *)file to:(LocalClient *)localClient beingAt:(int)depth;
{
  NSString           *fileName;
  unsigned long long fileSize;
  NSString           *command;
  char               buff[MAX_DATA_BUFF];
  FILE               *localFileStream;
  int                bytesRead;
  NSMutableArray     *reply;
  unsigned int       minimumPercentIncrement;
  unsigned int       progressIncBytes;
  int                replyCode;
  unsigned long long totalBytes;
  NSString           *localPath;
  BOOL               gotFile;

  fileName = [file name];
  fileSize = [file size];
  minimumPercentIncrement = fileSize / 100; // we should guard against maxint

  localPath = [[localClient workingDir] stringByAppendingPathComponent:fileName];

  if ([file isDir])
    {
      NSString     *pristineLocalPath;  /* original path */
      NSString     *pristineRemotePath; /* original path */
      NSArray      *dirList;
      NSString     *remoteDir;
      NSEnumerator *en;
      FileElement  *fEl;

      if (depth > MAX_DIR_RECURSION)
        {
          NSLog(@"Max depth reached: %d", depth);
          return NO;
        }
      
        pristineLocalPath = [[localClient workingDir] retain];
        pristineRemotePath = [[self workingDir] retain];
        
        remoteDir = [[self workingDir] stringByAppendingPathComponent:fileName];
        [self changeWorkingDir:remoteDir];

        if ([localClient createNewDir:localPath] == YES)
          {
            [localClient changeWorkingDir:localPath];
    
            dirList = [self dirContents];
            en = [dirList objectEnumerator];
            while ((fEl = [en nextObject]))
              {
                NSLog(@"recurse, download : %@", [fEl name]);
                [self retrieveFile:fEl to:localClient beingAt:depth+1];
              }
          }
        /* we get back were we started */
        [self changeWorkingDir:pristineRemotePath];
        [localClient changeWorkingDir:pristineLocalPath];
        [pristineLocalPath release];
        [pristineRemotePath release];
        return YES;
    }

    /* lets settle to a plain binary standard type */
    [self setTypeToI];
    
    if ([self initDataConn] < 0)
    {
        NSLog(@"error initiating data connection, retrieveFile");
        return NO;
    }

    command = [@"RETR " stringByAppendingString:fileName];
    [self writeLine:command];
    replyCode = [self readReply:&reply];
    NSLog(@"%d reply is %@: ", replyCode, [reply objectAtIndex:0]);

    if(replyCode != 150)
      {
	if (replyCode >= 400)
	  {
	    [controller showAlertDialog:[reply objectAtIndex:0]];
	    [self logIt: [reply objectAtIndex:0]];
	  }
	else
	  {
	    [controller showAlertDialog:@"Unexpected server error."];
	    NSLog(@"Unexpected condition in retrieve");
	  }
        return NO; /* we have an error or some unexpected condition */
      }
    else
      {
	NSString *s;
	NSRange bytesR;

	/* we try to parse the response which may look like this:
	   150 Opening BINARY mode data connection for core.current.tar.bz2 (10867411 bytes)
	   and extract the transfer size */
	s = [reply objectAtIndex:0];
	bytesR = [s rangeOfString:@")" options:NSBackwardsSearch];
	if (bytesR.location > 0)
	  {
	    NSRange leftParR;
	    NSString *sizeString;
	    long long tempLL;
	    unsigned long long tempSize;

	    NSLog(@"recognized a 150 response, looking for size in: %@", s);
	    leftParR = [s rangeOfString:@"(" options:NSBackwardsSearch];
	    if (leftParR.location > 0)
	      {
		sizeString = [s substringWithRange:NSMakeRange(leftParR.location+1, bytesR.location-leftParR.location)];
	        [[NSScanner scannerWithString: sizeString] scanLongLong:&tempLL];
		NSLog(@"parsed response size from %@ is %lld", sizeString, tempLL);
		if (tempLL > 0)
		  {
		    tempSize = (unsigned long long)tempLL;
		    if (fileSize == 0)
		      fileSize = tempSize;
		    else if (fileSize != tempSize)
		      NSLog(@"Apparently the server is lying! list size is: %llu, transfer size is: %lld", fileSize, tempSize);
		  }
	      }
	  }
      }
    [reply release];
    
    if ([self initDataStream] < 0)
    {
        [controller showAlertDialog:@"Unexpected connection error."];
        return NO;
    }
    
    localFileStream = fopen([localPath cString], "wb");
    if (localFileStream == NULL)
    {
        [controller showAlertDialog:@"Opening of local file failed.\nCheck permissions and free space."];
        perror("local fopen failed");
        return NO;
    }
    
    totalBytes = 0;
    progressIncBytes = 0;
    gotFile = NO;
    [controller setTransferBegin:fileName :fileSize];
    while (!gotFile)
    {
        bytesRead = recv(localSocket, buff, MAX_DATA_BUFF, 0);
        if (bytesRead == 0)
            gotFile = YES;
        else if (bytesRead < 0)
        {
            gotFile = YES;
            NSLog(@"error on socket read, retrieve file");
        } else
        {
            if (fwrite(buff, sizeof(char), bytesRead, localFileStream) < bytesRead)
            {
                NSLog(@"file write error, retrieve file");
            }
            totalBytes += bytesRead;
            progressIncBytes += bytesRead;
            if (progressIncBytes > minimumPercentIncrement) 
            {
                [controller setTransferProgress:[NSNumber numberWithUnsignedLongLong:totalBytes]];
                progressIncBytes = 0;
            }
        }
    }

    [controller setTransferEnd:[NSNumber numberWithUnsignedLongLong:totalBytes]];
    
    fclose(localFileStream);
    [self closeDataStream];
    [self readReply:&reply];
    [reply release];

    return gotFile;
}

- (oneway void)storeFile:(FileElement *)file from:(LocalClient *)localClient
{
  BOOL gotFile;
  
  gotFile = [self storeFile:file from:localClient beingAt:0];
  
  [controller fileStored:gotFile];
}

- (BOOL)storeFile:(FileElement *)file from:(LocalClient *)localClient beingAt:(int)depth
{
  NSString           *fileName;
  unsigned long long fileSize;
  NSString           *command;
  char               buff[MAX_DATA_BUFF];
  FILE               *localFileStream;
  NSMutableArray     *reply;
  int                bytesRead;
  unsigned int       minimumPercentIncrement;
  unsigned int       progressIncBytes;
  int                replyCode;
  unsigned long long totalBytes;
  NSString           *localPath;
  BOOL               gotFile;

  fileName = [file name];
  fileSize = [file size];
  minimumPercentIncrement = fileSize / 100; // we should guard against maxint

  localPath = [file path];

  if ([file isDir])
    {
      NSString     *pristineLocalPath;  /* original path */
      NSString     *pristineRemotePath; /* original path */
      NSArray      *dirList;
      NSString     *remotePath;
      NSEnumerator *en;
      FileElement  *fEl;

      if (depth > MAX_DIR_RECURSION)
        {
          NSLog(@"Max depth reached: %d", depth);
          return NO;
        }

      pristineLocalPath = [[localClient workingDir] retain];
      pristineRemotePath = [[self workingDir] retain];
      
      remotePath = [pristineRemotePath stringByAppendingPathComponent:fileName];
      [localClient changeWorkingDir:localPath];
      NSLog(@"local dir changed: %@", [localClient workingDir]);
      
      if ([self createNewDir:remotePath] == YES)
        {
            NSLog(@"remote dir created successfully");
            [self changeWorkingDir:remotePath];

            dirList = [localClient dirContents];
            en = [dirList objectEnumerator];
            while ((fEl = [en nextObject]))
            {
                NSLog(@"recurse, upload : %@", [fEl name]);
                [self storeFile:fEl from:localClient beingAt:(depth+1)];
            }
        }
        /* we get back were we started */
        [self changeWorkingDir:pristineRemotePath];
        [localClient changeWorkingDir:pristineLocalPath];
        [pristineLocalPath release];
        [pristineRemotePath release];
        return YES;
    }
    
    /* lets settle to a plain binary standard type */
    [self setTypeToI];

    if ([self initDataConn] < 0)
    {
        [controller showAlertDialog:@"Error initiating the Data Connection."];
        NSLog(@"error initiating data connection, storeFile");
        return NO;
    }

    command = [@"STOR " stringByAppendingString:fileName];
    [self writeLine:command];
    replyCode = [self readReply:&reply];
    NSLog(@"%d reply is %@: ", replyCode, [reply objectAtIndex:0]);

    if (replyCode >= 400 && replyCode <= 559)
    {
        [controller showAlertDialog:[reply objectAtIndex:0]];
        [self logIt: [reply objectAtIndex:0]];
        [reply release];
        return NO;
    }
    [reply release];

    
    if ([self initDataStream] < 0)
    {
        [controller showAlertDialog:@"Unexpected connection error."];
        return NO;
    }


    localFileStream = fopen([localPath cString], "rb");
    if (localFileStream == NULL)
    {
        [controller showAlertDialog:@"Opening of local file failed.\nCheck permissions."];
        perror("local fopen failed");
        return NO;
    }

    totalBytes = 0;
    progressIncBytes = 0;
    gotFile = NO;
    [controller setTransferBegin:fileName :fileSize];
    while (!gotFile)
    {
        bytesRead = fread(buff, sizeof(char), MAX_DATA_BUFF, localFileStream);
        if (bytesRead == 0)
        {
            gotFile = YES;
            if (!feof(localFileStream))
                NSLog(@"error on file read, store file");
            else
                NSLog(@"feof");
        } else
        {
          int sentBytes;
          
          if ((sentBytes = send(localSocket, buff, bytesRead, 0)) < bytesRead)
            {
                NSLog(@"socket write error, store file. Wrote %d of %d", sentBytes, bytesRead);
            }
            totalBytes += bytesRead;
            progressIncBytes += bytesRead;
            if (progressIncBytes > minimumPercentIncrement) 
            {
                [controller setTransferProgress:[NSNumber numberWithUnsignedLongLong:totalBytes]];
                progressIncBytes = 0;
            }
        }
    }
    [controller setTransferEnd:[NSNumber numberWithUnsignedLongLong:totalBytes]];
    
    fclose(localFileStream);
    [self closeDataStream];
    [self readReply:&reply];
    [reply release];
  return gotFile;
}

- (BOOL)deleteFile:(FileElement *)file beingAt:(int)depth
{
  NSString           *fileName;
  NSString           *command;
  NSMutableArray     *reply;
  int                replyCode;
  
  fileName = [file name];
  
  if ([file isDir])
    {
      NSString     *pristineRemotePath; /* original path */
      NSArray      *dirList;
      NSString     *remotePath;
      NSEnumerator *en;
      FileElement  *fEl;

        if (depth > 3)
        {
            NSLog(@"Max depth reached: %d", depth);
            return NO;
        }

        pristineRemotePath = [[self workingDir] retain];

        remotePath = [pristineRemotePath stringByAppendingPathComponent:fileName];

        NSLog(@"remote dir created successfully");
        [self changeWorkingDir:remotePath];

        dirList = [self dirContents];
        en = [dirList objectEnumerator];
        while ((fEl = [en nextObject]))
        {
            NSLog(@"recurse, delete : %@", [fEl name]);
            [self deleteFile:fEl beingAt:(depth+1)];
        }

        /* we get back were we started */
        [self changeWorkingDir:pristineRemotePath];
        [pristineRemotePath release];
    }

    command = [@"DELE " stringByAppendingString:fileName];
    [self writeLine:command];
    replyCode = [self readReply:&reply];
    NSLog(@"%d reply is %@: ", replyCode, [reply objectAtIndex:0]);
    
    if(replyCode >= 400)
      {
	[controller showAlertDialog:[reply objectAtIndex:0]];
        [self logIt: [reply objectAtIndex:0]];
	[reply release];
        return NO; /* we have an error or some unexpected condition */
      }
    [reply release];
    return YES;
}

/* initialize a connection */
/* set up and connect the control socket */
- (int)connect:(int)port :(char *)server
{
    struct hostent      *hostentPtr;
    socklentype         addrLen; /* socklen_t on some systems? */
    NSMutableArray      *reply;

    NSLog(@"connect to %s : %d", server, port);

    if((hostentPtr = gethostbyname(server)) == NULL)
    {
        NSLog(@"Could not resolve %s", server);
        return ERR_COULDNT_RESOLVE;
    }
    BCOPY((char *)hostentPtr->h_addr, (char *)&remoteSockName.sin_addr, hostentPtr->h_length);
    remoteSockName.sin_family = PF_INET;
    remoteSockName.sin_port = htons(port);

    if ((controlSocket = socket(PF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
    {
        perror("socket failed: ");
        return ERR_SOCKET_FAIL;
    }
    if (connect(controlSocket, (struct sockaddr*) &remoteSockName, sizeof(remoteSockName)) < 0)
    {
        perror("connect failed: ");
        return ERR_CONNECT_FAIL;
    }

    /* we retrieve now the local name of the created socked */
    /* the local port is for example important as default data port */
    addrLen = sizeof(localSockName);
    if (getsockname(controlSocket, (struct sockaddr *)&localSockName, &addrLen) < 0)
    {
        perror("ftpclient: getsockname");
        return ERR_GESOCKNAME_FAIL;
    }
    
    initStream(&ctrlStream, controlSocket);
    if([self readReply :&reply] < 0)
      return ERR_READ_FAIL;
    [reply release];
    return 0;
}

- (void)disconnect
{
  NSMutableArray *reply;
    
  [self writeLine:@"QUIT"];
  [self readReply:&reply];
  connected = NO;
  closesocket(controlSocket);
}

- (int)authenticate:(NSString *)user :(NSString *)pass
{
    NSString       *tempStr;
    NSMutableArray *reply;
    int            replyCode;


    tempStr = [@"USER " stringByAppendingString: user];
    if ([self writeLine:tempStr] < 0)
      return -2; /* we couldn't write */
    replyCode = [self readReply:&reply];
    if (replyCode == 530)
    {
        NSLog(@"Not logged in: %@", [reply objectAtIndex:0]);
        [reply release];
        [self disconnect];
        return -1;
    }
    [reply release];
    
    tempStr = [@"PASS " stringByAppendingString: pass];
    if ([self writeLine:tempStr byLoggingIt:NO] < 0)
      return -2; /* we couldn't write */
    replyCode = [self readReply:&reply];
    if (replyCode == 530)
    {
        NSLog(@"Not logged in: %@", [reply objectAtIndex:0]);
        [reply release];
        [self disconnect];
        return -1;
    }
    [reply release];
    
    connected = YES;

    /* get home directory as dir we first connected to */
    [self writeLine:@"PWD"];
    [self readReply:&reply];
    if ([reply count] >= 1)
    {
        NSString *line;
        unsigned int length;
        unsigned int first;
        unsigned int last;
        unsigned int i;
        
        line = [reply objectAtIndex:0];

        length = [line length];
        i = 0;
        while (i < length && ([line characterAtIndex:i] != '\"'))
            i++;
        first = i;
        if (first < length)
        {
            first++;
            i = length-1;
            while (i > 0 &&  ([line characterAtIndex:i] != '\"'))
                i--;
            last = i;
            homeDir = [[line substringWithRange: NSMakeRange(first, last-first)] retain];
            NSLog(@"homedir: %@", homeDir);
        } else
            homeDir = nil;
    }
    return 0;
}

/* initialize the data connection */
- (int)initDataConn
{
    socklentype addrLen; /* socklen_t on some systems ? */
    const int         socketReuse = 1;

    /* passive mode */
    if (usesPassive)
    {
        NSMutableArray *reply;
        int            replyCode;
        NSScanner      *addrScan;
        int            a1, a2, a3, a4;
        int            p1, p2;
        
        if ((dataSocket = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
        {
            perror("socket in initDataConn");
            return -1;
        }

        [self writeLine:@"PASV"];
        replyCode = [self readReply:&reply];
        if (replyCode != 227)
        {
            NSLog(@"passive mode failed");
            return -1;
        }
        NSLog(@"pasv reply is: %d %@", replyCode, [reply objectAtIndex:0]);

        addrScan = [NSScanner scannerWithString:[reply objectAtIndex:0]];
        [addrScan setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
        if ([addrScan scanInt:NULL] == NO)
        {
            NSLog(@"error while scanning pasv address");
            return -1;
        }
        NSLog(@"skipped result code");
        if ([addrScan scanInt:&a1] == NO)
        {
            NSLog(@"error while scanning pasv address");
            return -1;
        }
        NSLog(@"got first");
        if ([addrScan scanInt:&a2] == NO)
        {
            NSLog(@"error while scanning pasv address");
            return -1;
        }
        NSLog(@"got second");
        if ([addrScan scanInt:&a3] == NO)
        {
            NSLog(@"error while scanning pasv address");
            return -1;
        }
        if ([addrScan scanInt:&a4] == NO)
        {
            NSLog(@"error while scanning pasv address");
            return -1;
        }
        if ([addrScan scanInt:&p1] == NO)
        {
            NSLog(@"error while scanning pasv port");
            return -1;
        }
        if ([addrScan scanInt:&p2] == NO)
        {
            NSLog(@"error while scanning pasv port");
            return -1;
        }
        NSLog(@"read: %d %d %d %d : %d %d", a1, a2, a3, a4, p1, p2);

        dataSockName.sin_family = AF_INET;
        dataSockName.sin_addr.s_addr = htonl((a1 << 24) | (a2 << 16) | (a3 << 8) | a4);
        dataSockName.sin_port = htons((p1 << 8) | p2);

        if (connect(dataSocket, (struct sockaddr *) &dataSockName, sizeof(dataSockName)) < 0)
        {
            perror("connect in initDataConn");
            return -1;
        }
        
        return 0;
    }

    /* active mode, default or PORT arbitrated */
    dataSockName = localSockName;

    /* system picks up a port */
    if (usesPorts == YES)
        dataSockName.sin_port = 0;
    
    if ((dataSocket = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
    {
        perror("socket in initDataConn");
        return -1;
    }

    /* if we use the default port, we set the option to reuse the port */
    /* linux is happier if we set both ends that way */
    if (usesPorts == NO)
    {
        if (setsockopt(dataSocket, SOL_SOCKET, SO_REUSEADDR, &socketReuse, (socklentype) sizeof (socketReuse)) < 0)
        {
            perror("ftpclient: setsockopt (reuse address) on data");
        }
        if (setsockopt(controlSocket, SOL_SOCKET, SO_REUSEADDR, &socketReuse, (socklentype) sizeof (socketReuse)) < 0)
        {
            perror("ftpclient: setsockopt (reuse address) on control");
        }
    }
    
    if (bind(dataSocket, (struct sockaddr *)&dataSockName, sizeof (dataSockName)) < 0)
    {
        perror("ftpclient: bind");
        return -1;
    }

    if (usesPorts == YES)
    {
        addrLen = sizeof (dataSockName);
        if (getsockname(dataSocket, (struct sockaddr *)&dataSockName, &addrLen) < 0)
        {
            perror("ftpclient: getsockname");
            return -1;
        }
    }
    
    if (listen(dataSocket, 1) < 0)
    {
        perror("ftpclient: listen");
        return -1;
    }

    if (usesPorts == YES)
    {
        union addrAccess /* we use this union to extract the 8 bytes of an address */
        {
            struct in_addr   sinAddr;
            unsigned char    ipv4[4];
        } addr;
        NSMutableArray *reply;
        NSString       *tempStr;
        unsigned char  p1, p2;
        int            returnCode;
        unsigned int   port;


        addr.sinAddr = dataSockName.sin_addr;
        port = ntohs(dataSockName.sin_port);
        p1 = (port & 0xFF00) >> 8;
        p2 = port & 0x00FF;
        tempStr = [NSString stringWithFormat:@"PORT %u,%u,%u,%u,%u,%u", addr.ipv4[0], addr.ipv4[1], addr.ipv4[2], addr.ipv4[3], p1, p2];
        [self writeLine:tempStr];
        NSLog(@"port str: %@", tempStr);
        if ((returnCode = [self readReply:&reply]) != 200)
        {
          if(reply && [reply count] > 0)
            {
              NSLog(@"error occoured in port command: %@", [reply objectAtIndex:0]);
              return -1;
            }
          NSLog(@"error in port command, no code");
          return -2;
        }
    }
    return 0;
}

- (int)initDataStream
{
    struct sockaddr from;
    socklentype     fromLen;
    
    fromLen = sizeof(from);
    if (usesPassive)
    {
        initStream(&dataStream, dataSocket);
        localSocket = dataSocket;
    } else
    {
        if ((localSocket = accept(dataSocket, &from, &fromLen)) < 0)
        {
            perror("accepting socket, initDataStream: ");
            return -1;
        }
        initStream(&dataStream, localSocket);
    }

    return 0;
}

- (int)closeDataConn
{
    closesocket(dataSocket);
    return 0;
}

- (void)closeDataStream
{
    // a passive localSocket is just a copy of the dataSocket
    if (usesPassive == NO)
        closesocket(localSocket);
    // apparently it is not true that fclose closes the underlying
    // descriptor, without closing dataSocket we got a bind error
    // at the next connection attempt
    [self closeDataConn];
}

/*
 creates a new directory
 tries to guess if the given dir is relative (no starting /) or absolute
 Is this portable to non-unix OS's?
 */
- (BOOL)createNewDir:(NSString *)dir
{
  NSString       *remotePath;
  NSString       *command;
  NSMutableArray *reply;
  int            replyCode;

  if ([dir hasPrefix:@"/"])
    {
      NSLog(@"%@ is an absolute path", dir);
      remotePath = dir;
    } else
    {
      NSLog(@"%@ is a relative path", dir);
      remotePath = [[self workingDir] stringByAppendingPathComponent:dir];
    }

  command =[@"MKD " stringByAppendingString:remotePath];
  [self writeLine:command];
  replyCode = [self readReply:&reply];
  if (replyCode == 257)
    return YES;
  else
    {
      NSLog(@"remote mkdir code: %d %@", replyCode, [reply objectAtIndex:0]);
      return NO;
    }
}


/* RM again: a better path limit is needed */
- (bycopy NSArray *)dirContents
{
    int                ch;
    char               buff[MAX_DATA_BUFF];
    unsigned           readBytes;
    enum               states_m1 { READ, GOTR };
    enum               states_m1 state;
    NSMutableArray     *listArr;
    FileElement        *aFile;
    char               path[4096];
    NSMutableArray     *reply;
    int                replyCode;
    unsigned long long transferSize;
    
    if (!connected)
        return nil;
    
    [workingDir getCString:path];

    /* lets settle to a plain ascii standard type */
    if ([self setTypeToA] < 0)
    {
        connected = NO;
        NSLog(@"Timed out.");
        return nil;
    }
    
    /* create an array with a reasonable starting size */
    listArr = [NSMutableArray arrayWithCapacity:5];
    
    [self initDataConn];
    [self writeLine:@"LIST"];
    replyCode = [self readReply:&reply];

    if ([self initDataStream] < 0)
        return nil;

    transferSize = 0;
    [controller setTransferBegin:@"Listing" :transferSize];
    /* read the directory listing, each line being CR-LF terminated */
    state = READ;
    readBytes = 0;
    while ((ch = getChar(&dataStream)) != EOF)
      {
        if (ch == '\r')
            state = GOTR;
        else if (ch == '\n' && state == GOTR)
          { 
            buff[readBytes] = '\0';
            [self logIt:[NSString stringWithCString:buff]];
            state = READ; /* reset the state for a new line */
	    transferSize += readBytes;
            readBytes = 0;
            aFile = [[FileElement alloc] initWithLsLine:buff];
            if (aFile)
              {
                [listArr addObject:aFile];
                [aFile release];
              }
	    [controller setTransferProgress:[NSNumber numberWithUnsignedLongLong:transferSize]];
          }
        else
            buff[readBytes++] = ch;
      }
/* FIXME ***********    if (ferror(dataStream))
    {
        perror("error in reading data stream: ");
    } else if (feof(dataStream))
    {
         fprintf(stderr, "feof\n");
    } */
    [self closeDataStream];
    [controller setTransferEnd:[NSNumber numberWithUnsignedLongLong:transferSize]];

    replyCode = [self readReply:&reply];
    
    return [NSArray arrayWithArray:listArr];
}

- (BOOL)renameFile:(FileElement *)file to:(NSString *)name
{
  NSString       *commandStr;
  NSMutableArray *reply;
  int            replyCode;

  commandStr = [NSString stringWithFormat:@"RNFR %@", [file name]];
  [self writeLine:commandStr];
  replyCode = [self readReply:&reply];
  if (replyCode != 350)
    {
      NSLog(@"Error during Rename from %d", replyCode);
      return NO;
    }

  commandStr = [NSString stringWithFormat:@"RNTO %@", name];
  [self writeLine:commandStr];
  replyCode = [self readReply:&reply];

  if (replyCode == 250)
    {
      [file setName:name];
      return YES;
    }

  return NO;
}

@end
