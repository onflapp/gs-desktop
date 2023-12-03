#include <stdlib.h>

#ifdef GNUSTEP
#define BOOL XWINDOWSBOOL	// prevent X windows BOOL
#include <X11/Xlib.h>		// warning
#undef BOOL
#endif

#define RAND ((float)rand()/(float)RAND_MAX)
 
float randBetween(float lower, float upper)
{
  float result = 0.0;
  
  if (lower > upper) 
    {
      float temp = 0.0;
      temp = lower; lower = upper; upper = temp;
    }
  result = ((upper - lower) * RAND + lower);
  return result;
}

