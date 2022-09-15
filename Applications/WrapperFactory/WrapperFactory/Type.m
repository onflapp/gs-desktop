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

#include "Type.h"
#include "WrapperDocument.h"


@interface Type (Private)

- (void)typeChangedAttribute: (NSString *)attr
                       value: (id)value;

@end



@implementation Type

- (id)init
{
    self = [super init];
    if ( self ) {
        NSImage *img = [[NSImage alloc] initByReferencingFile: [[NSBundle mainBundle] pathForImageResource: @"DefaultAppIcon"]];
        icon = RETAIN([Icon iconWithImage: img]);
        name = _(@"Unnamed");
        extensions = @"";
    }
    return self;
}

- (Icon *)icon
{
    return icon;
}
- (void)setIcon: (Icon *)i
{
    ASSIGN(icon, i);
    [self typeChangedAttribute: @"icon"
          value: (i)];
}

- (NSString *)name
{
    return name;
}
- (void)setName: (NSString *)n
{
    ASSIGN(name, n);
    [self typeChangedAttribute: @"name"
          value: (n)];
}

- (NSString *)extensions
{
    return extensions;
}
- (void)setExtensions: (NSString *)e
{
    ASSIGN(extensions, e);
    [self typeChangedAttribute: @"extensions"
          value: (e)];
}

@end


@implementation Type (Private)

- (void)typeChangedAttribute: (NSString *)attr
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
