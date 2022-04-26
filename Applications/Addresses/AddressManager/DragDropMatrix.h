/* This is -*- ObjC -*-)

   DragDropMatrix.h   
   \author: Björn Giesler <giesler@ira.uka.de>
   
   A Matrix that allows drag and drop between its cells
   
   $Author: buzzdee $
   $Locker:  $
   $Revision: 1.2 $
   $Date: 2013/02/11 10:08:40 $
 */

#ifndef DRAGDROPMATRIX_H
#define DRAGDROPMATRIX_H

/* system includes */
/* (none) */

/* my includes */
/* (none) */

@interface DragDropMatrix: NSMatrix
{
  NSBrowserCell *oldCell, *curCell;
  NSRect oldFrame;
  NSInteger groupRow;

  BOOL _didDrag;
  SEL _shouldSel, _didSel;
}
- (BOOL) acceptsFirstMouse: (NSEvent *) event;
- (void) copyToPasteboard: (NSPasteboard *) pb;
- (void) mouseDown: (NSEvent *) event;
- (void) mouseDragged: (NSEvent *) event;
- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL) local;
- (void) draggingExited:  (id<NSDraggingInfo>) sender;
- (NSDragOperation) draggingUpdated: (id<NSDraggingInfo>) sender;
- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>) sender;
- (BOOL) performDragOperation: (id<NSDraggingInfo>) sender;

- (NSImage*) draggingImage;
@end

@interface NSObject (DragDropMatrixDelegate)
- (NSDragOperation) dragDropMatrix: (DragDropMatrix*) matrix
	shouldAcceptDropFromSender: (id<NSDraggingInfo>) sender
			    onCell: (NSCell*) cell;
- (BOOL) dragDropMatrix: (DragDropMatrix*) matrix
didAcceptDropFromSender: (id<NSDraggingInfo>) sender
		 onCell: (NSCell*) cell;
@end

#endif /* DRAGDROPMATRIX_H */
