//
// This code is public domain. Do whatever you want with it.
//
// This test application shows how to check for new mail on
// a POP3 server. If there are any messages on the server,
// it downloads the first ones and dumps it on stdout.
//
// *** PLEASE READ Pantomime/Documentation/README ***
//
// Author: Ludovic Marcotte <ludovic@Sophos.ca>
//

#import <AppKit/AppKit.h>


//
// You can safely either #include or #import Pantomime headers.
// Include/import Pantomime.h to have access to every class
// or include/import them individually.
//
#import <Pantomime/Pantomime.h>

//
// Modify those defines to reflect your environment.
//

#define SERVER_NAME  @"pop.gmail.com"
#define SERVER_PORT  995
#define USE_SSL      NO
#define USERNAME     @"german@xelalug.org"
#define PASSWORD     @"cranfork725"
#define MECHANISM    @"none"  // use "none" for normal POP3 authentication


//
// Our class interface.
//
@interface SimplePOP3 : NSObject
{
  @private
    CWPOP3Store *_pop3;
}
@end


//
// Our class implementation.
//
@implementation SimplePOP3

- (void) applicationDidFinishLaunching: (NSNotification *) theNotification
{
  // We initialize our POP3Store instance
  _pop3 = [[CWPOP3Store alloc] initWithName: SERVER_NAME  port: SERVER_PORT];
  [_pop3 setDelegate: self];

  // We connect to the server _in background_. That means, this call
  // is non-blocking and methods will be invoked on the delegate
  // (or notifications will be posted) for further dialog with
  // the remote POP3server.
  NSLog(@"Connecting to the %@ server...", SERVER_NAME);
  [_pop3 connectInBackgroundAndNotify];
}


//
// This method is automatically called once the POP3 authentication
// has completed. If it has failed, -authenticationFailed: will
// be invoked.
//
- (void) authenticationCompleted: (NSNotification *) theNotification
{
  NSLog(@"Authentication completed! Checking for messages..");
  [[_pop3 defaultFolder] prefetch];
}


//
// This method is automatically called once the POP3 authentication
// has failed. If it has succeeded, -authenticationCompleted: will
// be invoked.
//
- (void) authenticationFailed: (NSNotification *) theNotification
{
  NSLog(@"Authentication failed! Closing the connection...");
  [_pop3 close];
}


//
// This method is automatically called when the connection to
// the POP3 server was established.
//
- (void) connectionEstablished: (NSNotification *) theNotification
{
  NSLog(@"Connected!");

  if (USE_SSL)
    {
      NSLog(@"Now starting SSL...");
      [(CWTCPConnection *)[_pop3 connection] startSSL];
    }
}


//
// This method is automatically called when the connection to
// the POP3 server was terminated avec invoking -close on the
// POP3Store instance.
//
- (void) connectionTerminated: (NSNotification *) theNotification
{
  NSLog(@"Connection closed.");
  RELEASE(_pop3);
  [NSApp terminate: self];
}


//
// This method is automatically invoked when the folder information
// was fully prefetched from the POP3 server. Once it has been
// prefetched, one can prefetch specific messages.
//
- (void) folderPrefetchCompleted: (NSNotification *) theNotification
{
  int count;

  count = [(CWPOP3Folder *)[_pop3 defaultFolder] count];

  NSLog(@"There are %d messages on the server.", count);

  if (count > 0)
    {
      NSLog(@"Prefetching and initializing the first one...");
      [[[[_pop3 defaultFolder] allMessages] objectAtIndex: 0] setInitialized: YES];
    }
  else
    {
      NSLog(@"Closing the connection...");
      [_pop3 close];
    }
}


//
// This method is automatically invoked when a message was 
// fully prefetched from the POP3 server.
//
- (void) messagePrefetchCompleted: (NSNotification *) theNotification
{
  CWMessage *aMessage;

  aMessage = [[theNotification userInfo] objectForKey: @"Message"];

  NSLog(@"Got the message! The subject is: %@", [aMessage subject]);
  NSLog(@"The full content is:\n\n------------------------\n%s------------------------", [[aMessage rawSource] cString]);

  NSLog(@"Closing the connection...");
  [_pop3 close];
}


//
// This method is automatically invoked once the POP3Store service
// is fully initialized.
//
- (void) serviceInitialized: (NSNotification *) theNotification
{
  if (USE_SSL)
    {
      NSLog(@"SSL handshaking completed.");
    }

  NSLog(@"Available authentication mechanisms: %@", [_pop3 supportedMechanisms]);
  [_pop3 authenticate: USERNAME  password: PASSWORD  mechanism: MECHANISM];
}

@end


//
// Main entry point for the test application.
//
int main(int argc, const char *argv[], char *env[])
{
  NSAutoreleasePool *pool;
  SimplePOP3 *o;
  
  pool = [[NSAutoreleasePool alloc] init];
  o = [[SimplePOP3 alloc] init];
  
  [NSApplication sharedApplication];
  [NSApp setDelegate: o];
  [NSApp run];
  RELEASE(o);
  RELEASE(pool);
  
  return 0;
}
