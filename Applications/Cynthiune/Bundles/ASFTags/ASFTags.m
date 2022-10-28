/* ASFTags.m - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#import <Foundation/Foundation.h>

#import <Cynthiune/utils.h>

#import "ASFMetaData.h"
#import "ASFTags.h"

#define LOCALIZED(X) _b ([ASFTags class], X)

@interface NSString (CynthiuneASFTagsExtension)

+ (NSString *) stringWithASFText: (unsigned char *) text
                          length: (unsigned int) length;

@end

@implementation NSString (CynthiuneASFTagsExtension)

+ (NSString *) stringWithASFText: (unsigned char *) text
                          length: (unsigned int) length
{
  NSString *string;
  unsigned int realLength;

  realLength = length;
  while (*(text + realLength - 2) == 0
         && *(text + realLength - 1) == 0
         && realLength > 0)
    realLength -= 2;

  string = [[self alloc] initWithBytes: text
                         length: realLength
                         encoding: NSUnicodeStringEncoding];
  [string autorelease];

  return string;
}

@end

static char *
convertGUID (const unsigned char GUID[])
{
  char *cGUID;

  cGUID = malloc (37);
  sprintf (cGUID, "%.8lX-%.4X-%.4X-%.2X%.2X-%.2X%.2X%.2X%.2X%.2X%.2X",
           *((unsigned long *) GUID), *((unsigned short *) GUID + 2),
           *((unsigned short *) GUID + 3), *((unsigned char *) GUID + 8),
           *((unsigned char *) GUID + 9), *((unsigned char *) GUID + 10),
           *((unsigned char *) GUID + 11), *((unsigned char *) GUID + 12),
           *((unsigned char *) GUID + 13), *((unsigned char *) GUID + 14),
           *((unsigned char *) GUID + 15));

  return cGUID;
}

static int
objectIsOfType (ASFObject *object, const char GUID[])
{
  char *cGUID;
  int result;

  cGUID = convertGUID (object->guid);
  result = (strncmp (GUID, cGUID, 16) == 0);
  free (cGUID);

  return result;
}

static void
parseContentDescription (ContentDescriptionObject *object, FileMetaData *data)
{
  unsigned char *ptr;

  ptr = (unsigned char *) object + sizeof (ContentDescriptionObject);
  data->title = ((object->title_length)
                 ? [NSString stringWithASFText: ptr
                             length: object->title_length]
                 : nil);
  ptr += object->title_length;
  data->author = ((object->author_length)
                  ? [NSString stringWithASFText: ptr
                              length: object->author_length]
                  : nil);
}

static inline unsigned char *
asfstrndup (unsigned char *text, unsigned int length)
{
  unsigned char *string;

  string = malloc (length);
  memcpy (string, text, length);

  return string;
}

static ContentDescriptor *
parseDescriptor (unsigned char *object)
{
  ContentDescriptor *descriptor;
  unsigned char *ptr;

  ptr = object;
  descriptor = malloc (sizeof (ContentDescriptor));
  descriptor->name_length = *ptr + 256 * *(ptr + 1);
  ptr += 2;
  descriptor->name = asfstrndup (ptr, descriptor->name_length);
  ptr += descriptor->name_length;
  descriptor->value_datatype = *((unsigned short *) ptr);
  ptr += 2;
  descriptor->value_length = *ptr + 256 * *(ptr + 1);
  ptr += 2;
  descriptor->value = asfstrndup (ptr, descriptor->value_length);

  return descriptor;
}

static inline unsigned int
sizeOfDescriptor (const ContentDescriptor *descriptor)
{
  return (6 + descriptor->name_length + descriptor->value_length);
}

static ContentDescriptor **
parseDescriptors (ExtendedContentDescriptionObject *object)
{
  ContentDescriptor **descriptors;
  ContentDescriptor *descriptor;
  unsigned int count;
  unsigned char *ptr;

  descriptors = malloc (sizeof (ContentDescriptor *)
                        * object->descriptors_count);
  ptr = (unsigned char *) object + sizeof (ExtendedContentDescriptionObject);
  for (count = 0; count < object->descriptors_count; count++)
    {
      descriptor = parseDescriptor (ptr);
      *(descriptors + count) = descriptor;
      ptr += sizeOfDescriptor (descriptor);
    }

  return descriptors;
}

static NSString *
extractValueFromDescriptor (ContentDescriptor *descriptor)
{
  NSString *value;

  switch (descriptor->value_datatype)
    {
    case tUNICODE_STRING:
      value = [NSString stringWithASFText: descriptor->value
                        length: descriptor->value_length];
      break;
    case tBYTE_ARRAY:
      value = [NSString stringWithCString: (char *) descriptor->value
                        length: descriptor->value_length];
      break;
    case tBOOLEAN:
      value = [NSString stringWithFormat: @"%s",
                        (*((unsigned long *) descriptor->value)
                         ? "YES" : "NO")];
      break;
    case tWORD:
      value = [NSString stringWithFormat: @"%d",
                        *((unsigned long *) descriptor->value)];
      break;
    case tDWORD:
      value = [NSString stringWithFormat: @"%d",
                        *((unsigned long *) descriptor->value)];
      break;
    case tQWORD:
      value = [NSString stringWithFormat: @"%l",
                        *((unsigned long long *) descriptor->value)];
      break;
    default:
      NSLog (@"unknown datatype: '%d'", descriptor->value_datatype);
      value = nil;
    }

  return value;
}

static void
FillExtendedDictionary (ContentDescriptor * const *descriptors,
                        unsigned int max, NSMutableDictionary *dictionary)
{
  ContentDescriptor *descriptor;
  unsigned int count;
  NSString *name;

  for (count = 0; count < max; count++)
    {
      descriptor = descriptors[count];
      if (descriptor->name_length)
        {
          name = [NSString stringWithASFText: descriptor->name
                           length: descriptor->name_length];
          [dictionary setObject: extractValueFromDescriptor (descriptor)
                      forKey: name];
        }
    }
}

static void
parseExtendedContentDescription (ExtendedContentDescriptionObject *object,
                                 FileMetaData *data)
{
  unsigned int count;
  ContentDescriptor **descriptors;

  descriptors = parseDescriptors (object);
  FillExtendedDictionary (descriptors,
                          object->descriptors_count,
                          data->extendedDictionary);
  for (count = 0; count < object->descriptors_count; count++)
    {
      free (descriptors[count]->name);
      free (descriptors[count]->value);
      free (descriptors[count]);
    }
  free (descriptors);
}

static FileMetaData *
parseHeaderData (void *data, int size)
{
  char *ptr;
  ASFObject *optr;
  FileMetaData *metadata;

  ptr = data;
  metadata = calloc (sizeof (FileMetaData), 1);
  metadata->extendedDictionary = [NSMutableDictionary new];

  while (ptr < (char *) data + size)
    {
      optr = (ASFObject *) ptr;
      if (objectIsOfType (optr, ASF_Content_Description_Object))
        parseContentDescription ((ContentDescriptionObject *) optr, metadata);
      else if (objectIsOfType (optr, ASF_Extended_Content_Description_Object))
        parseExtendedContentDescription ((ExtendedContentDescriptionObject *)
                                         optr, metadata);
      ptr += optr->size;
    }

  return metadata;
}

static HeaderObject *
readHeaderObject (FILE *asf)
{
  HeaderObject *newObject;

  newObject = malloc (sizeof (HeaderObject));
  fread (newObject->guid, 16, 1, asf);
  fread (&(newObject->size), 8, 1, asf);
  fread (&(newObject->number), 4, 1, asf);
  fread (&(newObject->res1), 1, 1, asf);
  fread (&(newObject->res2), 1, 1, asf);

  if (newObject->res1 != 0x01 || newObject->res2 != 0x02)
    {
      free (newObject);
      newObject = NULL;
    }

  return newObject;
}

static inline FileMetaData *
readMetaData (FILE *asf)
{
  HeaderObject *ho;
  void *data;
  FileMetaData *metadata;

  ho = readHeaderObject (asf);
  if (objectIsOfType ((ASFObject *) ho, ASF_Header_Object))
    {
      data = malloc (ho->size - 30);
      fread (data, ho->size - 30, 1, asf);
      metadata = parseHeaderData (data, ho->size - 30);
      free (data);
    }
  else
    metadata = NULL;

  free (ho);

  return metadata;
}

@implementation ASFTags : NSObject

+ (NSString *) bundleDescription
{
  return @"A bundle to read/set the tags of ASF files";
}

+ (NSArray *) bundleCopyrightStrings
{
  return [NSArray arrayWithObjects:
                    @"Copyright (C) 2005  Wolfgang Sourdeau",
                  nil];
}

+ (NSString *) _readTitle: (FileMetaData *) metadata
{
  NSString *title;

  title = [metadata->extendedDictionary objectForKey: @"Title"];
  if (!title)
    title = [metadata->extendedDictionary objectForKey: @"WM/Title"];
  if (!title)
    title = metadata->title;

  return title;
}

+ (NSString *) _readArtist: (FileMetaData *) metadata
{
  NSString *artist;

  artist = [metadata->extendedDictionary objectForKey: @"WM/AlbumArtist"];
  if (!artist)
    artist = [metadata->extendedDictionary objectForKey: @"WM/Composer"];
  if (!artist)
    artist = metadata->author;

  return artist;
}

+ (NSString *) _readTrackNumber: (FileMetaData *) metadata
{
  NSString *trackNumber, *track;

  trackNumber = [metadata->extendedDictionary objectForKey: @"WM/TrackNumber"];
  if (!trackNumber)
    {
      track = [metadata->extendedDictionary objectForKey: @"WM/Track"];
      if (track)
        trackNumber = [NSString stringWithFormat:
                                  @"%d", 1 + [track intValue]];
    }

  return trackNumber;
}

+ (BOOL) readTitle: (NSString **) title
            artist: (NSString **) artist
             album: (NSString **) album
       trackNumber: (NSString **) trackNumber
             genre: (NSString **) genre
              year: (NSString **) year
        ofFilename: (NSString *) filename
{
  FILE *cFile;
  FileMetaData *metadata;
  BOOL result;

  result = NO;

  cFile = fopen ([filename cString], "r");
  if (cFile)
    {
      metadata = readMetaData (cFile);
      if (metadata)
        {
          result = YES;
          SET (*title, [self _readTitle: metadata]);
          SET (*artist, [self _readArtist: metadata]);
          SET (*album,
               [metadata->extendedDictionary objectForKey: @"WM/AlbumTitle"]);
          SET (*trackNumber, [self _readTrackNumber: metadata]);
          SET (*genre,
               [metadata->extendedDictionary objectForKey: @"WM/Genre"]);
          SET (*year,
               [metadata->extendedDictionary objectForKey: @"WM/Year"]);

          [metadata->extendedDictionary release];
          free (metadata);
        }
      fclose (cFile);
    }

  return result;
}

@end
