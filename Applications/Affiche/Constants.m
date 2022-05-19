//
// Constants.m
//
// Ludovic Marcotte <ludovic@Sophos.ca>
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#import "Constants.h"

// Constants for the UI
const int TextFieldHeight = 21;
const int ButtonHeight = 25;

NSString *AfficheUserLibraryPath()
{
  NSString *aString;

  aString = [NSString stringWithFormat: @"%@/Affiche", 
		      [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] ];

  return aString;
}
