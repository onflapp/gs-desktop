//
// This code is public domain. Do whatever you want with it.
//
// This test application shows how to send a simple message
// using the SMTP protocol. See the "define section" below
// for various settings you can activate.
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
#define FROM_ADDRESS @"Ludovic Marcotte <ludovic@Sophos.ca>"
#define TO_ADDRESS   @"Ludovic Marcotte <ludovic@Sophos.ca>"

#define SERVER_NAME  @"smtp.gmail.com"
#define SERVER_PORT  587
#define USE_SECURE   2         // 0 -> NO, 1 -> SSL (usually port 465), 2 -> TLS (usually port 25 or 587)
#define USERNAME     @"foo@gmail.com"
#define PASSWORD     @"foobarbaz"
#define MECHANISM    @"PLAIN"  // use "none" for no SMTP authentication
                               // "PLAIN", "LOGIN" and "CRAM-MD5" are supported.

//
// How many messages would you like to send over the same connection?
//
static int number_of_messages = 3;

//
// Our class interface.
//
@interface SimpleSMTP : NSObject
{
  @private
    CWSMTP *_smtp;
}
@end


//
// Our class implementation.
//
@implementation SimpleSMTP

- (void) applicationDidFinishLaunching: (NSNotification *) theNotification
{
  CWInternetAddress *address;
  CWMessage *message;

  // We create a simple message object.
  message = [[CWMessage alloc] init];
  [message setSubject: @"Pantomime Test!"];
  
  // We set the "From:" header
  address = [[CWInternetAddress alloc] initWithString: FROM_ADDRESS];
  [message setFrom: address];
  RELEASE(address);

  // We set the "To: header
  address = [[CWInternetAddress alloc] initWithString: TO_ADDRESS];
  [address setType: PantomimeToRecipient];
  [message addRecipient: address];
  RELEASE(address);

  // We set the Message's Content-Type, encoding and charset
  [message setContentType: @"text/plain"];                    
  [message setContentTransferEncoding: PantomimeEncodingNone];
  [message setCharset: @"us-ascii"];

  // We set the Message's content
  [message setContent: [@"This is a simple content." dataUsingEncoding: NSASCIIStringEncoding]];
  
  // We initialize our SMTP instance
  _smtp = [[CWSMTP alloc] initWithName: SERVER_NAME  port: SERVER_PORT];
  [_smtp setDelegate: self];
  [_smtp setMessage: message];
  RELEASE(message);

  // We connect to the server _in background_. That means, this call
  // is non-blocking and methods will be invoked on the delegate
  // (or notifications will be posted) for further dialog with
  // the remote SMTP server.
  NSLog(@"Connecting to the %@ server...", SERVER_NAME);
  [_smtp connectInBackgroundAndNotify];
}


//
// This method is automatically called once the SMTP authentication
// has completed. If it has failed, -authenticationFailed: will
// be invoked.
//
- (void) authenticationCompleted: (NSNotification *) theNotification
{
  NSLog(@"Authentication completed! Sending the message...");
  [_smtp sendMessage];
}


//
// This method is automatically called once the SMTP authentication
// has failed. If it has succeeded, -authenticationCompleted: will
// be invoked.
//
- (void) authenticationFailed: (NSNotification *) theNotification
{
  NSLog(@"Authentication failed! Closing the connection...");
  [_smtp close];
}


//
// This method is automatically called when the connection to
// the SMTP server was established.
//
- (void) connectionEstablished: (NSNotification *) theNotification
{
  NSLog(@"Connected!");

  if (USE_SECURE == 1)
    {
      NSLog(@"Now starting SSL...");
      [(CWTCPConnection *)[_smtp connection] startSSL];
    }
}


//
// This method is automatically called when the connection to the
// server is abruptly closed by the server. GMail does that for example
// when you call close. You should make sure your message is sent
// in this delegate and not assume it only happens when after you
// invoke -close.
//
- (void) connectionLost: (NSNotification *) theNotification
{
  NSLog(@"Connection lost to the server!");
  RELEASE(_smtp);
 [NSApp terminate: self];
}


//
// This method is automatically called when the connection to
// the SMTP server was terminated avec invoking -close on the
// SMTP instance.
//
- (void) connectionTerminated: (NSNotification *) theNotification
{
  NSLog(@"Connection closed.");
  RELEASE(_smtp);
  [NSApp terminate: self];
}


//
// This method is automatically called when the message has been
// successfully sent.
//
- (void) messageSent: (NSNotification *) theNotification
{
  NSLog(@"Sent!\nClosing the connection.");

  number_of_messages--;

  if (number_of_messages == 0)
    {
      [_smtp close];
    }
  else
    {
      // If you wish to either change the recipients, message or
      // the message data, you should do so in -transactionResetCompleted:
      // before calling again -sendMessage. The -reset method will NOT
      // change either the previously used recipients, message or
      // message data.
      [_smtp reset];
    }
}

//
// This method is automatically invoked once the SMTP service
// is fully initialized. One can send a message directly (if no
// SMTP authentication is required to relay the mail) or proceed
// with the authentication if needed.
//
- (void) serviceInitialized: (NSNotification *) theNotification
{
  if (![(CWTCPConnection *)[[theNotification object] connection] isSSL] && USE_SECURE == 2)
    {
      [[theNotification object] startTLS];
      return;
    }

  if (USE_SECURE == 1)
    {
      NSLog(@"SSL handshaking completed.");
    }

  if ([MECHANISM isEqualToString: @"none"])
    {
      NSLog(@"Sending the message...");
      [_smtp sendMessage];
    }
  else
    {
      NSLog(@"Available authentication mechanisms: %@", [_smtp supportedMechanisms]);
      [_smtp authenticate: USERNAME  password: PASSWORD  mechanism: MECHANISM];
    }
}

//
// This method is invoked once the transaction has been reset. This
// can be useful if one when to send more than one message over
// the same SMTP connection.
//
- (void) transactionResetCompleted: (NSNotification *) theNotification
{
  NSLog(@"Sending the message over the same connection...");
  [_smtp sendMessage];
}

@end


//
// Main entry point for the test application.
//
int main(int argc, const char *argv[], char *env[])
{
  NSAutoreleasePool *pool;
  SimpleSMTP *o;
  
  pool = [[NSAutoreleasePool alloc] init];
  o = [[SimpleSMTP alloc] init];
  
  [NSApplication sharedApplication];
  [NSApp setDelegate: o];
  [NSApp run];
  RELEASE(o);
  RELEASE(pool);

  return 0;
  
}
