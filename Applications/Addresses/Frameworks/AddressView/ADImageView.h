// ADImageView.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address View Framework for GNUstep
// 

#import <Addresses/Addresses.h>
#import <AppKit/AppKit.h>


@interface ADImageView: NSImageView
{
  id __target;
  SEL _selector;
  id _delegate;
  ADPerson *_person;
  BOOL _mouseDownOnSelf, _mouseDragged;
}
- initWithFrame: (NSRect) frame;
- (void) setTarget: (id) target;
- (void) setAction: (SEL) sel;
- (void) mouseDown: (NSEvent*) event;
- (void) mouseUp: (NSEvent*) event;
- (void) mouseDragged: (NSEvent*) event;
- (BOOL) hasEditableCells;
- (void) setDelegate: (id) delegate;
- (id) delegate;

- (void) setPerson: (ADPerson*) person;
- (ADPerson*) person;
@end

@interface NSObject (ADImageViewDelegate)
- (BOOL) imageView: (ADImageView*) view
     willDragImage: (NSImage*) image;
- (BOOL) imageView: (ADImageView*) view
    willDragPerson: (ADPerson*) aPerson;
- (NSImage*) draggingImage;
@end
