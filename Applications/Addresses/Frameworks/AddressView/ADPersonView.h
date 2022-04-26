/* This is -*- ObjC -*-)

   ADPersonView.h   
   Author: Björn Giesler <giesler@ira.uka.de>
   
 */

#import <AppKit/AppKit.h>
#import <Addresses/Addresses.h>

#import <AddressView/ADPersonPropertyView.h>

/**
 * Posted whenever the ADFirstName or ADLastName fields are changed.
 */
extern NSString * const ADPersonNameChangedNotification;

/**
 * Pasteboard identifier. Value for this is a NSArray:
 * ({ UID=<uniqueId>; AB=<AddressBookDescription>;
 *    PID=<pidOfProcessOwningAddressBook}, ...)
 */
extern NSString * const ADPeoplePboardType;

@interface ADPersonView: NSView <ADPersonPropertyViewDelegate>
{
  BOOL _fillsSuperview;
  ADPerson *_person;
  BOOL _editable;
  int _headerLineY, _footerLineY, _iconY;
  int _editingViewIndex;

  id _imageView, _noteView;
  BOOL _displaysImage, _forceImage;

  NSImage *_lockImg, *_shareImg;

  id _delegate;
  BOOL _acceptsDrop;
  BOOL _noteTextChanged;

  float _fontSize;

  BOOL _mouseDownOnSelf;
}

- initWithFrame: (NSRect) aRect;

- (void) layout;
- (BOOL) fillsSuperview;
- (void) setFillsSuperview: (BOOL) yesno;
- (void) calcSize;

- (void) setPerson: (ADPerson*) person;
- (ADPerson*) person;

// displays image if the person has one.
- (void) setDisplaysImage: (BOOL) yesno;
- (BOOL) displaysImage;
// always display image, displaying a dummy if the person doesn't have one.
- (void) setForceImage: (BOOL) yesno;
- (BOOL) forceImage;

- (void) drawRect: (NSRect) rect;

- (BOOL) isEditable;
- (void) setEditable: (BOOL) yn;
- (void) beginEditingInFirstCell;

- (void) superviewFrameChanged: (NSNotification*) note;
- (void) imageClicked: (id) sender;

- (void) cleanupEmptyProperty: (NSString*) prop;
- (void) cleanupEmptyProperties;

- (void) setDelegate: (id) delegate;
- (id) delegate;

- (void) setAcceptsDrop: (BOOL) yesno;
- (BOOL) acceptsDrop;

- (void) setFontSize: (float) fontSize;
- (float) fontSize;
@end

@interface ADPersonView (PropertyMangling)
+ (NSString*) nextLabelAfter: (NSString*) previous
		 forProperty: (NSString*) property;
+ (NSString*) defaultLabelForProperty: (NSString*) property;
+ (id) emptyValueForProperty: (NSString*) property;
+ (NSArray*) layoutRuleForProperty: (NSString*) property
			     value: (NSDictionary*) dict;

+ (NSString*) isoCountryCodeForCountryName: (NSString*) name;
+ (NSString*) isoCountryCodeForCurrentLocale;
+ (void) setDefaultISOCountryCode: (NSString*) code;
@end

@interface NSObject (ADPersonViewDelegate)
- (BOOL) personView: (ADPersonView*) aView
   shouldAcceptDrop: (id<NSDraggingInfo>) info;
- (BOOL) personView: (ADPersonView*) aView
receivedDroppedPersons: (NSArray*) persons;

- (BOOL) personView: (ADPersonView*) aView
   willDragProperty: (NSString*) aProperty;
- (BOOL) personView: (ADPersonView*) aView
      willDragImage: (NSImage*) anImage;
- (BOOL) personView: (ADPersonView*) aView
     willDragPerson: (ADPerson*) aPerson;
@end

