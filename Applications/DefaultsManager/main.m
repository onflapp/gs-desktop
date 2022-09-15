/* $Id: main.m,v 1.1.1.1 2000/11/10 23:04:48 robert Exp $ */

#import <AppKit/AppKit.h>
#import "AppController.h"

#define APP_NAME @"GSDefaults"

/*
 * Create the application's menu
 */

void createMenu();

/*
 * Initialise and go!
 */

int main(int argc, const char *argv[]) {
  NSApplication     *theApp;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  AppController     *controller;
  
#ifndef NX_CURRENT_COMPILER_RELEASE
  initialize_gnustep_backend();
#endif
  
  theApp = [NSApplication sharedApplication];

  createMenu();

  controller = [[AppController alloc] init];
  [theApp setDelegate:controller];

  /*
   * Go...
   */  

  [theApp run];
  
  /*
   * ...and finish!
   */

  RELEASE(controller);
  RELEASE(pool);
  
  return 0;
}

void createMenu()
{
  NSMenu *menu;
  NSMenu *info;
  NSMenu *edit;
  NSMenu *services;
  NSMenu *windows;

  SEL action = @selector(method:);

  menu = [[NSMenu alloc] initWithTitle:APP_NAME];

  [menu addItemWithTitle:@"Info" action:@selector(showInfoPanel:) keyEquivalent:@""];
  [menu addItemWithTitle:@"Edit" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Defaults..." action:@selector(showDefaultsWindow:) keyEquivalent:@""];
  [menu addItemWithTitle:@"Windows" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Services" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Hide" action:@selector(hide:) keyEquivalent:@"h"];
  [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];

  info = AUTORELEASE([[NSMenu alloc] init]);
  [menu setSubmenu:info forItem:[menu itemWithTitle:@"Info"]];
  [info addItemWithTitle:@"Info Panel..." action:@selector(showInfoPanel:) keyEquivalent:@""];
  [info addItemWithTitle:@"Preferences" action:@selector(showPrefPanel:) keyEquivalent:@""];
  [info addItemWithTitle:@"Help" action:action keyEquivalent:@"?"];

  edit = AUTORELEASE([[NSMenu alloc] init]);
  [edit addItemWithTitle:@"Cut" action:action keyEquivalent:@"x"];
  [edit addItemWithTitle:@"Copy" action:action keyEquivalent:@"c"];
  [edit addItemWithTitle:@"Paste" action:action keyEquivalent:@"v"];
  [edit addItemWithTitle:@"Delete" action:action keyEquivalent:@""];
  [edit addItemWithTitle:@"Select All" action:action keyEquivalent:@"a"];
  [menu setSubmenu:edit forItem:[menu itemWithTitle:@"Edit"]];

  windows = AUTORELEASE([[NSMenu alloc] init]);
  [windows addItemWithTitle:@"Arrange"
		   action:@selector(arrangeInFront:)
		   keyEquivalent:@""];
  [windows addItemWithTitle:@"Miniaturize"
		   action:@selector(performMiniaturize:)
		   keyEquivalent:@"m"];
  [windows addItemWithTitle:@"Close"
		   action:@selector(performClose:)
		   keyEquivalent:@"w"];
  [menu setSubmenu:windows forItem:[menu itemWithTitle:@"Windows"]];

  services = AUTORELEASE([[NSMenu alloc] init]);
  [menu setSubmenu:services forItem:[menu itemWithTitle:@"Services"]];

  [[NSApplication sharedApplication] setMainMenu:menu];
  [[NSApplication sharedApplication] setServicesMenu: services];

  [menu update];
  [menu display];
}



