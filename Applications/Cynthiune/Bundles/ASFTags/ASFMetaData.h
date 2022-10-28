/* ASFMetaData.h - this file is part of Cynthiune
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

#ifndef ASFMETADATA_H
#define ASFMETADATA_H

#define ASF_Header_Object "75B22630-668E-11CF-A6D9-00AA0062CE6C"
#define ASF_Data_Object "75B22636-668E-11CF-A6D9-00AA0062CE6C"
#define ASF_Simple_Index_Object "33000890-E5B1-11CF-89F4-00A0C90349CB"
#define ASF_Index_Object "D6E229D3-35DA-11D1-9034-00A0C90349BE"
#define ASF_Media_Object_Index_Object "FEB103F8-12AD-4C64-840F-2A1D2F7AD48C"
#define ASF_Timecode_Index_Object "3CB73FD0-0C4A-4803-953D-EDF7B6228F0C"

#define ASF_File_Properties_Object "8CABDCA1-A947-11CF-8EE4-00C00C205365"

#define ASF_Stream_Properties_Object "B7DC0791-A9B7-11CF-8EE6-00C00C205365"
#define ASF_Header_Extension_Object "5FBF03B5-A92E-11CF-8EE3-00C00C205365"
#define ASF_Codec_List_Object "86D15240-311D-11D0-A3A4-00A0C90348F6"
#define ASF_Script_Command_Object "1EFB1A30-0B62-11D0-A39B-00A0C90348F6"
#define ASF_Marker_Object "F487CD01-A951-11CF-8EE6-00C00C205365"
#define ASF_Bitrate_Mutual_Exclusion_Object "D6E229DC-35DA-11D1-9034-00A0C90349BE"
#define ASF_Error_Correction_Object "75B22635-668E-11CF-A6D9-00AA0062CE6C"
#define ASF_Content_Description_Object "75B22633-668E-11CF-A6D9-00AA0062CE6C"
#define ASF_Extended_Content_Description_Object "D2D0A440-E307-11D2-97F0-00A0C95EA850"
#define ASF_Content_Branding_Object "2211B3FA-BD23-11D2-B4B7-00A0C955FC6E"
#define ASF_Stream_Bitrate_Properties_Object "7BF875CE-468D-11D1-8D82-006097C9A2B2"
#define ASF_Content_Encryption_Object "2211B3FB-BD23-11D2-B4B7-00A0C955FC6E"
#define ASF_Extended_Content_Encryption_Object "298AE614-2622-4C17-B935-DAE07EE9289C"
#define ASF_Digital_Signature_Object "2211B3FC-BD23-11D2-B4B7-00A0C955FC6E"
#define ASF_Padding_Object "1806D474-CADF-4509-A4BA-9AABCB96AAE8"

#define ASF_Extended_Stream_Properties_Object "14E6A5CB-C672-4332-8399-A96952065B5A"
#define ASF_Advanced_Mutual_Exclusion_Object "A08649CF-4775-4670-8A16-6E35357566CD"
#define ASF_Group_Mutual_Exclusion_Object "D1465A40-5A79-4338-B71B-E36B8FD6C249"
#define ASF_Stream_Prioritization_Object "D4FED15B-88D3-454F-81F0-ED5C45999E24"
#define ASF_Bandwidth_Sharing_Object "A69609E6-517B-11D2-B6AF-00C04FD908E9"
#define ASF_Language_List_Object "7C4346A9-EFE0-4BFC-B229-393EDE415C85"
#define ASF_Metadata_Object "C5F8CBEA-5BAF-4877-8467-AA8C44FA4CCA"
#define ASF_Metadata_Library_Object "44231C94-9498-49D1-A141-1D134E457054"
#define ASF_Index_Parameters_Object "D6E229DF-35DA-11D1-9034-00A0C90349BE"
#define ASF_Media_Object_Index_Parameters_Object "6B203BAD-3F11-48E4-ACA8-D7613DE2CFA7"
#define ASF_Timecode_Index_Parameters_Object "F55E496D-9797-4B5D-8C8B-604DFE9BFB24"
#define ASF_Compatibility_Object "75B22630-668E-11CF-A6D9-00AA0062CE6C"
#define ASF_Advanced_Content_Encryption_Object "43058533-6981-49E6-9B74-AD12CB86D58C"

#define ASF_Audio_Media "F8699E40-5B4D-11CF-A8FD-00805F5C442B"
#define ASF_Video_Media "BC19EFC0-5B4D-11CF-A8FD-00805F5C442B"
#define ASF_Command_Media "59DACFC0-59E6-11D0-A3AC-00A0C90348F6"
#define ASF_JFIF_Media "B61BE100-5B4E-11CF-A8FD-00805F5C442B"
#define ASF_Degradable_JPEG_Media "35907DE0-E415-11CF-A917-00805F5C442B"
#define ASF_File_Transfer_Media "91BD222C-F21C-497A-8B6D-5AA86BFC0185"

#define ASF_Binary_Media "3AFB65E2-47EF-40F2-AC2C-70A90D71D343"

#define ASF_Web_Stream_Media_Subtype "776257D4-C627-41CB-8F81-7AC7FF1C40CC"
#define ASF_Web_Stream_Format "DA1E6B13-8359-4050-B398-388E965BF00C"

#define ASF_No_Error_Correction "20FB5700-5B55-11CF-A8FD-00805F5C442B"
#define ASF_Audio_Spread "BFC3CD50-618F-11CF-8BB2-00AA00B4E220"

#define ASF_Reserved_1 "ABD3D211-A9BA-11cf-8EE6-00C00C205365"

#define ASF_Content_Encryption_System_Windows_Media_DRM_Network_Devices "7A079BB6-DAA4-4e12-A5CA-91D38DC11A8D"

#define ASF_Reserved_2 "86D15241-311D-11D0-A3A4-00A0C90348F6"

#define ASF_Reserved_3 "4B1ACBE3-100B-11D0-A39B-00A0C90348F6"

#define ASF_Reserved_4 "4CFEDB20-75F6-11CF-9C0F-00A0C90349CB"

#define ASF_Mutex_Language "D6E22A00-35DA-11D1-9034-00A0C90349BE"
#define ASF_Mutex_Bitrate "D6E22A01-35DA-11D1-9034-00A0C90349BE"
#define ASF_Mutex_Unknown "D6E22A02-35DA-11D1-9034-00A0C90349BE"

#define ASF_Bandwidth_Sharing_Exclusive "AF6060AA-5197-11D2-B6AF-00C04FD908E9"
#define ASF_Bandwidth_Sharing_Partial "AF6060AB-5197-11D2-B6AF-00C04FD908E9"

#define ASF_Payload_Extension_System_Timecode "399595EC-8667-4E2D-8FDB-98814CE76C1E"
#define ASF_Payload_Extension_System_File_Name "E165EC0E-19ED-45D7-B4A7-25CBD1E28E9B"
#define ASF_Payload_Extension_System_Content_Type "D590DC20-07BC-436C-9CF7-F3BBFBF1A4DC"

#define ASF_Payload_Extension_System_Pixel_Aspect_Ratio "1B1EE554-F9EA-4BC8-821A-376B74E4C4B8"
#define ASF_Payload_Extension_System_Sample_Duration "C6BD9450-867F-4907-83A3-C77921B733AD"
#define ASF_Payload_Extension_System_Encryption_Sample_ID "6698B84E-0AFA-4330-AEB2-1C0A98D7A44D"

typedef struct ASFObject
{
  unsigned char guid[16];
  unsigned long long size;
} __attribute((packed)) ASFObject;

typedef struct HeaderObject
{
  unsigned char guid[16];
  unsigned long long size;
  unsigned int number;
  unsigned char res1;
  unsigned char res2;
} __attribute((packed)) HeaderObject;

typedef struct ContentDescriptionObject
{
  unsigned char guid[16];
  unsigned long long size;
  unsigned short title_length;
  unsigned short author_length;
  unsigned short copyright_length;
  unsigned short description_length;
  unsigned short rating_length;
} __attribute((packed)) ContentDescriptionObject;

typedef struct ExtendedContentDescriptionObject
{
  unsigned char guid[16];
  unsigned long long size;
  unsigned short descriptors_count;
} __attribute((packed)) ExtendedContentDescriptionObject;

enum
{
  tUNICODE_STRING = 0,
  tBYTE_ARRAY = 1,
  tBOOLEAN = 2,
  tDWORD = 3,
  tQWORD = 4,
  tWORD = 5
};

typedef struct ContentDescriptor
{
  unsigned short name_length;
  unsigned char *name;
  unsigned short value_datatype;
  unsigned short value_length;
  unsigned char *value;
} __attribute((packed)) ContentDescriptor;

#endif /* ASFMETADATA_H */
