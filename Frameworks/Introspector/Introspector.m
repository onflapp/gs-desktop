/*
   Project: Introspector

   Created: 2023-05-28 22:07:30 +0200 by oflorian

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "Introspector.h"

char* obj_intro_info(id val) {
  char *address = (char*)val;
  Class thisclass = object_getClass(val);
  Class superclass = class_getSuperclass(thisclass);
  printf("%s (%p)\n", class_getName(thisclass), address);
  while (superclass != Nil) {
    const char *name = class_getName(superclass);
    printf(": %s\n", name);
    superclass = class_getSuperclass(superclass);
  }
  return address;
}

char* obj_intro_descripion(id val) {
  char *address = (char*)val;
  char *desc = [[val description]cString];
  printf("%s\n", desc);
  return address;
}

char* obj_intro_list_ivars(id val) {
  unsigned int count = 0;
  Ivar *ivarList = class_copyIvarList([val class], &count);
  
  obj_intro_info(val);

  char *address = (char*)val;
  for (int i = 0; i < count; i++) {
    Ivar ivar = ivarList[i];
    const char *name = ivar_getName(ivar);
    const char *type = ivar_getTypeEncoding(ivar);
    ptrdiff_t offset = ivar_getOffset(ivar);
    printf("\t%s %s (%p)\n", name, type, (address + offset));
    //id vv = object_getIvar(val, ivar);
  }

  return address;
}

char* obj_intro_list_ivars_name(id val, char* iname) {
  unsigned int count = 0;
  Ivar *ivarList = class_copyIvarList([val class], &count);
  
  obj_intro_info(val);

  char *address = (char*)val;
  for (int i = 0; i < count; i++) {
    Ivar ivar = ivarList[i];
    const char *name = ivar_getName(ivar);
    if (!strcmp(name, iname)) {
      ptrdiff_t offset = ivar_getOffset(ivar);
      printf("\t%s (%p)\n", name, (address + offset));
      return address+offset;
    }
    //id vv = object_getIvar(val, ivar);
  }

  return NULL;
}
