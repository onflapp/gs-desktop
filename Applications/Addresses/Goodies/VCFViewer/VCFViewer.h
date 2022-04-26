// VCFViewer.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// VCF Content Viewer for GWorkspace
// 
// $Author: rmottola $
// $Locker:  $
// $Revision: 1.4 $
// $Date: 2009/09/29 21:20:24 $


#import <Foundation/Foundation.h>
#import <Inspector/ContentViewersProtocol.h>
#import <Addresses/Addresses.h>
#import <AddressView/ADPersonView.h>

@protocol ContentInspectorProtocol
- (void)contentsReadyAt:(NSString *)path;
@end

@interface VCFViewer: NSView <ContentViewersProtocol>
{
  id panel;
  NSArray *people;
  int currentPerson;

  NSScrollView *sv;
  NSClipView *cv;
  ADPersonView *pv;
  NSButton *nb, *pb;
  NSTextField *lbl;
  NSButton *ifb, *dfb;

  NSString *bundlePath;
  NSString *vcfPath;
  NSWorkspace *ws;
  id<ContentInspectorProtocol> inspector;
}

- (void) nextPerson: (id) sender;
- (void) previousPerson: (id) sender;

- (void) increaseFontSize: (id) sender;
- (void) decreaseFontSize: (id) sender;
@end

