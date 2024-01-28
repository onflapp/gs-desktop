/**
    ScriptingSupport
    Code for loading scripting
    
    NOTE: Copy and include this file into your application project.
  
  
    Copyright (c) 2002 Stefan Urbanek
  
    Written by: Stefan Urbanek <urbanek@host.sk>
    Date: 2002 Apr 13
 
    This file is part of the StepTalk project.
 
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.
  
    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

   */

#ifndef _STScriptingSupport_h
#define _STScriptingSupport_h

#include <AppKit/NSApplication.h>

@interface NSApplication(STApplicationScripting)
- (BOOL)initializeApplicationScripting;
- (BOOL)isScriptingSupported;

/* User interface */
- (void)orderFrontScriptsPanel:(id)sender;
- (void)orderFrontTranscriptWindow:(id)sender;
- (NSMenu *) scriptingMenu;
@end

#endif
