// ADPersonView.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address View Framework for GNUstep
// 
// $Author: buzzdee $
// $Locker:  $
// $Revision: 1.9 $
// $Date: 2013/02/23 14:25:21 $

#import "ADPersonView.h"
#import "ADPersonPropertyView.h"
#import "ADImageView.h"

NSString * const ADPersonNameChangedNotification = @"ADPersonNameChangedNotification";

NSString * const ADPeoplePboardType = @"ADPeoplePboardType";

// redefine _(@"...") so that it looks into our bundle, not the main bundle
#undef _
#define _(x) [[NSBundle bundleForClass: [ADImageView class]] \
		   localizedStringForKey: x \
		   value: x \
		   table: nil]

static NSDictionary *_labelDict, *_isoCodeDict, *_addressLayoutDict;
static NSImage *_vcfImage;

static NSString *__defaultCountryCode = nil;

@implementation ADPersonView
+ (void) loadRessources
{
  NSBundle *b; NSString *filename;

  b = [NSBundle bundleForClass: self];
  
  filename = [b pathForResource: @"Labels" ofType: @"dict"];
  _labelDict = [[NSString stringWithContentsOfFile: filename] propertyList];
  NSAssert(_labelDict && [_labelDict isKindOfClass: [NSDictionary class]],
	   @"Labels.dict could not be loaded!\n");
  [_labelDict retain];
  
  filename = [b pathForResource: @"ISOCodeMapping" ofType: @"dict"];
  _isoCodeDict = [[NSString stringWithContentsOfFile: filename] propertyList];
  NSAssert(_isoCodeDict && [_isoCodeDict isKindOfClass: [NSDictionary class]],
	   @"ISOCodeMapping.dict could not be loaded!\n");
  [_isoCodeDict retain];

  filename = [b pathForResource: @"AddressLayouts" ofType: @"dict"];
  _addressLayoutDict = [[NSString stringWithContentsOfFile: filename]
			 propertyList];
  NSAssert(_addressLayoutDict &&
	   [_addressLayoutDict isKindOfClass: [NSDictionary class]],
	   @"AddressLayouts.dict could not be loaded!\n");
  [_addressLayoutDict retain];

  filename = [b pathForResource: @"VCFImage" ofType: @"tiff"];
  _vcfImage = [[NSImage alloc] initWithContentsOfFile: filename];
  NSAssert(_vcfImage &&
	   [_vcfImage isKindOfClass: [NSImage class]],
	   @"VCFImage.tiff could not be loaded!\n");
}

- initWithFrame: (NSRect) frameRect
{
  NSBundle *b; NSString *filename;
  [super initWithFrame: frameRect];

  if(!_labelDict) [[self class] loadRessources];
  
  _person = nil;
  _delegate = nil;
  _editable = NO;
  _acceptsDrop = NO;
  _fontSize = [NSFont systemFontSize];
  _displaysImage = YES;
  _forceImage = NO;

  // load images
  b = [NSBundle bundleForClass: [self class]];
  filename = [b pathForImageResource: @"Lock.tiff"];
  _lockImg = [[NSImage alloc] initWithContentsOfFile: filename];
  NSAssert(_lockImg, @"Image \"Lock.tiff\" could not be loaded!\n");
  filename = [b pathForImageResource: @"Share.tiff"];
  _shareImg = [[NSImage alloc] initWithContentsOfFile: filename];
  NSAssert(_lockImg, @"Image \"Share.tiff\" could not be loaded!\n");

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(superviewFrameChanged:)
    name: NSViewFrameDidChangeNotification
    object: nil];

  [self registerForDraggedTypes: [NSArray arrayWithObjects:
					    @"NSVCardPboardType",
					  NSTIFFPboardType,
					  NSFilenamesPboardType,
					  nil]];
  return self;
}

- (void) dealloc
{
  [_person release];

  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [super dealloc];
}

- (BOOL) isFlipped
{
  return YES;
}

- (int) layoutHeaderAndReturnNextY
{
  ADPersonPropertyView *v;
  NSSize sizeNeeded;
  float IMGWIDTH = _fontSize*5;
  float IMGHEIGHT = IMGWIDTH*(3.0/4.0);

  int x = 5;
  int y = 5;

  if(_forceImage || (_displaysImage && [_person imageDataFile]))
    {
      // Image
      _imageView = [[ADImageView alloc]
		     initWithFrame: NSMakeRect(x, y, IMGWIDTH, IMGHEIGHT)];
      [self addSubview: _imageView];
      [_imageView setTarget: self];
      [_imageView setAction: @selector(imageClicked:)];
      [_imageView setPerson: _person];
      [_imageView setDelegate: self];
      
      x += IMGWIDTH + 10;
    }
  else
    _imageView = nil;
  
  // First name
  v = [[ADPersonPropertyView alloc] initWithFrame: NSMakeRect(x, y, 0, 0)];
  [v setEditable: _editable];
  [v setDelegate: self];
  [v setFontSize: _fontSize*1.5];
  [v setFont: [v boldFont]];
  [v setPerson: _person];
  [v setProperty: ADFirstNameProperty];
  [self addSubview: v];
  sizeNeeded = [v frame].size;
  sizeNeeded.width += [[v font] widthOfString: @"f"];
  sizeNeeded.height += 5;
  
  // Last name
  v = [[ADPersonPropertyView alloc]
	initWithFrame: NSMakeRect(x+sizeNeeded.width, y, 0, 0)];
  [v setEditable: _editable];
  [v setDelegate: self];
  [v setFontSize: _fontSize*1.5];
  [v setFont: [v boldFont]];
  [v setPerson: _person];
  [v setProperty: ADLastNameProperty];
  [self addSubview: v];
  sizeNeeded.width += [v frame].size.width;
  sizeNeeded.height = MAX(sizeNeeded.height, [v frame].size.height);

  y = sizeNeeded.height;
  v = [[ADPersonPropertyView alloc] initWithFrame: NSMakeRect(x, y, 0, 0)];
  [v setEditable: _editable];
  [v setDelegate: self];
  [v setPerson: _person];
  [v setProperty: ADOrganizationProperty];
  [v setFontSize: _fontSize];
  [self addSubview: v];
  if([v frame].size.height)
    sizeNeeded.height += [v frame].size.height;

  // Job title
  y = sizeNeeded.height;
  v = [[ADPersonPropertyView alloc] initWithFrame: NSMakeRect(x, y, 0, 0)];
  [v setEditable: _editable];
  [v setDelegate: self];
  [v setPerson: _person];
  [v setProperty: ADJobTitleProperty];
  [v setFontSize: _fontSize];
  [self addSubview: v];
  if([v frame].size.height)
    sizeNeeded.height += [v frame].size.height;

  if(_imageView)
    _iconY = ([_imageView frame].origin.y +
	      [_imageView frame].size.height + 15);
  else
    _iconY = 0;
  
  return MAX(sizeNeeded.height, _iconY);
}

- (void) layout
{
  NSEnumerator *e;
  NSString *property;
  NSArray *properties;
  int y;
  NSRect noteRect;
  id label;
  NSString *note;

  properties = [NSArray arrayWithObjects: ADBirthdayProperty,
			ADHomePageProperty,
			ADPhoneProperty,
			ADEmailProperty,
			ADAddressProperty,
			ADAIMInstantProperty,
			nil];

  if(_person)
    [self cleanupEmptyProperties];

  while([[self subviews] count])
    [[[self subviews] objectAtIndex: 0] removeFromSuperview];

  if(!_person)
    {
      [self calcSize];
      return;
    }

  y = [self layoutHeaderAndReturnNextY];

  _headerLineY = y + 7;
  y += 15;

  e = [properties objectEnumerator];
  while((property = [e nextObject]))
    {
      ADPersonPropertyView *v;
      
      v = [[ADPersonPropertyView alloc] initWithFrame: NSMakeRect(5, y, 0, 0)];
      [v setEditable: _editable];
      [v setDelegate: self];
      [v setDisplaysLabel: YES];
      [v setPerson: _person];
      [v setProperty: property];
      [v setFontSize: _fontSize];
      [self addSubview: v];

      if([v frame].size.height)
	y += [v frame].size.height + 15;
    }

  _footerLineY = y - 8;

  label = [[[NSTextField alloc] initWithFrame: NSMakeRect(5, y, 100, 100)]
	    autorelease];
  [label setStringValue: _(@"Notes:")];
  [label setEditable: NO]; [label setSelectable: NO];
  [label setBordered: NO]; [label setBezeled: NO];
  [label setDrawsBackground: NO];
  [label setFont: [NSFont boldSystemFontOfSize: _fontSize]];

  [label sizeToFit];
  [self addSubview: label];

  noteRect = NSMakeRect(NSMaxX([label frame]) + 5, y,
			400, 400);
  _noteView = [[NSTextView alloc] initWithFrame: noteRect];

  [_noteView setMinSize: NSMakeSize(50, 50)];
  [_noteView setMaxSize: NSMakeSize(400, 400)];
  [_noteView setVerticallyResizable: YES];
  [_noteView setHorizontallyResizable: YES];
  [_noteView setDelegate: self];
  note = [_person valueForProperty: ADNoteProperty];
  if (note != nil)
    [_noteView setString: note];
  [_noteView setFont: [NSFont systemFontOfSize: _fontSize]];
  _noteTextChanged = NO;

  if(_editable)
    {
      [_noteView setEditable: YES];
    }
  else
    [_noteView setEditable: NO];

  [self addSubview: _noteView];

  [self calcSize];
}

- (BOOL) fillsSuperview
{
  return _fillsSuperview;
}

- (void) setFillsSuperview: (BOOL) yesno
{
  _fillsSuperview = yesno;
  [self calcSize];
}

- (void) calcSize
{
  NSEnumerator *e;
  NSView *view;
  NSSize sizeNeeded;
  NSSize nvSize, nvMaxSize, nvMinSize;

  if(_fillsSuperview)
    {
      sizeNeeded = [[self superview] frame].size;
      if (sizeNeeded.width > 10)
	sizeNeeded.width -= 10;
      if (sizeNeeded.height > 15)
	sizeNeeded.height -= 15;
    }
  else
    sizeNeeded = NSMakeSize(0, 0);
  e = [[self subviews] objectEnumerator];
  while((view = [e nextObject]))
    {
      NSRect r;

      r = [view frame];

      sizeNeeded.height = r.origin.y + r.size.height;
      if(view != _noteView)
	sizeNeeded.width = MAX(sizeNeeded.width,
			       r.origin.x + r.size.width);
    }
  sizeNeeded.width += 10;
  sizeNeeded.height += 15;

  if(_fillsSuperview && [self superview])
    {
      NSSize superSize = [[self superview] frame].size;
      if(sizeNeeded.height < superSize.height)
	sizeNeeded.height = superSize.height;
      if(sizeNeeded.width < superSize.width)
	sizeNeeded.width = superSize.width;
    }

  if(_noteView)
    {
      nvSize = NSMakeSize(sizeNeeded.width - [_noteView frame].origin.x - 5,
			  [_noteView frame].size.height);
      nvMinSize = NSMakeSize(nvSize.width, [_noteView minSize].height);
      nvMaxSize = NSMakeSize(nvSize.width, [_noteView maxSize].height);
      [_noteView setFrameSize: nvSize];
      [_noteView setMinSize: nvMinSize];
      [_noteView setMaxSize: nvMaxSize];
    }
  
  [self setFrameSize: sizeNeeded];
}

- (void) setPerson: (ADPerson*) aPerson
{
  if(aPerson == _person || aPerson == nil)
    return;
  
  [_person release];
  _person = [aPerson retain];

  [self setFrame: NSZeroRect];
  [self layout];
}

- (ADPerson*) person
{
  return _person;
}

- (void) setDisplaysImage: (BOOL) yesno
{
  if(yesno == _displaysImage)
    return;
  _displaysImage = yesno;
  if([_person imageData])
    [self layout];
}

- (BOOL) displaysImage
{
  return _displaysImage;
}

- (void) setForceImage: (BOOL) yesno
{
  if(yesno == _forceImage)
    return;
  _forceImage = yesno;
  [self layout];
}

- (BOOL) forceImage
{
  return _forceImage;
}

- (void) drawRect: (NSRect) rect
{
  NSBezierPath *p; ADPersonPropertyView *v; NSEnumerator *e;
  NSRect r; float x;

  [self calcSize];
  
  [self lockFocus];

  if(![self isEditable])
    [[NSColor textBackgroundColor] set];
  else
    [[NSColor textBackgroundColor] set];

  NSRectFill(rect);

  if(!_person)
    {
      NSPoint p; NSSize s1, s2;

      NSAttributedString *str = [[[NSAttributedString alloc]
				   initWithString: _(@"No Person Selected")]
				  autorelease];
      [[NSColor disabledControlTextColor] set];

      s1 = [str size];
      s2 = [self frame].size;
      p.x = (s2.width-s1.width)/2;
      p.y = (s2.height-s1.height)/2;
      [str drawAtPoint: p];
      
      [self unlockFocus];
      return;
    }

  x = 5;

  if([_person readOnly])
    {
      [_lockImg compositeToPoint: NSMakePoint(x, _iconY)
		operation: NSCompositeCopy];
      x += [_lockImg size].width + 2;
    }

  if([_person shared])
    {
      [_shareImg compositeToPoint: NSMakePoint(x, _iconY)
		 operation: NSCompositeCopy];
      x += [_shareImg size].width + 2;
    }

  if([[_person uniqueId]
       isEqualToString: [[[_person addressBook] me] uniqueId]])
    {
      NSFont *meFont;
      NSMutableAttributedString *str;
      float y;
      
      meFont = [NSFont boldSystemFontOfSize: 8];
      str = [[[NSMutableAttributedString alloc] initWithString: _(@"Me")]
	      autorelease];

      [str addAttribute: NSFontAttributeName
	   value: meFont
	   range: NSMakeRange(0, [str length])];

      y = _iconY - [meFont boundingRectForFont].size.height;
      r = NSMakeRect(x, y, [meFont widthOfString: _(@"Me")],
		     [meFont boundingRectForFont].size.height);
		     
      [str drawInRect: r];
      x += r.size.width + 2;
    }

  
  [[NSColor disabledControlTextColor] set];
  p = [NSBezierPath bezierPath];
  [p moveToPoint: NSMakePoint(5, _headerLineY)];
  [p lineToPoint: NSMakePoint([self frame].size.width-5, _headerLineY)];
  [p stroke];

  // find last subview that actually displays anything and draw the
  // line directly underneath it
  e = [[self subviews] reverseObjectEnumerator];
  while((v = [e nextObject]))
    {
      if([v respondsToSelector: @selector(hasCells)])
	{
	  if([v hasCells]) break;
	}
      else
	break;
    }
  r = [_noteView frame];
  _footerLineY = r.origin.y - 7;
  if(_footerLineY > _headerLineY)
    {
      p = [NSBezierPath bezierPath];
      [p moveToPoint: NSMakePoint(5, _footerLineY)];
      [p lineToPoint: NSMakePoint([self frame].size.width-5, _footerLineY)];
      [p stroke];
    }
  
  [self unlockFocus];
}

- (BOOL) isEditable
{
  return _editable;
}

- (void) setEditable: (BOOL) yn
{
  if(yn == _editable)
    return;
  _editable = yn;

  if(_noteTextChanged)
    {
      NSString *note = [_person valueForProperty: ADNoteProperty];
      if(note)
	{
	  if([[_noteView string] isEqualToString: @""])
	    [_person removeValueForProperty: ADNoteProperty];
	  else
	    [_person setValue: [_noteView string] forProperty: ADNoteProperty];
	}
      else if(![[_noteView string] isEqualToString: @""])
	[_person setValue: [_noteView string] forProperty: ADNoteProperty];
    }

  [self layout];
}

- (void) beginEditingInFirstCell
{
  NSArray *subs;
  
  if(!_editable) [self setEditable: YES];
  
  subs = [self subviews];
  _editingViewIndex = 0;

  while(![[subs objectAtIndex: _editingViewIndex]
	   respondsToSelector: @selector(hasEditableCells)] ||
	![[subs objectAtIndex: _editingViewIndex] hasEditableCells])
    _editingViewIndex++;
  [[subs objectAtIndex: _editingViewIndex] beginEditingInFirstCell];
}

- (void) superviewFrameChanged: (NSNotification*) note
{
  if([self isDescendantOf: [note object]] && self != [note object])
    [self layout];
}

- (void) imageClicked: (id) sender
{
  NSOpenPanel *panel;
  NSArray *types;
  int retval;

  if(!_editable) return;

  panel = [NSOpenPanel openPanel];
  types = [NSArray arrayWithObjects: @"jpg", @"JPG", @"jpeg", @"JPEG",
			    @"tiff", @"TIFF", @"tif", @"TIF", @"png", @"PNG", nil];
  [panel setCanChooseFiles: YES];
  [panel setCanChooseDirectories: NO];
  [panel setAllowsMultipleSelection: NO];
  retval = [panel runModalForTypes: types];

  if(retval == NSCancelButton) return;

  if([[panel filenames] count] != 1)
    {
      NSLog(@"Argh! %" PRIuPTR " filenames; 1 expected\n", [[panel filenames] count]);
      return;
    }
  if(![_person setImageDataWithFile: [[panel filenames] objectAtIndex: 0]])
    NSRunAlertPanel(_(@"Error Loading Image"),
		    [NSString stringWithFormat: _(@"The image file %@ could "
						  @"not be loaded.")],
		    _(@"OK"), nil, nil, nil);
  else
    [self layout];
}
  
- (void) cleanupEmptyProperty: (NSString*) property
{
  ADPropertyType type;

  type = [ADPerson typeOfProperty: property];

  if(type == ADStringProperty)
    {
      if([[_person valueForProperty: property] isEqualToString: @""] ||
	 [[_person valueForProperty: property]
	   isEqualToString: [[self class] emptyValueForProperty: property]])
	[_person removeValueForProperty: property];
      return;
    }
  else if(type == ADMultiStringProperty)
    {
      ADMutableMultiValue *mv; int i; BOOL didSomeWork, didSomethingAtAll;
      
      mv = [_person valueForProperty: property];
      if(![mv count]) return;
      
      didSomeWork = YES; didSomethingAtAll = NO;
      while(didSomeWork)
	{
	  didSomeWork = NO;
	  for(i=0; i<[mv count]; i++)
	    if([[mv valueAtIndex: i]
		 isEqualToString: [[self class]
				    emptyValueForProperty: property]])
	      {
		[mv removeValueAndLabelAtIndex: i];
		didSomeWork = YES;
		didSomethingAtAll = NO;
		i = 0;
		break;
	      }
	}
      if(didSomethingAtAll)
	[_person setValue: mv forProperty: property];
    }      
  else if(type == ADMultiDictionaryProperty)
    {
      ADMutableMultiValue *mv; int i; BOOL didSomeWork, didSomethingAtAll;

      mv = [[[ADMutableMultiValue alloc]
	      initWithMultiValue: [_person valueForProperty: property]]
	     autorelease];
      if(![mv count]) return;
      
      didSomeWork = YES; didSomethingAtAll = NO;
      while(didSomeWork)
	{
	  didSomeWork = NO;
	  for(i=0; i<[mv count]; i++)
	    if(![[mv valueAtIndex: i] count])
	      {
		[mv removeValueAndLabelAtIndex: i];
		didSomeWork = YES;
		didSomethingAtAll = NO;
		i = 0;
		break;
	      }
	}
      if(didSomethingAtAll)
	[_person setValue: mv forProperty: property];
    }
}

- (void) cleanupEmptyProperties
{
  NSEnumerator *e; NSString *prop;

  e = [[ADPerson properties] objectEnumerator];
  while((prop = [e nextObject]))
    [self cleanupEmptyProperty: prop];
}

- (void) setDelegate: (id) delegate
{
  _delegate = delegate;
}

- (id) delegate
{
  return _delegate;
}

- (void) setAcceptsDrop: (BOOL) yesno
{
  _acceptsDrop = yesno;
}

- (BOOL) acceptsDrop
{
  return _acceptsDrop;
}

- (void) setFontSize: (float) fontSize
{
  if(_fontSize == fontSize)
    return;
  _fontSize = fontSize;
  [self layout];
}

- (float) fontSize
{
  return _fontSize;
}

/*
 * Delegate methods
 */

- (BOOL) canPerformClickForProperty: (id) property
{
  if([property isEqualToString: ADEmailProperty] ||
     [property isEqualToString: ADHomePageProperty])
    return YES;
  return NO;
}

- (void) clickedOnProperty: (id) property
		 withValue: (id) value
		    inView: (id) sender
{
  if([property isEqualToString: ADEmailProperty])
    {
      NSString *mailAction = [[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultMailAction"];
      if ([mailAction length] == 0)
        mailAction = @"GNUMail/New Mail with recipient";

      NSPasteboard *pb = [NSPasteboard generalPasteboard];
      [pb declareTypes: [NSArray arrayWithObjects: NSStringPboardType, nil]
	  owner: self];
      [pb setString: value forType: NSStringPboardType];

      NSPerformService(mailAction, pb);
    }
  else if([property isEqualToString: ADHomePageProperty])
    {
      NSURL *url = [NSURL URLWithString: value];
      NSString *urlAction = [[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultURLAction"];
      if (url && [urlAction length])
        {
          NSPasteboard *pb = [NSPasteboard generalPasteboard];
          [pb declareTypes: [NSArray arrayWithObjects: NSStringPboardType, nil]
	             owner: self];
          [pb setString: value forType: NSStringPboardType];

          NSPerformService(urlAction, pb);
        }
      else if (url)
       {
         [[NSWorkspace sharedWorkspace] openURL: url];
       }
    }
}

- (void) valueForProperty: (id) property
	   changedToValue: (id) value
		   inView: (id) sender
{
}

- (void) viewWillBeginEditing: (id) view
{
  int i;

  for(i=0; i<[[self subviews] count]; i++)
    {
      id v = [[self subviews] objectAtIndex: i];
      if(v == view)
	_editingViewIndex = i;
      else if([v isKindOfClass: [ADPersonPropertyView class]])
	[v endEditing];
    }
}

- (void) view: (id) view
changedWidthFrom: (float) w1
	   to: (float) w2
{
  NSPoint o;
  NSEnumerator *e;
  ADPersonPropertyView *v;

  if(!view) return;
  
  o = [view frame].origin;
  e = [[self subviews] objectEnumerator];
  while((v = [e nextObject]))
    {
      NSPoint p;
      if(v == view) continue;
      p = [v frame].origin;
      if(p.y == o.y && p.x > o.x)
	{
	  p.x += (w2-w1);
	  [v setFrameOrigin: p];
	}
    }
  [self setNeedsDisplay: YES];
}

- (void) view: (id) view
changedHeightFrom: (float) oldH
	   to: (float) newH
{
  NSPoint o;
  NSEnumerator *e;
  ADPersonPropertyView *v;

  if(!view) return;

  o = [view frame].origin;
  e = [[self subviews] objectEnumerator];
  while((v = [e nextObject]))
    {
      NSPoint p;
      if(v == view) continue;
      p = [v frame].origin;
      if(p.y > o.y)
	{
	  p.y += (newH-oldH);
	  [v setFrameOrigin: p];
	}
    }
  [self setNeedsDisplay: YES];
}

- (void) beginEditingInNextViewWithTextMovement: (int) movement
{
  NSArray *subs;

  [self layout];
  
  subs = [self subviews];
  if(![subs count]) return;
  
  switch(movement)
    {
    case NSReturnTextMovement:
      return;
      
    case NSTabTextMovement:
      do {
	_editingViewIndex++;
	if(_editingViewIndex >= [subs count])
	  _editingViewIndex = 0;
	if([[subs objectAtIndex: _editingViewIndex]
	     respondsToSelector: @selector(hasEditableCells)] &&
	   [[subs objectAtIndex: _editingViewIndex]
	     hasEditableCells])
	  break;
      } while(YES);
      [[subs objectAtIndex: _editingViewIndex] beginEditingInFirstCell];
      break;

    case NSBacktabTextMovement:
      do {
	_editingViewIndex--;
	if(_editingViewIndex < 0)
	  _editingViewIndex = [subs count]-1;
	if([[subs objectAtIndex: _editingViewIndex]
	     respondsToSelector: @selector(hasEditableCells)] &&
	   [[subs objectAtIndex: _editingViewIndex]
	     hasEditableCells])
	  break;
      } while(YES);
      [[subs objectAtIndex: _editingViewIndex] beginEditingInLastCell];
      break;
    default:
      break;
    }
}

- (BOOL) personPropertyView: (ADPersonPropertyView*) view
	      willDragValue: (NSString*) value
		forProperty: (NSString*) aProperty
{
  if(!_delegate ||
     ![_delegate
	respondsToSelector: @selector(personView:willDragProperty:)] ||
     ![_delegate personView: self willDragProperty: aProperty])
    return NO;
  return YES;
}

- (BOOL) personPropertyView: (ADPersonPropertyView*) view
	     willDragPerson: (ADPerson*) aPerson
{
  if(!_delegate ||
     ![_delegate
	respondsToSelector: @selector(personView:willDragPerson:)] ||
     ![_delegate personView: self willDragPerson: aPerson])
    return NO;
  return YES;
}

- (BOOL) imageView: (ADImageView*) view
     willDragImage: (NSImage*) image
{
  if(!_delegate ||
     ![_delegate
	respondsToSelector: @selector(personView:willDragProperty:)] ||
     ![_delegate personView: self willDragProperty: ADImageProperty])
    return NO;
  return YES;
}

- (BOOL) imageView: (ADImageView*) view
    willDragPerson: (ADPerson*) aPerson
{
  if(!_delegate ||
     ![_delegate
	respondsToSelector: @selector(personView:willDragPerson:)] ||
     ![_delegate personView: self willDragPerson: aPerson])
    return NO;
  return YES;
}

- (NSImage*) draggingImage
{
  return _vcfImage;
}

/*
 * NoteView delegate methods
 */

- (void) textDidChange: (NSNotification*) aNotification
{
  id view;

  view = [aNotification object];
  if(view != _noteView)
    return;

  _noteTextChanged = YES;
  [view sizeToFit];
  [self calcSize];
}

- (void) textDidEndEditing: (NSNotification*) aNotification
{
  id view; NSString *note;

  view = [aNotification object];
  if(view != _noteView)
    return;

  note = [_person valueForProperty: ADNoteProperty];
  if(note)
    {
      if([[view string] isEqualToString: @""])
	[_person removeValueForProperty: ADNoteProperty];
      else
	[_person setValue: [view string] forProperty: ADNoteProperty];
    }
  else if(![[view string] isEqualToString: @""])
    [_person setValue: [view string] forProperty: ADNoteProperty];

  _noteTextChanged = NO;
}

/*
 * action methods
 */

- (void) mouseDown: (NSEvent*) event
{
  NSEnumerator *e;
  id v;

  e = [[self subviews] objectEnumerator];
  while((v = [e nextObject]))
    if([v isKindOfClass: [ADPersonPropertyView class]])
      [v endEditing];
  [self layout];
  [super mouseDown: event];

  _mouseDownOnSelf = YES;
}

- (void) _DISABLED_mouseDragged: (NSEvent*) event
{
  NSPasteboard *pb;
  NSString *str;
  NSMutableDictionary *dict;
  
  if(!_mouseDownOnSelf || _editable)
    return;

  if(!_delegate ||
     ![_delegate respondsToSelector: @selector(personView:willDragPerson:)] ||
     ![_delegate personView: self willDragPerson: _person])
    return;
  
  pb = [NSPasteboard pasteboardWithName: NSDragPboard];
  [pb declareTypes: [NSArray arrayWithObjects: @"NSVCardPboardType",
			     @"NSFilesPromisePboardType",
			     NSStringPboardType,
			     ADPeoplePboardType,
			     nil]
      owner: self];

  [pb setData: [_person vCardRepresentation] forType: @"NSVCardPboardType"];

  dict = [NSMutableDictionary dictionary];
  [dict setObject: [NSString stringWithFormat: @"%d",
			     [[NSProcessInfo processInfo] processIdentifier]]
	forKey: @"PID"];
  if([_person uniqueId])
    [dict setObject: [_person uniqueId]
	  forKey: @"UID"];
  if([_person addressBook])
    [dict setObject: [[_person addressBook] addressBookDescription]
	  forKey: @"AB"];
  [pb setPropertyList: [NSArray arrayWithObject: dict]
      forType: ADPeoplePboardType];

  if([[_person valueForProperty: ADEmailProperty] count])
    str = [NSString stringWithFormat: @"%@ <%@>",
		    [_person screenNameWithFormat: ADScreenNameFirstNameFirst],
		    [[_person valueForProperty: ADEmailProperty]
		      valueAtIndex: 0]];
  else
    str = [_person screenName];
  [pb setString: str forType: NSStringPboardType];

  [self dragImage: _vcfImage
	at: NSZeroPoint
	offset: NSZeroSize
	event: event
	pasteboard: pb
	source: self
	slideBack: YES];
}

- (void) mouseUp: (NSEvent*) event
{
  _mouseDownOnSelf = NO;
}

/*
 * Drag and drop
 */

- (NSDragOperation) draggingEntered: (id<NSDraggingInfo>) sender
{
  BOOL ok; NSPasteboard *pb; NSArray *types;

  if([sender draggingSource] == self ||
     ([[sender draggingSource] isKindOfClass: [NSView class]] &&
      [[sender draggingSource] isDescendantOf: self]))
    return NO;
  
  ok = NO;
  pb = [sender draggingPasteboard];
  types = [pb types];

  if([types containsObject: NSFilenamesPboardType])
    {
      NSArray *arr; NSString *fname, *ext;
      NSArray *imgExts;

      arr = [pb propertyListForType: NSFilenamesPboardType];

      if(![arr isKindOfClass: [NSArray class]] ||
	 [arr count] != 1)
	return NSDragOperationNone;

      fname = [arr objectAtIndex: 0];
      ext = [[fname pathExtension] lowercaseString];
      imgExts = [NSArray arrayWithObjects: @"vcf", @"jpg", @"jpeg", @"tif",
			 @"tiff", nil];

      // accept image only if we have a person
      if([imgExts containsObject: ext] && !_person)
	return NSDragOperationNone;
      // don't accept anything besides images and VCFs
      else if(![imgExts containsObject: ext] &&
	      ![ext isEqualToString: @"vcf"])
	return NSDragOperationNone;
    }
  
  if(_delegate &&
     [_delegate respondsToSelector: @selector(personView:shouldAcceptDrop:)])
    {
      if([_delegate personView: self shouldAcceptDrop: sender])
	ok = YES;
      else
	ok = NO;
    }
  else
    {
      if(_acceptsDrop) ok = YES;
      else ok = NO;
    }

  if(ok)
    return NSDragOperationCopy;
  else
    return NSDragOperationNone;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>) sender
{
  BOOL ok; NSPasteboard *pb; NSArray *types;

  if([sender draggingSource] == self ||
     ([[sender draggingSource] isKindOfClass: [NSView class]] &&
      [[sender draggingSource] isDescendantOf: self]))
    return NO;

  ok = NO;
  pb = [sender draggingPasteboard];
  types = [pb types];

  if(_delegate &&
     [_delegate respondsToSelector: @selector(personView:shouldAcceptDrop:)])
    {
      if(![_delegate personView: self shouldAcceptDrop: sender])
	return NO;
    }
  else
    {
      if(!_acceptsDrop)
	return NO;
    }

  return YES;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>) sender
{
  BOOL ok; NSPasteboard *pb; NSArray *types;

  ok = NO;
  pb = [sender draggingPasteboard];
  types = [pb types];

  if([types containsObject: NSFilenamesPboardType])
    {
      NSArray *arr; NSString *fname, *ext;

      arr = [pb propertyListForType: NSFilenamesPboardType];

      if(![arr isKindOfClass: [NSArray class]] ||
	 [arr count] != 1)
	return NSDragOperationNone;

      fname = [arr objectAtIndex: 0];
      ext = [[fname pathExtension] lowercaseString];

      // convert vcf file
      if([ext isEqualToString: @"vcf"])
	{
	  NSMutableArray *ppl;
	  id conv; ADRecord *r;

	  conv = [[ADConverterManager sharedManager] 
		   inputConverterWithFile: fname];
	  ppl = [NSMutableArray array];
	  while((r = [conv nextRecord]))
	    {
	      if(![r isKindOfClass: [ADPerson class]])
		continue;
	      [ppl addObject: r];
	    }
	  if(![ppl count]) return NO;

	  if(_delegate &&
	     [_delegate respondsToSelector:
			  @selector(personView:receivedDroppedPersons:)])
	    {
	      if(![_delegate personView: self receivedDroppedPersons: ppl])
		return NO;
	    }
	  else
	    [self setPerson: [ppl objectAtIndex: 0]];
	  return YES;
	}

      else if([[NSArray arrayWithObjects: @"jpg", @"jpeg", @"tif", @"tiff",
			nil] containsObject: ext])
	{
	  if(!_person) return NO;
	  if(![_person setImageDataWithFile: fname]) return NO;
	  [self layout];
	  return YES;
	}
    }

  else if([types containsObject: NSTIFFPboardType])
    {
      NSData *data = [pb dataForType: NSTIFFPboardType];
      if(![_person setImageData: data]) return NO;
      if(![_person setImageDataType: @"tiff"]) return NO;
      [self layout];
      return YES;
    }

  else if([types containsObject: @"NSVCardPboardType"])
    {
      ADPerson *p;
      NSData *data;

      data = [pb dataForType: @"NSVCardPboardType"];
      p = [[[ADPerson alloc] initWithVCardRepresentation: data] autorelease];
      if(!p)
	return NO;

      if(_delegate &&
	 [_delegate respondsToSelector:
		      @selector(personView:receivedDroppedPersons:)])
	{
	  if(![_delegate personView: self
			 receivedDroppedPersons: [NSArray arrayWithObject: p]])
	    return NO;
	}
      else
	[self setPerson: p];

      return YES;
    }

  return NO;
}

- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL) isLocal
{
  return NSDragOperationCopy|NSDragOperationLink;
}
@end

@implementation ADPersonView (PropertyMangling)
+ (NSString*) nextLabelAfter: (NSString*) previous
		 forProperty: (NSString*) property
{
  NSArray *arr; NSInteger index;
  
  arr = [_labelDict objectForKey: property];
  if(!arr || ![arr count]) arr = [_labelDict objectForKey: @"Default"];
  if(!arr || ![arr count]) return @"!!UNKNOWN!!";

  index = [arr indexOfObject: previous];
  if(index == NSNotFound) return [arr objectAtIndex: 0];
  index++; if(index >= [arr count]) index = 0;
  return [arr objectAtIndex: index];
}

+ (NSString*) defaultLabelForProperty: (NSString*) property
{
  NSArray *arr;

  arr = [_labelDict objectForKey: property];
  if(!arr || ![arr count]) arr = [_labelDict objectForKey: @"Default"];
  if(!arr || ![arr count]) return @"!!UNKNOWN!!";
  return [arr objectAtIndex: 0];
}

+ (id) emptyValueForProperty: (NSString*) property
{
  ADPropertyType type = [ADPerson typeOfProperty: property];
  switch(type)
    {
    case ADDateProperty:
    case ADStringProperty:
    case ADMultiStringProperty:
      return [NSString stringWithFormat: @"[%@]",
		       ADLocalizedPropertyOrLabel(property)];
    case ADDictionaryProperty:
    case ADMultiDictionaryProperty:
      return [NSMutableDictionary dictionary];

    default:
      NSLog(@"Can't create empty value for %@ (type 0x%x)\n",
	    property, type);
    }

  return nil;
}

+ (NSArray*) layoutRuleForProperty: (NSString*) property
  			     value: (NSDictionary*) dict
{
  NSString *countryCode, *countryName;
  NSArray *layout;

  countryCode =  [dict objectForKey: ADAddressCountryCodeKey];
  countryName = [dict objectForKey: ADAddressCountryKey];
  if(!countryCode && countryName)
    countryCode = [self isoCountryCodeForCountryName: countryName];
  if(!countryCode && __defaultCountryCode)
    countryCode = __defaultCountryCode;
  if(!countryCode)
    countryCode = [self isoCountryCodeForCurrentLocale];

  layout = [_addressLayoutDict objectForKey: countryCode];
  if(!layout)
    layout = [_addressLayoutDict objectForKey: @"Default"];

  return layout;
}

+ (NSString*) isoCountryCodeForCountryName: (NSString*) name
{
  NSEnumerator *e; NSString *key;

  e = [[_isoCodeDict allKeys] objectEnumerator];
  while((key = [e nextObject]))
    if([[_isoCodeDict objectForKey: key] containsObject: name])
      return key;
  
  NSLog(@"No default set\n");
  return [self isoCountryCodeForCurrentLocale];
}

+ (void) setDefaultISOCountryCode: (NSString*) code
{
  [__defaultCountryCode release];
  __defaultCountryCode = [code copy];
}

+ (NSString*) isoCountryCodeForCurrentLocale
{
  NSString *lang; NSRange range;

  lang = [[[NSProcessInfo processInfo] environment] objectForKey: @"LANG"];
  if(!lang) return @"us"; // hard-coded default!!

  range = [lang rangeOfString: @"_"];
  if(range.location != NSNotFound)
    lang = [[lang substringFromIndex: range.location+range.length]
	     lowercaseString];

  if(![[_isoCodeDict allKeys] containsObject: lang])
    lang = @"us";
  
  return lang;
}

@end
