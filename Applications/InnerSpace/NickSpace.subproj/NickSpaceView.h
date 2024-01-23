#import <AppKit/AppKit.h>

#define RIGHT 0
#define LEFT 1
#define UP 2
#define DOWN 3

#define HORSIZE (horCount * (vertCount + 1))
#define VERTSIZE ((horCount + 1) * vertCount)

#define HOREDGE(I,J) (horEdges[(vertCount + 1)*(I) + (J)])
#define VERTEDGE(I,J) (vertEdges[vertCount*(I) + (J)])

typedef struct {
  int row, col;
} intPair;

typedef struct {
  intPair tailEdge;
  int    tailOrient;
  intPair headEdge;   /* head edge */
  int     headOrient; /* orientation of headEdge */
  int     maxLength;
  int     currentLength; 
  BOOL    dead;       /* YES if head edge currently can't progress */
} trail;

@interface NickSpaceView : NSView
{
  id spaceControl;
  id countControl;
  id lengthControl;
  id colorWell;
  id colorScrollers;
  id addRemoveButtons;
  id numColorsField;
  
  int horCount, vertCount;
  char *horEdges, *vertEdges;
  
  int lastLevel;
  BOOL firstTime;
  
  id inspector;
  
  id image;	
  
  float tcRatio;
  int trailCount;
  trail *trails;
  
  int spacing;
  
  float tlRatio;
  int maxTrailLen;
  int minTrailLen;
  
  
  int numColors;
  int currColor;
  NSMutableArray *colors;
  
}

- (void)calcNext;
- (void)oneStep;
- (id)newSize:(BOOL)freeOld;
- (id)startTrails;
- (id)inspector:(id)sender;

- (id)updateCurrColor:(id)sender;
- (id)scrollColor:(id)sender;
- (id)addColor:(id)sender;
- (id)removeColor:(id)sender;

- (id)getSpacingFrom:(id)sender;
- (id)getNumberFrom:(id)sender;
- (id)getMaxLenFrom:(id)sender;

@end
