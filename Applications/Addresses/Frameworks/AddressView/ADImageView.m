// ADImageView.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address View Framwork for GNUstep
// 

/* my includes */
#import "ADImageView.h"
#import "ADPersonView.h"

@implementation ADImageView
- initWithFrame: (NSRect) frame
{
  [super initWithFrame: frame];
  [self registerForDraggedTypes: [NSArray arrayWithObjects:
					    @"NSVCardPboardType",
					  NSTIFFPboardType,
					  NSFilenamesPboardType,
					  nil]];
  _delegate = nil;
  _person = nil;
  _mouseDownOnSelf = NO;
  
  return self;
}

- (void) dealloc
{
  [_person release];
  [super dealloc];
}

- (void) setTarget: (id) target
{
  __target = target;
}

- (void) setAction: (SEL) sel
{
  _selector = sel;
}

- (void) mouseDown: (NSEvent*) event
{
  _mouseDownOnSelf = YES;
  _mouseDragged = NO;
}

- (void) mouseUp: (NSEvent*) event
{
  if(_mouseDragged)
    return;
  if([__target respondsToSelector: _selector])
    [__target performSelector: _selector withObject: self];
}

- (void) _DISABLED_mouseDragged: (NSEvent*) event
{
  NSPasteboard *pb;

  if(!_mouseDownOnSelf || !_delegate)
    return;
  if([[self superview] isKindOfClass: [ADPersonView class]] &&
     [(ADPersonView*)[self superview] isEditable])
    return;
  
  pb = [NSPasteboard pasteboardWithName: NSDragPboard];

  if([_person imageData] &&
     [_delegate respondsToSelector: @selector(imageView:willDragImage:)] &&
     [_delegate imageView: self
		willDragImage: [self image]])
    {
      [pb declareTypes: [NSArray arrayWithObject: NSTIFFPboardType]
	  owner: self];
      [pb setData: [[self image] TIFFRepresentation]
	  forType: NSTIFFPboardType];

      [self dragImage: [self image]
	    at: NSZeroPoint
	    offset: NSZeroSize
	    event: event
	    pasteboard: pb
	    source: self
	    slideBack: YES];
    }
  else if(![_person imageData] &&
	  [_delegate respondsToSelector: @selector(imageView:willDragPerson:)] &&
	  [_delegate imageView: self
		     willDragPerson: _person])
    {
      NSString *str;
      NSMutableDictionary *dict;
      
      [pb declareTypes: [NSArray arrayWithObjects: @"NSVCardPboardType",
				 @"NSFilesPromisePboardType",
				 NSStringPboardType,
				 ADPeoplePboardType,
				 nil]
	  owner: self];
      [pb setData: [_person vCardRepresentation]
	  forType: @"NSVCardPboardType"];

      dict = [NSMutableDictionary dictionary];
      [dict setObject: [NSString stringWithFormat: @"%d",
				 [[NSProcessInfo processInfo]
				   processIdentifier]]
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

      [self dragImage: [_delegate draggingImage]
	    at: NSZeroPoint
	    offset: NSZeroSize
	    event: event
	    pasteboard: pb
	    source: self
	    slideBack: YES];
    }
}

- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL) isLocal
{
  return NSDragOperationCopy|NSDragOperationLink;
}
  
- (BOOL) hasEditableCells
{
  return NO;
}

- (NSDragOperation) draggingEntered: (id<NSDraggingInfo>) sender
{
  return [[self superview] draggingEntered: sender];
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>) sender
{
  return [[self superview] prepareForDragOperation: sender];
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>) sender
{
  return [[self superview] performDragOperation: sender];
}
- (void) setDelegate: (id) delegate
{
  _delegate = delegate;
}
- (id) delegate
{
  return _delegate;
}

- (void) setPerson: (ADPerson*) person
{
  NSString *imgPath = nil;

  if(person == _person)
    return;

  [_person release];
  _person = nil;
  [self setImage: nil];

  if(!person)
    return;

  _person = [person retain];
  
  if(![_person isKindOfClass: [NSDistantObject class]])
    imgPath = [_person imageDataFile];
  if(!imgPath) imgPath = [[NSBundle bundleForClass: [self class]]
			   pathForImageResource: @"UnknownImage.tiff"];
  if(!imgPath)
    NSLog(@"Error: UnknownImage.tiff not found!\n");
  else
    {
      NSImage *img = [[[NSImage alloc] initWithContentsOfFile: imgPath]
		       autorelease];
      if(!img) NSLog(@"Error: Couldn't load %@\n", imgPath);
      else
	[self setImage: img];
    }
}

- (ADPerson*) person
{
  return _person;
}
@end
