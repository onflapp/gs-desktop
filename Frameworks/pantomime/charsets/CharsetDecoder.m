/*
**  CharsetDecoder.m
**
**  Copyright (c) 2001-2004
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "CharsetDecoder.h"

@implementation CharsetDecoder
@end

int main(int argc, const char *argv[], char *env[])
{
  CREATE_AUTORELEASE_POOL(pool);
  FILE *stream;
  char *aLine;
  char *basename,*c;
  char *charsetname;
  int i;
  
  int code;
  unichar value[2];
  char buf[80];

  if (argc != 2)
    {
      printf("\nUsage:  openapp CharsetDecoder.app filename.txt\n\n");
      RELEASE(pool);
      exit(0);
    }

  basename=strdup(argv[1]);
  for (c=basename;*c!='.';c++)
  {
    *c=toupper(*c);
    if (*c=='-') *c='_';
  }
  *c=0;

  charsetname=strdup(argv[1]);
  *strchr(charsetname,'.')=0;
  if (!strncmp(charsetname,"iso",3))
    {
      memmove(&charsetname[4],&charsetname[3],strlen(charsetname)-3+1);
      charsetname[3]='-';
    }
  
  aLine = (char*)malloc(sizeof(char)*1024);
  value[1] = 0;
  
  stream = fopen(argv[1], "r");

  printf(
  "#include <Pantomime/%s.h>\n"         /* basename */
  "\n"
  "static struct charset_code code_table[]={",
  basename);

  i=0;
  while (fgets(aLine, 128, stream) != NULL)
    {
      if (!i++) printf("\n");
      if (i==5) i=0;
      sscanf(aLine, "=%02x\tU+%04x\t%s", &code, value, buf);
      printf("{0x%02x,0x%04x}, ",code,value[0]);
    }

  printf(
  "};\n"
  "\n"
  "@implementation %s\n" /* basename */
  "\n"
  "- (id) init\n"
  "{\n"
  "\treturn [super initWithCodeCharTable: code_table  length: sizeof(code_table)/sizeof(code_table[0])];\n"
  "}\n\n"
  "- (NSString *) name\n"
  "{\n"
  "\treturn @\"%s\";\n" /* charsetname */
  "}\n"
  "\n"
  "@end\n"
  "\n",basename,charsetname);

  free(aLine);
  
  RELEASE(pool);
  exit(0);
}
