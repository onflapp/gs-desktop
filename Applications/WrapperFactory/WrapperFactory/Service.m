/* Copyright (C) 2003 Raffael Herzog
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * $Id: Type.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/Type.m $
 */

#include <AppKit/AppKit.h>

#include "Service.h"
#include "WrapperDocument.h"


@interface Service (Private)

- (void)serviceChangedAttribute: (NSString *)attr
                       value: (id)value;

@end



@implementation Service

- (id)init
{
    self = [super init];
    if ( self ) {
        name = @"Unnamed";
        shell = @"/bin/sh";
        action = @"";
    }
    return self;
}

- (NSString *)name
{
    return name;
}
- (void)setName: (NSString *)n
{
    ASSIGN(name, n);
    [self serviceChangedAttribute: @"name"
          value: (n)];
}

- (NSString *)shell
{
    return shell;
}
- (void)setShell: (NSString *)n
{
    ASSIGN(shell, n);
    [self serviceChangedAttribute: @"shell"
          value: (n)];
}

- (NSString *)action
{
    return action;
}
- (void)setAction: (NSString *)n
{
    ASSIGN(action, n);
    [self serviceChangedAttribute: @"action"
          value: (n)];
}

@end


@implementation Service (Private)

- (void)serviceChangedAttribute: (NSString *)attr
                       value: (id)value
{
    [[NSNotificationCenter defaultCenter] postNotificationName: WrapperAggregateChangedNotification
                                          object: (self)
                                          userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                  attr, WrapperAggregateChangedAttributeName,
                                                                  value, WrapperAggregateChangedAttributeValue,
                                                                  nil]];
}

@end
