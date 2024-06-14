#import "NickSpaceView.h"
#import <AppKit/AppKit.h>
#import <time.h>
#import <limits.h>

#define COLORWIDTH 2
#define ERASEWIDTH 5

/** Draw a line segment */
void doSeg(float x1, float y1, float x2, float y2)
{
  PSmoveto(x1,y1);
  PSlineto(x2,y2);
}

@interface NSColor (GetColorsFromString)
+ (NSColor *)colorFromStringRepresentation:(NSString *)colorString;
- (NSString *)stringRepresentation;
@end

@implementation NSColor (GetColorsFromString)
+ (NSColor *)colorFromStringRepresentation:(NSString *)colorString
{
    CGFloat r, g, b, a;
    NSArray *array = [colorString componentsSeparatedByString:@" "];
    if(!array) return nil;
    if([array count] < 3) {
        NSLog(@"%@: + colorFromStringRepresentation", [[self class] description]);
        NSLog(@"%@: String must contain red, green, and blue components", [[self class] description]);
        return nil;
    }
    r = [[array objectAtIndex:0] floatValue];
    g = [[array objectAtIndex:1] floatValue];
    b = [[array objectAtIndex:2] floatValue];
    a = [array count] > 3 ? [[array objectAtIndex:3] floatValue] : 1.0;
    NSColor* c = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
    return c;
}

- (NSString *)stringRepresentation
{
    CGFloat r, g, b, a;
    [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
    NSString* s = [NSString stringWithFormat:@"%f %f %f %f",r,g,b,a];
    return s;
}
@end

@interface NSString (ColorValue)
- (NSColor *) colorValue;
@end

@implementation NSString (ColorValue)
- (NSColor *) colorValue
{
  return [NSColor colorFromStringRepresentation: self];
}
@end

@implementation NickSpaceView

- (void) calcNext
{
  int i, j;
  BOOL tryingLeft, tryingRight;  // with respect to the CURRENT ORIENTATION!!
  
  
  for (i=0;i<trailCount;i++) {
    if ((!trails[i].dead && trails[i].maxLength > trails[i].currentLength) ||
	trails[i].currentLength<=1) 
      continue;
    
    if (trails[i].tailOrient == UP || trails[i].tailOrient == DOWN)
      VERTEDGE(trails[i].tailEdge.row,trails[i].tailEdge.col) = 0;
    else
      HOREDGE(trails[i].tailEdge.row,trails[i].tailEdge.col) = 0;
    
    trails[i].currentLength--;
    
    /* update tail edges */	
    switch (trails[i].tailOrient) {
      
    case UP:
      if (VERTEDGE(trails[i].tailEdge.row+1,trails[i].tailEdge.col))
	trails[i].tailEdge.row++;
      else if (HOREDGE(trails[i].tailEdge.row,trails[i].tailEdge.col))
	trails[i].tailOrient = LEFT;
      else if (HOREDGE(trails[i].tailEdge.row,trails[i].tailEdge.col+1)) {
	trails[i].tailEdge.col++;
	trails[i].tailOrient = RIGHT;
      }
      break;
      
    case DOWN:
      if (VERTEDGE(trails[i].tailEdge.row-1,trails[i].tailEdge.col))
	trails[i].tailEdge.row--;
      else if (HOREDGE(trails[i].tailEdge.row-1,trails[i].tailEdge.col)) {
	trails[i].tailEdge.row--;
	trails[i].tailOrient = LEFT;
      }
      else if (HOREDGE(trails[i].tailEdge.row-1,trails[i].tailEdge.col+1)) {
	trails[i].tailEdge.row--;
	trails[i].tailEdge.col++;
	trails[i].tailOrient = RIGHT;
      }
      break;
      
    case RIGHT:
      if (HOREDGE(trails[i].tailEdge.row,trails[i].tailEdge.col+1))
	trails[i].tailEdge.col++;
      else if (VERTEDGE(trails[i].tailEdge.row,trails[i].tailEdge.col))
	trails[i].tailOrient = DOWN;
      else if (VERTEDGE(trails[i].tailEdge.row+1,trails[i].tailEdge.col)) {
	trails[i].tailEdge.row++;
	trails[i].tailOrient = UP;
      }
      break;
      
    case LEFT:
      if (HOREDGE(trails[i].tailEdge.row,trails[i].tailEdge.col-1))
	trails[i].tailEdge.col--;
      else if (VERTEDGE(trails[i].tailEdge.row,trails[i].tailEdge.col-1)) {
	trails[i].tailEdge.col--;
	trails[i].tailOrient = DOWN;
      }
      else if (VERTEDGE(trails[i].tailEdge.row+1,trails[i].tailEdge.col-1)) {
	trails[i].tailEdge.row++;
	trails[i].tailEdge.col--;
	trails[i].tailOrient = UP;
      }
      break;
    }
  }
  
  /* update head edges */
  for (i=0;i<trailCount;i++) {
    if (firstTime) {
      trails[i].headEdge = trails[i].tailEdge;
      trails[i].tailOrient = trails[i].headOrient;
    } else {
      trails[i].dead = NO;
      switch (trails[i].headOrient) {
	
      case UP: 
	if (trails[i].headEdge.row < horCount - 1 &&
	    !VERTEDGE(trails[i].headEdge.row + 2,trails[i].headEdge.col) &&
	    !HOREDGE(trails[i].headEdge.row + 1,trails[i].headEdge.col) &&
	    !HOREDGE(trails[i].headEdge.row + 1,trails[i].headEdge.col + 1))
	  trails[i].headEdge.row++; /* continue UP */
	else {
	  tryingLeft = (BOOL)random()%2;
	  for (j=0;j<2;j++) {
	    if (tryingLeft) {
	      if (trails[i].headEdge.col > 0 &&
		  !VERTEDGE(trails[i].headEdge.row,trails[i].headEdge.col-1) &&
		  !VERTEDGE(trails[i].headEdge.row+1,trails[i].headEdge.col-1) &&
		  !HOREDGE(trails[i].headEdge.row,trails[i].headEdge.col-1)) {
		trails[i].headOrient = LEFT;
		break;
	      }	
	    } else {
	      if (trails[i].headEdge.col < vertCount - 1 &&
		  !VERTEDGE(trails[i].headEdge.row,trails[i].headEdge.col+1) &&
		  !VERTEDGE(trails[i].headEdge.row+1,trails[i].headEdge.col+1) &&
		  !HOREDGE(trails[i].headEdge.row,trails[i].headEdge.col+2)) {
		trails[i].headEdge.col++;
		trails[i].headOrient = RIGHT;
		break;
	      }
	    }
	    if (j==1)
	      trails[i].dead = YES;
	    else
	      tryingLeft = 1 - tryingLeft;
	  }
	}
	break;
	
      case DOWN: 
	if (trails[i].headEdge.row > 1 &&
	    !VERTEDGE(trails[i].headEdge.row - 2,trails[i].headEdge.col) &&
	    !HOREDGE(trails[i].headEdge.row - 2,trails[i].headEdge.col) &&
	    !HOREDGE(trails[i].headEdge.row - 2,trails[i].headEdge.col + 1))
	  trails[i].headEdge.row--; /* continue DOWN */
	else {
	  tryingRight = (BOOL)random()%2;
	  for (j=0;j<2;j++) {
	    if (tryingRight) {
	      if (trails[i].headEdge.col > 0 &&
		  !VERTEDGE(trails[i].headEdge.row,trails[i].headEdge.col-1) &&
		  !VERTEDGE(trails[i].headEdge.row-1,trails[i].headEdge.col-1) &&
		  !HOREDGE(trails[i].headEdge.row-1,trails[i].headEdge.col-1)) {
		trails[i].headEdge.row--;
		trails[i].headOrient = LEFT;
		break;
	      }	
	    } else {
	      if (trails[i].headEdge.col < vertCount - 1 &&
		  !VERTEDGE(trails[i].headEdge.row,trails[i].headEdge.col+1) &&
		  !VERTEDGE(trails[i].headEdge.row-1,trails[i].headEdge.col+1) &&
		  !HOREDGE(trails[i].headEdge.row-1,trails[i].headEdge.col+2)) {
		trails[i].headEdge.col++;
		trails[i].headEdge.row--;
		trails[i].headOrient = RIGHT;
		break;
	      }
	    }
	    if (j==1)
	      trails[i].dead = YES;
	    else
	      tryingRight = 1 - tryingRight;
	  }
	}
	break;
	
      case RIGHT:
	if (trails[i].headEdge.col < vertCount - 1 &&
	    !HOREDGE(trails[i].headEdge.row,trails[i].headEdge.col+2) &&
	    !VERTEDGE(trails[i].headEdge.row,trails[i].headEdge.col + 1) &&
	    !VERTEDGE(trails[i].headEdge.row + 1,trails[i].headEdge.col + 1))
	  trails[i].headEdge.col++; // continue RIGHT
	else {
	  tryingRight = (BOOL)random()%2;
	  for (j=0;j<2;j++) {
	    if (tryingRight) {
	      if (trails[i].headEdge.row > 0 && 
		  !HOREDGE(trails[i].headEdge.row-1,trails[i].headEdge.col) &&
		  !HOREDGE(trails[i].headEdge.row-1,trails[i].headEdge.col+1) &&
		  !VERTEDGE(trails[i].headEdge.row-1,trails[i].headEdge.col)) {
		trails[i].headOrient = DOWN;
		break;
	      }
	    } else {
	      if (trails[i].headEdge.row < horCount - 1 &&
		  !HOREDGE(trails[i].headEdge.row+1,trails[i].headEdge.col) &&
		  !HOREDGE(trails[i].headEdge.row+1,trails[i].headEdge.col+1) &&
		  !VERTEDGE(trails[i].headEdge.row+2,trails[i].headEdge.col)) {
		trails[i].headEdge.row++;
		trails[i].headOrient = UP;
		break;
	      }
	    }
	    if (j==1)
	      trails[i].dead = YES;
	    else
	      tryingRight = 1 - tryingRight;
	  }	
	}
	break;
	
      case LEFT:
	if (trails[i].headEdge.col > 1 &&
	    !HOREDGE(trails[i].headEdge.row,trails[i].headEdge.col-2) &&
	    !VERTEDGE(trails[i].headEdge.row+1,trails[i].headEdge.col-2) &&
	    !VERTEDGE(trails[i].headEdge.row,trails[i].headEdge.col-2))
	  trails[i].headEdge.col--; // continue LEFT
	else {
	  tryingLeft = (BOOL)random()%2;
	  for (j=0;j<2;j++) {
	    if (tryingLeft) {
	      if (trails[i].headEdge.row > 0 && 
		  !HOREDGE(trails[i].headEdge.row-1,trails[i].headEdge.col) &&
		  !HOREDGE(trails[i].headEdge.row-1,trails[i].headEdge.col-1) &&
		  !VERTEDGE(trails[i].headEdge.row-1,trails[i].headEdge.col-1)) {
		trails[i].headEdge.col--;
		trails[i].headOrient = DOWN;
		break;
	      }
	    } else {
	      if (trails[i].headEdge.row < horCount - 1 &&
		  !HOREDGE(trails[i].headEdge.row+1,trails[i].headEdge.col) &&
		  !HOREDGE(trails[i].headEdge.row+1,trails[i].headEdge.col-1) &&
		  !VERTEDGE(trails[i].headEdge.row+2,trails[i].headEdge.col-1)) {
		trails[i].headEdge.row++;
		trails[i].headEdge.col--;
		trails[i].headOrient = UP;
		break;
	      }
	    }
	    if (j==1)
	      trails[i].dead = YES;
	    else
	      tryingLeft = 1 - tryingLeft;
	  }	
	}
      }
      if (!trails[i].dead)
	trails[i].currentLength++;
    }
    if (!trails[i].dead) {
      if (trails[i].headOrient == UP || trails[i].headOrient == DOWN) 
	VERTEDGE(trails[i].headEdge.row,trails[i].headEdge.col) = 1;
      else
	HOREDGE(trails[i].headEdge.row,trails[i].headEdge.col) = 1;
    }
    
  }
  
  firstTime = 0;
}

-(void)oneStep
{
  int i, level, currCol;
  NSRect bounds = [self bounds];

  
  /* if window level changed, reinitialize and decide whether to buffer or not */
  level = [[self window] level];
  if (level != lastLevel) 
    {
      lastLevel = level;
      if (level < NSNormalWindowLevel) 
	{
	  [self newSize:YES];
	  image = [[NSImage alloc] initWithSize: bounds.size];
	  [image lockFocus];
	  PSsetgray(0);
	  NSRectFill(bounds);
	  [image unlockFocus];
      } 
      else 
	{
	  [self newSize:YES];
	  if (image) 
	    {
	      [image release];
	      image = nil;
	    }
	}
    }
  
  /* erase tail edges, as needed (calc'ed last time through */
  PSsetgray(0);
  PSsetlinewidth(ERASEWIDTH);
  for (i=0;i<trailCount;i++) 
    {
      if ((!trails[i].dead && trails[i].maxLength > trails[i].currentLength) ||
	  trails[i].currentLength<=1) 
	continue;
      
      if (trails[i].tailOrient == UP || trails[i].tailOrient == DOWN) 
	{
	  doSeg((float)((trails[i].tailEdge.col + 1) * spacing),
		(float)(trails[i].tailEdge.row * spacing),
		(float)((trails[i].tailEdge.col + 1) * spacing),
		(float)((trails[i].tailEdge.row + 1) * spacing));
	} 
      else 
	{
	  doSeg((float)(trails[i].tailEdge.col * spacing),
		(float)((trails[i].tailEdge.row + 1) * spacing),
		(float)((trails[i].tailEdge.col + 1) * spacing),
		(float)((trails[i].tailEdge.row + 1) * spacing));
	}
    }
  PSstroke();
  
  if (image) 
    {
      [image lockFocus];
      /* erase tail edges, as needed (calc'ed last time through) */
      PSsetgray(0);
      PSsetlinewidth(ERASEWIDTH);
      for (i=0;i<trailCount;i++) 
	{
	  if ((!trails[i].dead && trails[i].maxLength > trails[i].currentLength) ||
	      trails[i].currentLength<=1) 
	    continue;

	  if (trails[i].tailOrient == UP || trails[i].tailOrient == DOWN) 
	    {
	      doSeg((float)((trails[i].tailEdge.col + 1) * spacing),
		    (float)(trails[i].tailEdge.row * spacing),
		    (float)((trails[i].tailEdge.col + 1) * spacing),
		    (float)((trails[i].tailEdge.row + 1) * spacing));
	    } 
	  else 
	    {
	      doSeg((float)(trails[i].tailEdge.col * spacing),
		    (float)((trails[i].tailEdge.row + 1) * spacing),
		    (float)((trails[i].tailEdge.col + 1) * spacing),
		    (float)((trails[i].tailEdge.row + 1) * spacing));
	    }
	}
    PSstroke();
    [image unlockFocus];
  }
  
  
  [self calcNext];
  
  /* draw head edges, as needed */
  currCol = 0; // historical accident--careful not to confuse with currColor
  [[[colors objectAtIndex: currCol] colorValue] set];
  for(i = 0;i<trailCount; i++) 
    {
      PSsetlinewidth(COLORWIDTH);
      if (i==(trailCount*(currCol+1))/numColors) 
	{
	  currCol++;
	  PSstroke();
	  [[[colors objectAtIndex: currCol] colorValue] set];
	}			
      if (trails[i].dead)
	continue;
      if (trails[i].headOrient == UP || trails[i].headOrient == DOWN) 
	{
	  PSmoveto((float)((trails[i].headEdge.col + 1) * spacing),
		   (float)(trails[i].headEdge.row * spacing));
	  PSlineto((float)((trails[i].headEdge.col + 1) * spacing),
		   (float)((trails[i].headEdge.row + 1) * spacing));
	} 
      else 
	{
	  PSmoveto((float)(trails[i].headEdge.col * spacing),
		   (float)((trails[i].headEdge.row + 1) * spacing));
	  PSlineto((float)((trails[i].headEdge.col + 1) * spacing),
		   (float)((trails[i].headEdge.row + 1) * spacing));
	}
    }	
  PSstroke();
  
  if (image)
    {
      [image lockFocus];
      currCol = 0;
      [[[colors objectAtIndex: currCol] colorValue] set];
      PSsetlinewidth(COLORWIDTH);
      for(i = 0;i<trailCount; i++) 
	{
	  if (i==(trailCount*(currCol+1))/3) 
	    {
	      currCol++;
	      PSstroke();
	      [[[colors objectAtIndex: currCol] colorValue] set];
	    }			

	  if (trails[i].dead)
	    continue;

	  if (trails[i].headOrient == UP || trails[i].headOrient == DOWN) 
	    {
	      PSmoveto((float)((trails[i].headEdge.col + 1) * spacing),
		       (float)(trails[i].headEdge.row * spacing));
	      PSlineto((float)((trails[i].headEdge.col + 1) * spacing),
		       (float)((trails[i].headEdge.row + 1) * spacing));
	    } 
	  else 
	    {
	      PSmoveto((float)(trails[i].headEdge.col * spacing),
		       (float)((trails[i].headEdge.row + 1) * spacing));
	      PSlineto((float)((trails[i].headEdge.col + 1) * spacing),
		       (float)((trails[i].headEdge.row + 1) * spacing));
	    }
	}	
      PSstroke();
      [image unlockFocus];
    }		
}

-(id)initWithFrame:(NSRect)frameRect
{
  //NSString *defaults = @"{\"spacing\" = \"\"; \"tcRatio\" = \"\"; \"tlRatio\" = \"\";}";
  //NSDictionary *defDict = [defaults propertyList];
  NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
  int i;
  
  srandom(time(0));
  
  if((self = [super initWithFrame: frameRect]) != nil)
    {
  
      /* these are preserved from bezierView--I don't know if they're doing any good */
      [self allocateGState];		// For faster lock/unlockFocus
      // [self setClipping:NO];		// even faster...
      
      /* Miscellaneous initializations */
      image = nil;
      lastLevel = 0;
      
      if(![NSBundle loadNibNamed: @"NickSpace" owner:self])
	{
	  NSLog(@"Failed to load inspector");
	}
      
      /* Set target/action for buttons in the matrix */
      [[addRemoveButtons cellAtRow:0 column:0] setTarget:self];
      [[addRemoveButtons cellAtRow:0 column:0] setAction:@selector(addColor:)];
      [[addRemoveButtons cellAtRow:1 column:0] setTarget:self];
      [[addRemoveButtons cellAtRow:1 column:0] setAction:@selector(removeColor:)];
      
      /* Check the first default; if it hasn't been written before, get all
       * parameters from the controls; else,  read all defaults and set the controls
       */
      if ([[userDef stringForKey: @"spacing"] length] == 0) 
	{
	  // Some empirically determined initial settings:
	  spacing = 8;
	  tcRatio = .6;
	  tlRatio = 1.0;
	  
	  numColors = 10;
	  currColor = 0;
	  colors = [[NSMutableArray alloc] init];
	  
	  [userDef setFloat: spacing forKey: @"spacing"];
	  [userDef setFloat: tcRatio forKey: @"tcRatio"];
	  [userDef setFloat: tlRatio forKey: @"tlRatio"];
	  [userDef setInteger: numColors forKey: @"numColors"];
	  
	  // randomize an initial set of colors:
	  for (i=0;i<numColors;i++) 
	    {
	      float red = (float)random()/(float)INT_MAX;
	      float green = (float)random()/(float)INT_MAX;
	      float blue = (float)random()/(float)INT_MAX;
	      NSColor *color = [NSColor colorWithCalibratedRed: red
					green: green
					blue: blue
					alpha: 1.0];
	      [colors addObject: [color stringRepresentation]];
	    }
	  
	  [userDef setObject: colors forKey: @"colors"];
	} 
      else 
	{
	  spacing = (float)[userDef floatForKey: @"spacing"];
	  tcRatio = (float)[userDef floatForKey: @"tcRatio"];
	  tlRatio = (float)[userDef floatForKey: @"tlRatio"];
	  numColors = [userDef integerForKey: @"numColors"];
	  colors = [[NSMutableArray alloc] initWithArray: AUTORELEASE([userDef arrayForKey: @"colors"])];
	  currColor = 0;
	}
      
      [spaceControl setIntValue:(int)spacing];
      [countControl setFloatValue:(float)tcRatio];
      [lengthControl setFloatValue:(float)tlRatio];
      [colorWell setColor: [[colors objectAtIndex: currColor] colorValue]]; 
      [numColorsField setStringValue: [NSString stringWithFormat: @"%d/%d", currColor+1, numColors]];
      
      [self newSize:NO];
    }
  return self;
}

- (void) setFrame: (NSRect)frame
{
  [super setFrame: frame];
  [self newSize:YES];
}

/*
- drawSelf:(const NXRect *)rects :(int)rectCount
{
  int i;
  if (!rects || !rectCount) return self;
  
  for (i=0;i<rectCount;i++)
    [image composite:NX_COPY fromRect:&(rects[i]) toPoint:&(rects[i].origin)];
  
  return self;
}
*/

- (void) drawRect:(NSRect)rects
{
  PSsetlinewidth(0);
  PSsetgray(0);
  NSRectFill(rects);	
}

/* next two methods do initializations */
- newSize:(BOOL)freeOld;
{
  NSRect bounds = [self bounds];

  if (freeOld) {
    free(horEdges);
    free(vertEdges);
    free(trails);
  }
  
  horCount = (int)((bounds.size.height - 5.0) / spacing);
  vertCount = (int)((bounds.size.width - 5.0) / spacing);
  
  horEdges = (char *)malloc(HORSIZE);
  vertEdges = (char *)malloc(VERTSIZE);
  bzero(horEdges,HORSIZE);
  bzero(vertEdges,VERTSIZE);
  
  trailCount = (int)((vertCount + horCount) * tcRatio);
  trailCount = trailCount ? trailCount : 1;
  trails = (trail *)malloc(sizeof(trail)*trailCount);
  
  maxTrailLen = (vertCount + horCount) * 4 * tlRatio;
  minTrailLen = maxTrailLen/40;
  maxTrailLen = maxTrailLen < 2 ? 2 : maxTrailLen;
  minTrailLen = minTrailLen < 2 ? 2 : minTrailLen;
  
  firstTime = YES;
  
  [self startTrails];
  
  if ([self window]) {
    [self lockFocus];
    PSsetgray(0);
    NSRectFill(bounds);
    [self unlockFocus];
  }
  
  if (image){
    [image lockFocus];
    PSsetgray(0);
    NSRectFill(bounds);
    [image unlockFocus];
  }
  
  return self;
}

- startTrails
{
  int i,j;
  BOOL dup;
  int initPos[trailCount];
  
  
  /* This could potentially take arbitrarily long--should tighten up;
   */	
  for (i=0;i<trailCount;) {
    dup = NO;
    if (trailCount < vertCount + horCount) {
      initPos[i] = (random() % (vertCount + horCount))*2;
      for (j=0;j<i;j++) {
	if (initPos[j] == initPos[i]) {
	  dup = YES;
	  break;
	}
      }
    } else
      initPos[i] = i * 2;
    if (!dup) 
      i++;
  }
  
  for (i=0;i<trailCount;i++) {
    trails[i].currentLength = 1;
    if (tlRatio == 1.0)
      trails[i].maxLength = INT_MAX;
    else
      trails[i].maxLength = (random() % ((maxTrailLen - minTrailLen) + 1) + minTrailLen);
    trails[i].dead = NO;
    if (initPos[i] < vertCount) {
      trails[i].tailEdge.row = 0;
      trails[i].tailEdge.col = initPos[i];
      trails[i].headOrient = UP;
      continue;
    }
    if (vertCount <= initPos[i] && initPos[i] < vertCount + horCount) {
      trails[i].tailEdge.row = initPos[i] - vertCount;
      trails[i].tailEdge.col = vertCount;
      trails[i].headOrient = LEFT;
      continue;
    }
    if (vertCount + horCount <= initPos[i] && initPos[i] < (2*vertCount + horCount)) {
      trails[i].tailEdge.row = horCount;
      trails[i].tailEdge.col = initPos[i] - (vertCount + horCount);
      trails[i].headOrient = DOWN;
      continue;
    }
    trails[i].tailEdge.row = initPos[i] - (2*vertCount + horCount);
    trails[i].tailEdge.col = 0;
    trails[i].headOrient = RIGHT;
  }
  
  return self;
}

- (id)inspector:(id)sender
{
  return inspector;
}

- (id)updateCurrColor:(id)sender
{
  NSColor *color = [sender color];
  [colors replaceObjectAtIndex: currColor withObject: [color stringRepresentation]];
  [[NSUserDefaults standardUserDefaults] setObject: colors forKey: @"colors"];
  return self;
}

- (id)scrollColor:(id)sender
{  
  if ([sender selectedRow]==1)
    currColor = currColor==0 ? numColors-1 : currColor-1;
  else
    currColor = (currColor + 1)%numColors;
  
  [colorWell setColor: [[colors objectAtIndex: currColor] colorValue]];
  [numColorsField setStringValue: [NSString stringWithFormat: @"%d/%d", currColor+1, numColors]];
  return self;
}

- (id)addColor:(id)sender
{
  float 
    red = (float)random()/(float)LONG_MAX, 
    green = (float)random()/(float)LONG_MAX, 
    blue = (float)random()/(float)LONG_MAX;
  NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
  NSColor  *color = [NSColor colorWithCalibratedRed: red
			     green: green
			     blue: blue
			     alpha: 1.0];    

  numColors++;
  currColor = numColors-1;
  
  [colors addObject: [color stringRepresentation]];
  
  [userDefs setObject: colors forKey: @"colors"];
  [userDefs setInteger: numColors forKey: @"numColors"];
  [colorWell setColor: color];    
  
  [numColorsField setStringValue: [NSString stringWithFormat: @"%d/%d", currColor+1, numColors]];

  return self;
}

- (id)removeColor: (id)sender
{
  NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
  NSColor *cColor = nil;
  
  if (numColors==1)
    return self;

  [colors removeLastObject];
  [userDefs setObject: colors forKey: @"colors"];

  numColors--;
  [userDefs setInteger: numColors forKey: @"numColors"];  

  currColor %= numColors;  
  cColor = [[colors objectAtIndex: currColor] colorValue];
  [colorWell setColor: cColor];
  [numColorsField setStringValue: [NSString stringWithFormat: @"%d/%d", currColor+1, numColors]];
  
  return self;
}


- getSpacingFrom:sender;
{
  NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
  spacing = [sender intValue];
  [userDefs setInteger: spacing forKey: @"spacing"];  
  [self newSize:YES];
  return self;
}

- getNumberFrom:sender
{
  NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
  tcRatio = [sender floatValue];
  [userDefs setFloat: tcRatio forKey: @"tcRatio"];  
  [self newSize:YES];
  return self;
}

- getMaxLenFrom:sender
{
  NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
  tlRatio = [sender floatValue];
  [userDefs setFloat: tlRatio forKey: @"tlRatio"];  
  [self newSize:YES];
  return self;
}

@end
