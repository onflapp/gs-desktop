/***************************************************************************
                                conversions.m
                          -------------------
    begin                : Sun Dec 21 01:37:22 CST 2003
    copyright            : (C) 2003 by Andy Ruder
    email                : aeruder@ksu.edu
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#import <netclasses/NetTCP.h>
#import <netclasses/NetBase.h>
#import "testsuite.h"

#import <Foundation/Foundation.h>

NSString *num_to_hex_le(uint32_t num)
{
	unsigned char y[4];
	uint32_t *t;
	NSMutableString *string;
	int z;

	t = (uint32_t *)y;
	
	*t = num;

	string = [NSMutableString stringWithString: @"0x"];
	for (z = 3; z >= 0 ; z--)
	{
		[string appendString: [NSString stringWithFormat: @"%02x",
		  (unsigned)y[z]]];
	}
	
	return string;
}
	
int main(void)
{
	CREATE_AUTORELEASE_POOL(apr);
	TCPSystem *system;
	NSEnumerator *iter;
	id object;
	uint32_t num;
	NSDictionary *dict;
	
	system = [TCPSystem sharedInstance];

	NSLog(@"This is a cruddy test, it will only work correctly on machines"
	@" where host order != network order :)");
	dict = 
	  [NSDictionary dictionaryWithObjectsAndKeys:
	  @"0x4466dc75", @"68.102.220.117",
	  @"0x7f000001", @"127.0.0.1",
	  @"0xffffffff", @"255.255.255.255",
	  nil];

	iter = [dict keyEnumerator];

	while ((object = [iter nextObject]))
	{
		id val;

		val = [dict objectForKey: object];
		num = 0;
		[system hostOrderInteger: &num fromHost: [NSHost hostWithAddress: object]];
		testEqual(@"Host order",
		  num_to_hex_le(num), val);
	}

	dict = 
	  [NSDictionary dictionaryWithObjectsAndKeys:
	  @"0x75dc6644", @"68.102.220.117", 
	  @"0x0100007f", @"127.0.0.1",
	  @"0xffffffff", @"255.255.255.255",
	  nil];

	iter = [dict keyEnumerator];

	while ((object = [iter nextObject]))
	{
		id val;

		val = [dict objectForKey: object];
		num = 0;
		[system networkOrderInteger: &num fromHost: [NSHost hostWithAddress: object]];
		testEqual(@"Network order",
		  num_to_hex_le(num), val);
	}

	FINISH();

	RELEASE(apr);
	
	return 0;
}
