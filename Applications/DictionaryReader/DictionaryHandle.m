/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "DictionaryHandle.h"


@implementation DictionaryHandle

+(id) dictionaryFromPropertyList: (NSDictionary*) aPropertyList
{
    DictionaryHandle* dict;
    
    dict = [NSClassFromString([aPropertyList objectForKey: @"class"]) alloc];
    dict = [dict initFromPropertyList: aPropertyList];
    [dict autorelease];
    
    return dict;
}

-(id) initFromPropertyList: (NSDictionary*) aPropertyList
{
    NSAssert([self class] != [DictionaryHandle class],
        @"DictionaryHandle is abstract, don't instantiate it directly!"
    );
    
    if ((self = [super init]) != nil) {
        [self setActive: [[aPropertyList objectForKey: @"active"] intValue]];
        NSString* name = [aPropertyList objectForKey: @"name"];
        if (!name) name = @"Unknown";
        [self setName:name];
    }
    
    return self;
}

-(NSDictionary*) shortPropertyList
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: 4];
    
    [dict setObject: [isa description] forKey: @"class"];
    [dict setObject: [NSNumber numberWithBool: _active] forKey: @"active"];
    [dict setObject: _name forKey: @"name"];
    
    return dict;
}

- (BOOL)isEqual:(id)object 
{
    if (![self isKindOfClass:[object class]]) 
        return NO;
    else
        return [[self name] isEqual:(DictionaryHandle*)[object name]] && \
               [[self location] isEqual:(DictionaryHandle*)[object location]];
}

-(BOOL) isActive
{
    return _active;
}

-(void) setActive: (BOOL) isActive
{
    _active = isActive;
}

-(NSString*) name
{
    return _name;
}

-(void) setName:(NSString*) name
{
    ASSIGN(_name, name);
}

@end
