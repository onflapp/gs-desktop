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

void introsp_print_info(id val) {
  if (!val) {
    printf("nil\n");
    return;
  }

  char *address = (char*)val;
  Class thisclass = object_getClass(val);
  Class superclass = class_getSuperclass(thisclass);
  printf("%s (%p)\n", class_getName(thisclass), address);
  while (superclass != Nil) {
    const char *name = class_getName(superclass);
    printf(": %s\n", name);
    superclass = class_getSuperclass(superclass);
  }
}

void introsp_print_descripion(id val) {
  if (!val) {
    printf("nil\n");
    return;
  }
  else {
    if ([val respondsToSelector:@selector(debugDescription)]) {
      const char *desc = [[val debugDescription]cString];
      printf("%s\n", desc);
      return;
    }
    else {
      const char *desc = [[val description]cString];
      printf("%s\n", desc);
      return;
    }
  }
}

void introsp_print_methods_all(id val, int format) {
  unsigned int count = 0;
  Method *methodList = class_copyMethodList([val class], &count);
  if (!count) {
    return;
  }
  
  for (int i = 0; i < count; i++) {
    Method method = methodList[i];
    SEL sel = method_getName(method);
    const char *name = sel_getName(sel);
    Method cm = class_getClassMethod([val class], sel);

    if (cm) {
     if (format) printf("+ %s\n", name);
    }
    else {
      printf("- %s\n", name);
    }
  }

  free(methodList);
}

void introsp_print_methods(id val) {
  introsp_print_methods_all(val, 0);
}

void introsp_print_ivar_description(id val, Ivar ivar) {
  const char *type = ivar_getTypeEncoding(ivar);
  const char *name = ivar_getName(ivar);
  if (*type == '@') {
    id ival = object_getIvar(val, ivar);
    if (!ival) {
      printf("(%s) %s = nil\n", type, name);
    }
    else {
      if ([ival respondsToSelector:@selector(debugDescription)]) {
        const char *desc = [[ival debugDescription]cString];
        printf("(%s) %s = %s\n", type, name, desc);
      }
      else {
        const char *desc = [[ival description]cString];
        printf("(%s) %s = %s\n", type, name, desc);
      }
    }
  }
  else if (*type == 'q') {
    long long ival = (long long)object_getIvar(val, ivar);
    printf("(%s) %s = %lld\n", type, name, ival);
  }
  else if (*type == 'Q') {
    unsigned long long ival = (unsigned long long)object_getIvar(val, ivar);
    printf("(%s) %s = %lld\n", type, name, ival);
  }
  else if (*type == 'C') {
    unsigned char ival = (unsigned char)object_getIvar(val, ivar);
    printf("(%s) %s = %c\n", type, name, ival);
  }
  else {
    printf("(%s) %s = ???\n", type, name);
  }
}

void introsp_print_ivars_all(id val, int format) {
  unsigned int count = 0;
  Ivar *ivarList = class_copyIvarList([val class], &count);
  if (!count) {
    return;
  }
  
  char *address = (char*)val;
  for (int i = 0; i < count; i++) {
    Ivar ivar = ivarList[i];
    if (format == 1) {
      introsp_print_ivar_description(val, ivar);
    }
    else {
      const char *name = ivar_getName(ivar);
      const char *type = ivar_getTypeEncoding(ivar);
      ptrdiff_t offset = ivar_getOffset(ivar);
      printf("%s %s (%p)\n", name, type, (address + offset));
    }
  }

  free(ivarList);
}

id introsp_get_ivar_value(id val, const char* iname) {
  unsigned int count = 0;
  Ivar *ivarList = class_copyIvarList([val class], &count);
  if (!count) {
    return NULL;
  }
 
  id ival = NULL; 
  for (int i = 0; i < count; i++) {
    Ivar ivar = ivarList[i];
    const char *name = ivar_getName(ivar);
    const char *type = ivar_getTypeEncoding(ivar);
    if (strcmp(name, iname) == 0) {
      ival = object_getIvar(val, ivar);
      break;
    }
  }

  free(ivarList);

  return ival;
}

id introsp_get_ivar_value_r(id val, const char* inames) {
  if (!inames || !val) return nil;

  id ival = val;
  int sz = strlen(inames);
  char *buff = malloc(sz);
  strcpy(buff, inames);
  char *p = strtok(buff, ".");
  while(p != NULL) {
    ival = introsp_get_ivar_value(ival, p);
    if (ival) {
      p = strtok(NULL, ".");
    }
    else {
      break;
    }
  }
  free(buff);
  return ival;
}

void introsp_print_ivars(id val) {
  introsp_print_ivars_all(val, 0);
}

@implementation Introspector

- (id) initWithObject:(id) obj {
  self = [super init];

  _object = [obj retain];

  return self;
}

- (void) printDescription {
  [Introspector printDescription:_object];
}

- (void) printObject {
  [Introspector printObject:_object];
}

- (void) printMethods {
  [Introspector printMethods:_object];
}

+ (void) printDescription:(id)val {
  introsp_print_descripion(val);
}

+ (void) printObject:(id)val {
  introsp_print_info(val);
  introsp_print_ivars_all(val, 1);
}

+ (void) printVariable:(NSString*) name inObject:(id)val {
  id ival = introsp_get_ivar_value_r(val, [name cString]);
  if (!ival) {
    printf("nil\n");
  }
  else {
    introsp_print_info(ival);
    introsp_print_ivars_all(ival, 1);
  }
}


+ (void) printMethods:(id)val {
  introsp_print_methods(val);
}

@end

@implementation NSObject (Introspect)

- (Introspector*) introspect {
  return [[[Introspector alloc] initWithObject:self] autorelease];
}

@end
