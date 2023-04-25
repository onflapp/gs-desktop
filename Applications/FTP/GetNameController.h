/* -*- mode: objc -*-

 Project: FTP

 Copyright (C) 2013-2016 Free Software Foundation

 Author: Riccardo Mottola

 Created: 2013-06-05

 Controller class to get an new name from the user in a panel dialog.

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

#import <Foundation/Foundation.h>

#if !defined (GNUSTEP) &&  (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
#ifndef NSInteger
#define NSInteger int
#endif
#ifndef NSUInteger
#define NSUInteger unsigned
#endif
#endif

@class NSPanel, NSTextField;

@interface GetNameController : NSObject
{
  IBOutlet NSPanel *panel;
  IBOutlet NSTextField *textField;
  IBOutlet NSTextField *messageField;
  IBOutlet NSTextField *labelField;
  IBOutlet NSButton *cancelButton;
  IBOutlet NSButton *okButton;
  
  NSInteger returnCode;
}

-(NSInteger)runAsModal;
-(void)setTitle:(NSString *)title;
-(void)setMessage:(NSString *)desc;

-(void)setName:(NSString  *)name;
-(NSString *)name;

-(IBAction)okPressed:(id)sender;
-(IBAction)cancelPressed:(id)sender;

@end
