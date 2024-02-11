/* Copyright (C) 2020 Free Software Foundation, Inc.

   Written by:  onflapp
   Created: September 2020

   This file is part of the gs-desktop Project

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   You should have received a copy of the GNU General Public
   License along with this program; see the file COPYING.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

   */

#import	<AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>
#import "ShellUIProxy.h"

@implementation ShellUIProxy

- (id) init {
  self = [super init];
  controls = [[NSMutableDictionary alloc] init];
  context = [[NSMutableDictionary alloc] init];

  return self;
}

- (void) dealloc {
  RELEASE(delegate);
  [controls release];
  [context release];
  [super dealloc];
}

- (NSView*) iconView {
  return iconView;
}

- (NSWindow*) window {
  return window;
}

- (NSMenu*) menu {
  return menu;
}

- (BOOL) validateMenuItem:(NSMenuItem*) item {
  return YES;
}

- (BOOL) validateUserInterfaceItem:(id) item {
  return YES;
}

- (NSString*) stringForControl:(id) val {
  if (!val) return @"";

  if ([val isKindOfClass:[NSControl class]]) {
    NSString* str = [val stringValue];
    return str?str:@"";
  }
  else {
    return @"";
  }
}

- (id) nameForControl:(id) control {
  for (NSString* key in [controls allKeys]) {
    id val = [controls valueForKey:key];
    if (val == control) {
      return key;
    }
  }
  return nil;
}

- (void) updateContext {
  for (NSString* key in [controls allKeys]) {
    id val = [controls valueForKey:key];
    NSString* str = [self stringForControl:val];
    [context setValue:str forKey:key];
  }
}

- (BOOL)respondsToSelector:(SEL) aSelector {
  NSString* sel = NSStringFromSelector(aSelector);
  if ([sel hasPrefix:@"set"]) {
    return YES;
  }
  else if ([sel hasPrefix:@"do"]) {
    return YES;
  }
  else {
    return NO;
  }
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
  //NSString* sel = NSStringFromSelector(aSelector);
  return nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
  return [NSMethodSignature signatureWithObjCTypes:"@^v^v^c@"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
  NSString* sel = NSStringFromSelector([anInvocation selector]);
  id val = nil;
  [anInvocation getArgument:&val atIndex:2];

  if ([sel isEqualToString:@"setMenu:"]) {
    ASSIGN(menu, val);
  }
  else if ([sel isEqualToString:@"setWindow:"]) {
    ASSIGN(window, val);
  }
  else if ([sel isEqualToString:@"setIconView:"]) {
    ASSIGN(iconView, val);
  }
  else if ([sel hasPrefix:@"set"]) {
    NSString* key = [sel substringFromIndex:3];
    key = [key substringToIndex:[key length] - 1];
    key = [key uppercaseString];

    if ([val isKindOfClass:[NSControl class]]) {
      [controls setValue:val forKey:key];
      [self updateContext];
    }
  }
  else if ([sel hasPrefix:@"do"]) {
    NSString* key = [self nameForControl:val];
    if (key) {
      NSString* str = [self stringForControl:val];
      [context setValue:str forKey:key];
    }
    if (delegate) {
      NSString* act = [sel substringToIndex:[sel length] - 1];
      act = [act lowercaseString];

      NSLog(@"act:%@", act);
      NSData* data = [[self stringForContext]dataUsingEncoding:NSUTF8StringEncoding];
      NSMutableArray* args = [NSMutableArray array];
      [args addObject:act];
      if (val && [val isKindOfClass:[NSString class]]) {
        [args addObject:val];
      }
      [delegate execTaskWithArguments:args data:data delegate:self];
    }
  }
}

- (NSString*) stringForContext {
  NSMutableString* buff = [NSMutableString string];
  for (NSString* key in [context allKeys]) {
    NSString* val = [context valueForKey:key];
    [buff appendFormat:@"%@='%@'\n", key, val];
  }
  return buff;
}

- (void) updateValue:(NSString*) val forControl:(NSString*) name {
  id control = [controls valueForKey:name];
  if (control) {
    NSLog(@"control %@ = [%@]", name, val);
    [control setStringValue:val];
    [self updateContext];
  }
  else {
    NSLog(@"control name [%@] not found", name);
    NSLog(@">%@", controls);
  }
}

- (void) processLine:(NSString*) line {
  NSInteger x = [line rangeOfString:@"="].location;
  if (x != NSNotFound) {
    NSString* key = [line substringToIndex:x];
    NSString* val = [line substringFromIndex:x+1];
    [self updateValue:val forControl:key];
  }
  else {
    NSLog(@"[%@]", line);
  }
}

- (void) handleActions:(id) del {
  ASSIGN(delegate, del);
  NSArray* args = [NSArray array];
  NSData* data = nil;
  [delegate execTaskWithArguments:args data:data delegate:self];
}

@end
